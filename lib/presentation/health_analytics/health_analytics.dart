import 'package:fl_chart/fl_chart.dart';
import '../../core/app_export.dart';

class HealthAnalytics extends StatefulWidget {
  const HealthAnalytics({super.key});

  @override
  State<HealthAnalytics> createState() => _HealthAnalyticsState();
}

class _HealthAnalyticsState extends State<HealthAnalytics> {
  List<VitalStatistics> _vitalStats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVitalStats();
  }

  Future<void> _loadVitalStats() async {
    setState(() => _isLoading = true);
    final dataService = Provider.of<DataService>(context, listen: false);
    _vitalStats = await dataService.getVitalStatisticsByPatientId('patientId'); // Replace with actual patient ID
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Analytics'),
        actions: [
          IconButton(
            icon: const CustomIconWidget(iconName: 'refresh', size: 24),
            onPressed: _loadVitalStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vital Statistics Trends', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: _vitalStats.isEmpty
                        ? const Center(child: Text("No data available"))
                        : LineChart(
                            LineChartData(
                              gridData: FlGridData(show: true),
                              titlesData: FlTitlesData(show: true),
                              borderData: FlBorderData(show: true),
                              minX: 0,
                              maxX: _vitalStats.length > 1 ? _vitalStats.length.toDouble() - 1 : 0,
                              minY: 0,
                              maxY: 200, // Adjust based on data
                              lineBarsData: [
                                LineChartBarData(
                                  spots: _vitalStats.asMap().entries.map((e) {
                                    // Assuming heartRate is a string like '80 bpm', we parse it.
                                    final heartRateValue = double.tryParse(e.value.heartRate?.split(' ').first ?? '0') ?? 0.0;
                                    return FlSpot(e.key.toDouble(), heartRateValue);
                                  }).toList(),
                                  isCurved: true,
                                  color: AppTheme.lightTheme.colorScheme.primary,
                                  dotData: FlDotData(show: true),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Insights', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Your average heart rate this week is 72 bpm, which is within normal range.'),
                    ),
                  ),
                  // Add more insights based on data
                ],
              ),
            ),
    );
  }
}