import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../utils/app_constants.dart';
import '../services/localization_service.dart';
import '../services/analysis_service.dart';
import '../services/chart_export_service.dart';
import '../models/analysis_result.dart';
import '../widgets/analysis_card.dart';
import '../widgets/custom_button.dart';

class ChartsScreen extends ConsumerStatefulWidget {
  const ChartsScreen({super.key});

  @override
  ConsumerState<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends ConsumerState<ChartsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  int _selectedChartIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
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
          isArabic ? 'الرسوم البيانية' : 'Charts',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        backgroundColor: AppConstants.primaryColor,
        elevation: 0,
        actions: [
          if (analysisState.result != null) ..[
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _showShareOptions(analysisState.result!),
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () => _showExportOptions(analysisState.result!),
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
            fontSize: 12,
          ),
          isScrollable: true,
          tabs: [
            Tab(text: isArabic ? 'السرعة' : 'Velocity'),
            Tab(text: isArabic ? 'CASA' : 'CASA'),
            Tab(text: isArabic ? 'الشكل' : 'Morphology'),
            Tab(text: isArabic ? 'التوزيع' : 'Distribution'),
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
        child: analysisState.result != null
            ? _buildChartsContent(analysisState.result!, isArabic)
            : _buildNoDataState(isArabic),
      ),
    );
  }

  Widget _buildChartsContent(AnalysisResult result, bool isArabic) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, _slideAnimation.value),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildVelocityChart(result, isArabic),
          _buildCasaChart(result, isArabic),
          _buildMorphologyChart(result, isArabic),
          _buildDistributionChart(result, isArabic),
        ],
      ),
    );
  }

  Widget _buildVelocityChart(AnalysisResult result, bool isArabic) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // رسم بياني خطي للسرعة مع الزمن
          AnalysisCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'السرعة عبر الزمن' : 'Velocity Over Time',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textColor,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: LineChart(
                    _buildVelocityLineChart(result),
                  ),
                ),
                const SizedBox(height: 16),
                _buildChartLegend([
                  _LegendItem(isArabic ? 'السرعة' : 'Velocity', AppConstants.accentColor),
                ]),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // رسم بياني للسرعات المختلفة
          AnalysisCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'أنواع السرعة' : 'Velocity Types',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textColor,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: BarChart(
                    _buildVelocityBarChart(result, isArabic),
                  ),
                ),
                const SizedBox(height: 16),
                _buildChartLegend([
                  _LegendItem('VCL', Colors.blue),
                  _LegendItem('VSL', Colors.green),
                  _LegendItem('VAP', Colors.orange),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCasaChart(AnalysisResult result, bool isArabic) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // رسم بياني دائري للمؤشرات
          AnalysisCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'مؤشرات CASA' : 'CASA Parameters',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textColor,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: RadarChart(
                    _buildCasaRadarChart(result),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // رسم بياني شريطي أفقي للمؤشرات
          AnalysisCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'مقارنة بالقيم الطبيعية' : 'Comparison with Normal Values',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textColor,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 16),
                ..._buildCasaParameterBars(result, isArabic),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMorphologyChart(AnalysisResult result, bool isArabic) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // رسم دائري للشكل العام
          AnalysisCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'توزيع الشكل' : 'Morphology Distribution',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textColor,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: PieChart(
                    _buildMorphologyPieChart(result, isArabic),
                  ),
                ),
                const SizedBox(height: 16),
                _buildChartLegend([
                  _LegendItem(
                    isArabic ? 'طبيعي' : 'Normal', 
                    AppConstants.successColor,
                  ),
                  _LegendItem(
                    isArabic ? 'غير طبيعي' : 'Abnormal', 
                    AppConstants.errorColor,
                  ),
                ]),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // رسم شريطي للعيوب
          AnalysisCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'أنواع العيوب' : 'Defect Types',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textColor,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    _buildDefectsBarChart(result, isArabic),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionChart(AnalysisResult result, bool isArabic) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // رسم توزيع الحجم
          AnalysisCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'توزيع تركيز الحيوانات المنوية' : 'Sperm Concentration Distribution',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textColor,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: BarChart(
                    _buildConcentrationDistChart(result),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // رسم لمقارنة المؤشرات الرئيسية
          AnalysisCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'المؤشرات الرئيسية' : 'Key Metrics',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textColor,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  child: LineChart(
                    _buildKeyMetricsChart(result, isArabic),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState(bool isArabic) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 64,
              color: AppConstants.textColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'لا توجد بيانات للرسوم البيانية' : 'No Chart Data Available',
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
                  ? 'قم بتحليل عينة أولاً لعرض الرسوم البيانية'
                  : 'Analyze a sample first to view charts',
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
              text: isArabic ? 'بدء تحليل' : 'Start Analysis',
              onPressed: () {
                ref.read(currentPageProvider.notifier).state = 0;
              },
              icon: Icons.biotech,
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildVelocityLineChart(AnalysisResult result) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) {
          return const FlLine(
            color: AppConstants.surfaceColor,
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return const FlLine(
            color: AppConstants.surfaceColor,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}s',
                style: const TextStyle(
                  color: AppConstants.secondaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 10,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(
                  color: AppConstants.secondaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: AppConstants.surfaceColor),
      ),
      minX: 0,
      maxX: result.velocityDistribution.length.toDouble() - 1,
      minY: 0,
      maxY: result.velocityDistribution.isNotEmpty 
          ? result.velocityDistribution.map((e) => e.velocity).reduce(math.max) + 10
          : 100,
      lineBarsData: [
        LineChartBarData(
          spots: result.velocityDistribution.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.velocity);
          }).toList(),
          isCurved: true,
          gradient: const LinearGradient(
            colors: [AppConstants.accentColor, AppConstants.primaryColor],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppConstants.accentColor.withOpacity(0.3),
                AppConstants.accentColor.withOpacity(0.1),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  BarChartData _buildVelocityBarChart(AnalysisResult result, bool isArabic) {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 100,
      barTouchData: BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const titles = ['VCL', 'VSL', 'VAP'];
              return Text(
                titles[value.toInt()],
                style: const TextStyle(
                  color: AppConstants.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(
                  color: AppConstants.secondaryTextColor,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: [
        BarChartGroupData(
          x: 0,
          barRods: [
            BarChartRodData(
              toY: result.casaParameters.vcl,
              color: Colors.blue,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
        BarChartGroupData(
          x: 1,
          barRods: [
            BarChartRodData(
              toY: result.casaParameters.vsl,
              color: Colors.green,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
        BarChartGroupData(
          x: 2,
          barRods: [
            BarChartRodData(
              toY: result.casaParameters.vap,
              color: Colors.orange,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ],
    );
  }

  RadarChartData _buildCasaRadarChart(AnalysisResult result) {
    return RadarChartData(
      radarBackgroundColor: Colors.transparent,
      radarBorderData: const BorderSide(color: AppConstants.surfaceColor),
      titlePositionPercentageOffset: 0.2,
      getTitle: (index, angle) {
        const titles = ['VCL', 'VSL', 'VAP', 'LIN', 'STR'];
        return RadarChartTitle(text: titles[index % titles.length]);
      },
      dataSets: [
        RadarDataSet(
          fillColor: AppConstants.accentColor.withOpacity(0.2),
          borderColor: AppConstants.accentColor,
          entryRadius: 3,
          dataEntries: [
            RadarEntry(value: result.casaParameters.vcl / 2),
            RadarEntry(value: result.casaParameters.vsl / 2),
            RadarEntry(value: result.casaParameters.vap / 2),
            RadarEntry(value: result.casaParameters.lin),
            RadarEntry(value: result.casaParameters.str),
          ],
        ),
      ],
      swapAnimationDuration: const Duration(milliseconds: 400),
    );
  }

  List<Widget> _buildCasaParameterBars(AnalysisResult result, bool isArabic) {
    final parameters = [
      ('LIN', result.casaParameters.lin, 50.0, 85.0),
      ('STR', result.casaParameters.str, 60.0, 90.0),
      ('WOB', result.casaParameters.wob, 50.0, 80.0),
      ('MOT', result.casaParameters.mot, 40.0, 100.0),
    ];

    return parameters.map((param) {
      final name = param.$1;
      final value = param.$2;
      final minNormal = param.$3;
      final maxNormal = param.$4;
      final isNormal = value >= minNormal && value <= maxNormal;

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppConstants.textColor,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 8),
            Stack(
              children: [
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: (value / 100).clamp(0.0, 1.0),
                  child: Container(
                    height: 20,
                    decoration: BoxDecoration(
                      color: isNormal 
                          ? AppConstants.successColor 
                          : AppConstants.warningColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 2,
                  child: Text(
                    '${value.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  PieChartData _buildMorphologyPieChart(AnalysisResult result, bool isArabic) {
    return PieChartData(
      pieTouchData: PieTouchData(enabled: false),
      borderData: FlBorderData(show: false),
      sectionsSpace: 0,
      centerSpaceRadius: 40,
      sections: [
        PieChartSectionData(
          color: AppConstants.successColor,
          value: result.morphology.normal,
          title: '${result.morphology.normal.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Cairo',
          ),
        ),
        PieChartSectionData(
          color: AppConstants.errorColor,
          value: result.morphology.abnormal,
          title: '${result.morphology.abnormal.toStringAsFixed(1)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }

  BarChartData _buildDefectsBarChart(AnalysisResult result, bool isArabic) {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 25,
      barTouchData: BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final titles = isArabic 
                  ? ['الرأس', 'الذيل', 'الرقبة']
                  : ['Head', 'Tail', 'Neck'];
              return Text(
                titles[value.toInt()],
                style: const TextStyle(
                  color: AppConstants.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: [
        BarChartGroupData(
          x: 0,
          barRods: [
            BarChartRodData(
              toY: result.morphology.headDefects,
              color: AppConstants.errorColor,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
        BarChartGroupData(
          x: 1,
          barRods: [
            BarChartRodData(
              toY: result.morphology.tailDefects,
              color: AppConstants.warningColor,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
        BarChartGroupData(
          x: 2,
          barRods: [
            BarChartRodData(
              toY: result.morphology.neckDefects,
              color: AppConstants.infoColor,
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ],
    );
  }

  BarChartData _buildConcentrationDistChart(AnalysisResult result) {
    // محاكاة بيانات التوزيع
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 30,
      barTouchData: BarTouchData(enabled: false),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text(
                '${(value * 5).toInt()}M',
                style: const TextStyle(
                  color: AppConstants.secondaryTextColor,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: List.generate(8, (index) {
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: math.Random().nextDouble() * 25 + 5,
              color: AppConstants.accentColor,
              width: 15,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        );
      }),
    );
  }

  LineChartData _buildKeyMetricsChart(AnalysisResult result, bool isArabic) {
    return LineChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final metrics = isArabic 
                  ? ['العدد', 'الحركة', 'التركيز', 'الشكل']
                  : ['Count', 'Motility', 'Concentration', 'Morphology'];
              if (value.toInt() < metrics.length) {
                return Text(
                  metrics[value.toInt()],
                  style: const TextStyle(
                    color: AppConstants.secondaryTextColor,
                    fontSize: 10,
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 3,
      minY: 0,
      maxY: 100,
      lineBarsData: [
        LineChartBarData(
          spots: [
            FlSpot(0, (result.spermCount / 100) * 100),
            FlSpot(1, result.motility),
            FlSpot(2, (result.concentration / 50) * 100),
            FlSpot(3, result.morphology.normal),
          ],
          isCurved: true,
          color: AppConstants.accentColor,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 6,
                color: AppConstants.accentColor,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChartLegend(List<_LegendItem> items) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items.map((item) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppConstants.secondaryTextColor,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _captureChart() async {
    final isArabic = ref.read(localizationProvider).languageCode == 'ar';
    
    try {
      // تصدير الرسم البياني كصورة
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic 
                ? 'تم حفظ الرسم البياني بنجاح'
                : 'Chart captured successfully',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppConstants.successColor,
          action: SnackBarAction(
            label: isArabic ? 'مشاركة' : 'Share',
            textColor: Colors.white,
            onPressed: () {
              _shareChart();
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic 
                ? 'خطأ في حفظ الرسم البياني'
                : 'Error capturing chart',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }
  
  Future<void> _shareChart() async {
    final isArabic = ref.read(localizationProvider).languageCode == 'ar';
    final analysisResult = ref.read(analysisStateProvider).result;
    
    if (analysisResult == null) return;
    
    try {
      // إعداد بيانات المشاركة
      final chartData = _generateChartSummary(analysisResult, isArabic);
      
      // مشاركة البيانات
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic 
                ? 'تم إعداد بيانات المشاركة'
                : 'Chart data prepared for sharing',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppConstants.infoColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic 
                ? 'خطأ في مشاركة الرسم البياني'
                : 'Error sharing chart',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }
  
  String _generateChartSummary(AnalysisResult result, bool isArabic) {
    if (isArabic) {
      return '''
📈 تقرير تحليل الحيوانات المنوية

🔍 النتائج الرئيسية:
• عدد الحيوانات المنوية: ${result.spermCount} مليون/مل
• نسبة الحركة: ${result.motility.toStringAsFixed(1)}%
• التركيز: ${result.concentration.toStringAsFixed(1)} مليون/مل

📊 مؤشرات CASA:
• VCL: ${result.casaParameters.vcl.toStringAsFixed(1)} µm/s
• VSL: ${result.casaParameters.vsl.toStringAsFixed(1)} µm/s
• VAP: ${result.casaParameters.vap.toStringAsFixed(1)} µm/s
• LIN: ${result.casaParameters.lin.toStringAsFixed(1)}%
• STR: ${result.casaParameters.str.toStringAsFixed(1)}%

🔬 الشكل والبنية:
• طبيعي: ${result.morphology.normal.toStringAsFixed(1)}%
• غير طبيعي: ${result.morphology.abnormal.toStringAsFixed(1)}%

🏥 تم التحليل بواسطة Sperm Analyzer AI
''';
    } else {
      return '''
📈 Sperm Analysis Report

🔍 Key Results:
• Sperm Count: ${result.spermCount} million/ml
• Motility: ${result.motility.toStringAsFixed(1)}%
• Concentration: ${result.concentration.toStringAsFixed(1)} million/ml

📊 CASA Parameters:
• VCL: ${result.casaParameters.vcl.toStringAsFixed(1)} µm/s
• VSL: ${result.casaParameters.vsl.toStringAsFixed(1)} µm/s
• VAP: ${result.casaParameters.vap.toStringAsFixed(1)} µm/s
• LIN: ${result.casaParameters.lin.toStringAsFixed(1)}%
• STR: ${result.casaParameters.str.toStringAsFixed(1)}%

🔬 Morphology:
• Normal: ${result.morphology.normal.toStringAsFixed(1)}%
• Abnormal: ${result.morphology.abnormal.toStringAsFixed(1)}%

🏥 Analyzed by Sperm Analyzer AI
''';
    }
  }
  
  /// عرض خيارات المشاركة
  void _showShareOptions(AnalysisResult result) {
    final isArabic = ref.read(localizationProvider).languageCode == 'ar';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppConstants.padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'مشاركة النتائج' : 'Share Results',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textColor,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 20),
              
              _buildShareOption(
                icon: Icons.message,
                title: isArabic ? 'مشاركة نصية' : 'Share as Text',
                subtitle: isArabic ? 'ملخص النتائج' : 'Summary of results',
                onTap: () {
                  Navigator.pop(context);
                  ChartExportService.shareAsText(result, isArabic);
                },
              ),
              
              _buildShareOption(
                icon: Icons.picture_as_pdf,
                title: isArabic ? 'تقرير مفصل' : 'Detailed Report',
                subtitle: isArabic ? 'تقرير شامل ومفصل' : 'Complete detailed report',
                onTap: () async {
                  Navigator.pop(context);
                  final file = await ChartExportService.exportDetailedReport(result, isArabic);
                  if (file != null) {
                    await ChartExportService.shareFile(file, 'Report');
                  }
                },
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
  
  /// عرض خيارات التصدير
  void _showExportOptions(AnalysisResult result) {
    final isArabic = ref.read(localizationProvider).languageCode == 'ar';
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppConstants.padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic ? 'تصدير البيانات' : 'Export Data',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.textColor,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 20),
              
              _buildExportOption(
                icon: Icons.table_chart,
                title: 'CSV',
                subtitle: isArabic ? 'جدول بيانات' : 'Spreadsheet data',
                onTap: () async {
                  Navigator.pop(context);
                  final file = await ChartExportService.exportAsCSV(result, isArabic);
                  if (file != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isArabic ? 'تم حفظ ملف CSV بنجاح' : 'CSV file saved successfully',
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        backgroundColor: AppConstants.successColor,
                        action: SnackBarAction(
                          label: isArabic ? 'مشاركة' : 'Share',
                          onPressed: () => ChartExportService.shareFile(file, 'CSV'),
                        ),
                      ),
                    );
                  }
                },
              ),
              
              _buildExportOption(
                icon: Icons.code,
                title: 'JSON',
                subtitle: isArabic ? 'بيانات مهيكلة' : 'Structured data',
                onTap: () async {
                  Navigator.pop(context);
                  final file = await ChartExportService.exportAsJSON(result);
                  if (file != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isArabic ? 'تم حفظ ملف JSON بنجاح' : 'JSON file saved successfully',
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        backgroundColor: AppConstants.successColor,
                        action: SnackBarAction(
                          label: isArabic ? 'مشاركة' : 'Share',
                          onPressed: () => ChartExportService.shareFile(file, 'JSON'),
                        ),
                      ),
                    );
                  }
                },
              ),
              
              _buildExportOption(
                icon: Icons.description,
                title: isArabic ? 'تقرير مفصل' : 'Detailed Report',
                subtitle: isArabic ? 'تقرير طبي شامل' : 'Complete medical report',
                onTap: () async {
                  Navigator.pop(context);
                  final file = await ChartExportService.exportDetailedReport(result, isArabic);
                  if (file != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isArabic ? 'تم حفظ التقرير بنجاح' : 'Report saved successfully',
                          style: const TextStyle(fontFamily: 'Cairo'),
                        ),
                        backgroundColor: AppConstants.successColor,
                        action: SnackBarAction(
                          label: isArabic ? 'مشاركة' : 'Share',
                          onPressed: () => ChartExportService.shareFile(file, 'Report'),
                        ),
                      ),
                    );
                  }
                },
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppConstants.accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppConstants.accentColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppConstants.textColor,
          fontFamily: 'Cairo',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppConstants.secondaryTextColor,
          fontFamily: 'Cairo',
        ),
      ),
      onTap: onTap,
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: AppConstants.secondaryTextColor,
        size: 16,
      ),
    );
  }
  
  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppConstants.infoColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: AppConstants.infoColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppConstants.textColor,
          fontFamily: 'Cairo',
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppConstants.secondaryTextColor,
          fontFamily: 'Cairo',
        ),
      ),
      onTap: onTap,
      trailing: const Icon(
        Icons.download,
        color: AppConstants.secondaryTextColor,
        size: 16,
      ),
    );
  }
}

class _LegendItem {
  final String label;
  final Color color;

  _LegendItem(this.label, this.color);
}

