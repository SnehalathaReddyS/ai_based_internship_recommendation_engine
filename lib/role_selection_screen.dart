import 'package:flutter/material.dart';
import 'auth_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 80, color: Color(0xFF0F172A)),
            const SizedBox(height: 20),
            const Text("Welcome to Internship Hub", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
            _btn(context, "Student", Icons.person_outline, "student"),
            const SizedBox(height: 20),
            _btn(context, "Recruiter", Icons.business_center_outlined, "recruiter"),
          ],
        ),
      ),
    );
  }

  Widget _btn(BuildContext context, String t, IconData i, String r) => SizedBox(
    width: 280, height: 60,
    child: ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AuthScreen(role: r))),
      icon: Icon(i), label: Text(t, style: const TextStyle(fontSize: 18)),
    ),
  );
}