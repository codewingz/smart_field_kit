import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

TextEditingValue _value(String text, int caret) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: caret),
);

void main() {
  test('forward delete on a leading literal with no input does not throw', () {
    final mask = SmartMaskFormatter(SmartInputMask('(###) ###'));
    final result = mask.formatEditUpdate(_value('(', 0), _value('', 0));
    expect(result.text, isEmpty);
  });

  test('mask and card formatters share the same delete behaviour', () {
    final mask = SmartMaskFormatter(SmartInputMask('####/####'));
    const card = SmartCardNumberFormatter();
    final maskForward = mask.formatEditUpdate(
      _value('4111/2345', 4),
      _value('41112345', 4),
    );
    final cardForward = card.formatEditUpdate(
      _value('4111 2345', 4),
      _value('41112345', 4),
    );
    expect(maskForward.text, '4111/345');
    expect(cardForward.text, '4111 345');
    expect(maskForward.selection.baseOffset, 4);
    expect(cardForward.selection.baseOffset, 4);
    final maskBack = mask.formatEditUpdate(
      _value('4111/2345', 5),
      _value('41112345', 4),
    );
    final cardBack = card.formatEditUpdate(
      _value('4111 2345', 5),
      _value('41112345', 4),
    );
    expect(maskBack.text, '4112/345');
    expect(cardBack.text, '4112 345');
    expect(maskBack.selection.baseOffset, 3);
    expect(cardBack.selection.baseOffset, 3);
  });

  test('password rules and strength criteria agree on character classes', () {
    for (final sample in ['É', 'é', '٣', '!', 'a1', 'Aa1!', '日本']) {
      final rules = {
        SmartBuiltInCheck.passwordUppercase: SmartPasswordCriterion.uppercase,
        SmartBuiltInCheck.passwordLowercase: SmartPasswordCriterion.lowercase,
        SmartBuiltInCheck.passwordDigit: SmartPasswordCriterion.digit,
        SmartBuiltInCheck.passwordSpecialCharacter:
            SmartPasswordCriterion.specialCharacter,
      };
      for (final entry in rules.entries) {
        final validatorPasses =
            SmartValidators.passwordRules({entry.key})(sample) == null;
        expect(validatorPasses, entry.value.test(sample), reason: sample);
      }
    }
  });
}
