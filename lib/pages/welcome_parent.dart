import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/student_details_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WelcomeParentPage extends StatefulWidget {
  const WelcomeParentPage({Key? key}) : super(key: key);

  @override
  _WelcomeParentPageState createState() => _WelcomeParentPageState();
}

class _WelcomeParentPageState extends State<WelcomeParentPage> {
  List<dynamic> _etudiants = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _parentName = '';
  int _parentId = 0;

  @override
  void initState() {
    super.initState();
    _fetchParentData();
  }

  Future<void> _fetchParentData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final parentId = prefs.getInt('userId');
      final token = prefs.getString('token');
      
      if (parentId == null || token == null) {
        throw Exception('Session invalide');
      }

      // Récupérer les infos du parent
      final parentResponse = await http.get(
        Uri.parse('http://localhost:8004/api/parents/$parentId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (parentResponse.statusCode == 200) {
        final parentData = json.decode(parentResponse.body);
        setState(() {
          _parentId = parentId;
          _parentName = parentData['nom'] ?? 'Parent';
        });

        // Récupérer les étudiants de ce parent
        await _fetchParentStudents();
      } else {
        throw Exception('Impossible de récupérer les informations du parent');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur: ${e.toString()}';
      });
    }
  }

  Future<void> _fetchParentStudents() async {
    try {
      final token = (await SharedPreferences.getInstance()).getString('token');
      
      final response = await http.get(
        Uri.parse('http://localhost:8004/api/etudiants?parentId=$_parentId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final filteredStudents = data is List 
            ? data.where((e) => e['parentId'] == _parentId).toList()
            : [];
        
        setState(() {
          _etudiants = filteredStudents;
          _isLoading = false;
        });
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors du chargement des étudiants: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text(
          'Espace de $_parentName',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchParentStudents,
            tooltip: 'Rafraîchir',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushReplacementNamed(context, '/login');
            },
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.blue.shade700,
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Card(
                      elevation: 3,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                )
              : _etudiants.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.school,
                            size: 60,
                            color: Colors.blue.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun enfant trouvé',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vous n\'avez pas encore d\'enfant enregistré',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade400,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildStudentsGrid(),
    );
  }

  Widget _buildStudentsGrid() {
    // Use a maximum of 2 cards per row for centering
    final crossAxisCount = _etudiants.length < 2 ? _etudiants.length : 2;
    final size = MediaQuery.of(context).size.width / (crossAxisCount + 1);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600), // Limit max width for larger screens
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: _etudiants.length,
          itemBuilder: (context, index) {
            final etudiant = _etudiants[index];
            return _buildStudentCard(etudiant, size);
          },
        ),
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> etudiant, double size) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDetailsPage(etudiantId: etudiant['id']),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: size * 0.6,
                height: size * 0.6,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.school,
                  size: size * 0.3,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${etudiant['prenom']} ${etudiant['nom']}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.blue.shade900,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
            
            ],
          ),
        ),
      ),
    );
  }
}