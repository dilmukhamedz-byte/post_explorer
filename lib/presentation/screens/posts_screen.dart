import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../state/post_bloc.dart';
import 'post_detail_screen.dart';
import '../../data/remote/post_api.dart';
import '../../core/network/dio_client.dart';
import '../../data/models/post.dart';

class PostsScreen extends StatelessWidget {
  const PostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    scrollController.addListener(() {
      if (scrollController.position.pixels >= scrollController.position.maxScrollExtent * 0.9) {
        context.read<PostBloc>().add(LoadMorePostsEvent());
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Explorer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Фильтр по пользователю 1',
            onPressed: () {
              // Вы можете вызвать загрузку с фильтром
              context.read<PostBloc>().add(LoadPostsEvent());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Применен фильтр по пользователю')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PostBloc>().add(LoadPostsEvent());
            },
          ),
        ],
      ),
      body: BlocBuilder<PostBloc, PostState>(
        builder: (context, state) {
          if (state.status == PostStatus.loading && state.posts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == PostStatus.error && state.posts.isEmpty) {
            return Center(child: Text(state.errorMessage ?? 'Ошибка загрузки'));
          }

          return Column(
            children: [
              if (state.status == PostStatus.cached)
                Container(
                  color: Colors.orange,
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  child: const Text(
                    'Офлайн режим (показан кэш)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: state.posts.length + (state.status == PostStatus.paginationLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= state.posts.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final post = state.posts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        title: Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailScreen(post: post),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePostDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Новый пост'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Заголовок'),
            ),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: 'Текст'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty && bodyController.text.isNotEmpty) {
                final api = PostApi(DioClient().dio);
                final newPost = Post(
                  id: 0,
                  userId: 1,
                  title: titleController.text,
                  body: bodyController.text,
                );
                try {
                  await api.createPost(newPost);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Пост успешно создан')),
                    );
                    context.read<PostBloc>().add(LoadPostsEvent());
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ошибка при создании поста')),
                    );
                  }
                }
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }
}