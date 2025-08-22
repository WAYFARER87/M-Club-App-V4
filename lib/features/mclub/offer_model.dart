class Offer {
  final String id;
  final List<String> categoryIds;   // из category[].id
  final List<String> categoryNames; // из category[].name

  final String title;
  final String titleShort;

  final String descriptionShort;
  final String descriptionHtml;     // description (HTML)

  final String benefitText;         // "Скидка 15%"
  final num? benefitPercent;        // 15 (если удастся выделить число)

  final DateTime? dateStart;
  final DateTime? dateEnd;

  final String? photoUrl;           // миниатюра
  final List<String> photosUrl;     // галерея

  final List<Branch> branches;
  final OfferLinks links;

  Offer({
    required this.id,
    required this.categoryIds,
    required this.categoryNames,
    required this.title,
    required this.titleShort,
    required this.descriptionShort,
    required this.descriptionHtml,
    required this.benefitText,
    required this.benefitPercent,
    required this.dateStart,
    required this.dateEnd,
    required this.photoUrl,
    required this.photosUrl,
    required this.branches,
    required this.links,
  });

  factory Offer.fromJson(Map<String, dynamic> json) {
    // категории
    final cats = (json['category'] as List?) ?? const [];
    final catIds = <String>[];
    final catNames = <String>[];
    for (final c in cats) {
      if (c is Map<String, dynamic>) {
        if (c['id'] != null) catIds.add(c['id'].toString());
        if (c['name'] != null) catNames.add(c['name'].toString());
      }
    }

    // проценты из "Скидка 15%"
    num? parsePercent(String s) {
      final m = RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(s);
      if (m != null) {
        final v = m.group(1)!.replaceAll(',', '.');
        return num.tryParse(v);
      }
      return null;
    }

    // даты — секунды unix
    DateTime? fromUnix(dynamic v) {
      if (v == null) return null;
      final n = int.tryParse(v.toString());
      if (n == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(n * 1000, isUtc: true).toLocal();
    }

    // фото
    final photos = <String>[];
    final rawPhotos = json['photos_url'];
    if (rawPhotos is List) {
      for (final p in rawPhotos) {
        if (p != null) photos.add(p.toString());
      }
    }

    // филиалы
    final branches = <Branch>[];
    final rawBranches = json['branches'];
    if (rawBranches is List) {
      for (final b in rawBranches) {
        if (b is Map<String, dynamic>) {
          branches.add(Branch.fromJson(b));
        }
      }
    }

    return Offer(
      id: json['id']?.toString() ?? '',
      categoryIds: catIds,
      categoryNames: catNames,
      title: (json['title'] ?? '').toString(),
      titleShort: (json['title_short'] ?? '').toString(),
      descriptionShort: (json['description_short'] ?? '').toString(),
      descriptionHtml: (json['description'] ?? '').toString(),
      benefitText: (json['benefit'] ?? '').toString(),
      benefitPercent: parsePercent((json['benefit'] ?? '').toString()),
      dateStart: fromUnix(json['date_start']),
      dateEnd: fromUnix(json['date_end']),
      photoUrl: (json['photo_url'] as String?)?.toString(),
      photosUrl: photos,
      branches: branches,
      links: OfferLinks.fromJson(json['links'] as Map<String, dynamic>? ?? const {}),
    );
  }
}

class Branch {
  final String? code;
  final double? lat;
  final double? lng;
  final String? phone;
  final String? address;
  final String? email;
  final String? notificationTitle;
  final String? notificationText;

  Branch({
    this.code,
    this.lat,
    this.lng,
    this.phone,
    this.address,
    this.email,
    this.notificationTitle,
    this.notificationText,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) => v == null ? null : double.tryParse(v.toString());
    return Branch(
      code: json['code']?.toString(),
      lat: toDouble(json['lattitude']),   // да, поле с двумя t
      lng: toDouble(json['longitude']),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      email: json['email']?.toString(),
      notificationTitle: json['notification_title']?.toString(),
      notificationText: json['notification_text']?.toString(),
    );
  }
}

class OfferLinks {
  final String? facebook;
  final String? instagram;
  final String? www;
  final String? shareUrl;

  OfferLinks({
    this.facebook,
    this.instagram,
    this.www,
    this.shareUrl,
  });

  factory OfferLinks.fromJson(Map<String, dynamic> json) {
    return OfferLinks(
      facebook: _emptyToNull(json['facebook']),
      instagram: _emptyToNull(json['instagram']),
      www: _emptyToNull(json['www']),
      shareUrl: _emptyToNull(json['share_url']),
    );
  }

  static String? _emptyToNull(dynamic v) {
    final s = v?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }
}
