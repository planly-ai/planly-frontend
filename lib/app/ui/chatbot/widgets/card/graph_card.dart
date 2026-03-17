import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:planly_ai/app/utils/responsive_utils.dart';

class GraphCard extends StatelessWidget {
  final String title;
  final GraphData graph;

  const GraphCard({
    super.key,
    required this.title,
    required this.graph,
  });

  factory GraphCard.fromJson(Map<String, dynamic> json) {
    return GraphCard(
      title: json['title'] ?? '',
      graph: GraphData.fromJson(json['graph'] ?? {}),
    );
  }

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
            _buildIntegratedHeader(context),
            const SizedBox(height: AppConstants.spacingL),
            _buildChartSection(context, colorScheme),
            const SizedBox(height: AppConstants.spacingM),
            Center(
              child: Text(
                '单位: ${graph.unit}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegratedHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = colorScheme.primary;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.spacingXS),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
          ),
          child: Icon(
            graph.chartType == 'line' ? Icons.psychology : Icons.bar_chart,
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
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, 14),
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '数据分析图表',
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

  Widget _buildChartSection(BuildContext context, ColorScheme colorScheme) {
    return SizedBox(
      height: 200,
      child: graph.chartType == 'bar'
          ? _buildBarChart(context, colorScheme)
          : _buildLineChart(context, colorScheme),
    );
  }

  Widget _buildBarChart(BuildContext context, ColorScheme colorScheme) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxY() * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent,
            tooltipPadding: EdgeInsets.zero,
            tooltipMargin: 4,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                rod.toY.toString(),
                TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: _getTitlesData(context, colorScheme),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        barGroups: graph.data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                color: colorScheme.primary.withValues(alpha: 0.8),
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLineChart(BuildContext context, ColorScheme colorScheme) {
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent,
            tooltipPadding: EdgeInsets.zero,
            tooltipMargin: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  spot.y.toString(),
                  TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: const FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: _getDrawingHorizontalLine,
        ),
        titlesData: _getTitlesData(context, colorScheme),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (graph.xAxis.length - 1).toDouble(),
        minY: 0,
        maxY: _getMaxY() * 1.2,
        lineBarsData: [
          LineChartBarData(
            spots: graph.data.asMap().entries.map((entry) {
              return FlSpot(entry.key.toDouble(), entry.value.toDouble());
            }).toList(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.primary.withValues(alpha: 0.4),
              ],
            ),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.2),
                  colorScheme.primary.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static FlLine _getDrawingHorizontalLine(double value) {
    return const FlLine(
      color: Color(0xFFEEEEEE),
      strokeWidth: 1,
      dashArray: [5, 5],
    );
  }

  double _getMaxY() {
    if (graph.data.isEmpty) return 10;
    return graph.data.reduce((a, b) => a > b ? a : b).toDouble();
  }

  FlTitlesData _getTitlesData(BuildContext context, ColorScheme colorScheme) {
    return FlTitlesData(
      show: true,
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 2,
          getTitlesWidget: (value, meta) {
            return Text(
              value.toInt().toString(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
            );
          },
          reservedSize: 20,
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index >= 0 && index < graph.xAxis.length) {
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  graph.xAxis[index],
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
          reservedSize: 28,
        ),
      ),
    );
  }
}

class GraphData {
  final String chartType;
  final List<String> xAxis;
  final List<num> data;
  final String unit;

  GraphData({
    required this.chartType,
    required this.xAxis,
    required this.data,
    required this.unit,
  });

  factory GraphData.fromJson(Map<String, dynamic> json) {
    return GraphData(
      chartType: json['chartType'] ?? 'bar',
      xAxis: List<String>.from(json['xAxis'] ?? []),
      data: List<num>.from(json['data'] ?? []),
      unit: json['unit'] ?? '',
    );
  }
}

// Preview main function for testing
void main() {
  runApp(const GraphCardTestApp());
}

class GraphCardTestApp extends StatelessWidget {
  const GraphCardTestApp({super.key});

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
        appBar: AppBar(title: const Text('GRAPH 卡片展示'), centerTitle: true),
        backgroundColor: Colors.grey[100],
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GraphCard(
                title: "本周专注时长统计",
                graph: GraphData(
                  chartType: "line",
                  xAxis: ["Mon", "Tue", "Wed", "Thu", "Fri"],
                  data: [4.5, 6, 3, 5.5, 4.5],
                  unit: "h",
                ),
              ),
              const SizedBox(height: 20),
              GraphCard(
                title: "任务完成分布",
                graph: GraphData(
                  chartType: "bar",
                  xAxis: ["Bug", "Feature", "Refactor", "Test"],
                  data: [12, 8, 15, 6],
                  unit: "个",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
