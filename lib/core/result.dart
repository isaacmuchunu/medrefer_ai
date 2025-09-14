/// A type-safe result wrapper for handling success and error states
sealed class Result<T> {
  const Result();

  /// Create a successful result
  factory Result.success(T data) = Success<T>;

  /// Create an error result
  factory Result.error(String message, [Object? error, StackTrace? stackTrace]) = Error<T>;

  /// Create a loading result
  factory Result.loading() = Loading<T>;

  /// Check if the result is successful
  bool get isSuccess => this is Success<T>;

  /// Check if the result is an error
  bool get isError => this is Error<T>;

  /// Check if the result is loading
  bool get isLoading => this is Loading<T>;

  /// Get the data if successful, null otherwise
  T? get data => isSuccess ? (this as Success<T>).data : null;

  /// Get the error message if error, null otherwise
  String? get errorMessage => isError ? (this as Error<T>).message : null;

  /// Get the error object if error, null otherwise
  Object? get error => isError ? (this as Error<T>).error : null;

  /// Get the stack trace if error, null otherwise
  StackTrace? get stackTrace => isError ? (this as Error<T>).stackTrace : null;

  /// Transform the data if successful
  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success<T>(data: final data) => Result.success(transform(data)),
      Error<T>(message: final message, error: final error, stackTrace: final stackTrace) => 
        Result.error(message, error, stackTrace),
      Loading<T>() => Result.loading(),
    };
  }

  /// Transform the data if successful, or return a default value
  R mapOr<R>(R defaultValue, R Function(T data) transform) {
    return switch (this) {
      Success<T>(data: final data) => transform(data),
      Error<T>() => defaultValue,
      Loading<T>() => defaultValue,
    };
  }

  /// Transform the data if successful, or return a computed default value
  R mapOrElse<R>(R Function() defaultValue, R Function(T data) transform) {
    return switch (this) {
      Success<T>(data: final data) => transform(data),
      Error<T>() => defaultValue(),
      Loading<T>() => defaultValue(),
    };
  }

  /// Execute a function if the result is successful
  Result<T> onSuccess(void Function(T data) callback) {
    if (isSuccess) {
      callback((this as Success<T>).data);
    }
    return this;
  }

  /// Execute a function if the result is an error
  Result<T> onError(void Function(String message, Object? error) callback) {
    if (isError) {
      final error = this as Error<T>;
      callback(error.message, error.error);
    }
    return this;
  }

  /// Execute a function if the result is loading
  Result<T> onLoading(void Function() callback) {
    if (isLoading) {
      callback();
    }
    return this;
  }

  /// Chain another async operation if successful
  Future<Result<R>> andThen<R>(Future<Result<R>> Function(T data) operation) async {
    return switch (this) {
      Success<T>(data: final data) => await operation(data),
      Error<T>(message: final message, error: final error, stackTrace: final stackTrace) => 
        Result.error(message, error, stackTrace),
      Loading<T>() => Result.loading(),
    };
  }

  /// Chain another operation if successful
  Result<R> andThenSync<R>(Result<R> Function(T data) operation) {
    return switch (this) {
      Success<T>(data: final data) => operation(data),
      Error<T>(message: final message, error: final error, stackTrace: final stackTrace) => 
        Result.error(message, error, stackTrace),
      Loading<T>() => Result.loading(),
    };
  }

  /// Unwrap the result, throwing an exception if it's an error
  T unwrap() {
    return switch (this) {
      Success<T>(data: final data) => data,
      Error<T>(message: final message) => throw Exception('Unwrapped error result: $message'),
      Loading<T>() => throw Exception('Unwrapped loading result'),
    };
  }

  /// Unwrap the result, returning a default value if it's an error
  T unwrapOr(T defaultValue) {
    return switch (this) {
      Success<T>(data: final data) => data,
      Error<T>() => defaultValue,
      Loading<T>() => defaultValue,
    };
  }

  /// Unwrap the result, computing a default value if it's an error
  T unwrapOrElse(T Function() defaultValue) {
    return switch (this) {
      Success<T>(data: final data) => data,
      Error<T>() => defaultValue(),
      Loading<T>() => defaultValue(),
    };
  }

  @override
  String toString() {
    return switch (this) {
      Success<T>(data: final data) => 'Success($data)',
      Error<T>(message: final message) => 'Error($message)',
      Loading<T>() => 'Loading()',
    };
  }

  @override
  bool operator ==(Object other) {
    return switch (this) {
      Success<T>(data: final data) => other is Success<T> && other.data == data,
      Error<T>(message: final message) => other is Error<T> && other.message == message,
      Loading<T>() => other is Loading<T>,
    };
  }

  @override
  int get hashCode {
    return switch (this) {
      Success<T>(data: final data) => data.hashCode,
      Error<T>(message: final message) => message.hashCode,
      Loading<T>() => 'Loading'.hashCode,
    };
  }
}

