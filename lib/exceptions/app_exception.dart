class AppException implements Exception {
  final String _message;
  final Object? _cause;

  /// `message` is expected to be user friendly
  /// `cause` should contains real exception or other type of
  /// information why there was a problem.
  AppException([
    this._message = 'An error occurred, please try again later.',
    this._cause,
  ]);

  @override
  String toString() {
    return "Exception: $_message, cause: $_cause";
  }

  /// `message` is expected to be user friendly
  String get message => _message;
}
