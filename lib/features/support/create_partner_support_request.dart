import 'package:cloud_firestore/cloud_firestore.dart';

/// Writes the existing Partner support-request document shape.
///
/// UI-specific categories, validation, and messaging remain with each screen.
/// This helper intentionally preserves the current collection and fields.
Future<void> createPartnerSupportRequest({
  required String userId,
  required String category,
  required String message,
}) {
  return FirebaseFirestore.instance.collection('support_requests').add({
    'userId': userId,
    'walkerId': userId,
    'category': category,
    'message': message,
    'status': 'open',
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });
}