/// Success result containing data
final class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  String toString() => 'Success($data)';
}

/// Error result containing error information
final class Error<T> extends Result<T> {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  const Error(this.message, [this.error, this.stackTrace]);

  @override
  String toString() => 'Error($message)';
}

/// Loading result indicating an operation is in progress
final class Loading<T> extends Result<T> {
  const Loading();

  @override
  String toString() => 'Loading()';
}

/// Extension methods for Future<Result<T>>
extension FutureResultExtension<T> on Future<Result<T>> {
  /// Transform the result when the future completes
  Future<Result<R>> map<R>(R Function(T data) transform) async {
    final result = await this;
    return result.map(transform);
  }

  /// Handle the result when the future completes
  Future<void> handle({
    void Function(T data)? onSuccess,
    void Function(String message, Object? error)? onError,
    void Function()? onLoading,
  }) async {
    final result = await this;
    result.onSuccess(onSuccess ?? (_) {}).onError(onError ?? (_, __) {}).onLoading(onLoading ?? () {});
  }

  /// Unwrap the result when the future completes
  Future<T> unwrap() async {
    final result = await this;
    return result.unwrap();
  }

  /// Unwrap the result with a default value when the future completes
  Future<T> unwrapOr(T defaultValue) async {
    final result = await this;
    return result.unwrapOr(defaultValue);
  }
}

/// Extension methods for Result<List<T>>
extension ResultListExtension<T> on Result<List<T>> {
  /// Get the first item if the list is not empty
  Result<T?> get first {
    return map((list) => list.isNotEmpty ? list.first : null);
  }

  /// Get the last item if the list is not empty
  Result<T?> get last {
    return map((list) => list.isNotEmpty ? list.last : null);
  }

  /// Get the length of the list
  Result<int> get length {
    return map((list) => list.length);
  }

  /// Check if the list is empty
  Result<bool> get isEmpty {
    return map((list) => list.isEmpty);
  }

  /// Check if the list is not empty
  Result<bool> get isNotEmpty {
    return map((list) => list.isNotEmpty);
  }

  /// Filter the list
  Result<List<T>> where(bool Function(T item) test) {
    return map((list) => list.where(test).toList());
  }

  /// Map over the list
  Result<List<R>> mapList<R>(R Function(T item) transform) {
    return map((list) => list.map(transform).toList());
  }
}

/// Extension methods for Result<Map<K, V>>
extension ResultMapExtension<K, V> on Result<Map<K, V>> {
  /// Get a value from the map
  Result<V?> getValue(K key) {
    return map((map) => map[key]);
  }

  /// Check if the map contains a key
  Result<bool> containsKey(K key) {
    return map((map) => map.containsKey(key));
  }

  /// Check if the map contains a value
  Result<bool> containsValue(V value) {
    return map((map) => map.containsValue(value));
  }

  /// Get the keys of the map
  Result<Iterable<K>> get keys {
    return map((map) => map.keys);
  }

  /// Get the values of the map
  Result<Iterable<V>> get values {
    return map((map) => map.values);
  }
}