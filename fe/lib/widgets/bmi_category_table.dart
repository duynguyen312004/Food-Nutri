import 'package:flutter/material.dart';

// ============ BMI Table Section (Có nút ẩn/hiện) =============
class BmiCategoryTable extends StatefulWidget {
  final double bmi;
  const BmiCategoryTable({super.key, required this.bmi});

  @override
  State<BmiCategoryTable> createState() => _BmiCategoryTableState();
}

class _BmiCategoryTableState extends State<BmiCategoryTable> {
  bool _expanded = true;

  int _getBmiIndex(double bmi) {
    if (bmi < 18.5) return 0;
    if (bmi < 23) return 1;
    if (bmi < 25) return 2;
    if (bmi < 30) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'range': 'Dưới 18.5', 'label': 'Thiếu cân'},
      {'range': '18.5 - 22.9', 'label': 'Cân nặng bình thường'},
      {'range': '23 - 24.9', 'label': 'Tiền béo phì/ Thừa cân'},
      {'range': '25 - 29.9', 'label': 'Béo phì độ I'},
      {'range': 'Trên 30', 'label': 'Béo phì độ II'},
    ];
    final bmiIndex = _getBmiIndex(widget.bmi);

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF252836),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 0),
            child: Row(
              children: [
                Text(
                  'Bảng phân loại mức độ gầy - béo dựa vào chỉ số BMI',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
              child: Divider(color: Colors.white12, thickness: 1, height: 1),
            ),
            ...List.generate(categories.length, (i) {
              final isCurrent = i == bmiIndex;
              return Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        categories[i]['range']!,
                        style: TextStyle(
                          color:
                              isCurrent ? Colors.purpleAccent : Colors.white70,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        categories[i]['label']!,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color:
                              isCurrent ? Colors.purpleAccent : Colors.white70,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          // Nút ẩn/hiện bảng
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              margin: const EdgeInsets.only(
                  left: 16, right: 16, bottom: 12, top: 4),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _expanded ? 'Ẩn thông tin ' : 'Hiện thông tin ',
                    style: const TextStyle(
                        color: Colors.white70, fontWeight: FontWeight.w600),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.white60,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
