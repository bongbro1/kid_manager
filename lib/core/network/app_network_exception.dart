class AppNetworkException implements Exception {
  const AppNetworkException([this.message]);

  final String? message;

  @override
  String toString() => message ?? 'AppNetworkException';
}
