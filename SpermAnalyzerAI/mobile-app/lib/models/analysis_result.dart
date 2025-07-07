import 'package:json_annotation/json_annotation.dart';

part 'analysis_result.g.dart';

@JsonSerializable()
class AnalysisResult {
  final String id;
  final String fileName;
  final int fileSize;
  final DateTime analysisDate;
  final int spermCount;
  final double motility;
  final double concentration;
  final CasaParameters casaParameters;
  final SpermMorphology morphology;
  final List<VelocityDataPoint> velocityDistribution;
  final AnalysisMetadata? metadata;

  const AnalysisResult({
    required this.id,
    required this.fileName,
    required this.fileSize,
    required this.analysisDate,
    required this.spermCount,
    required this.motility,
    required this.concentration,
    required this.casaParameters,
    required this.morphology,
    required this.velocityDistribution,
    this.metadata,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) =>
      _$AnalysisResultFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisResultToJson(this);

  // تقييم جودة العينة بناءً على المؤشرات
  AnalysisQuality get quality {
    final scores = [
      _evaluateMotility(),
      _evaluateConcentration(),
      _evaluateMorphology(),
      _evaluateCasaParameters(),
    ];
    
    final averageScore = scores.reduce((a, b) => a + b) / scores.length;
    
    if (averageScore >= 80) return AnalysisQuality.excellent;
    if (averageScore >= 60) return AnalysisQuality.good;
    if (averageScore >= 40) return AnalysisQuality.fair;
    return AnalysisQuality.poor;
  }

  double _evaluateMotility() {
    if (motility >= 60) return 100;
    if (motility >= 40) return 75;
    if (motility >= 20) return 50;
    return 25;
  }

  double _evaluateConcentration() {
    if (concentration >= 20) return 100;
    if (concentration >= 15) return 75;
    if (concentration >= 10) return 50;
    return 25;
  }

  double _evaluateMorphology() {
    if (morphology.normal >= 70) return 100;
    if (morphology.normal >= 50) return 75;
    if (morphology.normal >= 30) return 50;
    return 25;
  }

  double _evaluateCasaParameters() {
    final linScore = casaParameters.lin >= 50 ? 100 : (casaParameters.lin / 50) * 100;
    final strScore = casaParameters.str >= 70 ? 100 : (casaParameters.str / 70) * 100;
    return (linScore + strScore) / 2;
  }

  String getQualityText(bool isArabic) {
    switch (quality) {
      case AnalysisQuality.excellent:
        return isArabic ? 'ممتازة' : 'Excellent';
      case AnalysisQuality.good:
        return isArabic ? 'جيدة' : 'Good';
      case AnalysisQuality.fair:
        return isArabic ? 'متوسطة' : 'Fair';
      case AnalysisQuality.poor:
        return isArabic ? 'ضعيفة' : 'Poor';
    }
  }
}

@JsonSerializable()
class CasaParameters {
  final double vcl; // Curvilinear Velocity
  final double vsl; // Straight-line Velocity
  final double vap; // Average Path Velocity
  final double lin; // Linearity
  final double str; // Straightness
  final double wob; // Wobble
  final double alh; // Amplitude of Lateral Head displacement
  final double bcf; // Beat Cross Frequency
  final double mot; // Motility percentage

  const CasaParameters({
    required this.vcl,
    required this.vsl,
    required this.vap,
    required this.lin,
    required this.str,
    required this.wob,
    required this.alh,
    required this.bcf,
    required this.mot,
  });

  factory CasaParameters.fromJson(Map<String, dynamic> json) =>
      _$CasaParametersFromJson(json);

  Map<String, dynamic> toJson() => _$CasaParametersToJson(this);

  // تحديد ما إذا كان المؤشر ضمن النطاق الطبيعي
  bool isParameterNormal(String parameter) {
    final value = getParameterValue(parameter);
    final range = AppConstants.normalRanges[parameter];
    if (range == null) return true;
    
    return value >= range['min']! && value <= range['max']!;
  }

