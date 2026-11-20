
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 62,
          child: Column(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor:
                    active ? AppTheme.forest : AppTheme.moss,
                child: Icon(
                  label == 'All'
                      ? Icons.grid_view_rounded
                      : label == 'PG'
                          ? Icons.bed_outlined
                          : Icons.home_outlined,
                  color: active ? Colors.white : AppTheme.forest,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
