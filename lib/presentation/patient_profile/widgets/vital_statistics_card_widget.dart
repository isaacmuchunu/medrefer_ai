import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../core/app_export.dart';

class VitalStatisticsCardWidget extends StatelessWidget {
  final Map<String, dynamic> vitalData;
  final bool isMetric;
  final VoidCallback onUnitToggle;

  const VitalStatisticsCardWidget({
    super.key,
    required this.vitalData,
    this.isMetric = false,
    required this.onUnitToggle,
  });

  @override
  Widget build(BuildContext context) {
    final vitals = <Map<String, dynamic>>[
      {
        "title": "Blood Pressure",
        "value": vitalData["bloodPressure"] ?? "120/80",
        "unit": "mmHg",
        "icon": "favorite",
        "color": AppTheme.errorLight,
        "status": "normal",
        "trend": vitalData["bp_trend"] ?? [120.0, 122.0, 118.0, 121.0, 120.0],
        "range": "90/60 - 120/80",
      },
      {
        "title": "Heart Rate",
        "value": vitalData["heartRate"] ?? "72",
        "unit": "bpm",
        "icon": "monitor_heart",
        "color": AppTheme.lightTheme.primaryColor,
        "status": "high",
        "trend": vitalData["hr_trend"] ?? [70.0, 72.0, 75.0, 73.0, 78.0],
        "range": "60 - 100",
      },
      {
        "title": "Temperature",
        "value": isMetric
            ? ((double.tryParse(vitalData["temperature"] ?? "98.6")! - 32) * 5 / 9)
                .toStringAsFixed(1)
            : vitalData["temperature"] ?? "98.6",
        "unit": isMetric ? "°C" : "°F",
        "icon": "thermostat",
        "color": AppTheme.warningLight,
        "status": "normal",
        "trend": vitalData["temp_trend"] ?? [98.6, 98.7, 98.5, 98.8, 98.6],
        "range": isMetric ? "36.1 - 37.2" : "97 - 99",
      },
      {
        "title": "Oxygen Sat",
        "value": vitalData["oxygenSaturation"] ?? "98",
        "unit": "%",
        "icon": "air",
        "color": AppTheme.successLight,
        "status": "normal",
        "trend": vitalData["o2_trend"] ?? [98.0, 97.0, 98.0, 99.0, 98.0],
        "range": "95 - 100",
      },
    ];

    final lastUpdated = vitalData['lastUpdated'] != null
        ? DateFormat('MMM d, hh:mm a').format(DateTime.parse(vitalData['lastUpdated']))
        : 'N/A';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'health_and_safety',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              SizedBox(width: 2.w),
              Text(
                "Vital Statistics",
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onUnitToggle,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isMetric ? '°C, kg, cm' : '°F, lbs, in',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.primaryColor,
                      fontSize: 10.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            "Last updated: $lastUpdated",
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryLight,
              fontSize: 10.sp,
            ),
          ),
          SizedBox(height: 3.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 3.w,
              mainAxisSpacing: 2.h,
              childAspectRatio: 1.8,
            ),
            itemCount: vitals.length,
            itemBuilder: (context, index) {
              final vital = vitals[index];
              final statusColor = vital["status"] == "normal"
                  ? AppTheme.successLight
                  : (vital["status"] == "high" ? AppTheme.errorLight : AppTheme.warningLight);

              return Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: (vital["color"] as Color).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (vital["color"] as Color).withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomIconWidget(
                          iconName: vital["icon"] as String,
                          color: vital["color"] as Color,
                          size: 20,
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vital["title"] as String,
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              vital["value"] as String,
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: vital["color"] as Color,
                              ),
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              vital["unit"] as String,
                              style: AppTheme.lightTheme.textTheme.bodySmall
                                  ?.copyWith(
                                color: AppTheme.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 20,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: (vital["trend"] as List<double>)
                                  .asMap()
                                  .entries
                                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                                  .toList(),
                              isCurved: true,
                              color: (vital["color"] as Color).withOpacity(0.5),
                              barWidth: 2,
                              dotData: FlDotData(show: false),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
