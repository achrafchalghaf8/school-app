import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/models/user.dart';
import 'admin_drawer.dart';
import '../services/localization_service.dart';
import '../widgets/language_selector.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({Key? key}) : super(key: key);

  @override
  _AccountsPageState createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  final AuthService _authService = AuthService();
  List<User> _allAccounts = [];
  List<User> _filteredAccounts = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  // Couleurs
  final Color primaryColor = Colors.blue.shade900;
  final Color accentColor = Colors.blue.shade600;
  final Color backgroundColor = Colors.grey.shade50;
  final Color errorColor = Colors.red.shade700;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _searchController.addListener(_filterAccounts);
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final accounts = await _authService.getAccounts();
      setState(() {
        _allAccounts = accounts;
        _filteredAccounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackbar(e.toString());
    }
  }

  void _filterAccounts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _isSearching = query.isNotEmpty;
      _filteredAccounts = _allAccounts.where((user) {
        return user.nom.toLowerCase().contains(query) ||
               user.email.toLowerCase().contains(query) ||
               user.role.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${context.tr('common.error')}: $message'),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<String?> _showPasswordDialog({bool isUpdate = false}) async {
    final passwordController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          title: Text(
            isUpdate 
              ? context.tr('accounts.change_password') 
              : context.tr('accounts.set_password'),
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: isUpdate 
                ? context.tr('accounts.new_password_optional') 
                : context.tr('login.password'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(Icons.lock, color: primaryColor),
              filled: true,
              fillColor: Colors.blue.shade50,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.tr('common.cancel'),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, 
                  vertical: 12,
                ),
              ),
              onPressed: () => Navigator.pop(context, passwordController.text),
              child: Text(
                context.tr('common.confirm'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog({User? user}) {
    final emailController = TextEditingController(text: user?.email ?? '');
    final nameController = TextEditingController(text: user?.nom ?? '');
    String selectedRole = user?.role ?? 'PARENT';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
              title: Text(
                user == null 
                  ? context.tr('accounts.add_account') 
                  : context.tr('accounts.edit_account'),
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: context.tr('login.email'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.email, color: primaryColor),
                        filled: true,
                        fillColor: Colors.blue.shade50,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: context.tr('common.name'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(Icons.person, color: primaryColor),
                        filled: true,
                        fillColor: Colors.blue.shade50,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      items: ['ADMIN', 'PARENT', 'ENSEIGNANT', 'CONCIERGE']
                          .map((role) => DropdownMenuItem(
                                value: role,
                                child: Text(role),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value!;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: context.tr('accounts.role'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: Icon(
                          Icons.admin_panel_settings, 
                          color: primaryColor,
                        ),
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
                  child: Text(
                    context.tr('common.cancel'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, 
                      vertical: 12,
                    ),
                  ),
                  onPressed: () async {
                    final newUser = User(
                      id: user?.id ?? 0,
                      email: emailController.text,
                      nom: nameController.text,
                      role: selectedRole,
                      token: '',
                      tokenExpiration: '',
                    );

                    try {
                      if (user == null) {
                        final password = await _showPasswordDialog();
                        if (password == null || password.isEmpty) {
                          throw Exception(
                            context.tr('accounts.password_required'));
                        }
                        await _authService.createAccount(newUser, password);
                      } else {
                        final newPassword = await _showPasswordDialog(
                          isUpdate: true);
                        await _authService.updateAccount(
                          newUser, 
                          password: newPassword,
                        );
                      }
                      _loadAccounts();
                      Navigator.pop(context);
                    } catch (e) {
                      _showErrorSnackbar(e.toString());
                    }
                  },
                  child: Text(
                    user == null 
                      ? context.tr('common.add') 
                      : context.tr('common.save'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(int id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
          title: Text(
            context.tr('accounts.delete_account'),
            style: TextStyle(
              color: errorColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(context.tr('accounts.delete_confirmation')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                context.tr('common.cancel'),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, 
                  vertical: 12,
                ),
              ),
              onPressed: () async {
                try {
                  await _authService.deleteAccount(id);
                  _loadAccounts();
                  Navigator.pop(context);
                } catch (e) {
                  _showErrorSnackbar(e.toString());
                }
              },
              child: Text(
                context.tr('common.delete'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('accounts.page_title'),
          style: const TextStyle(
            color: Colors.white, 
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 4,
        actions: const [LanguageSelector()],
      ),
      drawer: const AdminDrawer(),
      body: Container(
        color: backgroundColor,
        child: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingIndicator()
                  : _filteredAccounts.isEmpty
                      ? _buildEmptyState()
                      : _buildAccountsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 6,
        onPressed: () => _showEditDialog(),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: context.tr('common.search_hint'),
          prefixIcon: Icon(Icons.search, color: primaryColor),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: Icon(Icons.clear, color: primaryColor),
                  onPressed: () {
                    _searchController.clear();
                    _filterAccounts();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: primaryColor.withOpacity(0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: primaryColor, 
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0, 
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSearching ? Icons.search_off : Icons.group_off,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _isSearching
                ? context.tr('accounts.no_results')
                : context.tr('accounts.no_accounts'),
            style: TextStyle(
              color: Colors.grey.shade600, 
              fontSize: 16,
            ),
          ),
          if (_isSearching)
            TextButton(
              onPressed: () {
                _searchController.clear();
                _filterAccounts();
              },
              child: Text(context.tr('accounts.clear_search')),
            ),
        ],
      ),
    );
  }

  Widget _buildAccountsList() {
    return RefreshIndicator(
      onRefresh: _loadAccounts,
      color: primaryColor,
      backgroundColor: backgroundColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredAccounts.length,
        itemBuilder: (context, index) {
          final user = _filteredAccounts[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: _getRoleColor(user.role).withOpacity(0.2),
                child: Text(
                  user.nom.isNotEmpty ? user.nom[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: _getRoleColor(user.role),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                user.nom,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(
                    '${context.tr('accounts.role')}: ${user.role}',
                    style: TextStyle(
                      color: _getRoleColor(user.role),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit, 
                      color: primaryColor,
                    ),
                    onPressed: () => _showEditDialog(user: user),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete, 
                      color: errorColor,
                    ),
                    onPressed: () => _showDeleteDialog(user.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'ADMIN':
        return Colors.red.shade700;
      case 'ENSEIGNANT':
        return Colors.green.shade700;
      case 'CONCIERGE':
        return Colors.orange.shade700;
      case 'PARENT':
      default:
        return primaryColor;
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterAccounts);
    _searchController.dispose();
    super.dispose();
  }
}