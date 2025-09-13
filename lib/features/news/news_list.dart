import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/services/news_api_service.dart';
import 'models/news_item.dart';

class NewsList extends StatefulWidget {
  const NewsList({super.key, this.categoryId});

  final String? categoryId;

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
    if (_scrollController.position.extentAfter < 200) {
      _loadMore();
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _items.clear();
      _page = 1;
      _pages = 1;
      _error = null;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_isLoading || _page > _pages) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final page = await _api.fetchNews(
        page: _page,
        categoryId: widget.categoryId,
      );
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
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadMore,
                child: const Text('Повторить'),
              ),
            ],
          ),
        );
      }
    }

    final showBottom = _isLoading || _error != null;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error ?? 'Ошибка'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadMore,
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              );
            }
          }
          final item = _items[index];
          return NewsListItem(item: item);
        },
      ),
    );
  }
}

class NewsListItem extends StatelessWidget {
  const NewsListItem({super.key, required this.item});

  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (item.image.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                item.image,
                fit: BoxFit.cover,
              ),
            )
          else
            const SizedBox(
              height: 180,
              child: ColoredBox(color: Colors.black12),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  item.contentPreview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (item.published != null)
                  Text(
                    DateFormat('dd.MM.yyyy').format(item.published!),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


