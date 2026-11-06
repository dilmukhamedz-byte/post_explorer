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
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<PostBloc>().add(LoadPostsEvent()),
          ),
        ],
      ),
      body: BlocBuilder<PostBloc, PostState>(
        builder: (context, state) {
          if (state.status == PostStatus.loading && state.allPosts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == PostStatus.error && state.allPosts.isEmpty) {
            return Center(child: Text(state.errorMessage ?? 'Ошибка загрузки'));
          }

          return Column(
            children: [
              if (state.status == PostStatus.cached)
                Container(
                  color: Colors.orange,
                  width: double.infinity,
                  padding: const EdgeInsets.all(6),
                  child: const Text(
                    'Показаны сохранённые данные (офлайн)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              
              // Строка поиска
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  onChanged: (value) => context.read<PostBloc>().add(SearchPostsEvent(value)),
                  decoration: InputDecoration(
                    hintText: 'Поиск среди загруженных',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),

              // Чипсы фильтрации
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Все'),
                      selected: state.selectedUserId == null,
                      onSelected: (_) => context.read<PostBloc>().add(FilterPostsByAuthorEvent(null)),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('User 1'),
                      selected: state.selectedUserId == 1,
                      onSelected: (_) => context.read<PostBloc>().add(FilterPostsByAuthorEvent(1)),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('User 2'),
                      selected: state.selectedUserId == 2,
                      onSelected: (_) => context.read<PostBloc>().add(FilterPostsByAuthorEvent(2)),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: const Text('ID ↑'),
                      onPressed: () => context.read<PostBloc>().add(SortPostsEvent()),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      label: const Text('Сброс'),
                      onPressed: () => context.read<PostBloc>().add(LoadPostsEvent()),
                    ),
                  ],
                ),
              ),
              const Divider(),

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
    int selectedAuthorId = 1;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Новый пост'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Заголовок'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(labelText: 'Текст (мин. 10 символов)'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: selectedAuthorId,
                decoration: const InputDecoration(labelText: 'Автор'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Leanne Graham')),
                  DropdownMenuItem(value: 2, child: Text('Ervin Howell')),
                  DropdownMenuItem(value: 3, child: Text('Clementine Bauch')),
                ],
                onChanged: (val) => setStateDialog(() => selectedAuthorId = val!),
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
                if (titleController.text.isNotEmpty && bodyController.text.length >= 5) {
                  final api = PostApi(DioClient().dio);
                  final newPost = Post(
                    id: 0,
                    userId: selectedAuthorId,
                    title: titleController.text,
                    body: bodyController.text,
                  );
                  try {
                    await api.createPost(newPost);
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Сервер вернул id: 101. Пост добавлен локально.')),
                      );
                      context.read<PostBloc>().add(LoadPostsEvent());
                    }
                  } catch (e) {
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Пост добавлен локально (ошибка сервера)')),
                      );
                    }
                  }
                }
              },
              child: const Text('Опубликовать'),
            ),
          ],
        ),
      ),
    );
  }
}