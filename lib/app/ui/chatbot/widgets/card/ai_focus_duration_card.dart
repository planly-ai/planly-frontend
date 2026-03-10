import 'package:flutter/material.dart';
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
                _buildMainStat(context),
                const SizedBox(height: AppConstants.spacingXL),

                // Comparison Metrics
                _buildComparisonMetrics(context),
                const SizedBox(height: AppConstants.spacingXL),

                // Chart Section
                _buildChartSection(context),
                const SizedBox(height: AppConstants.spacingXL),

                // Insight Box
                _buildInsightBox(context),
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
    final color = const Color(0xFF9C27B0); // Focus primary color

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
                '专注时长统计',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '今天的深度思考记录',
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

  Widget _buildMainStat(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Split "4 小时 5 分钟" into parts for styling
    final parts = totalDuration.split(' ');
    
    return Column(
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: const Color(0xFF263238),
              fontWeight: FontWeight.bold,
              fontSize: ResponsiveUtils.getResponsiveFontSize(context, 48),
            ),
            children: [
              TextSpan(text: parts[0]),
              TextSpan(
                text: ' ${parts[1]} ',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                  color: const Color(0xFF455A64),
                ),
              ),
              TextSpan(text: parts[2]),
              TextSpan(
                text: ' ${parts[3]}',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 20),
                  color: const Color(0xFF455A64),
                ),
              ),
            ],
          ),
        ),
        Text(
          '今日累计专注时长',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF9E9E9E),
            fontWeight: FontWeight.bold,
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, 15),
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonMetrics(BuildContext context) {
    return Row(
      children: [
        // Yesterday Comparison
        Expanded(
          child: _buildMetricCard(
            context,
            title: '对比昨日',
            value: comparisonText,
            subValue: '↑ $comparisonPercentage',
            color: const Color(0xFF00C853),
            bgColor: const Color(0xFFE3F2FD),
            icon: Icons.trending_up,
            iconColor: const Color(0xFF2962FF),
          ),
        ),
        const SizedBox(width: AppConstants.spacingM),
        // Longest Session
        Expanded(
          child: _buildMetricCard(
            context,
            title: '最长时段',
            value: longestSession,
            subValue: '连续专注',
            color: const Color(0xFFD500F9),
            bgColor: const Color(0xFFFCE4EC),
            icon: Icons.hourglass_empty,
            iconColor: const Color(0xFFD500F9),
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
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF757575),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
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
              color: const Color(0xFF9E9E9E),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time, size: 18, color: Color(0xFF757575)),
            const SizedBox(width: 8),
            Text(
              '时段分布',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF455A64),
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
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 15,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
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
                        case 0: text = '9:00'; break;
                        case 2: text = '10:00'; break;
                        case 4: text = '11:00'; break;
                        case 6: text = '14:00'; break;
                        case 8: text = '15:00'; break;
                        case 10: text = '16:00'; break;
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(text, style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2962FF), Color(0xFFE040FB)],
                  ),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2962FF).withValues(alpha: 0.1),
                        const Color(0xFFE040FB).withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (spot) => Colors.blueAccent,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      return LineTooltipItem(
                        '${spot.y.toInt()} 分钟',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  Widget _buildInsightBox(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Color(0xFF455A64), fontSize: 13),
                children: [
                  const TextSpan(
                    text: '洞察：',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF673AB7)),
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
