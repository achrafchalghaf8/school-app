import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'admin_drawer.dart';
import '../services/localization_service.dart';
import '../widgets/language_selector.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({Key? key}) : super(key: key);

  @override
  _StudentsPageState createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  List<dynamic> students = [];
  List<dynamic> classes = [];
  List<dynamic> parents = [];
  bool isLoading = true;
  bool showForm = false;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  int? _selectedClassId;
  int? _selectedParentId;
  Map<String, dynamic>? _currentStudent;
  final String studentsApiUrl = "http://localhost:8004/api/etudiants";
  final String classesApiUrl = "http://localhost:8004/api/classes";
  final String parentsApiUrl = "http://localhost:8004/api/parents";
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchData();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    // Implement search functionality if needed
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final studentsResponse = await http.get(Uri.parse(studentsApiUrl));
      final classesResponse = await http.get(Uri.parse(classesApiUrl));
      final parentsResponse = await http.get(Uri.parse(parentsApiUrl));

      if (studentsResponse.statusCode == 200 && 
          classesResponse.statusCode == 200 &&
          parentsResponse.statusCode == 200) {
        setState(() {
          students = json.decode(studentsResponse.body);
          classes = json.decode(classesResponse.body);
          parents = json.decode(parentsResponse.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> deleteStudent(int id) async {
    try {
      final response = await http.delete(Uri.parse('$studentsApiUrl/$id'));
      if (response.statusCode == 204) {
        fetchData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Étudiant supprimé avec succès'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        throw Exception('Failed to delete student');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _toggleForm({Map<String, dynamic>? student}) {
    setState(() {
      showForm = !showForm;
      _currentStudent = student;
      if (student != null) {
        _nomController.text = student['nom'];
        _prenomController.text = student['prenom'];
        _selectedClassId = student['classeId'];
        _selectedParentId = student['parentId'];
      } else {
        _nomController.clear();
        _prenomController.clear();
        _selectedClassId = classes.isNotEmpty ? classes.first['id'] : null;
        _selectedParentId = parents.isNotEmpty ? parents.first['id'] : null;
      }
    });
  }

  Future<void> _saveStudent() async {
    if (_formKey.currentState!.validate()) {
      final newStudent = {
        'nom': _nomController.text,
        'prenom': _prenomController.text,
        'classeId': _selectedClassId,
        'parentId': _selectedParentId,
      };
      
      if (_currentStudent != null) {
        newStudent['id'] = _currentStudent!['id'];
      }

      try {
        final response = _currentStudent == null
            ? await http.post(
                Uri.parse(studentsApiUrl),
                headers: {'Content-Type': 'application/json'},
                body: json.encode(newStudent),
              )
            : await http.put(
                Uri.parse('$studentsApiUrl/${_currentStudent!['id']}'),
                headers: {'Content-Type': 'application/json'},
                body: json.encode(newStudent),
              );

        if (response.statusCode == 201 || response.statusCode == 200) {
          fetchData();
          _toggleForm();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_currentStudent == null 
                  ? 'Étudiant ajouté avec succès' 
                  : 'Étudiant modifié avec succès'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else {
          throw Exception('Failed to save student');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String getClassName(int classId) {
    try {
      return classes.firstWhere((c) => c['id'] == classId)['niveau'] ?? context.tr('common.unknown');
    } catch (e) {
      return context.tr('common.unknown');
    }
  }

  String getParentName(int parentId) {
    try {
      final parent = parents.firstWhere((p) => p['id'] == parentId);
      return '${parent['nom']} (${parent['telephone']})';
    } catch (e) {
      return context.tr('common.unknown');
    }
  }

  void _showDeleteConfirmationDialog(int studentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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
          content: Text(context.tr('students.delete_confirmation')),
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
                deleteStudent(studentId);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStudentForm() {
    if (classes.isEmpty || parents.isEmpty) {
      return Center(child: Text(context.tr('students.missing_data')));
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _currentStudent == null ? context.tr('students.add_student') : context.tr('students.edit_student'),
                style: TextStyle(
                  color: Colors.blue.shade900,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomController,
                decoration: InputDecoration(
                  labelText: context.tr('students.last_name'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.person, color: Colors.blue.shade900),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                ),
                validator: (value) => value?.isEmpty ?? true ? context.tr('forms.required_field') : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _prenomController,
                decoration: InputDecoration(
                  labelText: context.tr('students.first_name'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.person_outline, color: Colors.blue.shade900),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                ),
                validator: (value) => value?.isEmpty ?? true ? context.tr('forms.required_field') : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedClassId,
                decoration: InputDecoration(
                  labelText: context.tr('students.class'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.school, color: Colors.blue.shade900),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                ),
                items: classes.map<DropdownMenuItem<int>>((classe) {
                  return DropdownMenuItem<int>(
                    value: classe['id'],
                    child: Text(classe['niveau']),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedClassId = value),
                validator: (value) => value == null ? context.tr('forms.selection_required') : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _selectedParentId,
                decoration: InputDecoration(
                  labelText: context.tr('students.parent'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: Icon(Icons.family_restroom, color: Colors.blue.shade900),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                ),
                items: parents.map<DropdownMenuItem<int>>((parent) {
                  return DropdownMenuItem<int>(
                    value: parent['id'],
                    child: Text('${parent['nom']} (${parent['email']})'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedParentId = value),
                validator: (value) => value == null ? context.tr('forms.selection_required') : null,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _toggleForm,
                    child: Text(context.tr('common.cancel'), style: const TextStyle(color: Colors.grey)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade900,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _saveStudent,
                    child: Text(context.tr('common.save')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade900,
        title: Text(
          context.tr('students.page_title'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 4,
        shadowColor: Colors.black26,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchData,
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
                labelText: context.tr('students.search_placeholder'),
                prefixIcon: Icon(Icons.search, color: Colors.blue.shade900),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear, color: Colors.blue.shade900),
                  onPressed: () {
                    _searchController.clear();
                    fetchData();
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
          if (showForm) _buildStudentForm(),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.blue.shade900))
                : students.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun étudiant trouvé',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          return Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.blue.shade900,
                                child: Text(
                                  student['prenom'][0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                '${student['prenom']} ${student['nom']}',
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
                                    '${context.tr('students.class')}: ${getClassName(student['classeId'])}',
                                    style: TextStyle(color: Colors.grey.shade700),
                                  ),
                                  Text(
                                    '${context.tr('students.parent')}: ${getParentName(student['parentId'])}',
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      color: Colors.blue.shade900,
                                    ),
                                    onPressed: () => _toggleForm(student: student),
                                    tooltip: context.tr('common.edit'),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _showDeleteConfirmationDialog(student['id']),
                                    tooltip: context.tr('common.delete'),
                                  ),
                                ],
                              ),
                              onTap: () => _toggleForm(student: student),
                            ),
                          );
                        },
                      ),
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
        onPressed: () => _toggleForm(),
        child: Icon(showForm ? Icons.close : Icons.add, size: 28),
        tooltip: showForm ? context.tr('students.close_form') : context.tr('students.add_student'),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    super.dispose();
  }
}