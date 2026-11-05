import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dexa_assessment_mobile/main.dart';
import 'package:dexa_assessment_mobile/data/sample_data.dart';
import 'package:dexa_assessment_mobile/pages/notification_detail_page.dart';
import 'package:dexa_assessment_mobile/pages/announcement_detail_page.dart';
import 'package:dexa_assessment_mobile/services/notification_storage.dart';
import 'package:dexa_assessment_mobile/state/app_state.dart';
import 'package:dexa_assessment_mobile/theme/app_theme.dart';

void setViewport(WidgetTester tester, Size size, double scale) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  testWidgets('Filtered information remains usable at 320dp and 150% text', (
    tester,
  ) async {
    setViewport(tester, const Size(320, 640), 1.5);
    final state = AppState(storage: InMemoryNotificationStorage());
    await state.loadPersistedState();
    state.setTabIndex(1);
    state.setSearchQuery('magang');
    await tester.pumpWidget(DexaAssessmentApp(appState: state));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Menampilkan 1 dari 4 informasi'), findsOneWidget);
    await tester.tap(find.text('Reset filter'));
    await tester.pumpAndSettle();
    expect(state.searchQuery, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Notification detail labels fit at 320dp and 150% text', (
    tester,
  ) async {
    setViewport(tester, const Size(320, 640), 1.5);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: NotificationDetailPage(
          notification: SampleData.initialNotifications.first,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Announcement detail labels fit at 320dp and 150% text', (
    tester,
  ) async {
    setViewport(tester, const Size(320, 640), 1.5);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: AnnouncementDetailPage(
          announcement: SampleData.initialAnnouncements[1],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Search stays usable with keyboard open in landscape', (
    tester,
  ) async {
    setViewport(tester, const Size(640, 360), 1);
    final state = AppState(storage: InMemoryNotificationStorage());
    await state.loadPersistedState();
    state.setTabIndex(1);
    await tester.pumpWidget(DexaAssessmentApp(appState: state));
    await tester.enterText(find.byType(TextField), 'zzznomatch');
    tester.view.viewInsets = const FakeViewPadding(bottom: 180);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(state.filteredAnnouncements, isEmpty);
    await tester.ensureVisible(find.text('Reset filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset filter'));
    await tester.pumpAndSettle();
    expect(state.searchQuery, isEmpty);
    expect(state.filteredAnnouncements.length, state.totalAnnouncementCount);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Switching tabs dismisses search keyboard focus', (tester) async {
    final state = AppState(storage: InMemoryNotificationStorage());
    await state.loadPersistedState();
    state.setTabIndex(1);
    await tester.pumpWidget(DexaAssessmentApp(appState: state));
    await tester.enterText(find.byType(TextField), 'magang');
    await tester.pumpAndSettle();
    final search = tester.widget<EditableText>(find.byType(EditableText));
    expect(search.focusNode.hasFocus, isTrue);
    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.text('Profil'),
      ),
    );
    await tester.pumpAndSettle();
    expect(state.currentTabIndex, 3);
    expect(search.focusNode.hasFocus, isFalse);
    expect(state.searchQuery, 'magang');
  });
}
