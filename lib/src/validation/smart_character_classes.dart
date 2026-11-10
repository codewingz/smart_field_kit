final RegExp smartUppercaseExpression = RegExp(r'\p{Lu}', unicode: true);
final RegExp smartLowercaseExpression = RegExp(r'\p{Ll}', unicode: true);
final RegExp smartDigitExpression = RegExp(r'\p{Nd}', unicode: true);
final RegExp smartSpecialExpression = RegExp(
  r'[^\p{L}\p{N}\p{M}\s]',
  unicode: true,
);
