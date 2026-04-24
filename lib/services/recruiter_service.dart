import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class RecruiterService {
  static final List<String> stages = [
    'Applied', 'Test Round', 'Aptitude Test', 'Technical Test', 'Interview', 'Hired'
  ];

  static String getNextStage(String current) {
    int index = stages.indexOf(current);
    if (index == -1 || index == stages.length - 1) return current;
    return stages[index + 1];
  }

  static Future<void> updateStatus(String appId, String status) async {
    await FirebaseFirestore.instance.collection('applications').doc(appId).update({'status': status});
  }

  // REQUIREMENT: Deleted job reflected on student dashboard
  static Future<void> deleteJob(String jobId) async {
    var apps = await FirebaseFirestore.instance
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .get();
        
    for (var doc in apps.docs) {
      await doc.reference.update({'status': 'Deleted by Recruiter'});
    }
    await FirebaseFirestore.instance.collection('jobs').doc(jobId).delete();
  }

  static Future<void> advanceCandidate(String appId, String email, String name, String currentStatus) async {
    String next = getNextStage(currentStatus);
    await updateStatus(appId, next);

    String subject = next == 'Hired' ? "Job Offer: Congratulations!" : "Invitation: $next";
    String body = next == 'Hired' 
        ? "Dear $name, you cleared all rounds and are hired! Welcome."
        : "Dear $name, your application for the previous round was successful. You are invited to the $next.";

    final uri = Uri(
      scheme: 'mailto', path: email,
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}