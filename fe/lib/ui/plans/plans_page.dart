import 'package:flutter/material.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  int calorieIndex = 1;

  final List<String> calorieFilters = [
    "1600 Cal",
    "1600-1800 Cal",
    "1800-2000 Cal"
  ];

  final List<Map<String, dynamic>> plans = [
    {
      "image": "assets/images/food.jpg",
      "title":
          "Eat Clean dành cho dân văn phòng bận rộn cùng FoodNutri (1600-1800 calo)",
      "range": "1600 - 1800 cal / ngày",
      "meals": "4 bữa/ngày",
      "days": "7 ngày",
      "description":
          "Meal plan \"Eat Clean giảm muối - cắt đường\" từ FoodNutri được thiết kế dành riêng cho dân văn phòng bận rộn, thu nhập từ 10-15 triệu/tháng, mong muốn tự nấu mang theo nhưng vẫn đảm bảo đủ dinh dưỡng, tiện lợi và phù hợp với lịch làm việc dày đặc. Thực đơn tập trung vào các món dễ làm, nguyên liệu quen thuộc, chế biến nhanh gọn nhưng vẫn đảm bảo ngon miệng và tốt cho sức khỏe.\n\nĐặc điểm nổi bật:\n• Thiết kế riêng cho người bận rộn: Công thức đơn giản, nguyên liệu dễ mua, tối ưu thời gian nấu nướng.\n• Eat Clean đúng chuẩn: Giảm muối tối đa, không dùng đường tinh luyện, hạn chế gia vị công nghiệp.\n• Tối ưu sức khỏe: Ưu tiên thực phẩm giàu dinh dưỡng, giàu chất xơ, giàu đạm nạc và chất béo tốt.",
      "details": [
        {
          "meal": "Buổi trưa",
          "cal": 528,
          "foods": [
            {
              "img": "assets/images/food.jpg",
              "name": "Ức gà áp chảo xốt cam (eat clean)",
              "desc": "164g • 200 cal",
              "protein": 23.3,
              "carb": 17.2,
              "fat": 4.7,
            },
            {
              "img": "assets/images/food.jpg",
              "name": "Cơm gạo lứt đậu đen",
              "desc": "100g • 158 cal",
              "protein": 6,
              "carb": 23.4,
              "fat": 4.6,
            },
            {
              "img": "assets/images/food.jpg",
              "name": "Salad táo, bông cải và hạt óc chó",
              "desc": "185g • 170 cal",
              "protein": 4.6,
              "carb": 17.8,
              "fat": 9.2,
            }
          ],
        },
        {
          "meal": "Buổi tối",
          "cal": 122,
          "foods": [
            {
              "img": "assets/images/food.jpg",
              "name": "Khoai lang ruột vàng (khoai lang Nhật) luộc",
              "desc": "100g • 122 cal",
              "protein": 0.8,
              "carb": 29.2,
              "fat": 0.2,
            }
          ],
        },
        {
          "meal": "Ăn vặt",
          "cal": 0,
          "foods": [],
        }
      ]
    },
    // Bạn có thể thêm nhiều plan khác với cấu trúc trên.
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: 1,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          title: const Text("Thực đơn",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          centerTitle: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(54),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: Theme.of(context).colorScheme.surface,
              child: TabBar(
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(
                      width: 3, color: Theme.of(context).colorScheme.primary),
                  insets: const EdgeInsets.symmetric(horizontal: 24),
                ),
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey[500],
                tabs: const [
                  Tab(text: "Thực đơn của bạn"),
                  Tab(text: "Khám phá thực đơn"),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            const Center(child: Text("Chức năng đang phát triển...")),
            _DiscoveryTab(
              calorieFilters: calorieFilters,
              calorieIndex: calorieIndex,
              onFilterChanged: (i) => setState(() => calorieIndex = i),
              plans: plans,
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryTab extends StatelessWidget {
  final List<String> calorieFilters;
  final int calorieIndex;
  final Function(int) onFilterChanged;
  final List<Map<String, dynamic>> plans;

  const _DiscoveryTab({
    required this.calorieFilters,
    required this.calorieIndex,
    required this.onFilterChanged,
    required this.plans,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text("Đề xuất kế hoạch cho bạn",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 10),
          // Filter group
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: calorieFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final isActive = calorieIndex == i;
                return GestureDetector(
                  onTap: () => onFilterChanged(i),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[900],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      calorieFilters[i],
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey[300],
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: plans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 20),
              itemBuilder: (context, i) {
                final plan = plans[i];
                return _PlanCard(
                  plan: plan,
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PlanDetailPage(plan: plan),
                    ));
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final VoidCallback onTap;
  const _PlanCard({required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Theme.of(context).colorScheme.surfaceVariant,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: Image.asset(
                "assets/images/food.jpg",
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan["title"],
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    plan["range"],
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      _MiniBadge(label: plan["meals"]),
                      const SizedBox(width: 7),
                      _MiniBadge(label: plan["days"]),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  const _MiniBadge({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class PlanDetailPage extends StatelessWidget {
  final Map<String, dynamic> plan;
  const PlanDetailPage({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.zero,
              children: [
                // Ảnh to đầu trang
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  child: Image.asset(
                    "assets/images/food.jpg",
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _MiniBadge(label: plan["meals"]),
                          const SizedBox(width: 8),
                          _MiniBadge(label: plan["days"]),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(plan["title"],
                          style: const TextStyle(
                              fontSize: 21, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 11),
                      Text(
                        plan["description"] ?? "",
                        style: const TextStyle(
                            fontSize: 15, color: Colors.white70, height: 1.6),
                      ),
                      const SizedBox(height: 18),
                      ..._buildMealDetails(plan["details"]),
                      const SizedBox(height: 100), // Để chừa space cho nút
                    ],
                  ),
                ),
              ],
            ),
            // Nút back và actions
            Positioned(
              left: 10,
              top: 18,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            // 2 nút action
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: theme.colorScheme.surface,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        // TODO: Tuỳ chỉnh kế hoạch
                      },
                      child: const Text("Tuỳ chỉnh kế hoạch"),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        // TODO: Ăn theo kế hoạch này
                      },
                      child: const Text("Ăn theo kế hoạch này"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMealDetails(List? details) {
    if (details == null) return [];
    return details.map<Widget>((meal) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(meal["meal"],
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ...List.generate(meal["foods"].length, (idx) {
              final food = meal["foods"][idx];
              return Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 5),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        "assets/images/food.jpg",
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(food["name"],
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          Text(food["desc"],
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.grey)),
                          Row(
                            children: [
                              const Icon(Icons.flash_on,
                                  color: Colors.redAccent, size: 18),
                              Text(" ${food["protein"]}g  ",
                                  style: const TextStyle(fontSize: 13)),
                              const Icon(Icons.grain,
                                  color: Colors.blueAccent, size: 18),
                              Text(" ${food["carb"]}g  ",
                                  style: const TextStyle(fontSize: 13)),
                              const Icon(Icons.water_drop,
                                  color: Colors.amber, size: 18),
                              Text(" ${food["fat"]}g",
                                  style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    }).toList();
  }
}
