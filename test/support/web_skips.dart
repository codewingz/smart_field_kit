import 'package:flutter/foundation.dart';

const String contactPickerWebSkipReason =
    'The contact picker is not offered in a browser, so there is no picker '
    'action to drive.';

const String nativeUndoWebSkipReason =
    'A browser handles Ctrl+Z and Ctrl+Y with its own text history; the '
    'undo and redo intents are covered by a test that runs everywhere.';

const String sourceReadWebSkipReason =
    'Reads project files through dart:io, which is unavailable in a browser.';

const bool skipContactPickerOnWeb = kIsWeb;

const bool skipNativeUndoOnWeb = kIsWeb;
