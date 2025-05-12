import 'package:flutter/material.dart';
import 'package:nutrition_app/ui/journal/add_exercise_page.dart';
import 'package:nutrition_app/ui/journal/add_water_page.dart';

class AddEntryPage extends StatelessWidget {
  const AddEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm hoạt động'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            _OptionTile(
              icon: Icons.fastfood,
              label: 'Thêm bữa ăn',
              color: Colors.orangeAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Placeholder()),
              ),
            ),
            const SizedBox(height: 16),
            _OptionTile(
              icon: Icons.local_drink,
              label: 'Thêm nước uống',
              color: Colors.lightBlueAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddWaterPage()),
              ),
            ),
            const SizedBox(height: 16),
            _OptionTile(
              icon: Icons.fitness_center,
              label: 'Thêm bài tập',
              color: Colors.redAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddExercisePage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, size: 32, color: color),
        title: Text(label, style: const TextStyle(fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 20),
        onTap: onTap,
      ),
    );
  }
}
