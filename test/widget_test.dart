import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geriatriccare/app/app.dart';
import 'package:geriatriccare/features/navigation/presentation/pages/elder_navigation_page.dart';
import 'package:geriatriccare/features/health/presentation/providers/health_providers.dart';
import 'package:geriatriccare/features/medication/presentation/providers/medication_providers.dart';

void main() {
  testWidgets('Elder home renders the primary emergency action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          medicationSchedulesProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
          todayMedicationIntakesProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
          healthRecordsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: const GeriatricCareApp(home: ElderNavigationPage()),
      ),
    );
    expect(find.text('GỌI KHẨN\nCẤP'), findsOneWidget);
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Sức khỏe'), findsOneWidget);
    expect(find.text('Liên hệ'), findsOneWidget);
  });
}
