final class SmartUrlValidation {
  const SmartUrlValidation._();

  static const defaultSchemes = {'http', 'https'};

  static final RegExp _schemeExpression = RegExp(
    r'^([A-Za-z][A-Za-z0-9+.\-]*)://',
  );
  static final RegExp _unsafeExpression = RegExp(
    r'[\u0000- \u007f-   -     　<>"\\]',
  );
  static final RegExp _badPercentExpression = RegExp(r'%(?![0-9A-Fa-f]{2})');
  static final RegExp _portExpression = RegExp(r'^[0-9]{1,5}$');
  static final RegExp _ipv4Expression = RegExp(r'^[0-9]+(\.[0-9]+){3}$');
  static final RegExp _asciiLabelExpression = RegExp(
    r'^[A-Za-z0-9_](?:[A-Za-z0-9_\-]*[A-Za-z0-9_])?$',
  );
  static final RegExp _asciiExpression = RegExp(r'^[\u0000-\u007f]*$');

  static bool isValid(
    String value, {
    Set<String> allowedSchemes = defaultSchemes,
    bool allowBareDomain = false,
  }) {
    if (value.isEmpty ||
        _unsafeExpression.hasMatch(value) ||
        _badPercentExpression.hasMatch(value)) {
      return false;
    }

    final schemeMatch = _schemeExpression.firstMatch(value);
    String remainder;
    var bare = false;
    if (schemeMatch != null) {
      final scheme = schemeMatch.group(1)!.toLowerCase();
      final allowed = allowedSchemes.map((item) => item.toLowerCase());
      if (!allowed.contains(scheme)) {
        return false;
      }
      remainder = value.substring(schemeMatch.end);
    } else if (allowBareDomain) {
      remainder = value;
      bare = true;
    } else {
      return false;
    }

    final end = remainder.indexOf(RegExp(r'[/?#]'));
    final authority = end == -1 ? remainder : remainder.substring(0, end);
    if (!_isValidAuthority(authority, bare: bare)) {
      return false;
    }
    final parseable = bare ? 'https://$value' : value;
    return Uri.tryParse(parseable) != null;
  }

  static bool _isValidAuthority(String authority, {required bool bare}) {
    if (authority.isEmpty) {
      return false;
    }
    final at = authority.lastIndexOf('@');
    if (at != -1 && bare) {
      return false;
    }
    final hostPort = at == -1 ? authority : authority.substring(at + 1);
    if (at != -1) {
      final userInfo = authority.substring(0, at);
      if (userInfo.isEmpty || userInfo.contains('@')) {
        return false;
      }
    }

    String host;
    String? port;
    if (hostPort.startsWith('[')) {
      final close = hostPort.indexOf(']');
      if (close == -1) {
        return false;
      }
      host = hostPort.substring(1, close);
      final rest = hostPort.substring(close + 1);
      if (rest.isNotEmpty) {
        if (!rest.startsWith(':')) {
          return false;
        }
        port = rest.substring(1);
      }
      try {
        Uri.parseIPv6Address(host);
      } on FormatException {
        return false;
      }
    } else {
      final colon = hostPort.lastIndexOf(':');
      if (colon == -1) {
        host = hostPort;
      } else {
        host = hostPort.substring(0, colon);
        port = hostPort.substring(colon + 1);
      }
      if (!_isValidHostName(host, bare: bare)) {
        return false;
      }
    }

    if (port != null) {
      if (!_portExpression.hasMatch(port) || int.parse(port) > 65535) {
        return false;
      }
    }
    return true;
  }

  static bool _isValidHostName(String host, {required bool bare}) {
    if (host.isEmpty) {
      return false;
    }
    if (_ipv4Expression.hasMatch(host)) {
      return host.split('.').every((part) => int.parse(part) <= 255);
    }
    if (bare && !host.contains('.')) {
      return false;
    }
    final labels = host.endsWith('.')
        ? host.substring(0, host.length - 1).split('.')
        : host.split('.');
    for (final label in labels) {
      if (label.isEmpty) {
        return false;
      }
      if (_asciiExpression.hasMatch(label)) {
        if (!_asciiLabelExpression.hasMatch(label)) {
          return false;
        }
      } else if (label.contains(RegExp(r'[\u0000-,/:-@[-^`{-\u007f]'))) {
        return false;
      }
    }
    return true;
  }
}
