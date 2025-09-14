import 'package:flutter_test/flutter_test.dart';
import 'package:medrefer_ai/core/result.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('should create success result with data', () {
        const result = Result.success('test data');
        expect(result.isSuccess, true);
        expect(result.isError, false);
        expect(result.isLoading, false);
        expect(result.data, 'test data');
        expect(result.errorMessage, null);
        expect(result.error, null);
        expect(result.stackTrace, null);
      });

      test('should transform data with map', () {
        const result = Result.success(42);
        final transformed = result.map((data) => data * 2);
        expect(transformed.isSuccess, true);
        expect(transformed.data, 84);
      });

      test('should execute callback on success', () {
        const result = Result.success('test');
        var callbackExecuted = false;
        result.onSuccess((data) {
          expect(data, 'test');
          callbackExecuted = true;
        });
        expect(callbackExecuted, true);
      });

      test('should not execute error callback', () {
        const result = Result.success('test');
        var errorCallbackExecuted = false;
        result.onError((message, error) {
          errorCallbackExecuted = true;
        });
        expect(errorCallbackExecuted, false);
      });

      test('should unwrap data', () {
        const result = Result.success('test data');
        expect(result.unwrap(), 'test data');
      });

      test('should unwrap or return default', () {
        const result = Result.success('test data');
        expect(result.unwrapOr('default'), 'test data');
      });

      test('should unwrap or compute default', () {
        const result = Result.success('test data');
        expect(result.unwrapOrElse(() => 'computed'), 'test data');
      });
    });

    group('Error', () {
      test('should create error result with message', () {
        const result = Result.error('error message');
        expect(result.isSuccess, false);
        expect(result.isError, true);
        expect(result.isLoading, false);
        expect(result.data, null);
        expect(result.errorMessage, 'error message');
        expect(result.error, null);
        expect(result.stackTrace, null);
      });

      test('should create error result with error object and stack trace', () {
        final error = Exception('test error');
        final stackTrace = StackTrace.current;
        final result = Result.error('error message', error, stackTrace);
        expect(result.isError, true);
        expect(result.errorMessage, 'error message');
        expect(result.error, error);
        expect(result.stackTrace, stackTrace);
      });

      test('should not transform data with map', () {
        const result = Result.error('error message');
        final transformed = result.map((data) => data * 2);
        expect(transformed.isError, true);
        expect(transformed.errorMessage, 'error message');
      });

      test('should execute callback on error', () {
        const result = Result.error('error message');
        var callbackExecuted = false;
        result.onError((message, error) {
          expect(message, 'error message');
          callbackExecuted = true;
        });
        expect(callbackExecuted, true);
      });

      test('should not execute success callback', () {
        const result = Result.error('error message');
        var successCallbackExecuted = false;
        result.onSuccess((data) {
          successCallbackExecuted = true;
        });
        expect(successCallbackExecuted, false);
      });

      test('should throw when unwrapping', () {
        const result = Result.error('error message');
        expect(() => result.unwrap(), throwsException);
      });

      test('should return default when unwrapping or', () {
        const result = Result.error('error message');
        expect(result.unwrapOr('default'), 'default');
      });

      test('should compute default when unwrapping or else', () {
        const result = Result.error('error message');
        expect(result.unwrapOrElse(() => 'computed'), 'computed');
      });
    });

    group('Loading', () {
      test('should create loading result', () {
        const result = Result.loading();
        expect(result.isSuccess, false);
        expect(result.isError, false);
        expect(result.isLoading, true);
        expect(result.data, null);
        expect(result.errorMessage, null);
        expect(result.error, null);
        expect(result.stackTrace, null);
      });

      test('should not transform data with map', () {
        const result = Result.loading();
        final transformed = result.map((data) => data * 2);
        expect(transformed.isLoading, true);
      });

      test('should execute callback on loading', () {
        const result = Result.loading();
        var callbackExecuted = false;
        result.onLoading(() {
          callbackExecuted = true;
        });
        expect(callbackExecuted, true);
      });

      test('should not execute success or error callbacks', () {
        const result = Result.loading();
        var successCallbackExecuted = false;
        var errorCallbackExecuted = false;
        
        result.onSuccess((data) {
          successCallbackExecuted = true;
        });
        result.onError((message, error) {
          errorCallbackExecuted = true;
        });
        
        expect(successCallbackExecuted, false);
        expect(errorCallbackExecuted, false);
      });

      test('should throw when unwrapping', () {
        const result = Result.loading();
        expect(() => result.unwrap(), throwsException);
      });

      test('should return default when unwrapping or', () {
        const result = Result.loading();
        expect(result.unwrapOr('default'), 'default');
      });

      test('should compute default when unwrapping or else', () {
        const result = Result.loading();
        expect(result.unwrapOrElse(() => 'computed'), 'computed');
      });
    });

    group('mapOr', () {
      test('should return transformed value for success', () {
        const result = Result.success(42);
        final transformed = result.mapOr(0, (data) => data * 2);
        expect(transformed, 84);
      });

      test('should return default value for error', () {
        const result = Result.error('error');
        final transformed = result.mapOr(0, (data) => data * 2);
        expect(transformed, 0);
      });

      test('should return default value for loading', () {
        const result = Result.loading();
        final transformed = result.mapOr(0, (data) => data * 2);
        expect(transformed, 0);
      });
    });

    group('mapOrElse', () {
      test('should return transformed value for success', () {
        const result = Result.success(42);
        final transformed = result.mapOrElse(() => 0, (data) => data * 2);
        expect(transformed, 84);
      });

      test('should return computed default value for error', () {
        const result = Result.error('error');
        final transformed = result.mapOrElse(() => 100, (data) => data * 2);
        expect(transformed, 100);
      });

      test('should return computed default value for loading', () {
        const result = Result.loading();
        final transformed = result.mapOrElse(() => 200, (data) => data * 2);
        expect(transformed, 200);
      });
    });

    group('andThen', () {
      test('should chain successful operations', () async {
        const result = Result.success(42);
        final chained = await result.andThen((data) async => Result.success(data * 2));
        expect(chained.isSuccess, true);
        expect(chained.data, 84);
      });

      test('should not chain from error', () async {
        const result = Result.error('error');
        final chained = await result.andThen((data) async => Result.success(data * 2));
        expect(chained.isError, true);
        expect(chained.errorMessage, 'error');
      });

      test('should not chain from loading', () async {
        const result = Result.loading();
        final chained = await result.andThen((data) async => Result.success(data * 2));
        expect(chained.isLoading, true);
      });
    });

    group('andThenSync', () {
      test('should chain successful operations synchronously', () {
        const result = Result.success(42);
        final chained = result.andThenSync((data) => Result.success(data * 2));
        expect(chained.isSuccess, true);
        expect(chained.data, 84);
      });

      test('should not chain from error', () {
        const result = Result.error('error');
        final chained = result.andThenSync((data) => Result.success(data * 2));
        expect(chained.isError, true);
        expect(chained.errorMessage, 'error');
      });

      test('should not chain from loading', () {
        const result = Result.loading();
        final chained = result.andThenSync((data) => Result.success(data * 2));
        expect(chained.isLoading, true);
      });
    });

    group('Equality', () {
      test('should be equal for same success data', () {
        const result1 = Result.success('test');
        const result2 = Result.success('test');
        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('should not be equal for different success data', () {
        const result1 = Result.success('test1');
        const result2 = Result.success('test2');
        expect(result1, isNot(equals(result2)));
      });

      test('should be equal for same error message', () {
        const result1 = Result.error('error');
        const result2 = Result.error('error');
        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('should not be equal for different error messages', () {
        const result1 = Result.error('error1');
        const result2 = Result.error('error2');
        expect(result1, isNot(equals(result2)));
      });

      test('should be equal for loading results', () {
        const result1 = Result.loading();
        const result2 = Result.loading();
        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
      });
    });

    group('toString', () {
      test('should return correct string representation for success', () {
        const result = Result.success('test data');
        expect(result.toString(), 'Success(test data)');
      });

      test('should return correct string representation for error', () {
        const result = Result.error('error message');
        expect(result.toString(), 'Error(error message)');
      });

      test('should return correct string representation for loading', () {
        const result = Result.loading();
        expect(result.toString(), 'Loading()');
      });
    });
  });

  group('ResultListExtension', () {
    test('should get first item from successful list', () {
      const result = Result.success([1, 2, 3]);
      final first = result.first;
      expect(first.isSuccess, true);
      expect(first.data, 1);
    });

    test('should get null first item from empty list', () {
      const result = Result.success(<int>[]);
      final first = result.first;
      expect(first.isSuccess, true);
      expect(first.data, null);
    });

    test('should get last item from successful list', () {
      const result = Result.success([1, 2, 3]);
      final last = result.last;
      expect(last.isSuccess, true);
      expect(last.data, 3);
    });

    test('should get length from successful list', () {
      const result = Result.success([1, 2, 3]);
      final length = result.length;
      expect(length.isSuccess, true);
      expect(length.data, 3);
    });

    test('should check if list is empty', () {
      const result = Result.success(<int>[]);
      final isEmpty = result.isEmpty;
      expect(isEmpty.isSuccess, true);
      expect(isEmpty.data, true);
    });

    test('should check if list is not empty', () {
      const result = Result.success([1, 2, 3]);
      final isNotEmpty = result.isNotEmpty;
      expect(isNotEmpty.isSuccess, true);
      expect(isNotEmpty.data, true);
    });

    test('should filter list', () {
      const result = Result.success([1, 2, 3, 4, 5]);
      final filtered = result.where((item) => item % 2 == 0);
      expect(filtered.isSuccess, true);
      expect(filtered.data, [2, 4]);
    });

    test('should map over list', () {
      const result = Result.success([1, 2, 3]);
      final mapped = result.mapList((item) => item * 2);
      expect(mapped.isSuccess, true);
      expect(mapped.data, [2, 4, 6]);
    });
  });

  group('ResultMapExtension', () {
    test('should get value from successful map', () {
      const result = Result.success({'key1': 'value1', 'key2': 'value2'});
      final value = result.getValue('key1');
      expect(value.isSuccess, true);
      expect(value.data, 'value1');
    });

    test('should get null for missing key', () {
      const result = Result.success({'key1': 'value1'});
      final value = result.getValue('missing');
      expect(value.isSuccess, true);
      expect(value.data, null);
    });

    test('should check if map contains key', () {
      const result = Result.success({'key1': 'value1'});
      final containsKey = result.containsKey('key1');
      expect(containsKey.isSuccess, true);
      expect(containsKey.data, true);
    });

    test('should check if map contains value', () {
      const result = Result.success({'key1': 'value1'});
      final containsValue = result.containsValue('value1');
      expect(containsValue.isSuccess, true);
      expect(containsValue.data, true);
    });

    test('should get keys from map', () {
      const result = Result.success({'key1': 'value1', 'key2': 'value2'});
      final keys = result.keys;
      expect(keys.isSuccess, true);
      expect(keys.data, contains('key1'));
      expect(keys.data, contains('key2'));
    });

    test('should get values from map', () {
      const result = Result.success({'key1': 'value1', 'key2': 'value2'});
      final values = result.values;
      expect(values.isSuccess, true);
      expect(values.data, contains('value1'));
      expect(values.data, contains('value2'));
    });
  });
}