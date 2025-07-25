import 'package:flutter/material.dart';
import '../services/localization_service.dart';
import '../widgets/language_selector.dart';

class LanguageDemoPage extends StatefulWidget {
  const LanguageDemoPage({Key? key}) : super(key: key);

  @override
  State<LanguageDemoPage> createState() => _LanguageDemoPageState();
}

class _LanguageDemoPageState extends State<LanguageDemoPage> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalizationService(),
      builder: (context, child) {
        final isRTL = LocalizationService().isRTL;
        
        return Directionality(
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: Colors.blue.shade50,
            appBar: AppBar(
              title: Text(
                'Démonstration des traductions',
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
                LanguageSelector(
                  showAsDialog: false,
                  onLanguageChanged: () {
                    setState(() {});
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Informations générales
                  _buildSection(
                    title: 'Informations générales',
                    items: [
                      _buildTranslationItem('common.loading', context.tr('common.loading')),
                      _buildTranslationItem('common.error', context.tr('common.error')),
                      _buildTranslationItem('common.success', context.tr('common.success')),
                      _buildTranslationItem('common.save', context.tr('common.save')),
                      _buildTranslationItem('common.cancel', context.tr('common.cancel')),
                      _buildTranslationItem('common.refresh', context.tr('common.refresh')),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Section Cours
                  _buildSection(
                    title: 'Page Cours',
                    items: [
                      _buildTranslationItem('parents.courses.page_title', 
                          context.tr('parents.courses.page_title').replaceAll('{class}', '6ème A')),
                      _buildTranslationItem('parents.courses.no_courses_available', 
                          context.tr('parents.courses.no_courses_available')),
                      _buildTranslationItem('parents.courses.unknown_subject', 
                          context.tr('parents.courses.unknown_subject')),
                      _buildTranslationItem('parents.courses.exercises_label', 
                          context.tr('parents.courses.exercises_label')),
                      _buildTranslationItem('parents.courses.download', 
                          context.tr('parents.courses.download')),
                      _buildTranslationItem('parents.courses.published_on', 
                          context.tr('parents.courses.published_on').replaceAll('{date}', '15/01/2024')),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Section Emploi du temps
                  _buildSection(
                    title: 'Page Emploi du temps',
                    items: [
                      _buildTranslationItem('parents.schedule.page_title', 
                          context.tr('parents.schedule.page_title').replaceAll('{class}', '6ème A')),
                      _buildTranslationItem('parents.schedule.no_schedule_available', 
                          context.tr('parents.schedule.no_schedule_available')),
                      _buildTranslationItem('parents.schedule.most_recent_schedule', 
                          context.tr('parents.schedule.most_recent_schedule')),
                      _buildTranslationItem('parents.schedule.loading_file', 
                          context.tr('parents.schedule.loading_file')),
                      _buildTranslationItem('parents.schedule.student', 
                          context.tr('parents.schedule.student').replaceAll('{name}', 'Ahmed Ali')),
                      _buildTranslationItem('parents.schedule.schedules_available', 
                          context.tr('parents.schedule.schedules_available').replaceAll('{count}', '3')),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Section Navigation
                  _buildSection(
                    title: 'Navigation',
                    items: [
                      _buildTranslationItem('navigation.home', context.tr('navigation.home')),
                      _buildTranslationItem('navigation.dashboard', context.tr('navigation.dashboard')),
                      _buildTranslationItem('navigation.logout', context.tr('navigation.logout')),
                      _buildTranslationItem('navigation.language', context.tr('navigation.language')),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Informations sur la langue actuelle
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.blue.shade100),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informations sur la langue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                'Langue actuelle: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              Text(
                                LocalizationService().getCurrentLanguageName(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'Direction du texte: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              Text(
                                isRTL ? 'Droite vers gauche (RTL)' : 'Gauche vers droite (LTR)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'Code de langue: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              Text(
                                LocalizationService().currentLocale.languageCode.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blue.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 12),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationItem(String key, String translation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              key,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              translation,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blue.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
