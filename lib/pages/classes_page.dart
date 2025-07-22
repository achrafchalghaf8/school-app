import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'admin_drawer.dart';
import 'class_dialog.dart';
import '../services/localization_service.dart';
import '../widgets/language_selector.dart';

class ClassesPage extends StatefulWidget {
  const ClassesPage({Key? key}) : super(key: key);

  @override
  _ClassesPageState createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  final String _classesApiUrl = "http://localhost:8004/api/classes";
  final String _enseignantsApiUrl = "http://localhost:8004/api/enseignants";
  
  List<dynamic> _classes = [];
  List<dynamic> _enseignants = [];
  bool _isLoading = true;
  bool _hasError = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final [classesResponse, enseignantsResponse] = await Future.wait([
        http.get(Uri.parse(_classesApiUrl)),
        http.get(Uri.parse(_enseignantsApiUrl)),
      ]);

      if (classesResponse.statusCode == 200 && enseignantsResponse.statusCode == 200) {
        setState(() {
          _classes = json.decode(classesResponse.body);
          _enseignants = json.decode(enseignantsResponse.body);
          _isLoading = false;
        });
      } else {
        throw Exception(context.tr('classes.loading_error'));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _deleteClass(int id) async {
    try {
      final response = await http.delete(Uri.parse('$_classesApiUrl/$id'));
      
      if (response.statusCode == 204) {
        _fetchData();
        _showSuccessSnackBar(context.tr('classes.delete_success'));
      } else {
        throw Exception(context.tr('classes.delete_error'));
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${context.tr('common.error')}: $message'),
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

  void _showAddEditClassDialog({Map<String, dynamic>? classe}) {
    showDialog(
      context: context,
      builder: (context) => ClassDialog(
        classe: classe,
        enseignants: _enseignants,
        onSave: (newClasse) async {
          Navigator.of(context).pop();
          try {
            if (classe == null) {
              final response = await http.post(
                Uri.parse(_classesApiUrl),
                headers: {'Content-Type': 'application/json'},
                body: json.encode({
                  'niveau': newClasse['niveau'],
                  'enseignantIds': newClasse['enseignantIds'],
                }),
              );
              
              if (response.statusCode == 201) {
                _fetchData();
                _showSuccessSnackBar(context.tr('classes.add_success'));
              } else {
                throw Exception(context.tr('classes.loading_error'));
              }
            } else {
              final response = await http.put(
                Uri.parse('$_classesApiUrl/${newClasse['id']}'),
                headers: {'Content-Type': 'application/json'},
                body: json.encode({
                  'niveau': newClasse['niveau'],
                  'enseignantIds': newClasse['enseignantIds'],
                }),
              );
              
              if (response.statusCode == 200) {
                _fetchData();
                _showSuccessSnackBar(context.tr('classes.edit_success'));
              } else {
                throw Exception(context.tr('classes.loading_error'));
              }
            }
          } catch (e) {
            _showErrorSnackBar(e.toString());
          }
        },
      ),
    );
  }

  String _getEnseignantsNames(List<int> enseignantIds) {
    return _enseignants
        .where((enseignant) => enseignantIds.contains(enseignant['id']))
        .map((enseignant) => enseignant['nom'])
        .join(', ');
  }

  Widget _buildClassList() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue.shade900),
            const SizedBox(height: 16),
            Text(context.tr('common.loading')),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(context.tr('common.error_loading')), 
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade900,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _fetchData,
              child: Text(context.tr('common.retry')),
            ),
          ],
        ),
      );
    }

    if (_classes.isEmpty) {
      return Center(
        child: Text(
          context.tr('classes.no_classes'), 
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _classes.length,
      itemBuilder: (context, index) {
        final classe = _classes[index];
        final enseignantIds = List<int>.from(classe['enseignantIds'] ?? []);
        final enseignantsNames = _getEnseignantsNames(enseignantIds);

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
                classe['niveau']?[0]?.toUpperCase() ?? 'C',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              classe['niveau'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade900,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (enseignantsNames.isNotEmpty)
                  Text(
                    '${context.tr('classes.teachers')}: $enseignantsNames',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue.shade900),
                  onPressed: () => _showAddEditClassDialog(classe: classe),
                  tooltip: context.tr('common.edit'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _showDeleteConfirmation(classe['id']),
                  tooltip: context.tr('common.delete'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(int classId) {
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
        content: Text(context.tr('classes.delete_confirmation')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              context.tr('common.cancel'), 
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              _deleteClass(classId);
            },
            child: Text(
              context.tr('common.delete'), 
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue.shade900,
          title: Text(
            context.tr('classes.page_title'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          elevation: 4,
          shadowColor: const Color.fromARGB(66, 197, 193, 193),
          actions: [
            const LanguageSelector(),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchData,
              tooltip: context.tr('common.refresh'),
            ),
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
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    labelText: context.tr('classes.search_placeholder'),
                    prefixIcon: Icon(Icons.search, color: Colors.blue.shade900),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear, color: Colors.blue.shade900),
                      onPressed: () {
                        _searchController.clear();
                        _fetchData();
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
                child: _buildClassList(),
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
          onPressed: () => _showAddEditClassDialog(),
          child: const Icon(Icons.add, size: 28),
          tooltip: context.tr('classes.add_class'),
        ),
      ),
    );
  }
}