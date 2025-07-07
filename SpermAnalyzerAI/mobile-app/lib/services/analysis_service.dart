import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:convert';
import '../utils/app_constants.dart';
import '../models/analysis_result.dart';

// Provider لحالة التحليل
final analysisStateProvider = StateNotifierProvider<AnalysisNotifier, AnalysisState>((ref) {
  return AnalysisNotifier();
});

// Provider لخدمة API
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

class AnalysisState {
  final bool isAnalyzing;
  final double progress;
  final String status;
  final File? selectedFile;
  final AnalysisResult? result;
  final String? error;

  const AnalysisState({
    this.isAnalyzing = false,
    this.progress = 0.0,
    this.status = '',
    this.selectedFile,
    this.result,
    this.error,
  });

  AnalysisState copyWith({
    bool? isAnalyzing,
    double? progress,
    String? status,
    File? selectedFile,
    AnalysisResult? result,
    String? error,
  }) {
    return AnalysisState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      selectedFile: selectedFile ?? this.selectedFile,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }
}

class AnalysisNotifier extends StateNotifier<AnalysisState> {
  AnalysisNotifier() : super(const AnalysisState());

  void setSelectedFile(File file) {
    state = state.copyWith(selectedFile: file, error: null);
  }

  void clearSelectedFile() {
    state = state.copyWith(
      selectedFile: null,
      result: null,
      error: null,
      isAnalyzing: false,
      progress: 0.0,
      status: '',
    );
  }

  Future<void> startAnalysis(File file) async {
    state = state.copyWith(
      isAnalyzing: true,
      progress: 0.0,
      status: 'جاري رفع الملف...',
      error: null,
    );

    try {
      final apiService = ApiService();
      
      // رفع الملف
      state = state.copyWith(
        progress: 0.2,
        status: 'جاري رفع الملف...',
      );
      
      final analysisId = await apiService.uploadFile(file);
      
      // بدء التحليل
      state = state.copyWith(
        progress: 0.4,
        status: 'جاري تحليل العينة...',
      );
      
      final result = await apiService.analyzeFile(analysisId);
      
      // تحديث التقدم أثناء التحليل
      await _simulateAnalysisProgress();
      
      state = state.copyWith(
        isAnalyzing: false,
        progress: 1.0,
        status: 'تم التحليل بنجاح',
        result: result,
      );
      
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        error: e.toString(),
        status: 'فشل التحليل',
      );
      rethrow;
    }
  }

  Future<void> _simulateAnalysisProgress() async {
    final steps = [
      (0.5, 'كشف الحيوانات المنوية...'),
      (0.6, 'تتبع الحركة...'),
      (0.7, 'حساب مؤشرات CASA...'),
      (0.8, 'تحليل السرعة...'),
      (0.9, 'تحليل الشكل...'),
      (0.95, 'إنهاء التحليل...'),
    ];

    for (final step in steps) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (state.isAnalyzing) {
        state = state.copyWith(
          progress: step.$1,
          status: step.$2,
        );
      }
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

class ApiService {
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: AppConstants.connectionTimeout),
      receiveTimeout: const Duration(seconds: AppConstants.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // إضافة interceptor للتسجيل
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));
  }

  Future<String> uploadFile(File file) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '/upload',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200) {
        return response.data['analysis_id'];
      } else {
        throw ApiException('فشل في رفع الملف: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<AnalysisResult> analyzeFile(String analysisId) async {
    try {
      final response = await _dio.post(
        AppConstants.analyzeEndpoint,
        data: {'analysis_id': analysisId},
      );

      if (response.statusCode == 200) {
        return AnalysisResult.fromJson(response.data);
      } else {
        throw ApiException('فشل في التحليل: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<AnalysisResult?> getResults(String analysisId) async {
    try {
      final response = await _dio.get('${AppConstants.resultsEndpoint}/$analysisId');

      if (response.statusCode == 200) {
        return AnalysisResult.fromJson(response.data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw ApiException('فشل في جلب النتائج: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<bool> checkServerStatus() async {
    try {
      final response = await _dio.get(AppConstants.statusEndpoint);
      return response.statusCode == 200;
    } on DioException catch (e) {
      return false;
    }
  }

  Future<String> exportResults(String analysisId, String format) async {
    try {
      final response = await _dio.get(
        '${AppConstants.exportEndpoint}/$analysisId',
        queryParameters: {'format': format},
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode == 200) {
        // إرجاع البيانات كـ base64 للمعالجة في التطبيق
        return base64Encode(response.data);
      } else {
        throw ApiException('فشل في التصدير: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return ApiException('انتهت مهلة الاتصال');
      case DioExceptionType.sendTimeout:
        return ApiException('انتهت مهلة الإرسال');
      case DioExceptionType.receiveTimeout:
        return ApiException('انتهت مهلة الاستقبال');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data['detail'] ?? 'خطأ في الخادم';
        return ApiException('خطأ في الخادم ($statusCode): $message');
      case DioExceptionType.cancel:
        return ApiException('تم إلغاء الطلب');
      case DioExceptionType.connectionError:
        return ApiException('خطأ في الاتصال بالخادم');
      default:
        return ApiException('خطأ غير معروف: ${e.message}');
    }
  }
}

class ApiException implements Exception {
  final String message;
  
  const ApiException(this.message);
  
  @override
  String toString() => message;
}

// خدمة التحليل المحلي (للمحاكاة أثناء التطوير)
class LocalAnalysisService {
  static Future<AnalysisResult> simulateAnalysis(File file) async {
    // محاكاة وقت التحليل
    await Future.delayed(const Duration(seconds: 3));
    
    // إنتاج نتائج محاكاة واقعية
    return AnalysisResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fileName: file.path.split('/').last,
      fileSize: file.lengthSync(),
      analysisDate: DateTime.now(),
      spermCount: 45,
      motility: 68.5,
      concentration: 22.3,
      casaParameters: CasaParameters(
        vcl: 87.2,
        vsl: 45.6,
        vap: 62.8,
        lin: 52.4,
        str: 72.6,
        wob: 72.1,
        alh: 4.2,
        bcf: 12.8,
        mot: 68.5,
      ),
      morphology: SpermMorphology(
        normal: 78.5,
        abnormal: 21.5,
        headDefects: 12.3,
        tailDefects: 6.7,
        neckDefects: 2.5,
      ),
      velocityDistribution: [
        VelocityDataPoint(timePoint: 0, velocity: 45.2),
        VelocityDataPoint(timePoint: 1, velocity: 48.7),
        VelocityDataPoint(timePoint: 2, velocity: 52.1),
        VelocityDataPoint(timePoint: 3, velocity: 49.8),
        VelocityDataPoint(timePoint: 4, velocity: 47.3),
      ],
    );
  }
}