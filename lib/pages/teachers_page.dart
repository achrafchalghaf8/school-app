import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'admin_drawer.dart';
import 'teacher_dialog.dart';
import '../services/localization_service.dart';
import '../widgets/language_selector.dart';

class TeachersPage extends StatefulWidget {
  const TeachersPage({Key? key}) : super(key: key);

  @override
  _TeachersPageState createState() => _TeachersPageState();
}

class _TeachersPageState extends State<TeachersPage> {
  final String _teachersApiUrl = "http://localhost:8004/api/enseignants";
  final String _classesApiUrl = "http://localhost:8004/api/classes";
  
  List<dynamic> _teachers = [];
  List<dynamic> _filteredTeachers = [];
  List<dynamic> _classes = [];
  bool _isLoading = true;
  bool _hasError = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _filterTeachers(_searchController.text);
  }

  void _filterTeachers(String searchTerm) {
    if (searchTerm.isEmpty) {
      setState(() {
        _filteredTeachers = List.from(_teachers);
      });
      return;
    }

    final term = searchTerm.toLowerCase();
    setState(() {
      _filteredTeachers = _teachers.where((teacher) {
        return (teacher['nom']?.toString().toLowerCase().contains(term) ?? false) ||
               (teacher['email']?.toString().toLowerCase().contains(term) ?? false) ||
               (teacher['specialite']?.toString().toLowerCase().contains(term) ?? false) ||
               (teacher['telephone']?.toString().toLowerCase().contains(term) ?? false);
      }).toList();
    });
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final [teachersResponse, classesResponse] = await Future.wait([
        http.get(Uri.parse(_teachersApiUrl)),
        http.get(Uri.parse(_classesApiUrl)),
      ]);

      if (teachersResponse.statusCode == 200 && classesResponse.statusCode == 200) {
        setState(() {
          _teachers = json.decode(teachersResponse.body);
          _filteredTeachers = List.from(_teachers);
          _classes = json.decode(classesResponse.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${LocalizationService().translate('common.error')}: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _deleteTeacher(int id) async {
    try {
      final response = await http.delete(Uri.parse('$_teachersApiUrl/$id'));
      
      if (response.statusCode == 204) {
        _fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('teachers.delete_success')),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        throw Exception('Failed to delete teacher');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('teachers.delete_error')}: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showAddEditTeacherDialog({Map<String, dynamic>? teacher}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: TeacherDialog(
          teacher: teacher,
          classes: _classes,
          onSave: (newTeacher) async {
            Navigator.of(context).pop();
            try {
              final response = teacher == null
                  ? await http.post(
                      Uri.parse(_teachersApiUrl),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode(newTeacher),
                    )
                  : await http.put(
                      Uri.parse('$_teachersApiUrl/${teacher['id']}'),
                      headers: {'Content-Type': 'application/json'},
                      body: json.encode(newTeacher),
                    );

              if (response.statusCode == 201 || response.statusCode == 200) {
                _fetchData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(teacher == null
                        ? context.tr('teachers.add_success')
                        : context.tr('teachers.edit_success')),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } else {
                throw Exception('Failed to save teacher');
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${context.tr('common.error')}: ${e.toString()}'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildTeacherList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.blue.shade900));
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(context.tr('teachers.loading_error'), style: const TextStyle(color: Colors.redAccent)),
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
              onPressed: _fetchData,
              child: Text(context.tr('common.retry')),
            ),
          ],
        ),
      );
    }

    if (_filteredTeachers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? context.tr('teachers.no_teachers')
                  : context.tr('teachers.no_results'),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
            if (_searchController.text.isNotEmpty)
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _filterTeachers('');
                },
                child: Text(context.tr('teachers.clear_search')),
        )],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredTeachers.length,
      itemBuilder: (context, index) {
        final teacher = _filteredTeachers[index];
        final assignedClasses = _classes.where((c) => 
            (teacher['classeIds'] as List?)?.contains(c['id']) ?? false)
            .map((c) => c['niveau'])
            .join(', ');

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
                teacher['nom']?[0]?.toUpperCase() ?? 'E',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              teacher['nom'] ?? '',
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
                  teacher['email'] ?? '',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                Text(
                  '${context.tr('teachers.specialty')}: ${teacher['specialite'] ?? ''}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Text(
                  '${context.tr('teachers.phone')}: ${teacher['telephone'] ?? ''}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                if (assignedClasses.isNotEmpty)
                  Text(
                    '${context.tr('teachers.classes')}: $assignedClasses',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue.shade900),
                  onPressed: () => _showAddEditTeacherDialog(teacher: teacher),
                  tooltip: context.tr('common.edit'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _showDeleteConfirmation(teacher['id']),
                  tooltip: context.tr('common.delete'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(int teacherId) {
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
        content: Text(context.tr('teachers.delete_confirmation')),
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
              _deleteTeacher(teacherId);
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
            context.tr('teachers.page_title'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          elevation: 4,
          shadowColor: Colors.black26,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _fetchData,
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
                  labelText: context.tr('teachers.search_placeholder'),
                  hintText: context.tr('teachers.search_hint'),
                  prefixIcon: Icon(Icons.search, color: Colors.blue.shade900),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.blue.shade900),
                          onPressed: () {
                            _searchController.clear();
                            _filterTeachers('');
                          },
                        )
                      : null,
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                ),
                onChanged: (value) => _filterTeachers(value),
              ),
            ),
            Expanded(
              child: _buildTeacherList(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blue.shade900,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 6,
          onPressed: () => _showAddEditTeacherDialog(),
          child: const Icon(Icons.add, size: 28),
          tooltip: context.tr('teachers.add_teacher'),
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