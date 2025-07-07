import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/analysis_result.dart';
import '../services/localization_service.dart';

/// خدمة تصدير ومشاركة الرسوم البيانية
class ChartExportService {
  static const String _exportFolderName = 'chart_exports';
  
  /// تصدير البيانات كملف CSV
  static Future<File?> exportAsCSV(AnalysisResult result, bool isArabic) async {
    try {
      final directory = await _getExportDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'sperm_analysis_$timestamp.csv';
      final file = File('${directory.path}/$fileName');
      
      final csvContent = _generateCSVContent(result, isArabic);
      await file.writeAsString(csvContent);
      
      return file;
    } catch (e) {
      debugPrint('Error exporting CSV: $e');
      return null;
    }
  }
  
  /// تصدير البيانات كملف JSON
  static Future<File?> exportAsJSON(AnalysisResult result) async {
    try {
      final directory = await _getExportDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'sperm_analysis_$timestamp.json';
      final file = File('${directory.path}/$fileName');
      
      final jsonContent = result.toJson();
      await file.writeAsString(jsonContent);
      
      return file;
    } catch (e) {
      debugPrint('Error exporting JSON: $e');
      return null;
    }
  }
  
  /// تصدير تقرير مفصل كملف نصي
  static Future<File?> exportDetailedReport(AnalysisResult result, bool isArabic) async {
    try {
      final directory = await _getExportDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'detailed_report_$timestamp.txt';
      final file = File('${directory.path}/$fileName');
      
      final reportContent = _generateDetailedReport(result, isArabic);
      await file.writeAsString(reportContent);
      
      return file;
    } catch (e) {
      debugPrint('Error exporting detailed report: $e');
      return null;
    }
  }
  
  /// مشاركة البيانات كنص
  static Future<void> shareAsText(AnalysisResult result, bool isArabic) async {
    try {
      final summary = _generateTextSummary(result, isArabic);
      final subject = isArabic 
          ? 'تقرير تحليل الحيوانات المنوية - Sperm Analyzer AI'
          : 'Sperm Analysis Report - Sperm Analyzer AI';
      
      await Share.share(
        summary,
        subject: subject,
      );
    } catch (e) {
      debugPrint('Error sharing text: $e');
    }
  }
  
