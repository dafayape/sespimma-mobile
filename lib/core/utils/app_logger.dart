import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';

final talker = TalkerFlutter.init(
  settings: TalkerSettings(enabled: kDebugMode, useConsoleLogs: kDebugMode),
  logger: TalkerLogger(
    settings: TalkerLoggerSettings(
      level: kDebugMode ? LogLevel.verbose : LogLevel.error,
    ),
  ),
);
