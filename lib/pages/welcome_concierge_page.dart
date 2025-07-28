import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/websocket_service.dart';
import '../services/localization_service.dart';
import '../models/pickup_request.dart';
import '../widgets/language_selector.dart';
import 'dart:convert';

class WelcomeConciergePage extends StatefulWidget {
  const WelcomeConciergePage({Key? key}) : super(key: key);

  @override
  _WelcomeConciergePage createState() => _WelcomeConciergePage();
}

class _WelcomeConciergePage extends State<WelcomeConciergePage> {
  final WebSocketService _webSocketService = WebSocketService();
  final LocalizationService _localizationService = LocalizationService();
  List<PickupRequest> _pickupRequests = [];
  bool _isLoading = true;
  bool _isConnectingWebSocket = false;
  String _conciergeName = '';

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    print('🏫 [CONCIERGE PAGE] Initialisation de la page concierge');
    await _loadConciergeInfo();
    print('🏫 [CONCIERGE PAGE] Informations concierge chargées');
    await _loadStoredPickupRequests(); // Charger les demandes stockées
    print('🏫 [CONCIERGE PAGE] Demandes stockées chargées');
    await _initializeWebSocket();
    print('🏫 [CONCIERGE PAGE] WebSocket initialisé');
    setState(() {
      _isLoading = false;
    });
    print('🏫 [CONCIERGE PAGE] Initialisation terminée');
  }

  Future<void> _loadConciergeInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _conciergeName = prefs.getString('userName') ?? 'Concierge';
    });
  }

  Future<void> _loadStoredPickupRequests() async {
    print('🏫 [CONCIERGE PAGE] Début chargement des demandes');
    try {
      final storedRequests = await _webSocketService.getStoredPickupRequests();
      print('🏫 [CONCIERGE PAGE] Demandes récupérées du service: ${storedRequests.length}');

      setState(() {
        _pickupRequests = storedRequests.map((requestData) {
          print('🏫 [CONCIERGE PAGE] Conversion demande: ${requestData['studentName']}');
          return PickupRequest.fromJson(requestData);
        }).toList();
      });
      print('🏫 [CONCIERGE PAGE] Demandes chargées dans l\'UI: ${_pickupRequests.length}');
      print('Demandes chargées: ${_pickupRequests.length}');
    } catch (e) {
      print('❌ [CONCIERGE PAGE] Erreur lors du chargement: $e');
      print('Erreur lors du chargement des demandes: $e');
    }
  }

  Future<void> _initializeWebSocket() async {
    setState(() {
      _isConnectingWebSocket = true;
    });

    try {
      await _webSocketService.connect();

      // Écouter les demandes de récupération
      _webSocketService.onPickupRequestReceived = (data) {
        if (mounted) {
          setState(() {
            _pickupRequests.add(PickupRequest.fromJson(data));
          });

          // Afficher une notification
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr('concierge.new_request_notification').replaceAll('{studentName}', data['studentName']),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: context.tr('common.close'),
                onPressed: () {
                  // Scroll vers la nouvelle demande
                },
              ),
            ),
          );
        }
      };
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

  Future<void> _respondToPickupRequest(PickupRequest request, String response) async {
    try {
      // Mettre à jour le statut localement
      final status = response == 'APPROVED' ? 'APPROVED' : 'REJECTED';
      await _webSocketService.updatePickupRequestStatus(
        request.id,
        status,
        _conciergeName,
      );

      // Recharger les demandes pour refléter les changements
      await _loadStoredPickupRequests();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr('concierge.response_success').replaceAll('{studentName}', request.studentName),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de la réponse à la demande: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('concierge.response_error').replaceAll('{error}', e.toString())),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
        title: Text(
          context.tr('concierge.welcome').replaceAll('{name}', _conciergeName),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              await _loadStoredPickupRequests();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('concierge.requests_reloaded')),
                  backgroundColor: Colors.blue,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _webSocketService.isConnected ? Icons.wifi : Icons.wifi_off,
              color: _webSocketService.isConnected ? Colors.green : Colors.red,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _webSocketService.isConnected
                        ? context.tr('concierge.websocket_connected')
                        : context.tr('concierge.websocket_disconnected'),
                  ),
                  backgroundColor: _webSocketService.isConnected
                      ? Colors.green
                      : Colors.red,
                ),
              );
            },
          ),
          LanguageSelector(),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isConnectingWebSocket) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(context.tr('concierge.connecting_notifications')),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildPickupRequestsList()),
      ],
    );
  }

  Widget _buildPickupRequestsList() {
    if (_pickupRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('concierge.no_requests'),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('concierge.no_requests_description'),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _pickupRequests.length,
      itemBuilder: (context, index) {
        final request = _pickupRequests[_pickupRequests.length - 1 - index]; // Plus récent en premier
        return _buildPickupRequestCard(request);
      },
    );
  }

  Widget _buildPickupRequestCard(PickupRequest request) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (request.status) {
      case 'PENDING':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = context.tr('concierge.status.pending');
        break;
      case 'APPROVED':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = context.tr('concierge.status.approved');
        break;
      case 'REJECTED':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = context.tr('concierge.status.rejected');
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = context.tr('concierge.status.unknown');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: statusColor.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      statusIcon,
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.studentName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          context.tr('concierge.requested_by').replaceAll('{parentName}', request.parentName),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                request.reason,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('concierge.received_on').replaceAll('{dateTime}', _formatDateTime(request.timestamp)),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              if (request.status != 'PENDING') ...[
                const SizedBox(height: 8),
                Text(
                  context.tr('concierge.responded_by')
                      .replaceAll('{conciergeName}', request.conciergeName ?? '')
                      .replaceAll('{dateTime}', _formatDateTime(request.responseTimestamp!)),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
              if (request.status == 'PENDING') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _respondToPickupRequest(request, 'APPROVED'),
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: Text(context.tr('concierge.approve'), style: const TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _respondToPickupRequest(request, 'REJECTED'),
                        icon: const Icon(Icons.close, color: Colors.white),
                        label: Text(context.tr('concierge.reject'), style: const TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} à ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildHeader() {
    final pendingCount = _pickupRequests.where((r) => r.status == 'PENDING').length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active,
              size: 32,
              color: Colors.orange.shade700,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('concierge.pickup_requests'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('concierge.pending_requests').replaceAll('{count}', pendingCount.toString()),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: pendingCount > 0 ? Colors.orange.shade100 : Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$pendingCount',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: pendingCount > 0 ? Colors.orange.shade700 : Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _webSocketService.dispose();
    super.dispose();
  }
}