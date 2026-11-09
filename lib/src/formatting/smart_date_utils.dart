import 'package:flutter/material.dart' show TimeOfDay;

abstract final class SmartDateUtils {
  static bool isLeapYear(int year) {
    return year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
  }

  static int daysInMonth(int year, int month) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month');
    }
    const lengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return month == 2 && isLeapYear(year) ? 29 : lengths[month - 1];
  }

  static bool isValidDate(int year, int month, int day) {
    return year >= 1 &&
        year <= 9999 &&
        month >= 1 &&
        month <= 12 &&
        day >= 1 &&
        day <= daysInMonth(year, month);
  }

  static DateTime dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static String toIsoDate(DateTime value) {
    return '${_pad(value.year, 4)}-${_pad(value.month, 2)}-${_pad(value.day, 2)}';
  }

  static DateTime? tryParseIsoDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      return null;
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    return isValidDate(year, month, day) ? DateTime(year, month, day) : null;
  }

  static String toIsoTime(TimeOfDay value) {
    return '${_pad(value.hour, 2)}:${_pad(value.minute, 2)}';
  }

  static TimeOfDay? tryParseIsoTime(String value) {
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
    if (match == null) {
      return null;
    }
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    return hour < 24 && minute < 60
        ? TimeOfDay(hour: hour, minute: minute)
        : null;
  }

  static String toIsoDateTime(DateTime value) {
    return '${toIsoDate(value)}T${_pad(value.hour, 2)}:${_pad(value.minute, 2)}';
  }

  static DateTime? tryParseIsoDateTime(String value) {
    final parts = value.split('T');
    if (parts.length != 2) {
      return null;
    }
    final date = tryParseIsoDate(parts.first);
    final time = tryParseIsoTime(parts.last);
    if (date == null || time == null) {
      return null;
    }
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  static int compareTime(TimeOfDay a, TimeOfDay b) {
    return (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute);
  }

  static String _pad(int value, int width) =>
      value.toString().padLeft(width, '0');
}

final class SmartDateFormat {
  factory SmartDateFormat([String pattern = 'dd/MM/yyyy']) {
    final match = RegExp(
      r'^(.*?)(dd|MM|yyyy)(.*?)(dd|MM|yyyy)(.*?)(dd|MM|yyyy)(.*)$',
    ).firstMatch(pattern);
    if (match == null) {
      throw ArgumentError.value(
        pattern,
        'pattern',
        'Use dd, MM, and yyyy once each, for example dd/MM/yyyy.',
      );
    }
    final fields = [match.group(2)!, match.group(4)!, match.group(6)!];
    if (fields.toSet().length != 3) {
      throw ArgumentError.value(
        pattern,
        'pattern',
        'Use dd, MM, and yyyy once each, for example dd/MM/yyyy.',
      );
    }
    final separators = [
      match.group(1)!,
      match.group(3)!,
      match.group(5)!,
      match.group(7)!,
    ];
    if (separators.any((part) => RegExp(r'[A-Za-z0-9#*\\]').hasMatch(part))) {
      throw ArgumentError.value(
        pattern,
        'pattern',
        'Separators cannot contain letters, digits, #, *, or backslashes.',
      );
    }
    return SmartDateFormat._(pattern, fields, separators);
  }

  const SmartDateFormat._(this.pattern, this._fields, this._separators);

  final String pattern;
  final List<String> _fields;
  final List<String> _separators;

  String get inputMaskPattern {
    final buffer = StringBuffer(_separators[0]);
    for (var index = 0; index < 3; index++) {
      buffer.write(_fields[index] == 'yyyy' ? '####' : '##');
      buffer.write(_separators[index + 1]);
    }
    return buffer.toString();
  }

  String format(DateTime value) {
    final buffer = StringBuffer(_separators[0]);
    for (var index = 0; index < 3; index++) {
      switch (_fields[index]) {
        case 'dd':
          buffer.write(value.day.toString().padLeft(2, '0'));
        case 'MM':
          buffer.write(value.month.toString().padLeft(2, '0'));
        default:
          buffer.write(value.year.toString().padLeft(4, '0'));
      }
      buffer.write(_separators[index + 1]);
    }
    return buffer.toString();
  }

  DateTime? tryParse(String text) {
    final expression = StringBuffer('^${RegExp.escape(_separators[0])}');
    for (var index = 0; index < 3; index++) {
      expression.write(_fields[index] == 'yyyy' ? r'(\d{4})' : r'(\d{2})');
      expression.write(RegExp.escape(_separators[index + 1]));
    }
    expression.write(r'$');
    final match = RegExp(expression.toString()).firstMatch(text);
    if (match == null) {
      return null;
    }
    var day = 0;
    var month = 0;
    var year = 0;
    for (var index = 0; index < 3; index++) {
      final value = int.parse(match.group(index + 1)!);
      switch (_fields[index]) {
        case 'dd':
          day = value;
        case 'MM':
          month = value;
        default:
          year = value;
      }
    }
    return SmartDateUtils.isValidDate(year, month, day)
        ? DateTime(year, month, day)
        : null;
  }
}

final class SmartTimeFormat {
  const SmartTimeFormat({this.use24Hour = true});

  final bool use24Hour;

  String get pattern => use24Hour ? 'HH:mm' : 'hh:mm a';

  String get inputMaskPattern => use24Hour ? '##:##' : '##:## AA';

  String format(TimeOfDay value) {
    final minute = value.minute.toString().padLeft(2, '0');
    if (use24Hour) {
      return '${value.hour.toString().padLeft(2, '0')}:$minute';
    }
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final period = value.hour < 12 ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  TimeOfDay? tryParse(String text) {
    if (use24Hour) {
      final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(text);
      if (match == null) {
        return null;
      }
      final hour = int.parse(match.group(1)!);
      final minute = int.parse(match.group(2)!);
      return hour < 24 && minute < 60
          ? TimeOfDay(hour: hour, minute: minute)
          : null;
    }
    final match = RegExp(r'^(\d{2}):(\d{2}) ([AaPp][Mm])$').firstMatch(text);
    if (match == null) {
      return null;
    }
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour < 1 || hour > 12 || minute > 59) {
      return null;
    }
    final isPm = match.group(3)!.toLowerCase() == 'pm';
    return TimeOfDay(hour: hour % 12 + (isPm ? 12 : 0), minute: minute);
  }
}
