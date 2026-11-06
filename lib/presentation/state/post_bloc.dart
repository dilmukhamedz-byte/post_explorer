import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';

abstract class PostEvent {}
class LoadPostsEvent extends PostEvent {}
class LoadMorePostsEvent extends PostEvent {}

class SearchPostsEvent extends PostEvent {
  final String query;
  SearchPostsEvent(this.query);
}

class FilterPostsByAuthorEvent extends PostEvent {
  final int? userId;
  FilterPostsByAuthorEvent(this.userId);
}

class SortPostsEvent extends PostEvent {}

enum PostStatus { initial, loading, success, cached, error, paginationLoading }

class PostState {
  final PostStatus status;
  final List<Post> posts;
  final int page;
  final bool hasMore;
  final String? errorMessage;
  final int? selectedUserId;
  final String searchQuery;
  final List<Post> allPosts; // Полный список для локального поиска и фильтров

  PostState({
    this.status = PostStatus.initial,
    this.posts = const [],
    this.page = 1,
    this.hasMore = true,
    this.errorMessage,
    this.selectedUserId,
    this.searchQuery = '',
    this.allPosts = const [],
  });

  PostState copyWith({
    PostStatus? status,
    List<Post>? posts,
    int? page,
    bool? hasMore,
    String? errorMessage,
    int? selectedUserId,
    String? searchQuery,
    List<Post>? allPosts,
  }) {
    return PostState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
      selectedUserId: selectedUserId ?? this.selectedUserId,
      searchQuery: searchQuery ?? this.searchQuery,
      allPosts: allPosts ?? this.allPosts,
    );
  }
}

class PostBloc extends Bloc<PostEvent, PostState> {
  final PostRepository _repository;
  static const int _limit = 10;

  PostBloc(this._repository) : super(PostState()) {
    on<LoadPostsEvent>(_onLoadPosts);
    on<LoadMorePostsEvent>(_onLoadMorePosts);
    on<SearchPostsEvent>(_onSearchPosts);
    on<FilterPostsByAuthorEvent>(_onFilterPostsByAuthor);
    on<SortPostsEvent>(_onSortPosts);
  }

  Future<void> _onLoadPosts(LoadPostsEvent event, Emitter<PostState> emit) async {
    emit(state.copyWith(status: PostStatus.loading, page: 1, selectedUserId: null, searchQuery: ''));
    try {
      final posts = await _repository.getPosts(page: 1, limit: _limit);
      final isCached = _repository.isLastFetchFromCache;
      
      emit(state.copyWith(
        status: isCached ? PostStatus.cached : PostStatus.success,
        posts: posts,
        allPosts: posts,
        page: 1,
        hasMore: posts.length >= _limit,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PostStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onLoadMorePosts(LoadMorePostsEvent event, Emitter<PostState> emit) async {
    if (state.status == PostStatus.paginationLoading || !state.hasMore) return;
    
    emit(state.copyWith(status: PostStatus.paginationLoading));
    try {
      final nextPage = state.page + 1;
      final newPosts = await _repository.getPosts(page: nextPage, limit: _limit);

      final existingIds = state.allPosts.map((p) => p.id).toSet();
      final uniqueNewPosts = newPosts.where((p) => !existingIds.contains(p.id)).toList();
      final updatedAll = [...state.allPosts, ...uniqueNewPosts];

      emit(state.copyWith(
        status: PostStatus.success,
        posts: updatedAll,
        allPosts: updatedAll,
        page: nextPage,
        hasMore: uniqueNewPosts.isNotEmpty && newPosts.length >= _limit,
      ));
    } catch (e) {
      emit(state.copyWith(status: PostStatus.success));
    }
  }

  void _onSearchPosts(SearchPostsEvent event, Emitter<PostState> emit) {
    final query = event.query.toLowerCase();
    var filtered = state.allPosts;

    if (state.selectedUserId != null) {
      filtered = filtered.where((p) => p.userId == state.selectedUserId).toList();
    }

    if (query.isNotEmpty) {
      filtered = filtered.where((p) => p.title.toLowerCase().contains(query) || p.body.toLowerCase().contains(query)).toList();
    }

    emit(state.copyWith(posts: filtered, searchQuery: query));
  }

  void _onFilterPostsByAuthor(FilterPostsByAuthorEvent event, Emitter<PostState> emit) {
    final userId = event.userId;
    var filtered = state.allPosts;

    if (userId != null) {
      filtered = filtered.where((p) => p.userId == userId).toList();
    }

    if (state.searchQuery.isNotEmpty) {
      filtered = filtered.where((p) => p.title.toLowerCase().contains(state.searchQuery)).toList();
    }

    emit(state.copyWith(posts: filtered, selectedUserId: userId));
  }

  void _onSortPosts(SortPostsEvent event, Emitter<PostState> emit) {
    final sorted = List<Post>.from(state.posts)..sort((a, b) => b.id.compareTo(a.id));
    emit(state.copyWith(posts: sorted));
  }
}