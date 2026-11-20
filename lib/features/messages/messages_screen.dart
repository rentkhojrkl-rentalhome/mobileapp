
import 'package:flutter/material.dart';

import '../../core/widgets/empty_page.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyPage(
      title: 'Messages',
      icon: Icons.chat_bubble_outline,
      text: 'Your owner and tenant conversations will appear here.',
    );
  }
}
