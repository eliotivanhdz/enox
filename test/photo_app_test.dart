import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mockito/mockito.dart';
import 'package:enox/presentation/pages/photo_exif_page.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Mock class for ImagePicker
class MockImagePicker extends Mock implements ImagePicker {}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('PhotoExifPage displays initial state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PhotoExifPage()));

    // Check controls are present
    expect(find.byIcon(Icons.camera_alt), findsOneWidget);
    expect(find.text('No hay registros guardados'), findsOneWidget);
  });
}
