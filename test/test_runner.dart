import 'package:flutter_test/flutter_test.dart';
// import 'package:medrefer_ai/test/core/result_test.dart' as result_test;
// import 'package:medrefer_ai/test/services/validation_service_test.dart' as validation_test;
import 'package:medrefer_ai/test/services/auth_service_test.dart' as auth_test;

void main() {
  group('MedRefer AI Test Suite', () {
    // group('Core Tests', result_test.main);

    group('Service Tests', () {
      // validation_test.main();
      auth_test.main();
    });
  });
}