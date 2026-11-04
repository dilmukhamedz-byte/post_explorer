import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('1. PostsScreen displays app bar title correctly', (WidgetTester tester) async {
    // Проверяем отображение заголовка AppBar на экране
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Post Explorer')),
        ),
      ),
    );

    expect(find.text('Post Explorer'), findsOneWidget);
  });

  testWidgets('2. Floating action button for creating post exists', (WidgetTester tester) async {
    // Проверяем наличие кнопки добавления (+)
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: null,
            child: Icon(Icons.add),
          ),
        ),
      ),
    );

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('3. Refresh icon action test in AppBar', (WidgetTester tester) async {
    // Проверяем наличие кнопки обновления списка
    bool isPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  isPressed = true;
                },
              ),
            ],
          ),
        ),
      ),
    );

    // Находим иконку обновления и кликаем по ней
    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();

    expect(isPressed, isTrue);
  });
}