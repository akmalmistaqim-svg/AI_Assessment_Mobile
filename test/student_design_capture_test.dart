import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dexa_assessment_mobile/student/student_app.dart';

import 'student_flow_test.dart' show login, tab, viewport;
import 'student_classes_test.dart' show ClassRepository;
import 'student_registration_test.dart' show RegisterRepo;

void main() {
  testWidgets('render current design with real fonts and sample data', (
    tester,
  ) async {
    const registration = bool.fromEnvironment('CAPTURE_REGISTRATION');
    if (!registration && !const bool.fromEnvironment('CAPTURE_DESIGN')) return;
    await tester.runAsync(() async {
      const folder = String.fromEnvironment('FLUTTER_FONT_DIR');
      final loader = FontLoader('Roboto');
      for (final name in [
        'roboto-regular.ttf',
        'roboto-medium.ttf',
        'roboto-bold.ttf',
      ]) {
        loader.addFont(
          File('$folder/$name')
              .readAsBytes()
              .then((b) => ByteData.sublistView(b)),
        );
      }
      await loader.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(
        File('$folder/materialicons-regular.otf')
            .readAsBytes()
            .then((b) => ByteData.sublistView(b)),
      );
      await icons.load();
    });
    viewport(tester, const Size(390, 844));
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: StudentApp(
          repository: registration ? RegisterRepo() : ClassRepository(),
        ),
      ),
    );
    // Asset decoding uses the engine's real clock, outside the widget test clock.
    final logo = find.byType(Image).first;
    final logoContext = tester.element(logo);
    final logoProvider = tester.widget<Image>(logo).image;
    await tester.runAsync(() => precacheImage(logoProvider, logoContext));
    await tester.pumpAndSettle();
    expect(
      tester.renderObject<RenderImage>(find.byType(RawImage).first).image,
      isNotNull,
    );
    Future<void> capture(String name) async {
      void repaint(RenderObject object) {
        object.markNeedsPaint();
        object.visitChildren(repaint);
      }

      repaint(key.currentContext!.findRenderObject()!);
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final dir = Directory(
          registration
              ? 'docs/evidence/registration-design'
              : 'docs/evidence/student-classes-design',
        );
        await dir.create(recursive: true);
        await File('${dir.path}/student-new-$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('login');
    if (registration) {
      await tester.tap(find.byKey(const Key('student-open-register')));
      await tester.pumpAndSettle();
      expect(find.text('Buat akun mahasiswa'), findsOneWidget);
      await capture('register');
      return;
    }
    await login(tester);
    await capture('home-before-join');
    await tab(tester, 'Kelas Saya');
    await capture('classes-empty');
    await tester.enterText(
      find.byKey(const Key('student-class-code')),
      'RPL123',
    );
    await tester.ensureVisible(find.byKey(const Key('student-join-class')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('student-join-class')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await capture('classes-joined');
    await tester.ensureVisible(find.byKey(const ValueKey('class-rpl-a')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('class-rpl-a')));
    await tester.pumpAndSettle();
    await capture('class-detail');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tab(tester, 'Beranda');
    await capture('home');
    await tab(tester, 'Informasi');
    await capture('information');
    await tester.ensureVisible(find.text('Jadwal evaluasi semester'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jadwal evaluasi semester'));
    await tester.pumpAndSettle();
    await capture('information-detail');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tab(tester, 'Notifikasi');
    await capture('notifications');
    await tester.tap(find.text('Informasi baru untukmu'));
    await tester.pumpAndSettle();
    await capture('notification-detail');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tab(tester, 'Profil');
    await capture('profile');
    await tester.ensureVisible(find.byKey(const Key('student-sign-out')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('student-sign-out')));
    await tester.pumpAndSettle();
    await capture('logout');
  });
}
