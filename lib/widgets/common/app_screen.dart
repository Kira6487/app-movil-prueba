import 'package:flutter/material.dart';

class AppScreen extends StatelessWidget {
  const AppScreen({
    super.key,
    required this.title,
    this.actions = const [],
    required this.children,
  });

  final String title;
  final List<Widget> actions;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            actions: actions,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index.isOdd) {
                    return const SizedBox(height: 16);
                  }
                  return children[index ~/ 2];
                },
                childCount: children.isEmpty ? 0 : children.length * 2 - 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
