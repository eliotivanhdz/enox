import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mockito/mockito.dart';
import 'package:enox/main.dart';

// Mock class for ImagePicker
class MockImagePicker extends Mock implements ImagePicker {}

void main() {
  testWidgets('PhotoApp displays buttons and initial state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PhotoApp()));

    // Check buttons are present
    expect(find.text('Select from Gallery'), findsOneWidget);
    expect(find.text('Take Photo'), findsOneWidget);

    // Check no image initially
    expect(find.byType(Image), findsNothing);

    // Check no EXIF card initially
    expect(find.byType(Card), findsNothing);
  });
}
