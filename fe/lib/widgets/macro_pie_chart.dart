import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';

class MacroPieChart extends StatelessWidget {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final bool showIcon;

  const MacroPieChart({
    super.key,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.showIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final total = protein + carbs + fat;
    int pct(double v) => total == 0 ? 0 : ((v / total) * 100).round();

    final dataMap = {
      'Đạm': protein > 0 ? protein : 0.1,
      'Carb': carbs > 0 ? carbs : 0.1,
      'Béo': fat > 0 ? fat : 0.1,
    };

    final List<Widget> macros = [
      _macroCol(
        label: 'Chất đạm',
        value: protein,
        percent: pct(protein),
        color: const Color(0xFF43BFFE),
        icon: showIcon ? 'assets/icons/proteins.png' : null,
      ),
      _macroCol(
        label: 'Đường bột',
        value: carbs,
        percent: pct(carbs),
        color: const Color(0xFFFFC84B),
        icon: showIcon ? 'assets/icons/carb.png' : null,
      ),
      _macroCol(
        label: 'Chất béo',
        value: fat,
        percent: pct(fat),
        color: const Color(0xFFF55353),
        icon: showIcon ? 'assets/icons/fat.png' : null,
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              dataMap: dataMap,
              colorList: const [
                Color(0xFF43BFFE),
                Color(0xFFFFC84B),
                Color(0xFFF55353),
              ],
              chartRadius: 60,
              chartType: ChartType.ring,
              ringStrokeWidth: 10,
              baseChartColor: Colors.grey.shade800,
              legendOptions: const LegendOptions(showLegends: false),
              chartValuesOptions:
                  const ChartValuesOptions(showChartValues: false),
            ),
            Column(
              children: [
                Text('${calories.round()}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const Text('kcal',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            )
          ],
        ),
        ...macros,
      ],
    );
  }

  Widget _macroCol({
    required String label,
    required double value,
    required int percent,
    required Color color,
    String? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Text('$percent%',
              style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          Text('${value.toStringAsFixed(1)} g',
              style: const TextStyle(color: Colors.white)),
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Row(
                children: [
                  Image.asset(icon, width: 14, height: 14),
                  const SizedBox(width: 4),
                  Text(label,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
