import 'package:hive/hive.dart';
import '../models/post.dart';

class PostCache {
  static const String boxName = 'posts_box';

  Future<void> savePosts(List<Post> posts) async {
    final box = Hive.box<Post>(boxName);
    await box.clear();
    final map = {for (var post in posts) post.id: post};
    await box.putAll(map);
  }

  List<Post> getCachedPosts() {
    if (!Hive.isBoxOpen(boxName)) return [];
    return Hive.box<Post>(boxName).values.toList();
  }
}