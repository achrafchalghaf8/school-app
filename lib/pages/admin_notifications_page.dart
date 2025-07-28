import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/localization_service.dart';

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({Key? key}) : super(key: key);

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  List<dynamic> notifications = [];
  List<dynamic> filteredNotifications = [];
  List<dynamic> comptes = [];
  bool isLoading = false;
  String error = '';
  TextEditingController searchController = TextEditingController();

  // Couleurs
  final primaryColor = Colors.blue.shade900;
  final accentColor = Colors.blue.shade600;
  final backgroundColor = Colors.grey.shade50;

  @override
  void initState() {
    super.initState();
    _loadData();
    searchController.addListener(_filterNotifications);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _fetchAllNotifications(),
      _fetchAllComptes(),
    ]);
  }

  Future<void> _fetchAllNotifications() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8004/api/notifications'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          notifications = List.from(data);
          filteredNotifications = List.from(data);
        });
      } else {
        throw Exception(context.tr('admin_notifications.error_loading').replaceAll('{code}', response.statusCode.toString()));
      }
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  Future<void> _fetchAllComptes() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8004/api/comptes'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          comptes = List.from(data);
          isLoading = false;
        });
      } else {
        throw Exception(context.tr('admin_notifications.error_loading').replaceAll('{code}', response.statusCode.toString()));
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void _filterNotifications() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredNotifications = notifications.where((notification) {
        final content = notification['contenu']?.toString().toLowerCase() ?? '';
        final recipients = (notification['compteIds'] as List)
            .map((id) => _getUserName(id).toLowerCase())
            .join(' ');
        return content.contains(query) || recipients.contains(query);
      }).toList();
    });
  }

  String _getUserName(int compteId) {
    final compte = comptes.firstWhere(
      (c) => c['id'] == compteId,
      orElse: () => {'nom': context.tr('common.unknown')},
    );
    return compte['nom'];
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, child) {
        final isRTL = LocalizationService().isRTL;
        
        return Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                context.tr('admin_notifications.page_title'),
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              backgroundColor: primaryColor,
              elevation: 4,
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.white),
                  onPressed: _refresh,
                  tooltip: context.tr('admin_notifications.refresh'),
                ),
              ],
            ),
            body: Container(
              color: backgroundColor,
              child: Column(
                children: [
                  _buildSearchBar(),
                  Expanded(child: _buildNotificationList()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: context.tr('common.search'),
          prefixIcon: Icon(Icons.search, color: primaryColor),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: primaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('admin_notifications.loading'),
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              context.tr('admin_notifications.error_message').replaceAll('{message}', error),
              style: TextStyle(color: Colors.red.shade700, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _loadData,
              child: Text(context.tr('admin_notifications.retry')),
            ),
          ],
        ),
      );
    }

    if (filteredNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              searchController.text.isEmpty
                  ? context.tr('admin_notifications.no_notifications')
                  : context.tr('common.no_results').replaceAll('{query}', searchController.text),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: accentColor,
      backgroundColor: backgroundColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = filteredNotifications[index];
          return _buildNotificationItem(notification);
        },
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final compteIds = List<int>.from(notification['compteIds'] ?? []);
    final hasRecipients = compteIds.isNotEmpty;
    final recipientNames = compteIds.map(_getUserName).join(', ');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: primaryColor.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: hasRecipients 
              ? accentColor.withOpacity(0.2) 
              : Colors.grey.withOpacity(0.2),
          child: Icon(
            hasRecipients ? Icons.mark_email_read : Icons.mark_email_unread,
            color: hasRecipients ? accentColor : Colors.grey,
            size: 20,
          ),
        ),
        title: Text(
          '${context.tr('admin_notifications.notification_details')} #${notification['id']}',
          style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification['contenu'] ?? context.tr('admin_notifications.no_message'),
              style: TextStyle(color: Colors.grey.shade800),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(notification['date']),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (hasRecipients)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${context.tr('common.recipients')}: $recipientNames',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return context.tr('common.unknown_date');
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${context.tr('common.at')} ${date.hour}h${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}