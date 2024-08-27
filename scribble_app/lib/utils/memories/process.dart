import 'package:flutter/material.dart';
import 'package:scribble_app/backend/database/geolocation.dart';
import 'package:scribble_app/backend/database/transcript_segment.dart';
import 'package:scribble_app/backend/http/api/memories.dart';
import 'package:scribble_app/backend/http/webhooks.dart';
import 'package:scribble_app/backend/schema/memory.dart';
import 'package:scribble_app/backend/schema/message.dart';
import 'package:scribble_app/services/notification_service.dart';
import 'package:tuple/tuple.dart';

// Perform actions periodically
Future<ServerMemory?> processTranscriptContent(
  List<TranscriptSegment> transcriptSegments, {
  bool retrievedFromCache = false,
  DateTime? startedAt,
  DateTime? finishedAt,
  Geolocation? geolocation,
  List<Tuple2<String, String>> photos = const [],
  Function(ServerMessage)? sendMessageToChat,
  bool triggerIntegrations = true,
  String? language,
}) async {
  debugPrint('processTranscriptContent');
  if (transcriptSegments.isEmpty && photos.isEmpty) return null;
  CreateMemoryResponse? result = await createMemoryServer(
    startedAt: startedAt ?? DateTime.now(),
    finishedAt: finishedAt ?? DateTime.now(),
    transcriptSegments: transcriptSegments,
    geolocation: geolocation,
    photos: photos,
    triggerIntegrations: triggerIntegrations,
    language: language,
  );
  if (result == null || result.memory == null) return null;

  webhookOnMemoryCreatedCall(result.memory).then((s) {
    if (s.isNotEmpty) {
      NotificationService.instance
          .createNotification(title: 'Developer: On Memory Created', body: s, notificationId: 11);
    }
  });

  for (var message in result.messages) {
    String pluginId = message.pluginId ?? '';
    NotificationService.instance
        .createNotification(title: '$pluginId says', body: message.text, notificationId: pluginId.hashCode);
    if (sendMessageToChat != null) sendMessageToChat(message);
  }
  return result.memory;
}
