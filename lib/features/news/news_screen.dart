import 'package:flutter/material.dart';

import '../../core/services/news_api_service.dart';
import 'models/news_category.dart';
import 'models/news_item.dart';
import 'news_category_screen.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final _api = NewsApiService();
  List<NewsCategory> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final cats = await _api.fetchFeeds();
      if (mounted) {
        setState(() => _categories = cats);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Ошибка загрузки');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      } else {
        _isLoading = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_categories.isEmpty) {
      return Center(
        child: Text(_error ?? 'Нет данных'),
      );
    }

    return DefaultTabController(
      length: _categories.length + 1,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: [
              const Tab(text: 'Все новости'),
              for (final cat in _categories) Tab(text: cat.name),
            ],
            onTap: (index) {
              if (index == 0) return;
              final category = _categories[index - 1];
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => NewsCategoryScreen(category: category),
                ),
              );
            },
          ),
          const Expanded(
            child: NewsList(),
          ),
        ],
      ),
    );
  }
}

class NewsList extends StatefulWidget {
  const NewsList({super.key});

  @override
  State<NewsList> createState() => _NewsListState();
}

class _NewsListState extends State<NewsList> {
  final _api = NewsApiService();
  final _scrollController = ScrollController();
  final List<NewsItem> _items = [];
  bool _isLoading = false;
  String? _error;
  int _page = 1;
  int _pages = 1;

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _page > _pages) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final page = await _api.fetchNews(page: _page);
      setState(() {
        _items.addAll(page.items);
        _page = page.page + 1;
        _pages = page.pages;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      } else {
        _isLoading = false;
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      if (_isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_error != null) {
        return Center(child: Text(_error!));
      }
    }

    final showBottom = _isLoading || _error != null;

    return ListView.builder(
      controller: _scrollController,
      itemCount: _items.length + (showBottom ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          if (_isLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text(_error ?? 'Ошибка')),
            );
          }
        }
        final item = _items[index];
        return ListTile(
          title: Text(item.title),
          subtitle: item.published != null
              ? Text(item.published!.toLocal().toString())
              : null,
        );
      },
    );
  }
}

