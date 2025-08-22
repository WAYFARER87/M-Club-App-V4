import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/services/api_service.dart';
import 'offer_detail_screen.dart';

class MClubScreen extends StatefulWidget {
  const MClubScreen({super.key});

  @override
  State<MClubScreen> createState() => _MClubScreenState();
}

class _MClubScreenState extends State<MClubScreen> with SingleTickerProviderStateMixin {
  final _api = ApiService();

  List<dynamic> _categories = [];
  List<dynamic> _offers = [];
  String? _selectedCategoryId;
  String _sortMode = 'alphabet'; // 'alphabet' | 'distance'

  bool _isLoading = true;
  String? _error;
  static double _savedTabScrollOffset = 0;
  late final ScrollController _tabScrollController;
  TabController? _tabController;
  double _tabScrollOffset = 0;
  final List<GlobalKey> _tabKeys = [];
  final GlobalKey _tabBarKey = GlobalKey();

  double? _curLat;
  double? _curLng;

  static const _fallbackLat = 25.1972;
  static const _fallbackLng = 55.2744;


  @override
  void initState() {
    super.initState();
    _tabScrollOffset = _savedTabScrollOffset;
    _tabScrollController = ScrollController(initialScrollOffset: _tabScrollOffset)
      ..addListener(() {
        _tabScrollOffset = _tabScrollController.offset;
      });
    _initLocation();
    _loadData();
  }

  @override
  void dispose() {
    _savedTabScrollOffset = _tabScrollOffset;
    _tabScrollController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        _curLat = _fallbackLat;
        _curLng = _fallbackLng;
      } else {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _curLat = pos.latitude;
        _curLng = pos.longitude;
      }
    } catch (_) {
      _curLat = _fallbackLat;
      _curLng = _fallbackLng;
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cats = await _api.fetchCategories();
      final offers = await _api.fetchBenefits();

      _setupTabController(cats.length + 1);

      setState(() {
        _categories = cats;
        _offers = offers;
        _selectedCategoryId = null;
        _tabKeys
          ..clear()
          ..addAll(List.generate(cats.length + 1, (_) => GlobalKey()));
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerSelectedTab());
    } catch (e) {
      setState(() => _error = 'Не удалось загрузить данные');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setupTabController(int length) {
    _tabController?.dispose();
    _tabController = TabController(length: length, vsync: this);
    _tabController!.addListener(() {
      if (_tabController!.indexIsChanging) return;
      setState(() {
        _selectedCategoryId = _tabController!.index == 0
            ? null
            : _categories[_tabController!.index - 1]['id'].toString();
      });
      _centerSelectedTab();
    });
  }

  void _centerSelectedTab() {
    if (!_tabScrollController.hasClients || _tabController == null) return;
    final index = _tabController!.index;
    if (index >= _tabKeys.length) return;
    final tabContext = _tabKeys[index].currentContext;
    final barContext = _tabBarKey.currentContext;
    if (tabContext == null || barContext == null) return;
    final tabBox = tabContext.findRenderObject() as RenderBox?;
    final barBox = barContext.findRenderObject() as RenderBox?;
    if (tabBox == null || barBox == null) return;
    final barPos = barBox.localToGlobal(Offset.zero);
    final tabPos = tabBox.localToGlobal(Offset.zero);
    final relative = tabPos.dx - barPos.dx;
    final target = _tabScrollController.offset +
        relative -
        (barBox.size.width - tabBox.size.width) / 2;
    final clamped = target.clamp(
      0.0,
      _tabScrollController.position.maxScrollExtent,
    );
    _tabScrollController.animateTo(
      clamped.toDouble(),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  List<dynamic> get _filteredOffers {
    List<dynamic> filtered = _selectedCategoryId == null
        ? List<dynamic>.from(_offers)
        : _offers.where((offer) {
      final categories = offer['category'] as List<dynamic>? ?? [];
      return categories.any((c) => c['id'].toString() == _selectedCategoryId);
    }).toList();

    if (_sortMode == 'alphabet') {
      filtered.sort((a, b) {
        final at = (a['title'] ?? '').toString();
        final bt = (b['title'] ?? '').toString();
        return at.toLowerCase().compareTo(bt.toLowerCase());
      });
    } else if (_sortMode == 'distance' && _curLat != null && _curLng != null) {
      filtered.sort((a, b) {
        final da = _minDistanceMeters(a['branches']);
        final db = _minDistanceMeters(b['branches']);
        return da.compareTo(db);
      });
    }

    return filtered;
  }

  double _minDistanceMeters(List<dynamic>? branches) {
    if (branches == null || branches.isEmpty || _curLat == null || _curLng == null) {
      return double.infinity;
    }
    double best = double.infinity;
    for (final br in branches) {
      final lat = double.tryParse((br['lattitude'] ?? '').toString());
      final lng = double.tryParse((br['longitude'] ?? '').toString());
      if (lat == null || lng == null) continue;
      final d = Geolocator.distanceBetween(_curLat!, _curLng!, lat, lng);
      if (d < best) best = d;
    }
    return best;
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} км';
    } else {
      return '${meters.toStringAsFixed(0)} м';
    }
  }

  void _openSortModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('По алфавиту'),
                onTap: () {
                  setState(() => _sortMode = 'alphabet');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('По расстоянию'),
                onTap: () {
                  setState(() => _sortMode = 'distance');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _loadData, child: const Text('Повторить')),
          ],
        ),
      );
    } else {
      body = Column(
        children: [
          if (_tabController != null)
            Material(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                  child: TabBar(
                    key: _tabBarKey,
                    controller: _tabScrollController,
                    tabController: _tabController,
                    isScrollable: true,
                    labelColor: const Color(0xFF182857),
                    unselectedLabelColor: Colors.black54,
                    indicatorColor: Colors.transparent,
                    indicator: const UnderlineTabIndicator(
                      borderSide: BorderSide(color: Color(0xFF182857)),
                    ),
                    tabs: [
                      Tab(key: _tabKeys.isNotEmpty ? _tabKeys[0] : null, text: 'Все'),
                      ...List.generate(
                        _categories.length,
                        (i) => Tab(
                          key: _tabKeys.length > i + 1 ? _tabKeys[i + 1] : null,
                          text: _categories[i]['name'],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: _filteredOffers.isEmpty
                ? const Center(child: Text('Нет предложений'))
                : ListView.builder(
                    itemCount: _filteredOffers.length,
                    itemBuilder: (context, index) {
                      final offer = _filteredOffers[index];
                      final photo = (offer['photo_url'] ?? '').toString();
                      final title = (offer['title'] ?? '').toString();
                      final descr =
                          (offer['description_short'] ?? '').toString();

                      double? distance;
                      if (_sortMode == 'distance') {
                        final d = _minDistanceMeters(offer['branches']);
                        if (d != double.infinity) {
                          distance = d;
                        }
                      }

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    OfferDetailScreen(offer: offer)),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (photo.isNotEmpty)
                              Image.network(
                                photo,
                                width: double.infinity,
                                height:
                                    MediaQuery.of(context).size.width * 0.6,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: MediaQuery.of(context).size.width *
                                      0.6,
                                  color: Colors.grey.shade200,
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                height:
                                    MediaQuery.of(context).size.width * 0.6,
                                color: Colors.grey.shade200,
                              ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: 'Roboto',
                                    ),
                                  ),
                                  if (distance != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        _formatDistance(distance),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                descr,
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
                    },
                  ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Фильтр',
            onPressed: _openSortModal,
          ),
        ],
      ),
      body: body,
    );
  }
}
