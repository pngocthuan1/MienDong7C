sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;
  bool get isError => this is Error<T>;

  R when<R>({
    required R Function(T data) ok,
    required R Function(dynamic error, String message) error,
  });

  static Result<T> ok<T>(T data) => Ok(data);
  static Result<T> err<T>(dynamic error, String message) => Error(error, message);
}

class Ok<T> extends Result<T> {
  final T data;
  const Ok(this.data);

  @override
  R when<R>({
    required R Function(T data) ok,
    required R Function(dynamic error, String message) error,
  }) => ok(data);
}

class Error<T> extends Result<T> {
  final dynamic error;
  final String message;
  const Error(this.error, this.message);

  @override
  R when<R>({
    required R Function(T data) ok,
    required R Function(dynamic error, String message) error,
  }) => error(this.error, message);
}
