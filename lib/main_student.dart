import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'student/student_app.dart';
import 'student/fastapi_student_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const configured = String.fromEnvironment(
    'DEXA_API_BASE_URL',
    defaultValue: kDebugMode ? 'http://10.0.2.2:3001' : '',
  );
  runApp(
    StudentApp(
      repository: FastApiStudentRepository(
        baseUri: Uri.tryParse(configured) ?? Uri(),
        allowInsecureDevelopment: kDebugMode,
      ),
    ),
  );
}
