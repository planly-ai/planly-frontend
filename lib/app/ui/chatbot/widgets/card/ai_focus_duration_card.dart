import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:planly_ai/app/utils/responsive_utils.dart';

class AiFocusDurationCard extends StatelessWidget {
  final String totalDuration;
  final String comparisonText;
  final String comparisonPercentage;
  final String longestSession;
  final List<FlSpot> chartData;
  final String insight;

  const AiFocusDurationCard({
    super.key,
    required this.totalDuration,
    required this.comparisonText,
    required this.comparisonPercentage,
    required this.longestSession,
    required this.chartData,
    required this.insight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: AppConstants.elevationLow,
      margin: EdgeInsets.all(ResponsiveUtils.getResponsiveCardMargin(context)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Integrated Header: Icon + Title (StatsCard Style)
            _buildIntegratedHeader(context),

            const SizedBox(height: AppConstants.spacingL),

            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Main Statistic
                _buildMainStat(context, colorScheme),
                const SizedBox(height: AppConstants.spacingXL),

                // Comparison Metrics
                _buildComparisonMetrics(context, colorScheme),
                const SizedBox(height: AppConstants.spacingXL),

                // Chart Section
                _buildChartSection(context, colorScheme),
                const SizedBox(height: AppConstants.spacingXL),

                // Insight Box
                _buildInsightBox(context, colorScheme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegratedHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = colorScheme.primary; // Focus primary color

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingXS),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          ),
          child: Icon(
            Icons.psychology,
            size: AppConstants.iconSizeMedium,
            color: color,
          ),
        ),
        const SizedBox(width: AppConstants.spacingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'focus_statistics_title'.tr,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'focus_statistics_subtitle'.tr,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 10),
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainStat(BuildContext context, ColorScheme colorScheme) {
    final theme = Theme.of(context);

    // Split "4 小时 5 分钟" into parts for styling
    final parts = totalDuration.split(' ');
    // Handle the case where duration might be in different format or already translated if passed from outside
    // But here totalDuration seems to be hardcoded in preview as "4 小时 5 分钟"
    // We should probably translate the units if we can, but if it comes from AI it might be dynamic.
    // Let's at least translate the label below.

    return Column(
      children: [
        RichText(
          text: TextSpan(
            style: theme.textTheme.displayLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 48),
            ),
            children: [
              TextSpan(text: parts[0]),
              TextSpan(
                text: ' ${parts[1]} ',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              TextSpan(text: parts[2]),
              TextSpan(
                text: ' ${parts[3]}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(
          'focus_total_duration_label'.tr,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 15),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonMetrics(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        // Yesterday Comparison
        Expanded(
          child: _buildMetricCard(
            context,
            title: 'focus_compare_yesterday'.tr,
            value: comparisonText,
            subValue: '↑ $comparisonPercentage',
            color: colorScheme.primary,
            bgColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
            icon: Icons.trending_up,
            iconColor: colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppConstants.spacingM),
        // Longest Session
        Expanded(
          child: _buildMetricCard(
            context,
            title: 'focus_longest_session'.tr,
            value: longestSession,
            subValue: 'focus_continuous_focus'.tr,
            color: colorScheme.secondary,
            bgColor: colorScheme.secondaryContainer.withValues(alpha: 0.3),
            icon: Icons.hourglass_empty,
            iconColor: colorScheme.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subValue,
    required Color color,
    required Color bgColor,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.visible,
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          Text(
            subValue,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(BuildContext context, ColorScheme colorScheme) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time, size: 18, color: Color(0xFF757575)),
            const SizedBox(width: 8),
            Text(
              'focus_distribution'.tr,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.spacingL),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 15,
                getDrawingHorizontalLine: (value) {
                  return const FlLine(
                    color: Color(0xFFEEEEEE),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 15,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: ResponsiveUtils.getResponsiveFontSize(
                            context,
                            12,
                          ),
                        ),
                      );
                    },
                    reservedSize: 28,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      String text = '';
                      switch (value.toInt()) {
                        case 0:
                          text = '9:00';
                          break;
                        case 2:
                          text = '10:00';
                          break;
                        case 4:
                          text = '11:00';
                          break;
                        case 6:
                          text = '14:00';
                          break;
                        case 8:
                          text = '15:00';
                          break;
                        case 10:
                          text = '16:00';
                          break;
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          text,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                              context,
                              11,
                            ),
                          ),
                        ),
                      );
                    },
                    reservedSize: 28,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: 10,
              minY: 0,
              maxY: 60,
              lineBarsData: [
                LineChartBarData(
                  spots: chartData,
                  isCurved: true,
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.3),
                    ],
                  ),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.15),
                        colorScheme.primary.withValues(alpha: 0.02),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (spot) => colorScheme.primary,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      return LineTooltipItem(
                        '${spot.y.toInt()} ${'unit_minute'.tr}',
                        theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ) ??
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightBox(BuildContext context, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 13),
                ),
                children: [
                  TextSpan(
                    text: 'focus_insight_label'.tr,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  TextSpan(text: insight),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Preview main function for testing
void main() {
  runApp(const AiFocusDurationTestApp());
}

class AiFocusDurationTestApp extends StatelessWidget {
  const AiFocusDurationTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('专注时长卡片展示'), centerTitle: true),
        backgroundColor: Colors.grey[100],
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              AiFocusDurationCard(
                totalDuration: "4 小时 5 分钟",
                comparisonText: "+65 分钟",
                comparisonPercentage: "36%",
                longestSession: "90 分钟",
                chartData: const [
                  FlSpot(0, 45),
                  FlSpot(2, 60),
                  FlSpot(4, 30),
                  FlSpot(6, 55),
                  FlSpot(8, 45),
                  FlSpot(10, 15),
                ],
                insight: "今天的专注时间超过3小时，保持得非常好！",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
