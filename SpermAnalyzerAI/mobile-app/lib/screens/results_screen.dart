import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../utils/app_constants.dart';
import '../services/localization_service.dart';
import '../services/analysis_service.dart';
import '../models/analysis_result.dart';
import '../widgets/custom_button.dart';
import '../widgets/analysis_card.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  const ResultsScreen({super.key});

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = ref.watch(localizationProvider).languageCode == 'ar';
    final analysisState = ref.watch(analysisStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isArabic ? 'نتائج التحليل' : 'Analysis Results',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        backgroundColor: AppConstants.primaryColor,
        elevation: 0,
        actions: [
          if (analysisState.result != null) ...[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareResults(analysisState.result!),
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _showExportOptions(context, analysisState.result!),
            ),
          ],
        ],
        bottom: analysisState.result != null ? TabBar(
          controller: _tabController,
          indicatorColor: AppConstants.accentColor,
          indicatorWeight: 3,
          labelColor: AppConstants.accentColor,
          unselectedLabelColor: AppConstants.textColor.withOpacity(0.7),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontFamily: 'Cairo',
          ),
          tabs: [
            Tab(text: isArabic ? 'عام' : 'Overview'),
            Tab(text: isArabic ? 'CASA' : 'CASA'),
            Tab(text: isArabic ? 'الشكل' : 'Morphology'),
          ],
        ) : null,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppConstants.primaryColor,
              AppConstants.backgroundColor,
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: analysisState.result != null
                  ? _buildResultsContent(analysisState.result!, isArabic)
                  : _buildNoResultsState(isArabic),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResultsContent(AnalysisResult result, bool isArabic) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(result, isArabic),
        _buildCasaTab(result, isArabic),
        _buildMorphologyTab(result, isArabic),
      ],
    );
  }

  Widget _buildOverviewTab(AnalysisResult result, bool isArabic) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // بطاقة جودة العينة
          _buildQualityCard(result, isArabic),
          
          const SizedBox(height: 16),
          
          // النتائج الأساسية
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              ResultCard(
                title: isArabic ? 'عدد الحيوانات المنوية' : 'Sperm Count',
                value: result.spermCount.toString(),
                unit: isArabic ? 'خلية' : 'cells',
                icon: Icons.scatter_plot,
                isNormal: result.spermCount >= 15,
              ),
              ResultCard(
                title: isArabic ? 'الحركة' : 'Motility',
                value: result.motility.toStringAsFixed(1),
                unit: '%',
                icon: Icons.directions_run,
                isNormal: result.motility >= 40,
              ),
              ResultCard(
                title: isArabic ? 'التركيز' : 'Concentration',
                value: result.concentration.toStringAsFixed(1),
                unit: isArabic ? 'مليون/مل' : 'M/ml',
                icon: Icons.opacity,
                isNormal: result.concentration >= 15,
              ),
              ResultCard(
                title: isArabic ? 'الشكل الطبيعي' : 'Normal Morphology',
                value: result.morphology.normal.toStringAsFixed(1),
                unit: '%',
                icon: Icons.check_circle,
                isNormal: result.morphology.normal >= 4,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // معلومات الملف
          _buildFileInfoCard(result, isArabic),
          
          const SizedBox(height: 16),
          
          // رسم بياني سريع للسرعة
          _buildVelocityPreview(result, isArabic),
        ],
      ),
    );
  }

  Widget _buildCasaTab(AnalysisResult result, bool isArabic) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // عنوان المقطع
          Text(
            isArabic ? 'مؤشرات CASA' : 'CASA Parameters',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.textColor,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 16),
          
          // مؤشرات CASA
          ...AppConstants.casaParameters.map((param) {
            final value = result.casaParameters.getParameterValue(param);
            final isNormal = result.casaParameters.isParameterNormal(param);
            final unit = _getCasaParameterUnit(param);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: AnalysisCard(
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isNormal 
                            ? AppConstants.successColor 
                            : AppConstants.warningColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getCasaParameterName(param, isArabic),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.textColor,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                value.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: isNormal 
                                      ? AppConstants.successColor 
                                      : AppConstants.warningColor,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                unit,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppConstants.secondaryTextColor,
                                  fontFamily: 'Cairo',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isNormal ? Icons.check_circle : Icons.warning,
                      color: isNormal 
                          ? AppConstants.successColor 
                          : AppConstants.warningColor,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMorphologyTab(AnalysisResult result, bool isArabic) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // عنوان المقطع
          Text(
            isArabic ? 'تحليل الشكل' : 'Morphology Analysis',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.textColor,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 16),
          
          // رسم دائري للشكل
          AnalysisCard(
            child: Column(
              children: [
                SizedBox(
                  height: 200,
                  child: Stack(
                    children: [
                      Center(
                        child: SizedBox(
                          width: 150,
                          height: 150,
                          child: CircularProgressIndicator(
                            value: result.morphology.normal / 100,
                            strokeWidth: 20,
                            backgroundColor: AppConstants.errorColor.withOpacity(0.3),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppConstants.successColor,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${result.morphology.normal.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textColor,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            Text(
                              isArabic ? 'طبيعي' : 'Normal',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppConstants.secondaryTextColor,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMorphologyIndicator(
                      label: isArabic ? 'طبيعي' : 'Normal',
                      value: result.morphology.normal,
                      color: AppConstants.successColor,
                    ),
                    _buildMorphologyIndicator(
                      label: isArabic ? 'غير طبيعي' : 'Abnormal',
                      value: result.morphology.abnormal,
                      color: AppConstants.errorColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // تفاصيل العيوب
          Text(
            isArabic ? 'تفاصيل العيوب' : 'Defect Details',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppConstants.textColor,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 12),
          
          ResultCard(
            title: isArabic ? 'عيوب الرأس' : 'Head Defects',
            value: result.morphology.headDefects.toStringAsFixed(1),
            unit: '%',
            icon: Icons.circle,
            iconColor: AppConstants.warningColor,
            isNormal: result.morphology.headDefects < 20,
          ),
          const SizedBox(height: 12),
          
          ResultCard(
            title: isArabic ? 'عيوب الذيل' : 'Tail Defects',
            value: result.morphology.tailDefects.toStringAsFixed(1),
            unit: '%',
            icon: Icons.timeline,
            iconColor: AppConstants.warningColor,
            isNormal: result.morphology.tailDefects < 15,
          ),
          const SizedBox(height: 12),
          
          ResultCard(
            title: isArabic ? 'عيوب الرقبة' : 'Neck Defects',
            value: result.morphology.neckDefects.toStringAsFixed(1),
            unit: '%',
            icon: Icons.remove,
            iconColor: AppConstants.warningColor,
            isNormal: result.morphology.neckDefects < 10,
          ),
        ],
      ),
    );
  }

  Widget _buildQualityCard(AnalysisResult result, bool isArabic) {
    return AnalysisCard(
      gradient: AppConstants.accentGradient,
      child: Column(
        children: [
          Icon(
            _getQualityIcon(result.quality),
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            isArabic ? 'جودة العينة' : 'Sample Quality',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            result.getQualityText(isArabic),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateTime.now().toString().substring(0, 19),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white60,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileInfoCard(AnalysisResult result, bool isArabic) {
    return InfoCard(
      title: isArabic ? 'معلومات الملف' : 'File Information',
      description: '${result.fileName}\n${_formatFileSize(result.fileSize)}',
      icon: Icons.insert_drive_file,
    );
  }

  Widget _buildVelocityPreview(AnalysisResult result, bool isArabic) {
    return AnalysisCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'معاينة السرعة' : 'Velocity Preview',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppConstants.textColor,
              fontFamily: 'Cairo',
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                isArabic 
                    ? 'اضغط على الرسوم البيانية لعرض التفاصيل'
                    : 'Tap Charts tab for detailed visualization',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppConstants.secondaryTextColor,
                  fontFamily: 'Cairo',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMorphologyIndicator({
    required String label,
    required double value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppConstants.secondaryTextColor,
            fontFamily: 'Cairo',
          ),
        ),
        Text(
          '${value.toStringAsFixed(1)}%',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppConstants.textColor,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  Widget _buildNoResultsState(bool isArabic) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: AppConstants.textColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'لا توجد نتائج' : 'No Results Available',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppConstants.textColor,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic 
                  ? 'قم بتحليل عينة أولاً لعرض النتائج هنا'
                  : 'Analyze a sample first to view results here',
              style: const TextStyle(
                fontSize: 14,
                color: AppConstants.secondaryTextColor,
                fontFamily: 'Cairo',
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: isArabic ? 'بدء تحليل جديد' : 'Start New Analysis',
              onPressed: () {
                // تبديل إلى تبويب التحليل
                ref.read(currentPageProvider.notifier).state = 0;
              },
              icon: Icons.biotech,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getQualityIcon(AnalysisQuality quality) {
    switch (quality) {
      case AnalysisQuality.excellent:
        return Icons.star;
      case AnalysisQuality.good:
        return Icons.thumb_up;
      case AnalysisQuality.fair:
        return Icons.thumb_up_outlined;
      case AnalysisQuality.poor:
        return Icons.warning;
    }
  }

  String _getCasaParameterName(String param, bool isArabic) {
    if (!isArabic) return param;
    
    switch (param) {
      case 'VCL': return 'السرعة المنحنية';
      case 'VSL': return 'السرعة المستقيمة';
      case 'VAP': return 'متوسط سرعة المسار';
      case 'LIN': return 'الخطية';
      case 'STR': return 'الاستقامة';
      case 'WOB': return 'التذبذب';
      case 'ALH': return 'سعة النزوح الجانبي';
      case 'BCF': return 'تردد تقاطع النبضة';
      case 'MOT': return 'نسبة الحركة';
      default: return param;
    }
  }

  String _getCasaParameterUnit(String param) {
    switch (param) {
      case 'VCL':
      case 'VSL':
      case 'VAP':
        return 'μm/s';
      case 'LIN':
      case 'STR':
      case 'WOB':
      case 'MOT':
        return '%';
      case 'ALH':
        return 'μm';
      case 'BCF':
        return 'Hz';
      default:
        return '';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  Future<void> _shareResults(AnalysisResult result) async {
    try {
      final text = '''
تحليل الحيوانات المنوية - Sperm Analysis

عدد الحيوانات المنوية: ${result.spermCount}
الحركة: ${result.motility.toStringAsFixed(1)}%
التركيز: ${result.concentration.toStringAsFixed(1)} مليون/مل
الشكل الطبيعي: ${result.morphology.normal.toStringAsFixed(1)}%

تم التحليل بواسطة Sperm Analyzer AI
المطور: يوسف الشتيوي
''';
      
      await Share.share(text);
    } catch (e) {
      _showError('فشل في المشاركة: $e');
    }
  }

  void _showExportOptions(BuildContext context, AnalysisResult result) {
    final isArabic = ref.read(localizationProvider).languageCode == 'ar';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isArabic ? 'تصدير النتائج' : 'Export Results',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.textColor,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 20),
            ...AppConstants.exportFormats.map((format) => 
              ListTile(
                leading: Icon(
                  _getFormatIcon(format),
                  color: AppConstants.accentColor,
                ),
                title: Text(
                  format,
                  style: const TextStyle(
                    color: AppConstants.textColor,
                    fontFamily: 'Cairo',
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _exportResults(result, format);
                },
              ),
            ).toList(),
          ],
        ),
      ),
    );
  }

  IconData _getFormatIcon(String format) {
    switch (format) {
      case 'JSON': return Icons.code;
      case 'CSV': return Icons.table_chart;
      case 'PDF': return Icons.picture_as_pdf;
      default: return Icons.file_download;
    }
  }

  Future<void> _exportResults(AnalysisResult result, String format) async {
    try {
      String content;
      String fileName;
      
      switch (format) {
        case 'JSON':
          content = result.toJsonString();
          fileName = 'analysis_${DateTime.now().millisecondsSinceEpoch}.json';
          break;
        case 'CSV':
          content = result.toCsvString();
          fileName = 'analysis_${DateTime.now().millisecondsSinceEpoch}.csv';
          break;
        default:
          throw 'صيغة غير مدعومة';
      }
      
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(content);
      
      await Share.shareXFiles([XFile(file.path)]);
      
      _showSuccess('تم التصدير بنجاح');
    } catch (e) {
      _showError('فشل في التصدير: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppConstants.errorColor,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Cairo'),
        ),
        backgroundColor: AppConstants.successColor,
      ),
    );
  }
}

// Provider لتتبع الصفحة الحالية (من main_screen.dart)
import 'main_screen.dart';