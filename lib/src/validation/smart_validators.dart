import 'package:characters/characters.dart';

typedef SmartValidator = String? Function(String? value);

abstract final class SmartValidators {
  static SmartValidator requiredField({
    String message = 'This field is required.',
  }) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return message;
      }
      return null;
    };
  }

  static SmartValidator minLength(int length, {String? message}) {
    if (length < 0) {
      throw ArgumentError.value(length, 'length');
    }

    return (value) {
      if (_isBlank(value)) {
        return null;
      }
      if (value!.characters.length < length) {
        return message ?? 'Enter at least $length characters.';
      }
      return null;
    };
  }

  static SmartValidator maxLength(int length, {String? message}) {
    if (length < 0) {
      throw ArgumentError.value(length, 'length');
    }

    return (value) {
      if (_isBlank(value)) {
        return null;
      }
      if (value!.characters.length > length) {
        return message ?? 'Enter no more than $length characters.';
      }
      return null;
    };
  }

  static SmartValidator compose(Iterable<SmartValidator> validators) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) {
          return error;
        }
      }
      return null;
    };
  }

  static bool _isBlank(String? value) {
    return value == null || value.trim().isEmpty;
  }
}
