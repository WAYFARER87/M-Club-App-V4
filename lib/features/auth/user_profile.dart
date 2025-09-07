import 'package:m_club/core/utils/parse_bool.dart';

class UserProfile {
  final String cardNum;
  final String expireDate;
  final int userId;
  final String name;
  final String lastname;
  final String phone;
  final String email;
  final String login;
  final bool isVerifiedPhone;
  final bool isUaeResident;
  final String lang;

  UserProfile({
    required this.cardNum,
    required this.expireDate,
    required this.userId,
    required this.name,
    required this.lastname,
    required this.phone,
    required this.email,
    required this.login,
    required this.isVerifiedPhone,
    required this.isUaeResident,
    required this.lang,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      cardNum: json['card_num']?.toString() ?? '',
      expireDate: json['expire_date']?.toString() ?? '',
      userId: int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      lastname: json['lastname']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      login: json['login']?.toString() ?? '',
      isVerifiedPhone: parseBool(json['is_verified_phone']),
      isUaeResident: parseBool(json['is_uae_resident']),
      lang: json['lang']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'card_num': cardNum,
      'expire_date': expireDate,
      'user_id': userId,
      'name': name,
      'lastname': lastname,
      'phone': phone,
      'email': email,
      'login': login,
      'is_verified_phone': isVerifiedPhone,
      'is_uae_resident': isUaeResident,
      'lang': lang,
    };
  }

  int? get expiryMonth {
    final parts = expireDate.split('/');
    return parts.length >= 2 ? int.tryParse(parts[0]) : null;
  }

  int? get expiryYear {
    final parts = expireDate.split('/');
    if (parts.length >= 2) {
      final year = int.tryParse(parts[1]);
      if (year != null && year < 100) {
        return 2000 + year;
      }
      return year;
    }
    return null;
  }
}

