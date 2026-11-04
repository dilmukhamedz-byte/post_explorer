import 'package:dio/dio.dart';
import '../models/post.dart';

class PostApi {
  final Dio _dio;

  PostApi(this._dio);

  Future<List<Post>> getPosts({int? page, int? limit, int? userId}) async {
    final response = await _dio.get(
      '/posts',
      queryParameters: {
        if (page != null) '_page': page,
        if (limit != null) '_limit': limit,
        if (userId != null) 'userId': userId,
      },
    );
    return (response.data as List).map((json) => Post.fromJson(json)).toList();
  }

  Future<Post> createPost(Post post) async {
    final response = await _dio.post('/posts', data: post.toJson());
    return Post.fromJson(response.data);
  }
  // Внутри класса PostApi добавьте этот метод:
Future<List<dynamic>> getComments(int postId) async {
  final response = await _dio.get('/posts/$postId/comments');
  return response.data as List;
}
}