import 'dart:typed_data';

import 'package:feedback/feedback.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> sendFeedbackToFirebase(UserFeedback feedback) async {
  final screenshotPath = await uploadScreenshot(feedback.screenshot);
  final contactEmail = feedback.extra?['email'] as String?;

  await Supabase.instance.client.from('app_feedback').insert({
    'type': 'screenshot',
    'text': feedback.text,
    'screenshot_url': screenshotPath,
    'device': feedback.extra,
    if (contactEmail != null && contactEmail.isNotEmpty)
      'contact_email': contactEmail,
  });
}

Future<String> uploadScreenshot(Uint8List screenshotBytes) async {
  final path = '${DateTime.now().millisecondsSinceEpoch}.png';

  await Supabase.instance.client.storage
      .from('feedback-screenshots')
      .uploadBinary(
        path,
        screenshotBytes,
        fileOptions: const FileOptions(contentType: 'image/png'),
      );

  return 'feedback-screenshots/$path';
}
