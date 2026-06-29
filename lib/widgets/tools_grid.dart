import 'package:flutter/material.dart';

class ToolItem {
  final String label;
  final IconData icon;
  final Color containerColor;
  final Color iconColor;
  final VoidCallback onClick;

  const ToolItem({
    required this.label,
    required this.icon,
    required this.containerColor,
    required this.iconColor,
    required this.onClick,
  });
}

class ToolsGrid extends StatelessWidget {
  final VoidCallback onAllenamento;
  final VoidCallback onDieta;
  final VoidCallback onCommunity;
  final VoidCallback onProgressi;

  const ToolsGrid({
    super.key,
    required this.onAllenamento,
    required this.onDieta,
    required this.onCommunity,
    required this.onProgressi,
  });

  @override
  Widget build(BuildContext context) {
    final tools = [
      ToolItem(
        label: "Allenamento",
        icon: Icons.fitness_center_rounded,
        containerColor: const Color(0xFFEBE5FF),
        iconColor: const Color(0xFF6C5CE7),
        onClick: onAllenamento,
      ),
      ToolItem(
        label: "Dieta",
        icon: Icons.restaurant_rounded,
        containerColor: const Color(0xFFE8F8F5),
        iconColor: const Color(0xFF16A085),
        onClick: onDieta,
      ),
      ToolItem(
        label: "Community",
        icon: Icons.group_rounded,
        containerColor: const Color(0xFFFFF4E6),
        iconColor: const Color(0xFFE67E22),
        onClick: onCommunity,
      ),
      ToolItem(
        label: "Progressi",
        icon: Icons.show_chart_rounded,
        containerColor: const Color(0xFFFCEBE6),
        iconColor: const Color(0xFFD35400),
        onClick: onProgressi,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) {
        final tool = tools[index];
        return Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: const Color(0xFFF6F5F8),
          elevation: 0,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: tool.onClick,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: tool.containerColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      tool.icon,
                      color: tool.iconColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tool.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
