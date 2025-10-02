import 'dart:typed_data';

import 'package:feedback/feedback.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> sendFeedbackToFirebase(UserFeedback feedback) async {
  final screenshotUrl = await uploadScreenshot(feedback.screenshot);

  await FirebaseFirestore.instance.collection('app_feedback').add({
    'text': feedback.text,
    'screenshot_url': screenshotUrl,
    'timestamp': FieldValue.serverTimestamp(),
    'device': feedback.extra,
  });
}

Future<String> uploadScreenshot(Uint8List screenshotBytes) async {
  final storageRef = FirebaseStorage.instance
      .ref()
      .child('feedback_screenshots')
      .child('${DateTime.now().millisecondsSinceEpoch}.png');

  await storageRef.putData(screenshotBytes);
  return await storageRef.getDownloadURL();
}
