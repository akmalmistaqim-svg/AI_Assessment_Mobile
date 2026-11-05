import 'main_student.dart' as student;

import 'package:flutter/material.dart';

import 'pages/main_navigation_page.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() => student.main();

/// Widget akar aplikasi Dexa Assessment Mobile.
class DexaAssessmentApp extends StatefulWidget {
  final AppState? appState;

  const DexaAssessmentApp({super.key, this.appState});

  @override
  State<DexaAssessmentApp> createState() => _DexaAssessmentAppState();
}

class _DexaAssessmentAppState extends State<DexaAssessmentApp> {
  late final AppState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.appState ?? AppState();
    // Jika state dibuat otomatis secara internal, lakukan pemulihan jika belum diinisialisasi
    if (widget.appState == null && !_state.isInitialized) {
      _state.loadPersistedState();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: _state,
      child: MaterialApp(
        title: 'Dexa Assessment',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        home: const MainNavigationPage(),
      ),
    );
  }
}
