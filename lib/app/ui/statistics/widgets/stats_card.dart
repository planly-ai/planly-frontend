import 'package:flutter/material.dart';
import 'package:planly_ai/app/constants/app_constants.dart';
import 'package:planly_ai/app/utils/responsive_utils.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: AppConstants.elevationLow,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppConstants.spacingM),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingXS),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(
                  AppConstants.borderRadiusSmall,
                ),
              ),
              child: Icon(
                icon,
                size: AppConstants.iconSizeMedium,
                color: color,
              ),
            ),
            const SizedBox(width: AppConstants.spacingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        14,
                      ),
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        10,
                      ),
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const StatsCardTestApp());
}

class StatsCardTestApp extends StatelessWidget {
  const StatsCardTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StatsCard Test',
      // 配置 Material 3 主题，以适配你的 colorScheme 调用
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.light,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('StatsCard 展示'), centerTitle: true),
        // 使用灰色背景以便更好地观察卡片的 elevation 和圆角
        backgroundColor: Colors.grey[100],
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 示例 1: 专注时长
              StatsCard(
                title: '今日专注时长',
                value: '4 小时 5 分钟',
                icon: Icons.timer_outlined,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 16),

              // 示例 2: 任务完成率
              StatsCard(
                title: '任务完成率',
                value: '87%',
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
              const SizedBox(height: 16),

              // 示例 3: 连胜纪录
              StatsCard(
                title: '坚持天数',
                value: '12 天',
                icon: Icons.local_fire_department_outlined,
                color: Colors.orange,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
