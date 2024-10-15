import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:trace_foodchain_app/helpers/database_helper.dart';
import 'package:trace_foodchain_app/models/harvest_model.dart';

class HarvestTrendChart extends StatelessWidget {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  HarvestTrendChart({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HarvestModel>>(
      future: _databaseHelper.getHarvests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final harvests = snapshot.data ?? [];
        return _buildChart(harvests);
      },
    );
  }

  Widget _buildChart(List<HarvestModel> harvests) {
    final harvestData = _processHarvestData(harvests);
    return AspectRatio(
      aspectRatio: 1.70,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: true),
          minX: 0,
          maxX: harvestData.length.toDouble() - 1,
          minY: 0,
          maxY: harvestData
              .map((point) => point.y)
              .reduce((a, b) => a > b ? a : b),
          lineBarsData: [
            LineChartBarData(
              spots: harvestData,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _processHarvestData(List<HarvestModel> harvests) {
    //Transform Harvestmodel to list of maps
    List<Map<String, dynamic>> harvestListMap = [];
    for (var harvest in harvests) {
      harvestListMap.add(harvest.toMap());
    }

    harvestListMap.sort((a, b) => a['harvest_date'].compareTo(b['harvest_date']));
    return List.generate(harvests.length, (index) {
      final harvest = harvestListMap[index];
      return FlSpot(index.toDouble(), harvest['quantity'].toDouble());
    });
  }
}
