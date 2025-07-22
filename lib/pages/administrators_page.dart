import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/models/user.dart';
import 'admin_drawer.dart';
import '../services/localization_service.dart';
import '../widgets/language_selector.dart';

class AdministratorsPage extends StatefulWidget {
  const AdministratorsPage({Key? key}) : super(key: key);

  @override
  _AdministratorsPageState createState() => _AdministratorsPageState();
}

class _AdministratorsPageState extends State<AdministratorsPage> {
  final AuthService _authService = AuthService();
  late Future<List<User>> _adminsFuture;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _adminsFuture = _getAdmins();
    _searchController.addListener(_onSearchChanged);
  }

  Future<List<User>> _getAdmins() async {
    final accounts = await _authService.getAccounts();
    return accounts.where((user) => user.role == 'ADMIN').toList();
  }

  void _onSearchChanged() {
    setState(() {
      _adminsFuture = _getAdmins();
    });
  }

  void _refreshAdmins() {
    setState(() {
      _adminsFuture = _getAdmins();
    });
  }

  Future<String?> _showPasswordDialog({bool isUpdate = false}) async {
    final passwordController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          title: Text(
            isUpdate ? context.tr('administrators.new_password') : context.tr('accounts.set_password'),
            style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: isUpdate ? context.tr('administrators.new_password_optional') : context.tr('login.password'),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: Icon(Icons.lock, color: Colors.blue.shade900),
              filled: true,
              fillColor: Colors.blue.shade50,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('common.cancel'), style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade900,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () => Navigator.pop(context, passwordController.text),
              child: Text(context.tr('common.confirm'), style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  void _showAddAdminDialog() {
    final emailController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          title: Text(
            context.tr('administrators.add_admin'),
            style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: context.tr('login.email'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.email, color: Colors.blue.shade900),
                    filled: true,
                    fillColor: Colors.blue.shade50,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: context.tr('common.name'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.person, color: Colors.blue.shade900),
                    filled: true,
                    fillColor: Colors.blue.shade50,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('common.cancel'), style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade900,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () async {
                try {
                  final password = await _showPasswordDialog();
                  if (password == null || password.isEmpty) {
                    throw Exception(LocalizationService().translate('administrators.password_required'));
                  }

                  await _authService.createAdmin(
                    email: emailController.text,
                    nom: nameController.text,
                    password: password,
                  );
                  _refreshAdmins();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(LocalizationService().translate('administrators.success_add')),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${LocalizationService().translate('common.error')}: ${e.toString()}'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: Text(context.tr('common.add'), style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  void _showEditAdminDialog(User admin) {
    final emailController = TextEditingController(text: admin.email);
    final nameController = TextEditingController(text: admin.nom);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          title: Text(
            context.tr('administrators.edit_admin'),
            style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: context.tr('login.email'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.email, color: Colors.blue.shade900),
                    filled: true,
                    fillColor: Colors.blue.shade50,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: context.tr('common.name'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.person, color: Colors.blue.shade900),
                    filled: true,
                    fillColor: Colors.blue.shade50,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('common.cancel'), style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade900,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () async {
                final updatedAdmin = User(
                  id: admin.id,
                  email: emailController.text,
                  nom: nameController.text,
                  role: 'ADMIN',
                  token: admin.token,
                  tokenExpiration: admin.tokenExpiration,
                );

                try {
                  final newPassword = await _showPasswordDialog(isUpdate: true);
                  await _authService.updateAccount(updatedAdmin, password: newPassword);
                  _refreshAdmins();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(LocalizationService().translate('administrators.success_edit')),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: Text(context.tr('common.save'), style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          title: Text(
            context.tr('administrators.delete_admin'),
            style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold),
          ),
          content: Text(context.tr('administrators.delete_confirmation')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('common.cancel'), style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: () async {
                try {
                  await _authService.deleteAdmin(id);
                  _refreshAdmins();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(LocalizationService().translate('administrators.success_delete')),
                      backgroundColor: Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${LocalizationService().translate('common.error')}: ${e.toString()}'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              child: Text(context.tr('common.delete'), style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, child) => Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        title: Text(
          context.tr('administrators.page_title'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 4,
        shadowColor: Colors.black26,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshAdmins,
            tooltip: context.tr('common.refresh'),
          ),
          const LanguageSelector(),
        ],
      ),
      drawer: const AdminDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: context.tr('common.search'),
                prefixIcon: Icon(Icons.search, color: Colors.blue.shade900),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear, color: Colors.blue.shade900),
                  onPressed: () {
                    _searchController.clear();
                    _refreshAdmins();
                  },
                ),
                filled: true,
                fillColor: Colors.blue.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade900.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade900, width: 2),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<User>>(
              future: _adminsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: Colors.blue.shade900));
                } else if (snapshot.hasError) {
                  return Center(child: Text('${context.tr('common.error')}: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text(context.tr('administrators.no_admins'), style: const TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final admin = snapshot.data![index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.blue.shade900,
                          child: Text(
                            admin.nom.isNotEmpty ? admin.nom[0].toUpperCase() : 'A',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          admin.nom,
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue.shade900),
                        ),
                        subtitle: Text(
                          admin.email,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue.shade900),
                              onPressed: () => _showEditAdminDialog(admin),
                              tooltip: context.tr('administrators.tooltip_edit'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _showDeleteDialog(admin.id),
                              tooltip: context.tr('administrators.tooltip_delete'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 6,
        onPressed: _showAddAdminDialog,
        child: const Icon(Icons.add, size: 28),
        tooltip: context.tr('administrators.tooltip_add'),
      ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
}