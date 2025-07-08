import 'package:dio/dio.dart';

String getDioErrorMessage(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
      return "Connection timed out. Please check your internet connection and try again.";
    case DioExceptionType.sendTimeout:
      return "Server took too long to respond. Please try again.";
    case DioExceptionType.receiveTimeout:
      return "Response timeout. Please check your connection and try again.";
    case DioExceptionType.badCertificate:
      return "There's a problem with the security certificate. Please try again later or contact support.";
    case DioExceptionType.badResponse:
      return _handleBadResponse(error);
    case DioExceptionType.cancel:
      return "Request was cancelled.";
    case DioExceptionType.connectionError:
      // This is typically when there's no internet connection
      return "No internet connection. Please check your network settings and try again.";
    case DioExceptionType.unknown:
      if (error.error is String) {
        final errMsg = error.error as String;
        if (errMsg.contains('SocketException')) {
          return "Network error. Please check your internet connection.";
        }
      }
      return "An unexpected error occurred. Please try again.";
  }
}

String _handleBadResponse(DioException error) {
  final statusCode = error.response?.statusCode;
  final responseData = error.response?.data;

  // Try to extract server-provided error message if available
  String? serverMessage;
  try {
    if (responseData is Map<String, dynamic>) {
      serverMessage = responseData['message'] ??
          responseData['error'] ??
          responseData['description'];
    } else if (responseData is String) {
      serverMessage = responseData;
    }
  } catch (_) {}

  serverMessage = serverMessage?.trim();

  if (statusCode == null) {
    return serverMessage ?? "Received invalid response from server.";
  }

  switch (statusCode) {
    case 400:
      return serverMessage ?? "Bad request. Please check your input.";
    case 401:
      return serverMessage ?? "Authentication failed. Please log in again.";
    case 403:
      return serverMessage ??
          "You don't have permission to access this resource.";
    case 404:
      return serverMessage ?? "The requested resource was not found.";
    case 405:
      return serverMessage ?? "Method not allowed.";
    case 408:
      return serverMessage ?? "Request timeout. Please try again.";
    case 409:
      return serverMessage ??
          "Conflict occurred. Please resolve and try again.";
    case 422:
      return serverMessage ?? "Validation failed. Please check your input.";
    case 429:
      return serverMessage ??
          "Too many requests. Please wait and try again later.";
    case 500:
      return serverMessage ?? "Internal server error. Please try again later.";
    case 502:
      return serverMessage ?? "Bad gateway. Please try again later.";
    case 503:
      return serverMessage ?? "Service unavailable. Please try again later.";
    case 504:
      return serverMessage ?? "Gateway timeout. Please try again later.";
    default:
      if (statusCode >= 500) {
        return serverMessage ??
            "Server error occurred. Please try again later.";
      } else if (statusCode >= 400) {
        return serverMessage ?? "Request failed with status code $statusCode.";
      } else {
        return serverMessage ?? "Received unexpected status code $statusCode.";
      }
  }
}
