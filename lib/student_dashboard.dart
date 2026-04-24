import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'role_selection_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _idx = 1;
  final User? _user = FirebaseAuth.instance.currentUser;
  final _name = TextEditingController(), _phone = TextEditingController(), _coll = TextEditingController();
  final _branch = TextEditingController(), _passYear = TextEditingController(), _exp = TextEditingController();
  final _skills = TextEditingController(), _cgpa = TextEditingController();
  String? _resumeB64; bool _isEdit = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final u = _user; if (u == null) return;
    final doc = await FirebaseFirestore.instance.collection('students').doc(u.uid).get();
    if (doc.exists && mounted) {
      final d = doc.data()!;
      setState(() {
        _name.text = d['name'] ?? ''; _phone.text = d['phone'] ?? '';
        _coll.text = d['college'] ?? ''; _branch.text = d['branch'] ?? '';
        _passYear.text = d['passYear'] ?? ''; _exp.text = d['experience'] ?? '';
        _skills.text = d['skills'] ?? ''; _cgpa.text = d['cgpa'] ?? '';
        _resumeB64 = d['resumeData'];
      });
    } else if (mounted) { setState(() => _isEdit = true); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Hub"), actions: [
        IconButton(icon: const Icon(Icons.logout), onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RoleSelectionScreen()));
        })
      ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx, onTap: (i) => setState(() => _idx = i),
        selectedItemColor: const Color(0xFF0F172A),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Jobs"),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: "Applied"),
        ],
      ),
      body: IndexedStack(index: _idx, children: [_profileTab(), _jobsTab(), _appliedTab()]),
    );
  }

  Widget _profileTab() {
    if (_isEdit) {
      return SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
        _fld(_name, "Full Name"), _fld(_phone, "Phone"), _fld(_coll, "College"),
        _fld(_branch, "Branch"), _fld(_passYear, "Passing Year"),
        _fld(_skills, "Skills"), _fld(_cgpa, "CGPA"), _fld(_exp, "Experience (Years)"),
        const SizedBox(height: 10),
        Text("Email: ${_user?.email ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ElevatedButton(onPressed: _pick, child: Text(_resumeB64 == null ? "Upload PDF" : "Resume Attached ✅")),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _save, child: const Text("Save Profile"))),
      ]));
    }
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const CircleAvatar(radius: 40, child: Icon(Icons.person)),
      Text(_name.text.isEmpty ? "Student Name" : _name.text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ElevatedButton(onPressed: () => setState(() => _isEdit = true), child: const Text("Edit Profile"))
    ]));
  }

  Widget _jobsTab() => StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance.collection('jobs').snapshots(),
    builder: (context, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
      return ListView.builder(
        itemCount: snap.data!.docs.length,
        itemBuilder: (c, i) {
          final job = snap.data!.docs[i];
          return ListTile(
            title: Text(job['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(job['company']),
            trailing: const Icon(Icons.info_outline),
            onTap: () => _checkAndShowDetails(job),
          );
        },
      );
    },
  );

  Future<void> _checkAndShowDetails(DocumentSnapshot job) async {
    // REQUIREMENT: Prevent multiple applications for the same role
    final existing = await FirebaseFirestore.instance
        .collection('applications')
        .where('studentId', isEqualTo: _user!.uid)
        .where('jobId', isEqualTo: job.id)
        .get();

    if (!mounted) return;

    showModalBottomSheet(context: context, builder: (c) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(job['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text("Stipend: ${job['stipend'] ?? 'N/A'}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        const Divider(),
        Text("Description: ${job['jd'] ?? 'No description.'}"),
        Text("Required Skills: ${job['reqSkills'] ?? 'No description.'}"),
        const SizedBox(height: 20),
        if (existing.docs.isEmpty)
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () { Navigator.pop(context); _apply(job); }, 
            child: const Text("Apply Now")
          ))
        else
          const Center(child: Text("Already applied for this role", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
      ]),
    ));
  }

  Widget _appliedTab() {
    final u = _user; if (u == null) return const SizedBox();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('applications').where('studentId', isEqualTo: u.uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          itemCount: snap.data!.docs.length,
          itemBuilder: (c, i) {
            final app = snap.data!.docs[i];
            bool deletedByRecruiter = app['status'] == 'Deleted by Recruiter';
            bool withdrawn = app['status'] == 'Withdrawn';

            return Card(child: ListTile(
              title: Text(app['jobTitle']),
              subtitle: Text(
                "Status: ${app['status']}",
                style: TextStyle(color: deletedByRecruiter ? Colors.red : Colors.black54),
              ),
              trailing: deletedByRecruiter 
                ? const Text("Deleted", style: TextStyle(color: Colors.grey))
                : TextButton(
                    onPressed: () => _updateApp(app.id, withdrawn ? 'Applied' : 'Withdrawn'),
                    child: Text(withdrawn ? "Reapply" : "Withdraw", style: TextStyle(color: withdrawn ? Colors.blue : Colors.red)),
                  ),
            ));
          },
        );
      },
    );
  }

  Widget _fld(TextEditingController c, String l) => Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(controller: c, decoration: InputDecoration(labelText: l, border: const OutlineInputBorder())));
  
  Future<void> _pick() async {
    FilePickerResult? res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (res != null) {
      if (res.files.single.bytes != null) {
        setState(() => _resumeB64 = base64Encode(res.files.single.bytes!));
      } else {
        final bytes = await File(res.files.single.path!).readAsBytes();
        setState(() => _resumeB64 = base64Encode(bytes));
      }
    }
  }

  Future<void> _save() async {
    await FirebaseFirestore.instance.collection('students').doc(_user!.uid).set({
      'name': _name.text, 'phone': _phone.text, 'college': _coll.text, 'branch': _branch.text,
      'passYear': _passYear.text, 'experience': _exp.text, 'skills': _skills.text,
      'cgpa': _cgpa.text, 'resumeData': _resumeB64,
    }, SetOptions(merge: true));
    if (mounted) setState(() => _isEdit = false);
  }

  Future<void> _apply(DocumentSnapshot doc) async {
    await FirebaseFirestore.instance.collection('applications').add({
      'jobId': doc.id, 'jobTitle': doc['title'], 'recruiterId': doc['recruiterId'], 'studentId': _user!.uid,
      'studentName': _name.text, 'studentEmail': _user.email, 'status': 'Applied',
      'resumeData': _resumeB64, 'branch': _branch.text, 'passYear': _passYear.text, 'experience': _exp.text, 'college': _coll.text,
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Applied!")));
  }

  Future<void> _updateApp(String id, String status) async {
    await FirebaseFirestore.instance.collection('applications').doc(id).update({'status': status});
  }
}