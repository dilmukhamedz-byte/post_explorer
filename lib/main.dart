import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/network/dio_client.dart';
import 'data/local/post_cache.dart';
import 'data/models/post.dart';
import 'data/remote/post_api.dart';
import 'data/repositories/post_repository.dart';
import 'presentation/state/post_bloc.dart';
import 'presentation/screens/posts_screen.dart';

void main() async {
  // Инициализация связей Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // Инициализация локальной базы данных Hive
  await Hive.initFlutter();
  Hive.registerAdapter(PostAdapter());
  await Hive.openBox<Post>(PostCache.boxName);

  // Внедрение зависимостей (Dependency Injection)
  final dioClient = DioClient();
  final postApi = PostApi(dioClient.dio);
  final postCache = PostCache();
  final repository = PostRepository(postApi, postCache);

  runApp(MyApp(repository: repository));
}

class MyApp extends StatelessWidget {
  final PostRepository repository;
  const MyApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Post Explorer',
      debugShowCheckedModeBanner: false, // Убирает полоску DEBUG в углу
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) => PostBloc(repository)..add(LoadPostsEvent()),
        child: const PostsScreen(),
      ),
    );
  }
}