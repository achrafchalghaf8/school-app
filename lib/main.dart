import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/accounts_page.dart';
import 'package:flutter_application_1/pages/administrators_page.dart';
import 'package:flutter_application_1/pages/classes_page.dart';
import 'package:flutter_application_1/pages/cours_page.dart';
import 'package:flutter_application_1/pages/emplois_page.dart';
import 'package:flutter_application_1/pages/exercices_page.dart';
import 'package:flutter_application_1/pages/parents_page.dart';
import 'package:flutter_application_1/pages/students_page.dart';
import 'package:flutter_application_1/pages/teachers_page.dart';
import 'package:flutter_application_1/pages/welcome_admin.dart';
import 'package:flutter_application_1/pages/welcome_parent.dart';
import 'package:flutter_application_1/pages/welcome_teacher.dart';
import 'pages/login_page.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/admin': (context) => const WelcomeAdminPage(),
        '/parent': (context) => const WelcomeParentPage(),
        '/teacher': (context) {
  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
  return WelcomeTeacherPage(userId: args['userId'], token: args['token']);
},

          '/admin/administrators': (context) => const AdministratorsPage(),
            '/admin/teachers': (context) => const TeachersPage(),
              '/admin/parents': (context) => const ParentsPage(),
               '/admin/students': (context) => const StudentsPage(),
               '/admin/classes': (context) => const ClassesPage(),
               '/admin/schedule': (context) => EmploisPage(),
               '/admin/exercises': (context) => const ExercicesPage(),
               '/admin/courses': (context) => const CoursPage(),
               '/admin/dashboard': (context) => const WelcomeAdminPage(),


          

          '/admin/accounts': (context) => const AccountsPage(), // Ajoutez cette ligne

      },
    );
  }
}