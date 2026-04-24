import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});
  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _comp = TextEditingController(), _title = TextEditingController();
  final _sk = TextEditingController(), _jd = TextEditingController(), _stipend = TextEditingController();
  DateTime? _deadline;

  Future<void> _publish() async {
    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please set a deadline")));
      return;
    }
    final u = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('jobs').add({
      'recruiterId': u!.uid, 'company': _comp.text.trim(), 'title': _title.text.trim(),
      'jd': _jd.text.trim(), 'stipend': _stipend.text.trim(),
      'reqSkills': _sk.text.trim().toLowerCase(), 
      'deadline': Timestamp.fromDate(_deadline!),
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Post New Internship")),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
        TextField(controller: _comp, decoration: const InputDecoration(labelText: "Company")),
        TextField(controller: _title, decoration: const InputDecoration(labelText: "Job Title")),
        TextField(controller: _jd, decoration: const InputDecoration(labelText: "Description (JD)"), maxLines: 3),
        TextField(controller: _stipend, decoration: const InputDecoration(labelText: "Stipend Details")),
        TextField(controller: _sk, decoration: const InputDecoration(labelText: "Skills Required")),
        ListTile(
          title: Text(_deadline == null ? "Select Application Deadline" : "Deadline: ${_deadline.toString().split(' ')[0]}"),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
            if (date != null) setState(() => _deadline = date);
          },
        ),
        const SizedBox(height: 30),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _publish, child: const Text("Publish Job"))),
      ])),
    );
  }
}