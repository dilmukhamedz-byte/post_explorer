import 'package:flutter_test/flutter_test.dart';
import 'package:post_explorer/data/models/post.dart';

void main() {
  group('Post Explorer Unit Tests', () {
    
    test('1. Post.fromJson converts JSON correctly', () {
      final json = {'id': 5, 'userId': 2, 'title': 'Hello Flutter', 'body': 'Unit testing body'};
      final post = Post.fromJson(json);

      expect(post.id, 5);
      expect(post.userId, 2);
      expect(post.title, 'Hello Flutter');
      expect(post.body, 'Unit testing body');
    });

    test('2. Post.toJson converts Post to Map correctly', () {
      final post = Post(id: 1, userId: 1, title: 'Test Title', body: 'Test Body');
      final json = post.toJson();

      expect(json['id'], 1);
      expect(json['userId'], 1);
      expect(json['title'], 'Test Title');
      expect(json['body'], 'Test Body');
    });

    test('3. Post model handles unique IDs properly', () {
      final post1 = Post(id: 10, userId: 1, title: 'A', body: 'B');
      final post2 = Post(id: 20, userId: 1, title: 'A', body: 'B');

      expect(post1.id, isNot(equals(post2.id)));
    });

    test('4. Post properties type check', () {
      final post = Post(id: 1, userId: 1, title: 'Check', body: 'Immutability');
      expect(post.title, isA<String>());
      expect(post.id, isA<int>());
    });

    test('5. Post JSON mapping handles standard structure', () {
      final jsonMap = {'id': 99, 'userId': 3, 'title': 'Mock Title', 'body': 'Mock Body'};
      final post = Post.fromJson(jsonMap);
      
      expect(post.userId, equals(3));
      expect(post.body, isNotEmpty);
    });

  });
}