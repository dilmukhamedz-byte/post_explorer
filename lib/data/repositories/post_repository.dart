import '../remote/post_api.dart';
import '../local/post_cache.dart';
import '../models/post.dart';
import '../../core/error/app_exception.dart';

class PostRepository {
  final PostApi _api;
  final PostCache _cache;
  bool isLastFetchFromCache = false;

  PostRepository(this._api, this._cache);

  Future<List<Post>> getPosts({int page = 1, int limit = 10, int? userId}) async {
    try {
      final remotePosts = await _api.getPosts(page: page, limit: limit, userId: userId);
      if (page == 1 && userId == null) {
        await _cache.savePosts(remotePosts);
      }
      isLastFetchFromCache = false;
      return remotePosts;
    } catch (e) {
      if (page == 1) {
        final cached = _cache.getCachedPosts();
        if (cached.isNotEmpty) {
          isLastFetchFromCache = true;
          return userId != null ? cached.where((p) => p.userId == userId).toList() : cached;
        }
      }
      throw handleError(e);
    }
  }
}