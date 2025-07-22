import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/parent_dialog.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'admin_drawer.dart';
import '../services/localization_service.dart';
import '../widgets/language_selector.dart';

class ParentsPage extends StatefulWidget {
  const ParentsPage({Key? key}) : super(key: key);

  @override
  _ParentsPageState createState() => _ParentsPageState();
}

class _ParentsPageState extends State<ParentsPage> {
  List<dynamic> parents = [];
  bool isLoading = true;
  bool hasError = false;
  final String apiUrl = "http://localhost:8004/api/parents";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchParents();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Implémentation de la recherche
  }

  Future<void> fetchParents() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          parents = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load parents');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> deleteParent(int id) async {
    try {
      final response = await http.delete(Uri.parse('$apiUrl/$id'));
      if (response.statusCode == 204) {
        fetchParents();
        _showSuccessSnackBar(LocalizationService().translate('parents.delete_success'));
      } else {
        throw Exception('Failed to delete parent');
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${LocalizationService().translate('common.error')}: $message'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void showAddEditParentDialog({Map<String, dynamic>? parent}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ParentDialog(
          parent: parent,
          onSave: (newParent) async {
            Navigator.of(context).pop();
            try {
              final response = parent == null
                  ? await http.post(
                      Uri.parse(apiUrl),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode(newParent),
                    )
                  : await http.put(
                      Uri.parse('$apiUrl/${parent['id']}'),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode(newParent),
                    );

              if (response.statusCode == 201 || response.statusCode == 200) {
                fetchParents();
                _showSuccessSnackBar(
                  parent == null
                      ? context.tr('parents.add_success')
                      : context.tr('parents.edit_success')
                );
              } else {
                throw Exception('Failed to save parent');
              }
            } catch (e) {
              _showErrorSnackBar(e.toString());
            }
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(int parentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: Colors.white,
        title: Text(
          context.tr('common.confirm_delete'),
          style: TextStyle(
            color: Colors.blue.shade900,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(context.tr('parents.delete_confirmation')),
        actions: [
          TextButton(
            child: Text(context.tr('common.cancel'), style: const TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text(context.tr('common.delete'), style: const TextStyle(fontWeight: FontWeight.w600)),
            onPressed: () {
              Navigator.of(context).pop();
              deleteParent(parentId);
            },
          ),
        ],
      ),
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
          context.tr('parents.page_title'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 4,
        shadowColor: Colors.black26,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchParents,
            tooltip: context.tr('common.refresh'),
          ),
          const LanguageSelector(),
        ],
      ),
      drawer: const AdminDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: context.tr('parents.search_placeholder'),
                  prefixIcon: Icon(Icons.search, color: Colors.blue.shade900),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear, color: Colors.blue.shade900),
                    onPressed: () {
                      _searchController.clear();
                      fetchParents();
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
              child: _buildParentList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 6,
        onPressed: () => showAddEditParentDialog(),
        child: const Icon(Icons.add, size: 28),
        tooltip: context.tr('parents.add_parent'),
      ),
      ),
    );
  }

  Widget _buildParentList() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.blue.shade900));
    }

    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(context.tr('parents.loading_error'), style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade900,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: fetchParents,
              child: Text(context.tr('common.retry')),
            ),
          ],
        ),
      );
    }

    if (parents.isEmpty) {
      return Center(child: Text(context.tr('parents.no_parents'), style: const TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: parents.length,
      itemBuilder: (context, index) {
        final parent = parents[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue.shade900,
              child: Text(
                parent['nom']?[0]?.toUpperCase() ?? 'P',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              parent['nom'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade900,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  parent['email'] ?? '',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                Text(
                  '${context.tr('parents.phone')}: ${parent['telephone'] ?? ''}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue.shade900),
                  onPressed: () => showAddEditParentDialog(parent: parent),
                  tooltip: context.tr('common.edit'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _showDeleteConfirmation(parent['id']),
                  tooltip: context.tr('common.delete'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}