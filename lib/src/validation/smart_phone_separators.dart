final RegExp _directionMarks = RegExp(
  '[\u200e\u200f\u202a-\u202e\u2066-\u2069]',
);
final RegExp _spaceLike = RegExp('[\u00a0\u2007\u202f.]');
final RegExp _grouping = RegExp(r'[ ()\-]');

String smartNormalizePhoneSeparators(String value) {
  return value
      .replaceAll(_directionMarks, '')
      .replaceAll(_spaceLike, ' ')
      .trim();
}

String smartCompactPhone(String value) {
  return smartNormalizePhoneSeparators(value).replaceAll(_grouping, '');
}
