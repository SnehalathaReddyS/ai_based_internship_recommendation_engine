import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_dashboard.dart';
import 'recruiter_dashboard.dart';

class AuthScreen extends StatefulWidget {
  final String role;
  const AuthScreen({super.key, required this.role});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailC = TextEditingController(), _passC = TextEditingController();
  bool _isLoading = false, _isLogin = true;

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        UserCredential cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailC.text.trim(), password: _passC.text.trim());
        User? user = cred.user;
        await user?.reload();
        user = FirebaseAuth.instance.currentUser;

        if (!mounted) return;
        if (user != null && user.emailVerified) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (doc.data()?['role'] != widget.role) {
            await FirebaseAuth.instance.signOut();
            throw "Access Denied: You are registered as a ${doc.data()?['role']}.";
          }
          _go();
        } else {
          await user?.sendEmailVerification();
          await FirebaseAuth.instance.signOut();
          throw "Please verify your email. A new link has been sent to your inbox and SPAM folder.";
        }
      } else {
        UserCredential cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailC.text.trim(), password: _passC.text.trim());
        
        await cred.user!.sendEmailVerification();
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'role': widget.role, 'email': _emailC.text.trim(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Verification link sent! Please check your Spam folder."),
            backgroundColor: Colors.blue,
          ));
          setState(() => _isLogin = true);
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _go() {
    Navigator.pushReplacement(context, MaterialPageRoute(
      builder: (_) => widget.role == 'student' ? const StudentDashboard() : const RecruiterDashboard()
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${_isLogin ? 'Login' : 'Register'} - ${widget.role.toUpperCase()}")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(children: [
            TextField(controller: _emailC, decoration: const InputDecoration(labelText: "Email ID", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            TextField(controller: _passC, decoration: const InputDecoration(labelText: "Password", border: OutlineInputBorder()), obscureText: true),
            const SizedBox(height: 30),
            _isLoading ? const CircularProgressIndicator() : SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _submit, child: Text(_isLogin ? "Login" : "Register"))),
            TextButton(onPressed: () => setState(() => _isLogin = !_isLogin), child: Text(_isLogin ? "Need an account? Register" : "Have an account? Login"))
          ]),
        ),
      ),
    );
  }
}