  /// مشاركة ملف البيانات
  static Future<void> shareFile(File file, String type) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Sperm Analysis $type Export',
      );
    } catch (e) {
      debugPrint('Error sharing file: $e');
    }
  }
  
  /// الحصول على مجلد التصدير
  static Future<Directory> _getExportDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${documentsDir.path}/$_exportFolderName');
    
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    
    return exportDir;
  }
  
  /// إنشاء محتوى CSV
  static String _generateCSVContent(AnalysisResult result, bool isArabic) {
    final headers = isArabic
        ? 'المؤشر,القيمة,الوحدة,الحالة'
        : 'Parameter,Value,Unit,Status';
    
    final rows = <String>[headers];
    
    // إضافة البيانات الأساسية
    if (isArabic) {
      rows.addAll([
        'عدد الحيوانات المنوية,${result.spermCount},مليون/مل,${_getStatus(result.spermCount, 15, 'عدد')}',
        'نسبة الحركة,${result.motility.toStringAsFixed(1)},بالمئة,${_getStatus(result.motility, 40, 'نسبة')}',
        'التركيز,${result.concentration.toStringAsFixed(1)},مليون/مل,${_getStatus(result.concentration, 20, 'تركيز')}',
        'الجودة الإجمالية,${result.overallQuality.toStringAsFixed(1)},بالمئة,${_getStatus(result.overallQuality, 60, 'جودة')}',
      ]);
    } else {
      rows.addAll([
        'Sperm Count,${result.spermCount},million/ml,${_getStatusEn(result.spermCount, 15, 'count')}',
        'Motility,${result.motility.toStringAsFixed(1)},percent,${_getStatusEn(result.motility, 40, 'percentage')}',
        'Concentration,${result.concentration.toStringAsFixed(1)},million/ml,${_getStatusEn(result.concentration, 20, 'concentration')}',
        'Overall Quality,${result.overallQuality.toStringAsFixed(1)},percent,${_getStatusEn(result.overallQuality, 60, 'quality')}',
      ]);
    }
    
    // إضافة مؤشرات CASA
    if (isArabic) {
      rows.addAll([
        'VCL (السرعة المنحنية),${result.casaParameters.vcl.toStringAsFixed(1)},ميكرومتر/ثانية,${_getStatus(result.casaParameters.vcl, 25, 'سرعة')}',
        'VSL (السرعة المستقيمة),${result.casaParameters.vsl.toStringAsFixed(1)},ميكرومتر/ثانية,${_getStatus(result.casaParameters.vsl, 20, 'سرعة')}',
        'VAP (متوسط السرعة),${result.casaParameters.vap.toStringAsFixed(1)},ميكرومتر/ثانية,${_getStatus(result.casaParameters.vap, 22, 'سرعة')}',
        'LIN (الخطية),${result.casaParameters.lin.toStringAsFixed(1)},بالمئة,${_getStatus(result.casaParameters.lin, 50, 'نسبة')}',
        'STR (الاستقامة),${result.casaParameters.str.toStringAsFixed(1)},بالمئة,${_getStatus(result.casaParameters.str, 60, 'نسبة')}',
        'WOB (التذبذب),${result.casaParameters.wob.toStringAsFixed(1)},بالمئة,${_getStatus(result.casaParameters.wob, 50, 'نسبة')}',
        'MOT (الحركة),${result.casaParameters.mot.toStringAsFixed(1)},بالمئة,${_getStatus(result.casaParameters.mot, 40, 'نسبة')}',
      ]);
    } else {
      rows.addAll([
        'VCL (Curvilinear Velocity),${result.casaParameters.vcl.toStringAsFixed(1)},μm/s,${_getStatusEn(result.casaParameters.vcl, 25, 'velocity')}',
        'VSL (Straight Line Velocity),${result.casaParameters.vsl.toStringAsFixed(1)},μm/s,${_getStatusEn(result.casaParameters.vsl, 20, 'velocity')}',
        'VAP (Average Path Velocity),${result.casaParameters.vap.toStringAsFixed(1)},μm/s,${_getStatusEn(result.casaParameters.vap, 22, 'velocity')}',
        'LIN (Linearity),${result.casaParameters.lin.toStringAsFixed(1)},percent,${_getStatusEn(result.casaParameters.lin, 50, 'percentage')}',
        'STR (Straightness),${result.casaParameters.str.toStringAsFixed(1)},percent,${_getStatusEn(result.casaParameters.str, 60, 'percentage')}',
        'WOB (Wobble),${result.casaParameters.wob.toStringAsFixed(1)},percent,${_getStatusEn(result.casaParameters.wob, 50, 'percentage')}',
        'MOT (Motility),${result.casaParameters.mot.toStringAsFixed(1)},percent,${_getStatusEn(result.casaParameters.mot, 40, 'percentage')}',
      ]);
    }
    
    // إضافة بيانات الشكل
    if (isArabic) {
      rows.addAll([
        'الشكل الطبيعي,${result.morphology.normal.toStringAsFixed(1)},بالمئة,${_getStatus(result.morphology.normal, 4, 'نسبة')}',
        'الشكل غير الطبيعي,${result.morphology.abnormal.toStringAsFixed(1)},بالمئة,عكسي',
        'عيوب الرأس,${result.morphology.headDefects.toStringAsFixed(1)},بالمئة,عيوب',
        'عيوب الذيل,${result.morphology.tailDefects.toStringAsFixed(1)},بالمئة,عيوب',
        'عيوب الرقبة,${result.morphology.neckDefects.toStringAsFixed(1)},بالمئة,عيوب',
      ]);
    } else {
      rows.addAll([
        'Normal Morphology,${result.morphology.normal.toStringAsFixed(1)},percent,${_getStatusEn(result.morphology.normal, 4, 'percentage')}',
        'Abnormal Morphology,${result.morphology.abnormal.toStringAsFixed(1)},percent,Inverse',
        'Head Defects,${result.morphology.headDefects.toStringAsFixed(1)},percent,Defects',
        'Tail Defects,${result.morphology.tailDefects.toStringAsFixed(1)},percent,Defects',
        'Neck Defects,${result.morphology.neckDefects.toStringAsFixed(1)},percent,Defects',
      ]);
    }
    
    return rows.join('\n');
  }
  
  /// إنشاء التقرير المفصل
  static String _generateDetailedReport(AnalysisResult result, bool isArabic) {
    if (isArabic) {
      return '''
📋 تقرير تحليل الحيوانات المنوية - مفصل
=============================================

📅 تاريخ التحليل: ${DateTime.now().toString().split('.')[0]}
🔬 تم التحليل بواسطة: Sperm Analyzer AI
👨‍⚕️ الطبيب المعالج: ${result.metadata.doctorName ?? 'غير محدد'}
🏥 المختبر: ${result.metadata.labName ?? 'غير محدد'}

=============================================

📊 النتائج الأساسية:
---------------------
• عدد الحيوانات المنوية: ${result.spermCount} مليون/مل
  - الحد الطبيعي: ≥ 15 مليون/مل
  - التقييم: ${_getDetailedAssessment(result.spermCount, 15, isArabic)}

• نسبة الحركة: ${result.motility.toStringAsFixed(1)}%
  - الحد الطبيعي: ≥ 40%
  - التقييم: ${_getDetailedAssessment(result.motility, 40, isArabic)}

• التركيز: ${result.concentration.toStringAsFixed(1)} مليون/مل
  - الحد الطبيعي: ≥ 20 مليون/مل
  - التقييم: ${_getDetailedAssessment(result.concentration, 20, isArabic)}

• الجودة الإجمالية: ${result.overallQuality.toStringAsFixed(1)}%
  - الحد الطبيعي: ≥ 60%
  - التقييم: ${_getDetailedAssessment(result.overallQuality, 60, isArabic)}

=============================================

🔬 مؤشرات CASA المتقدمة:
------------------------
• VCL (السرعة المنحنية): ${result.casaParameters.vcl.toStringAsFixed(1)} μm/s
• VSL (السرعة المستقيمة): ${result.casaParameters.vsl.toStringAsFixed(1)} μm/s
• VAP (متوسط السرعة): ${result.casaParameters.vap.toStringAsFixed(1)} μm/s
• LIN (الخطية): ${result.casaParameters.lin.toStringAsFixed(1)}%
• STR (الاستقامة): ${result.casaParameters.str.toStringAsFixed(1)}%
• WOB (التذبذب): ${result.casaParameters.wob.toStringAsFixed(1)}%
• MOT (الحركة): ${result.casaParameters.mot.toStringAsFixed(1)}%
• ALH (سعة الحركة الجانبية): ${result.casaParameters.alh.toStringAsFixed(1)} μm
• BCF (تردد ضربات الذيل): ${result.casaParameters.bcf.toStringAsFixed(1)} Hz

=============================================

🧬 تحليل الشكل والبنية:
---------------------
• الشكل الطبيعي: ${result.morphology.normal.toStringAsFixed(1)}%
  - الحد الطبيعي: ≥ 4%
  - التقييم: ${_getDetailedAssessment(result.morphology.normal, 4, isArabic)}

• الشكل غير الطبيعي: ${result.morphology.abnormal.toStringAsFixed(1)}%

تفصيل العيوب:
• عيوب الرأس: ${result.morphology.headDefects.toStringAsFixed(1)}%
• عيوب الذيل: ${result.morphology.tailDefects.toStringAsFixed(1)}%
• عيوب الرقبة: ${result.morphology.neckDefects.toStringAsFixed(1)}%

=============================================

📈 توزيع السرعة:
---------------
${result.velocityDistribution.asMap().entries.map((entry) => 
  '• الثانية ${entry.key + 1}: ${entry.value.velocity.toStringAsFixed(1)} μm/s'
).join('\n')}

=============================================

⚕️ التوصيات الطبية:
------------------
${_generateRecommendations(result, isArabic)}

=============================================

📞 معلومات الاتصال:
------------------
🏥 المختبر: ${result.metadata.labName ?? 'غير محدد'}
📧 البريد الإلكتروني: ${result.metadata.contactEmail ?? 'غير محدد'}
📱 الهاتف: ${result.metadata.contactPhone ?? 'غير محدد'}

تم إنشاء هذا التقرير بواسطة Sperm Analyzer AI
تطبيق متطور لتحليل الحيوانات المنوية باستخدام الذكاء الاصطناعي

⚠️ تنويه: هذا التقرير لأغراض إعلامية فقط ولا يُغني عن استشارة طبيب مختص.
''';
    } else {
      return '''
📋 Sperm Analysis Report - Detailed
====================================

📅 Analysis Date: ${DateTime.now().toString().split('.')[0]}
🔬 Analyzed by: Sperm Analyzer AI
👨‍⚕️ Doctor: ${result.metadata.doctorName ?? 'Not specified'}
🏥 Laboratory: ${result.metadata.labName ?? 'Not specified'}

====================================

📊 Basic Results:
-----------------
• Sperm Count: ${result.spermCount} million/ml
  - Normal Range: ≥ 15 million/ml
  - Assessment: ${_getDetailedAssessment(result.spermCount, 15, isArabic)}

• Motility: ${result.motility.toStringAsFixed(1)}%
  - Normal Range: ≥ 40%
  - Assessment: ${_getDetailedAssessment(result.motility, 40, isArabic)}

• Concentration: ${result.concentration.toStringAsFixed(1)} million/ml
  - Normal Range: ≥ 20 million/ml
  - Assessment: ${_getDetailedAssessment(result.concentration, 20, isArabic)}

• Overall Quality: ${result.overallQuality.toStringAsFixed(1)}%
  - Normal Range: ≥ 60%
  - Assessment: ${_getDetailedAssessment(result.overallQuality, 60, isArabic)}

====================================

🔬 Advanced CASA Parameters:
----------------------------
• VCL (Curvilinear Velocity): ${result.casaParameters.vcl.toStringAsFixed(1)} μm/s
• VSL (Straight Line Velocity): ${result.casaParameters.vsl.toStringAsFixed(1)} μm/s
• VAP (Average Path Velocity): ${result.casaParameters.vap.toStringAsFixed(1)} μm/s
• LIN (Linearity): ${result.casaParameters.lin.toStringAsFixed(1)}%
• STR (Straightness): ${result.casaParameters.str.toStringAsFixed(1)}%
• WOB (Wobble): ${result.casaParameters.wob.toStringAsFixed(1)}%
• MOT (Motility): ${result.casaParameters.mot.toStringAsFixed(1)}%
• ALH (Amplitude of Lateral Head): ${result.casaParameters.alh.toStringAsFixed(1)} μm
• BCF (Beat Cross Frequency): ${result.casaParameters.bcf.toStringAsFixed(1)} Hz

====================================

🧬 Morphology Analysis:
----------------------
• Normal Morphology: ${result.morphology.normal.toStringAsFixed(1)}%
  - Normal Range: ≥ 4%
  - Assessment: ${_getDetailedAssessment(result.morphology.normal, 4, isArabic)}

• Abnormal Morphology: ${result.morphology.abnormal.toStringAsFixed(1)}%

Defect Details:
• Head Defects: ${result.morphology.headDefects.toStringAsFixed(1)}%
• Tail Defects: ${result.morphology.tailDefects.toStringAsFixed(1)}%
• Neck Defects: ${result.morphology.neckDefects.toStringAsFixed(1)}%

====================================

📈 Velocity Distribution:
------------------------
${result.velocityDistribution.asMap().entries.map((entry) => 
  '• Second ${entry.key + 1}: ${entry.value.velocity.toStringAsFixed(1)} μm/s'
).join('\n')}

====================================

⚕️ Medical Recommendations:
---------------------------
${_generateRecommendations(result, isArabic)}

====================================

📞 Contact Information:
----------------------
🏥 Laboratory: ${result.metadata.labName ?? 'Not specified'}
📧 Email: ${result.metadata.contactEmail ?? 'Not specified'}
📱 Phone: ${result.metadata.contactPhone ?? 'Not specified'}

This report was generated by Sperm Analyzer AI
Advanced sperm analysis application using artificial intelligence

⚠️ Disclaimer: This report is for informational purposes only and does not replace consultation with a qualified medical professional.
''';
    }
  }
  
  /// إنشاء ملخص نصي للمشاركة
  static String _generateTextSummary(AnalysisResult result, bool isArabic) {
    if (isArabic) {
      return '''
🔬 تقرير تحليل الحيوانات المنوية

📊 النتائج الرئيسية:
• العدد: ${result.spermCount} مليون/مل
• الحركة: ${result.motility.toStringAsFixed(1)}%
• التركيز: ${result.concentration.toStringAsFixed(1)} مليون/مل
• الجودة: ${result.overallQuality.toStringAsFixed(1)}%

🔬 مؤشرات CASA:
• VCL: ${result.casaParameters.vcl.toStringAsFixed(1)} μm/s
• VSL: ${result.casaParameters.vsl.toStringAsFixed(1)} μm/s
• LIN: ${result.casaParameters.lin.toStringAsFixed(1)}%

🧬 الشكل:
• طبيعي: ${result.morphology.normal.toStringAsFixed(1)}%
• غير طبيعي: ${result.morphology.abnormal.toStringAsFixed(1)}%

📱 تم التحليل بواسطة Sperm Analyzer AI
''';
    } else {
      return '''
🔬 Sperm Analysis Report

📊 Key Results:
• Count: ${result.spermCount} million/ml
• Motility: ${result.motility.toStringAsFixed(1)}%
• Concentration: ${result.concentration.toStringAsFixed(1)} million/ml
• Quality: ${result.overallQuality.toStringAsFixed(1)}%

🔬 CASA Parameters:
• VCL: ${result.casaParameters.vcl.toStringAsFixed(1)} μm/s
• VSL: ${result.casaParameters.vsl.toStringAsFixed(1)} μm/s
• LIN: ${result.casaParameters.lin.toStringAsFixed(1)}%

🧬 Morphology:
• Normal: ${result.morphology.normal.toStringAsFixed(1)}%
• Abnormal: ${result.morphology.abnormal.toStringAsFixed(1)}%

📱 Analyzed by Sperm Analyzer AI
''';
    }
  }
  
  /// تقييم الحالة باللغة العربية
  static String _getStatus(double value, double threshold, String type) {
    if (value >= threshold) {
      return 'طبيعي';
    } else if (value >= threshold * 0.8) {
      return 'حدي';
    } else {
      return 'منخفض';
    }
  }
  
  /// تقييم الحالة باللغة الإنجليزية
  static String _getStatusEn(double value, double threshold, String type) {
    if (value >= threshold) {
      return 'Normal';
    } else if (value >= threshold * 0.8) {
      return 'Borderline';
    } else {
      return 'Low';
    }
  }
  
  /// تقييم مفصل للحالة
  static String _getDetailedAssessment(double value, double threshold, bool isArabic) {
    final ratio = value / threshold;
    
    if (isArabic) {
      if (ratio >= 1.0) {
        return '✅ ضمن المعدل الطبيعي';
      } else if (ratio >= 0.8) {
        return '⚠️ حدي - يحتاج متابعة';
      } else if (ratio >= 0.5) {
        return '🔸 منخفض - يحتاج علاج';
      } else {
        return '🔴 منخفض جداً - يحتاج تدخل طبي';
      }
    } else {
      if (ratio >= 1.0) {
        return '✅ Within normal range';
      } else if (ratio >= 0.8) {
        return '⚠️ Borderline - needs monitoring';
      } else if (ratio >= 0.5) {
        return '🔸 Low - needs treatment';
      } else {
        return '🔴 Very low - requires medical intervention';
      }
    }
  }
  
  /// إنشاء التوصيات الطبية
  static String _generateRecommendations(AnalysisResult result, bool isArabic) {
    final recommendations = <String>[];
    
    if (isArabic) {
      if (result.spermCount < 15) {
        recommendations.add('• تحسين نمط الحياة والتغذية لزيادة عدد الحيوانات المنوية');
      }
      if (result.motility < 40) {
        recommendations.add('• ممارسة الرياضة المنتظمة لتحسين حركة الحيوانات المنوية');
      }
      if (result.morphology.normal < 4) {
        recommendations.add('• تناول مكملات غذائية تحتوي على مضادات الأكسدة');
      }
      if (result.overallQuality < 60) {
        recommendations.add('• تجنب التدخين والكحول والتوتر');
        recommendations.add('• الحصول على نوم كافي ومنتظم');
      }
      
      if (recommendations.isEmpty) {
        recommendations.add('• الحفاظ على نمط الحياة الصحي الحالي');
        recommendations.add('• إجراء فحوصات دورية للمتابعة');
      }
    } else {
      if (result.spermCount < 15) {
        recommendations.add('• Improve lifestyle and nutrition to increase sperm count');
      }
      if (result.motility < 40) {
        recommendations.add('• Regular exercise to improve sperm motility');
      }
      if (result.morphology.normal < 4) {
        recommendations.add('• Take antioxidant supplements');
      }
      if (result.overallQuality < 60) {
        recommendations.add('• Avoid smoking, alcohol, and stress');
        recommendations.add('• Get adequate and regular sleep');
      }
      
      if (recommendations.isEmpty) {
        recommendations.add('• Maintain current healthy lifestyle');
        recommendations.add('• Regular follow-up examinations');
      }
    }
    
    return recommendations.join('\n');
  }
  
  /// حفظ صورة الرسم البياني (مستقبلياً)
  static Future<File?> saveChartImage(Uint8List imageBytes, String chartType) async {
    try {
      final directory = await _getExportDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${chartType}_chart_$timestamp.png';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsBytes(imageBytes);
      return file;
    } catch (e) {
      debugPrint('Error saving chart image: $e');
      return null;
    }
  }
}