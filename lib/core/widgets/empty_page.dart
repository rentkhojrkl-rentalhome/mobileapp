
import 'package:flutter/material.dart';
import 'empty_state.dart';

class EmptyPage extends StatelessWidget {
  const EmptyPage({
    super.key,
    required this.title,
    required this.icon,
    required this.text,
  });

  final String title;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          Expanded(
            child: EmptyState(
              icon: icon,
              text: text,
            ),
          ),
        ],
      ),
    );
  }
}
