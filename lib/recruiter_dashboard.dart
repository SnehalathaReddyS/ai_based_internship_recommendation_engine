import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:universal_html/html.dart' as html; // Universal fix for APK build
import 'services/recruiter_service.dart';
import 'post_job_screen.dart';
import 'role_selection_screen.dart';

class RecruiterDashboard extends StatefulWidget {
  const RecruiterDashboard({super.key});
  @override
  State<RecruiterDashboard> createState() => _RecruiterDashboardState();
}

class _RecruiterDashboardState extends State<RecruiterDashboard> {
  final _user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Recruiter Portal"),
          bottom: const TabBar(tabs: [Tab(text: "Applicants"), Tab(text: "My Jobs")]),
          actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (!mounted) return;
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
          })],
        ),
        body: TabBarView(children: [_applicantsList(), _jobsList()]),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostJobScreen())),
        ),
      ),
    );
  }

  Widget _applicantsList() => StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('applications').where('recruiterId', isEqualTo: _user?.uid).snapshots(),
    builder: (context, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      return ListView.builder(
        itemCount: snap.data!.docs.length,
        itemBuilder: (c, i) => ListTile(
          title: Text(snap.data!.docs[i]['studentName'], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text("Role: ${snap.data!.docs[i]['jobTitle']} | Status: ${snap.data!.docs[i]['status']}"),
          trailing: const Icon(Icons.rate_review),
          onTap: () => _evaluate(snap.data!.docs[i]),
        ),
      );
    },
  );

  Widget _jobsList() => StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('jobs').where('recruiterId', isEqualTo: _user?.uid).snapshots(),
    builder: (context, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      return ListView.builder(
        itemCount: snap.data!.docs.length,
        itemBuilder: (c, i) {
          final job = snap.data!.docs[i];
          final data = job.data() as Map<String, dynamic>;
          String deadline = data.containsKey('deadline') 
              ? (data['deadline'] as Timestamp).toDate().toString().split(' ')[0] 
              : "No Deadline";
          return ListTile(
            title: Text(data['title']), 
            subtitle: Text("Deadline: $deadline"),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(job.id),
            ),
          );
        },
      );
    },
  );

  void _confirmDelete(String jobId) {
    showDialog(context: context, builder: (c) => AlertDialog(
      title: const Text("Delete Internship?"),
      content: const Text("Student applications will be marked as inactive."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () { RecruiterService.deleteJob(jobId); Navigator.pop(context); }, 
          child: const Text("DELETE", style: TextStyle(color: Colors.white))
        ),
      ],
    ));
  }

  void _evaluate(DocumentSnapshot doc) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('applications').doc(doc.id).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        final app = snap.data!.data() as Map;
        final String currentStatus = app['status'];

        return DraggableScrollableSheet(
          expand: false, initialChildSize: 0.9, builder: (c, s) => ListView(padding: const EdgeInsets.all(24), children: [
            Text(app['studentName'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text("Applied for: ${app['jobTitle']}"),
            const Divider(),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: app['resumeData'] == null ? null : () => _viewPDF(app['resumeData'], app['studentName']),
              icon: const Icon(Icons.picture_as_pdf), label: const Text("View Resume")
            ),
            const Divider(height: 30),

            if (currentStatus == 'Rejected') ...[
              const Center(child: Text("Rejected", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
            ] else if (currentStatus == 'Hired') ...[
              const Center(child: Text("Hired! 🎉", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
            ] else if (currentStatus == 'Deleted by Recruiter') ...[
              const Center(child: Text("Listing Deleted", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
            ] else ...[
              Text("CURRENT STAGE: ${currentStatus.toUpperCase()}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () => RecruiterService.advanceCandidate(doc.id, app['studentEmail'], app['studentName'], currentStatus),
                  child: const Text("ACCEPT & NEXT"),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => RecruiterService.updateStatus(doc.id, "Rejected"),
                  child: const Text("REJECT"),
                )),
              ]),
            ],
          ]),
        );
      }
    ));
  }

  Future<void> _viewPDF(String b64, String name) async {
    final bytes = base64Decode(b64);
    if (kIsWeb) {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.window.open(url, "_blank");
      html.Url.revokeObjectUrl(url);
    } else {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Resume_$name.pdf');
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
    }
  }
}