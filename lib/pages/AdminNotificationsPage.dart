// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import '../services/localization_service.dart';

// class AdminNotificationsPage extends StatefulWidget {
//   const AdminNotificationsPage({Key? key}) : super(key: key);

//   @override
//   _AdminNotificationsPageState createState() => _AdminNotificationsPageState();
// }

// class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
//   List<dynamic> notifications = [];
//   bool isLoading = true;
//   String errorMessage = '';

//   @override
//   // void initState() {
//     super.initState();
//     _fetchNotifications();
//   }

//   Future<void> _fetchNotifications() async {
//     setState(() {
//       isLoading = true;
//       errorMessage = '';
//     });

//     try {
//       final response = await http.get(
//         Uri.parse('http://localhost:8004/api/notifications'),
//         headers: {
//           'Content-Type': 'application/json',
//           // Ajoutez ici les headers d'authentification si nécessaire
//           // 'Authorization': 'Bearer $token',
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           notifications = data['notifications'] ?? [];
//           isLoading = false;
//         });
//       } else {
//         setState(() {
//           isLoading = false;
//           errorMessage = LocalizationService.instance.translate('admin_notifications.error_loading', {'code': response.statusCode.toString()});
//         });
//       }
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//         errorMessage = LocalizationService.instance.translate('admin_notifications.error_message', {'message': e.toString()});
//       });
//     }
//   }

//   Future<void> _refreshNotifications() async {
//     await _fetchNotifications();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(LocalizationService.instance.translate('admin_notifications.page_title')),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _refreshNotifications,
//             tooltip: LocalizationService.instance.translate('admin_notifications.refresh'),
//           ),
//         ],
//       ),
//       body: _buildBody(),
//     );
//   }

//   Widget _buildBody() {
//     if (isLoading) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const CircularProgressIndicator(),
//             const SizedBox(height: 16),
//             Text(LocalizationService.instance.translate('admin_notifications.loading')),
//           ],
//         ),
//       );
//     }

//     if (errorMessage.isNotEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(errorMessage),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: _fetchNotifications,
//               child: Text(LocalizationService.instance.translate('admin_notifications.retry')),
//             ),
//           ],
//         ),
//       );
//     }

//     if (notifications.isEmpty) {
//       return Center(
//         child: Text(LocalizationService.instance.translate('admin_notifications.no_notifications')),
//       );
//     }

//     return RefreshIndicator(
//       onRefresh: _refreshNotifications,
//       child: ListView.builder(
//         itemCount: notifications.length,
//         itemBuilder: (context, index) {
//           final notification = notifications[index];
//           return _buildNotificationCard(notification);
//         },
//       ),
//     );
//   }

//   Widget _buildNotificationCard(Map<String, dynamic> notification) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//       child: ListTile(
//         leading: _getNotificationIcon(notification['type']),
//         title: Text(
//           notification['title'] ?? LocalizationService.instance.translate('admin_notifications.no_title'),
//           style: TextStyle(
//             fontWeight: notification['read'] == false ? FontWeight.bold : FontWeight.normal,
//           ),
//         ),
//         subtitle: Text(notification['message'] ?? ''),
//         trailing: Text(
//           _formatDate(notification['createdAt']),
//           style: const TextStyle(fontSize: 12),
//         ),
//         onTap: () {
//           // Action lorsqu'on clique sur une notification
//           _handleNotificationTap(notification);
//         },
//       ),
//     );
//   }

//   Widget _getNotificationIcon(String? type) {
//     IconData icon;
//     Color color;

//     switch (type) {
//       case 'warning':
//         icon = Icons.warning;
//         color = Colors.orange;
//         break;
//       case 'error':
//         icon = Icons.error;
//         color = Colors.red;
//         break;
//       case 'success':
//         icon = Icons.check_circle;
//         color = Colors.green;
//         break;
//       default:
//         icon = Icons.notifications;
//         color = Colors.blue;
//     }

//     return Icon(icon, color: color);
//   }

//   String _formatDate(String? dateString) {
//     if (dateString == null) return '';
//     try {
//       final date = DateTime.parse(dateString);
//       return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
//     } catch (e) {
//       return dateString;
//     }
//   }

//   void _handleNotificationTap(Map<String, dynamic> notification) {
//     // Marquer comme lu ou effectuer une action spécifique
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(notification['title'] ?? LocalizationService.instance.translate('admin_notifications.notification_details')),
//         content: Text(notification['message'] ?? LocalizationService.instance.translate('admin_notifications.no_message')),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text(LocalizationService.instance.translate('admin_notifications.close')),
//           ),
//         ],
//       ),
//     );
//   }
// }