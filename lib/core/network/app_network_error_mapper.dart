import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:kid_manager/core/network/app_network_exception.dart';

class AppNetworkErrorMapper {
  AppNetworkErrorMapper._();

  static const Set<String> _firebaseNetworkCodes = {
    'unavailable',
    'deadline-exceeded',
    'network-request-failed',
  };

  static bool isNetworkError(Object error) {
    if (error is AppNetworkException) {
      return true;
    }
    if (error is FirebaseFunctionsException) {
      return _firebaseNetworkCodes.contains(error.code);
    }
    if (error is FirebaseAuthException) {
      return error.code == 'network-request-failed';
    }
    if (error is FirebaseException) {
      return _firebaseNetworkCodes.contains(error.code);
    }
    if (error is SocketException ||
        error is TimeoutException ||
        error is http.ClientException ||
        error is HandshakeException) {
      return true;
    }

    final raw = error.toString().toLowerCase();
    return raw.contains('socketexception') ||
        raw.contains('failed host lookup') ||
        raw.contains('network-request-failed') ||
        raw.contains('timed out') ||
        raw.contains('connection refused') ||
        raw.contains('software caused connection abort') ||
        raw.contains('unable to resolve host') ||
        raw.contains('unavailable');
  }

  static AppNetworkException? normalize(
    Object error, {
    String? fallbackMessage,
  }) {
    if (error is AppNetworkException) {
      return error;
    }
    if (!isNetworkError(error)) {
      return null;
    }
    return AppNetworkException(fallbackMessage);
  }
}
