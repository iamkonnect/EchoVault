import 'package:dio/dio.dart';
import 'dart:developer' as developer;
import '../config/api_config.dart';

class ArtistService {
  final Dio _dio;
  final String baseUrl;

  ArtistService({
    required Dio dio,
    this.baseUrl = '',
  }) : _dio = dio {
    // Use ApiConfig.baseUrl if baseUrl is empty
    _dio.options.baseUrl = baseUrl.isEmpty ? ApiConfig.baseUrl : baseUrl;
  }

  Future<Map<String, dynamic>> getArtistInsights() async {
    try {
      final response = await _dio.get(
          '${baseUrl.isEmpty ? ApiConfig.baseUrl : baseUrl}/artist/insights');
      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      developer.log('Failed to fetch artist insights: $e',
          name: 'ArtistService');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> uploadMusic({
    required String title,
    required String artistName,
    required String filePath,
    String quality = 'HI_RES_LOSSLESS',
  }) async {
    try {
      FormData formData = FormData.fromMap({
        'title': title,
        'artistName': artistName,
        'quality': quality,
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(
        '${baseUrl.isEmpty ? ApiConfig.baseUrl : baseUrl}/artist/upload',
        data: formData,
      );

      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      developer.log('Upload failed: $e', name: 'ArtistService');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> getArtistMusic() async {
    try {
      final response = await _dio
          .get('${baseUrl.isEmpty ? ApiConfig.baseUrl : baseUrl}/artist/music');
      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      developer.log('Failed to fetch artist music: $e', name: 'ArtistService');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> withdrawFunds({
    required double amount,
  }) async {
    try {
      final response = await _dio.post(
        '${baseUrl.isEmpty ? ApiConfig.baseUrl : baseUrl}/artist/withdraw',
        data: {
          'amount': amount,
        },
      );

      return {
        'success': true,
        'data': response.data,
      };
    } catch (e) {
      developer.log('Withdrawal failed: $e', name: 'ArtistService');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
