import 'package:flutter_test/flutter_test.dart';
import 'package:post_explorer/data/models/post.dart';

void main() {
  test('Post serialization and deserialization test', () {
    final json = {
      'id': 1,
      'userId': 1,
      'title': 'Test Title',
      'body': 'Test Body',
    };
    
    // Проверка конвертации из JSON
    final post = Post.fromJson(json);
    expect(post.id, 1);
    expect(post.title, 'Test Title');

    // Проверка конвертации в JSON
    final resultMap = post.toJson();
    expect(resultMap['title'], 'Test Title');
    expect(resultMap['userId'], 1);
  });
}