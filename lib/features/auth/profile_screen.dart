import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/api_service.dart';
import 'auth_email_screen.dart';
import 'user_profile.dart';
import 'club_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isEditing = false;
  String? _error;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await _api.fetchProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _nameCtrl.text = profile.name;
        _lastNameCtrl.text = profile.lastname;
        _phoneCtrl.text = profile.phone;
        _emailCtrl.text = profile.email;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Не удалось загрузить профиль: $e')),
        );
        setState(() => _error = 'Не удалось загрузить профиль');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final upd = await _api.updateProfile(
        name: _nameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
      );
      if (upd != null) {
        setState(() {
          _profile = upd;
          _phoneCtrl.text = upd.phone;
          _emailCtrl.text = upd.email;
          _isEditing = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Профиль обновлён')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _logout() async {
    await _api.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthEmailScreen()),
      (route) => false,
    );
  }

  Future<void> _deleteProfile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить профиль'),
        content:
            const Text('Вы уверены, что хотите удалить профиль? Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    try {
      await _api.deleteProfile();
      await _logout();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: $e')),
        );
        setState(() => _isDeleting = false);
      }
    }
  }

  Widget _buildEditForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Имя'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Введите имя' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastNameCtrl,
              decoration: const InputDecoration(labelText: 'Фамилия'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Введите фамилию' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Телефон'),
              readOnly: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              readOnly: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Сохранить'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewProfile() {
    final profile = _profile;
    if (profile == null) return const SizedBox();

    Widget buildTile(String label, String value, {bool? verified}) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        subtitle: Text(value),
        trailing: verified == null
            ? null
            : Icon(
                verified ? Icons.check_circle : Icons.error,
                color: verified ? Colors.green : Colors.red,
              ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          buildTile('Имя', profile.name),
          const SizedBox(height: 12),
          buildTile('Фамилия', profile.lastname),
          const SizedBox(height: 12),
          buildTile('Телефон', profile.phone,
              verified: profile.isVerifiedPhone),
          const SizedBox(height: 12),
          buildTile('Email', profile.email,
              verified: profile.isVerifiedEmail),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => setState(() => _isEditing = true),
            child: const Text('Изменить профиль'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _isDeleting ? null : _deleteProfile,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: _isDeleting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Удалить профиль'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _logout,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return _isEditing ? _buildEditForm() : _buildViewProfile();
  }

  Widget _buildCardTab() {
    final profile = _profile;
    if (profile == null) {
      return const SizedBox();
    }

    return Center(
      child: GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: profile.cardNum));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Номер карты скопирован')),
          );
        },
        child: ClubCard(
          cardNum: profile.cardNum,
          expireDate: profile.expireDate,
          firstName: profile.name,
          lastName: profile.lastname,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadProfile,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: Colors.white,
            child: const TabBar(
              labelColor: Color(0xFF182857),
              unselectedLabelColor: Colors.black54,
              tabs: [
                Tab(text: 'Профиль'),
                Tab(text: 'Клубная карта'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildProfileTab(),
                _buildCardTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
