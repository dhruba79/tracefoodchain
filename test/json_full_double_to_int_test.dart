import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:trace_foodchain_app/helpers/json_full_double_to_int.dart';
import 'package:trace_foodchain_app/helpers/sort_json_alphabetically.dart';

void main() {
  group('Json Full Double to int test', () {
    test('Only doubles that end with .0 should be converted to int', () {
      Map<String, dynamic> obj = {
        "str": "some test 1000.0 and behind",
        "only1000.0": "1000.0",
        "num": 1234.0, //This sould be replaced to 1234
        "nested": {
          "array": [
            {
              "num": 1000.0, //This sould be replaced to 1000
            }
          ],
        },
        "a": 1000.04,
      };

      final result = jsonFullDoubleToInt(obj);

      final sorted = sortJsonAlphabetically(result);

      final str = json.encode(sorted); //jsonEncode(obj);

      expect(
        '{"a":1000.04,"nested":{"array":[{"num":1000}]},"num":1234,"only1000.0":"1000.0","str":"some test 1000.0 and behind"}',
        str,
      );
    });
  });
}
