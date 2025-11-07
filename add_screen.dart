import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main_nav_shell.dart';
import 'add_pet_screen.dart';

class AddScreen extends StatelessWidget {
  const AddScreen({super.key});

  void _openAddPetScreen(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPetScreen()),
    );
    if (context.mounted) {
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openAddPetScreen(context);
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFEE8A9A),
        ),
      ),
    );
  }
}
