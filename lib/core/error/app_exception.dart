import 'package:dio/dio.dart';

abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);
}

class NetworkException extends AppException {
  const NetworkException() : super('Отсутствует подключение к интернету или таймаут.');
}

class ServerException extends AppException {
  const ServerException(super.message);
}

AppException handleError(dynamic error) {
  if (error is DioException) {
    if (error.type == DioExceptionType.connectionTimeout || 
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const NetworkException();
    }
    return ServerException('Ошибка сервера: ${error.response?.statusCode}');
  }
  return const ServerException('Неизвестная ошибка');
}