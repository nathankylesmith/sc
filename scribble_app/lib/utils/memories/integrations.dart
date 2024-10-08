import 'package:scribble_app/backend/database/transcript_segment.dart';
import 'package:scribble_app/backend/http/webhooks.dart';
import 'package:scribble_app/backend/schema/message.dart';
import 'package:scribble_app/services/notification_service.dart';

triggerTranscriptSegmentReceivedEvents(
  List<TranscriptSegment> segments,
  String sessionId, {
  Function(ServerMessage)? sendMessageToChat,
}) async {
  webhookOnTranscriptReceivedCall(segments, sessionId).then((s) {
    if (s.isNotEmpty)
      NotificationService.instance
          .createNotification(title: 'Developer: On Transcript Received', body: s, notificationId: 10);
  });
  // TODO: restore me, how to trigger from backend
}
