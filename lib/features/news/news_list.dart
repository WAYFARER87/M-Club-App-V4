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
  const NewsListItem({super.key, required this.item, this.onTap});

  final NewsItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final imageHeight = MediaQuery.of(context).size.width * 0.6;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.image.isNotEmpty)
            Image.network(
              item.image,
              width: double.infinity,
              height: imageHeight,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: imageHeight,
                color: Colors.grey.shade200,
              ),
            )
          else
            Container(
              width: double.infinity,
              height: imageHeight,
              color: Colors.grey.shade200,
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Roboto',
                  ),
                ),
                if (item.published != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('dd.MM.yyyy').format(item.published!),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              item.contentPreview,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                fontFamily: 'Roboto',
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
        ],
      ),
    );
  }
}


