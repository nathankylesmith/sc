import 'package:flutter/material.dart';
import 'package:scribble_app/backend/http/api/memories.dart';
import 'package:scribble_app/backend/schema/memory.dart';
import 'package:scribble_app/utils/analytics/mixpanel.dart';
import 'package:instabug_flutter/instabug_flutter.dart';

Future<ServerMemory?> reProcessMemory(
  BuildContext context,
  ServerMemory memory,
  Function onFailedProcessing,
  Function changeLoadingState,
) async {
  debugPrint('_reProcessMemory');
  changeLoadingState();
  try {
    var updatedMemory = await reProcessMemoryServer(memory.id);
    MixpanelManager().reProcessMemory(memory);
    changeLoadingState();
    return updatedMemory;
  } catch (err, stacktrace) {
    print(err);
    var memoryReporting = MixpanelManager().getMemoryEventProperties(memory);
    CrashReporting.reportHandledCrash(err, stacktrace, level: NonFatalExceptionLevel.critical, userAttributes: {
      'memory_transcript_length': memoryReporting['transcript_length'].toString(),
      'memory_transcript_word_count': memoryReporting['transcript_word_count'].toString(),
    });
    onFailedProcessing();
    changeLoadingState();
    return null;
  }
}
