import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/courses_page.dart';
import 'package:flutter_application_1/pages/emploi_du_temps_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/localization_service.dart';
import '../services/websocket_service.dart';

class StudentDetailsPage extends StatefulWidget {
  final int etudiantId;

  const StudentDetailsPage({Key? key, required this.etudiantId}) : super(key: key);

  @override
  _StudentDetailsPageState createState() => _StudentDetailsPageState();
}

class _StudentDetailsPageState extends State<StudentDetailsPage> {
  Map<String, dynamic>? _etudiantDetails;
  Map<String, dynamic>? _classeDetails;
  bool _isLoading = true;
  String _errorMessage = '';
  final WebSocketService _webSocketService = WebSocketService();
  bool _isConnectingWebSocket = false;
  bool _isSendingRequest = false;

  @override
  void initState() {
    super.initState();
    _fetchStudentAndClassDetails();
    _initializeWebSocket();
  }

  Future<void> _initializeWebSocket() async {
    setState(() {
      _isConnectingWebSocket = true;
    });

    try {
      await _webSocketService.connect();
    } catch (e) {
      print('Erreur lors de la connexion WebSocket: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isConnectingWebSocket = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _webSocketService.dispose();
    super.dispose();
  }

  Future<void> _fetchStudentAndClassDetails() async {
    try {
      // Récupérer les détails de l'étudiant
      final etudiantResponse = await http.get(
        Uri.parse('http://localhost:8004/api/etudiants/${widget.etudiantId}'),
      );

      if (etudiantResponse.statusCode != 200) {
        throw Exception(LocalizationService().translate('parents.student_details.failed_student_details'));
      }

      final etudiantData = json.decode(etudiantResponse.body);
      setState(() {
        _etudiantDetails = etudiantData;
      });

      // Récupérer les détails de la classe
      final classeId = etudiantData['classeId'];
      if (classeId == null) {
        throw Exception(LocalizationService().translate('parents.student_details.class_id_not_found'));
      }

      final classeResponse = await http.get(
        Uri.parse('http://localhost:8004/api/classes/$classeId'),
      );

      if (classeResponse.statusCode == 200) {
        setState(() {
          _classeDetails = json.decode(classeResponse.body);
          _isLoading = false;
        });
      } else {
        throw Exception(LocalizationService().translate('parents.student_details.failed_class_details'));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '${LocalizationService().translate('parents.student_details.loading_error')}: ${e.toString()}';
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all stored user data
    Navigator.pushReplacementNamed(context, '/login'); // Assumes a login route exists
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, child) => Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text(
          _etudiantDetails != null 
            ? '${_etudiantDetails!['prenom']} ${_etudiantDetails!['nom']}'
            : LocalizationService().translate('parents.student_details.page_title'),
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
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_etudiantDetails != null || _classeDetails != null)
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.blue.shade100),
                            ),
                            child: Container(
                              width: double.infinity, // Full width
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      size: 36,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          LocalizationService().translate('parents.student_details.student_label'),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.blue.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _etudiantDetails != null
                                              ? '${_etudiantDetails!['prenom']} ${_etudiantDetails!['nom']}'
                                              : LocalizationService().translate('parents.student_details.not_specified'),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.blue.shade900,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          LocalizationService().translate('parents.student_details.class_level'),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.blue.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _classeDetails != null
                                              ? _classeDetails!['niveau'] ?? LocalizationService().translate('parents.student_details.not_specified')
                                              : LocalizationService().translate('parents.student_details.not_specified'),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.blue.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.3,
                          children: [
                            _buildActionCard(
                              icon: Icons.schedule,
                              title: LocalizationService().translate('parents.student_details.schedule'),
                              onTap: _navigateToSchedule,
                            ),
                            _buildActionCard(
                              icon: Icons.menu_book,
                              title: LocalizationService().translate('parents.student_details.courses'),
                              onTap: _navigateToCourses,
                            ),
                            _buildActionCard(
                              icon: Icons.person,
                              title: LocalizationService().translate('parents.student_details.pickup_child'),
                              onTap: _navigateToPickup,
                            ),
                            _buildActionCard(
                              icon: Icons.logout,
                              title: LocalizationService().translate('parents.student_details.logout'),
                              onTap: _logout,
                              iconColor: Colors.redAccent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  void _navigateToSchedule() {
    if (_etudiantDetails == null || _classeDetails == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmploiDuTempsPage(
          classeId: _classeDetails!['id'],
          etudiantNom: '${_etudiantDetails!['prenom']} ${_etudiantDetails!['nom']}',
          niveauClasse: _classeDetails!['niveau'],
        ),
      ),
    );
  }

  void _navigateToCourses() {
    if (_etudiantDetails == null || _classeDetails == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CoursesPage(
          classeId: _classeDetails!['id'],
          niveauClasse: _classeDetails!['niveau'],
          etudiantNom: '${_etudiantDetails!['prenom']} ${_etudiantDetails!['nom']}',
        ),
      ),
    );
  }

  Future<void> _sendPickupRequest() async {
    print('👨‍👩‍👧‍👦 [PARENT PAGE] Début envoi demande de récupération');
    if (_etudiantDetails == null || _isSendingRequest) return;

    setState(() {
      _isSendingRequest = true;
    });

    try {
      // Récupérer les informations du parent
      final prefs = await SharedPreferences.getInstance();
      final parentName = prefs.getString('userName') ?? 'Parent';
      print('👨‍👩‍👧‍👦 [PARENT PAGE] Parent: $parentName');
      print('👨‍👩‍👧‍👦 [PARENT PAGE] Étudiant: ${_etudiantDetails!['prenom']} ${_etudiantDetails!['nom']}');

      // Envoyer la demande via WebSocket
      print('👨‍👩‍👧‍👦 [PARENT PAGE] Appel du service WebSocket...');
      final success = await _webSocketService.sendPickupRequest(
        studentId: widget.etudiantId,
        studentName: '${_etudiantDetails!['prenom']} ${_etudiantDetails!['nom']}',
        parentName: parentName,
        reason: 'Demande de récupération d\'enfant',
      );
      print('👨‍👩‍👧‍👦 [PARENT PAGE] Résultat du service: $success');

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Demande de récupération envoyée avec succès pour ${_etudiantDetails!['prenom']} ${_etudiantDetails!['nom']}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'envoi de la demande. Veuillez réessayer.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingRequest = false;
        });
      }
    }
  }

  void _navigateToPickup() {
    _sendPickupRequest();
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
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
                  icon,
                  size: 36,
                  color: iconColor ?? Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade900,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}