import 'dart:convert';

import 'package:flutter/services.dart';

/// The bundled demo data (`assets/demo/demo_data.json`), shared with the mock
/// API in `mock_api/`. Regenerate it with
/// `node mock_api/scripts/generate-fixtures.mjs`.
class DemoData {
  DemoData._();

  static const assetPath = 'assets/demo/demo_data.json';

  static Future<Map<String, dynamic>> load(AssetBundle bundle) async {
    final decoded = jsonDecode(await bundle.loadString(assetPath));
    if (decoded is Map<String, dynamic>) return decoded;
    throw const FormatException('Demo data must be a JSON object');
  }
}
