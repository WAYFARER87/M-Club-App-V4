import 'package:flutter/material.dart';

import 'models/news_category.dart';

class NewsCategoryScreen extends StatelessWidget {
  const NewsCategoryScreen({super.key, required this.category});

  final NewsCategory category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: Center(child: Text('Категория: ${category.name}')),
    );
  }
}