  double getParameterValue(String parameter) {
    switch (parameter) {
      case 'VCL': return vcl;
      case 'VSL': return vsl;
      case 'VAP': return vap;
      case 'LIN': return lin;
      case 'STR': return str;
      case 'WOB': return wob;
      case 'ALH': return alh;
      case 'BCF': return bcf;
      case 'MOT': return mot;
      default: return 0.0;
    }
  }
}

@JsonSerializable()
class SpermMorphology {
  final double normal;
  final double abnormal;
  final double headDefects;
  final double tailDefects;
  final double neckDefects;

  const SpermMorphology({
    required this.normal,
    required this.abnormal,
    required this.headDefects,
    required this.tailDefects,
    required this.neckDefects,
  });

  factory SpermMorphology.fromJson(Map<String, dynamic> json) =>
      _$SpermMorphologyFromJson(json);

  Map<String, dynamic> toJson() => _$SpermMorphologyToJson(this);
}

@JsonSerializable()
class VelocityDataPoint {
  final int timePoint;
  final double velocity;

  const VelocityDataPoint({
    required this.timePoint,
    required this.velocity,
  });

  factory VelocityDataPoint.fromJson(Map<String, dynamic> json) =>
      _$VelocityDataPointFromJson(json);

  Map<String, dynamic> toJson() => _$VelocityDataPointToJson(this);
}

@JsonSerializable()
class AnalysisMetadata {
  final String modelVersion;
  final double confidence;
  final int processingTime; // in milliseconds
  final Map<String, dynamic> additionalData;

  const AnalysisMetadata({
    required this.modelVersion,
    required this.confidence,
    required this.processingTime,
    required this.additionalData,
  });

  factory AnalysisMetadata.fromJson(Map<String, dynamic> json) =>
      _$AnalysisMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$AnalysisMetadataToJson(this);
}

enum AnalysisQuality {
  excellent,
  good,
  fair,
  poor,
}

// مساعدات لتحويل النتائج
extension AnalysisResultExtensions on AnalysisResult {
  Map<String, double> get casaParametersMap => {
    'VCL': casaParameters.vcl,
    'VSL': casaParameters.vsl,
    'VAP': casaParameters.vap,
    'LIN': casaParameters.lin,
    'STR': casaParameters.str,
    'WOB': casaParameters.wob,
    'ALH': casaParameters.alh,
    'BCF': casaParameters.bcf,
    'MOT': casaParameters.mot,
  };

  Map<String, double> get morphologyMap => {
    'Normal': morphology.normal,
    'Abnormal': morphology.abnormal,
    'Head Defects': morphology.headDefects,
    'Tail Defects': morphology.tailDefects,
    'Neck Defects': morphology.neckDefects,
  };

  List<Map<String, dynamic>> get velocityChartData => 
      velocityDistribution.map((point) => {
        'time': point.timePoint,
        'velocity': point.velocity,
      }).toList();

  String toCsvString() {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Parameter,Value,Unit');
    
    // Basic parameters
    buffer.writeln('Sperm Count,$spermCount,count');
    buffer.writeln('Motility,$motility,%');
    buffer.writeln('Concentration,$concentration,million/ml');
    
    // CASA parameters
    buffer.writeln('VCL,${casaParameters.vcl},μm/s');
    buffer.writeln('VSL,${casaParameters.vsl},μm/s');
    buffer.writeln('VAP,${casaParameters.vap},μm/s');
    buffer.writeln('LIN,${casaParameters.lin},%');
    buffer.writeln('STR,${casaParameters.str},%');
    buffer.writeln('WOB,${casaParameters.wob},%');
    buffer.writeln('ALH,${casaParameters.alh},μm');
    buffer.writeln('BCF,${casaParameters.bcf},Hz');
    buffer.writeln('MOT,${casaParameters.mot},%');
    
    // Morphology
    buffer.writeln('Normal Morphology,${morphology.normal},%');
    buffer.writeln('Abnormal Morphology,${morphology.abnormal},%');
    buffer.writeln('Head Defects,${morphology.headDefects},%');
    buffer.writeln('Tail Defects,${morphology.tailDefects},%');
    buffer.writeln('Neck Defects,${morphology.neckDefects},%');
    
    return buffer.toString();
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }
}

// استيراد AppConstants من ملف منفصل
import '../utils/app_constants.dart';
import 'dart:convert';