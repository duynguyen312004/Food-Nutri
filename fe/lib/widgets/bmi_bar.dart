import 'package:flutter/material.dart';

class BMIRangeBar extends StatelessWidget {
  final double bmi;
  final double min;
  final double max;
  final double width;
  final double barHeight;
  final double pointerSize;

  const BMIRangeBar({
    super.key,
    required this.bmi,
    this.min = 15,
    this.max = 35,
    this.width = 320,
    this.barHeight = 18,
    this.pointerSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    // Các mốc và màu vùng
    final points = [15.0, 18.5, 22.9, 24.9, 29.9, 35.0];
    final colors = [
      const Color(0xFF87B9FF), // xanh blue
      const Color(0xFF7FE18C), // xanh lá
      const Color(0xFFF6D365), // vàng
      const Color(0xFFFFAF80), // cam nhạt
      const Color(0xFFF57D7C), // đỏ
    ];

    // Xử lý pointer không vượt quá hai đầu
    double percent = ((bmi - min) / (max - min)).clamp(0.0, 1.0);

    // Tìm vùng active
    int activeIndex = 0;
    for (int i = 0; i < points.length - 1; i++) {
      if (bmi >= points[i] && bmi < points[i + 1]) {
        activeIndex = i;
        break;
      }
      if (bmi >= points[points.length - 2]) {
        activeIndex = points.length - 2;
      }
    }

    // Tính width từng block và fix lỗi tổng block phải đúng = width bar
    List<double> blockWidths = [];
    double total = 0;
    for (int i = 0; i < points.length - 1; i++) {
      double range = points[i + 1] - points[i];
      double w = ((range / (max - min)) * width);
      // Sửa lỗi làm tròn cuối cùng
      if (i == points.length - 2) w = width - total;
      blockWidths.add(w);
      total += w;
    }

    // Tăng chiều cao Stack để pointer nổi hẳn, không bị che
    final stackHeight = barHeight + pointerSize / 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: width,
          height: stackHeight,
          child: Stack(
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.none,
            children: [
              // Bar chia block màu
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(blockWidths.length, (i) {
                  return Container(
                    width: blockWidths[i],
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: colors[i],
                      borderRadius: BorderRadius.horizontal(
                        left: i == 0
                            ? Radius.circular(barHeight / 2)
                            : Radius.zero,
                        right: i == blockWidths.length - 1
                            ? Radius.circular(barHeight / 2)
                            : Radius.zero,
                      ),
                    ),
                  );
                }),
              ),
              // Pointer: nổi, không cắt
              Positioned(
                left: percent * (width - pointerSize),
                top: (stackHeight - pointerSize) / 2,
                child: Container(
                  width: pointerSize,
                  height: pointerSize,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.deepPurpleAccent,
                      width: 3,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        // Label số dưới bar
        SizedBox(
          width: width,
          height: 22,
          child: Stack(
            children: List.generate(points.length, (i) {
              // Tính vị trí phần trăm của label trên thanh bar
              double px = ((points[i] - min) / (max - min)) * (width - 1);
              final isActive = i == activeIndex;
              return Positioned(
                left: px -
                    18, // căn chỉnh label giữa điểm, 18 = nửa width text max (ước lượng)
                child: SizedBox(
                  width: 36, // cho label không bị chồng nhau
                  child: Center(
                    child: Text(
                      points[i].toStringAsFixed(
                          i == 0 || i == points.length - 1 ? 0 : 1),
                      style: TextStyle(
                        color:
                            isActive ? Colors.deepPurpleAccent : Colors.white70,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                        fontSize: isActive ? 14 : 13,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
