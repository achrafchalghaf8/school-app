import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/emplois_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'classe_detail_page.dart';

class WelcomeTeacherPage extends StatefulWidget {
  final int userId;
  final String token;
  const WelcomeTeacherPage({
    Key? key,
    required this.userId,
    required this.token,
  }) : super(key: key);

  @override
  State<WelcomeTeacherPage> createState() => _WelcomeTeacherPageState();
}

class _WelcomeTeacherPageState extends State<WelcomeTeacherPage> {
  List<Classe> _classes = [];
  List<Map<String, dynamic>> _cours = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchClasses();
    _fetchCours();
  }

  Future<void> _fetchClasses() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8004/api/classes'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _classes = data
              .map((e) => Classe.fromJson(e))
              .where((c) => c.enseignantIds.contains(widget.userId))
              .toList();
          _loading = false;
        });
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _fetchCours() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8004/api/cours'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _cours = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des cours: $e');
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text(
          'Espace Enseignant',
          style: TextStyle(
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
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _logout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.blue));
    }

    if (_error.isNotEmpty) {
      return _buildErrorWidget();
    }

    return _classes.isEmpty ? _buildNoClassesWidget() : _buildClassesGrid();
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, size: 60, color: Colors.redAccent),
                const SizedBox(height: 16),
                Text(
                  _error,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchClasses,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoClassesWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.class_,
            size: 60,
            color: Colors.blue.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune classe assignée',
            style: TextStyle(
              color: Colors.blue.shade600,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassesGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth > 600 ? 600 : constraints.maxWidth,
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: constraints.maxWidth > 600 ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: _classes.length,
                  itemBuilder: (context, index) {
                    final classe = _classes[index];
                    return _buildClassCard(classe);
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildClassCard(Classe classe) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToClassDetail(classe),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.class_,
                  size: 32,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  classe.niveau,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade900,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToClassDetail(Classe classe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ClasseDetailPage(
          classeId: classe.id,
          token: widget.token,
          enseignantId: widget.userId,
        ),
      ),
    );
  }
}
