import 'package:flutter/material.dart';

import 'main.dart' show DexaAssessmentApp;
import 'state/app_state.dart';

// Explicitly opt into the preserved offline demo. Not the production login flow.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.loadPersistedState();
  runApp(DexaAssessmentApp(appState: state));
}
