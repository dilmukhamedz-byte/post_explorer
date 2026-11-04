import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';

abstract class PostEvent {}
class LoadPostsEvent extends PostEvent {}
class LoadMorePostsEvent extends PostEvent {}

enum PostStatus { initial, loading, success, cached, error, paginationLoading }

class PostState {
  final PostStatus status;
  final List<Post> posts;
  final int page;
  final bool hasMore;
  final String? errorMessage;

  PostState({
    this.status = PostStatus.initial,
    this.posts = const [],
    this.page = 1,
    this.hasMore = true,
    this.errorMessage,
  });

  PostState copyWith({
    PostStatus? status,
    List<Post>? posts,
    int? page,
    bool? hasMore,
    String? errorMessage,
  }) {
    return PostState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }
}

class PostBloc extends Bloc<PostEvent, PostState> {
  final PostRepository _repository;
  static const int _limit = 10;

  PostBloc(this._repository) : super(PostState()) {
    on<LoadPostsEvent>(_onLoadPosts);
    on<LoadMorePostsEvent>(_onLoadMorePosts);
  }

  Future<void> _onLoadPosts(LoadPostsEvent event, Emitter<PostState> emit) async {
    emit(state.copyWith(status: PostStatus.loading, page: 1));
    try {
      final posts = await _repository.getPosts(page: 1, limit: _limit);
      final isCached = _repository.isLastFetchFromCache;
      
      emit(state.copyWith(
        status: isCached ? PostStatus.cached : PostStatus.success,
        posts: posts,
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

      // Защита от дубликатов по ID
      final existingIds = state.posts.map((p) => p.id).toSet();
      final uniqueNewPosts = newPosts.where((p) => !existingIds.contains(p.id)).toList();

      emit(state.copyWith(
        status: PostStatus.success,
        posts: [...state.posts, ...uniqueNewPosts],
        page: nextPage,
        hasMore: uniqueNewPosts.isNotEmpty && newPosts.length >= _limit,
      ));
    } catch (e) {
      // При ошибке пагинации не сбрасываем весь список, а возвращаем статус success
      emit(state.copyWith(status: PostStatus.success));
    }
  }
}