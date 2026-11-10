part of 'smart_field.dart';

final class _PhoneFeature extends _FieldFeature {
  _PhoneFeature(super.host) {
    _binding = SmartListenerBinding(_handleControllerChange);
  }

  late final SmartListenerBinding _binding;
  final country_picker.CountryService _countryService =
      country_picker.CountryService();
  SmartPhoneCountry? selectedCountry;
  String? _lastText;

  _SmartPhoneConfig get _config => host.field._phoneConfig!;

  @override
  void bind() {
    _binding.bind(host.textController);
    selectedCountry =
        _resolveCountry(selectedCountry?.isoCode) ??
        _resolveCountry(_config.initialCountryCode);
    _lastText = host.textController?.text;
  }

  @override
  void unbind() => _binding.dispose();

  @override
  void dispose() {
    _pickerGeneration++;
    _binding.dispose();
  }

  int _pickerGeneration = 0;

  @override
  void didUpdate(SmartField previous) {
    final before = previous._phoneConfig;
    final after = _config;
    final behaviorChanged =
        before == null ||
        before.policy != after.policy ||
        before.showCountryPicker != after.showCountryPicker ||
        !listEquals(before.allowedCountryCodes, after.allowedCountryCodes);
    if (behaviorChanged || !host.isInteractive) {
      _pickerGeneration++;
    }
  }

  bool _isCurrentPick(int generation, TextEditingController? controller) {
    return host.mounted &&
        host.isInteractive &&
        generation == _pickerGeneration &&
        identical(host.textController, controller);
  }

  @override
  void addSuffix(List<Widget> actions) {
    final phone = _config;
    actions.addAll([
      if (phone.showContactPicker && _supportsContactPicker)
        IconButton(
          tooltip: phone.contactPickerLabel,
          onPressed: host.isInteractive ? pickContact : null,
          icon: const Icon(Icons.contact_phone),
        ),
      if (phone.showClearButton)
        smartClearButton(
          tooltip: phone.clearLabel,
          onPressed:
              host.isInteractive &&
                  (host.textController?.text.isNotEmpty ?? false)
              ? clear
              : null,
        ),
    ]);
  }

  SmartPhoneCountry? _resolveCountry(String? isoCode) {
    if (isoCode == null || !_isCountryAllowed(isoCode)) {
      return null;
    }
    final country = _countryService.findByCode(isoCode);
    return country == null ? null : _toSmartCountry(country);
  }

  bool _isCountryAllowed(String isoCode) {
    final allowed = _config.allowedCountryCodes;
    return allowed == null || allowed.contains(isoCode.toUpperCase());
  }

  SmartPhoneCountry _toSmartCountry(country_picker.Country country) {
    return SmartPhoneCountry(
      isoCode: country.countryCode,
      name: country.name,
      dialCode: '+${country.phoneCode}',
      flagEmoji: country.flagEmoji,
    );
  }

  void _handleControllerChange() {
    final text = host.textController?.text ?? '';
    if (text == _lastText) {
      return;
    }
    final toggledEmpty = (_lastText?.isEmpty ?? true) != text.isEmpty;
    _lastText = text;
    _config.onPhoneChanged?.call(
      SmartPhoneValidation.parseValue(text, country: selectedCountry),
    );
    if (toggledEmpty) {
      host.rebuild();
    }
  }

  @override
  Widget? prefix(Widget? existing) {
    final config = _config;
    if (!config.showCountryPicker) {
      return existing;
    }
    final enabled = host.isInteractive;
    final selected = selectedCountry;
    final content = selected == null
        ? config.countryPlaceholder ?? const Icon(Icons.public, size: 20)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (config.showFlag) ...[
                Text(selected.flagEmoji),
                const SizedBox(width: 6),
              ],
              Text(
                selected.dialCode,
                textDirection: TextDirection.ltr,
                style:
                    config.countryTextStyle ??
                    Theme.of(host.context).textTheme.bodyMedium,
              ),
            ],
          );
    final picker = Semantics(
      label: selected == null
          ? config.selectCountryLabel
          : (config.changeCountryLabelBuilder?.call(selected) ??
                'Change country, ${selected.name}, ${selected.dialCode}'),
      button: true,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? _showCountryPicker : null,
        child: Padding(
          padding:
              config.countryPadding ??
              const EdgeInsetsDirectional.symmetric(horizontal: 12),
          child: ExcludeSemantics(
            child: SmartScaleToFit(maxWidthFactor: 0.5, child: content),
          ),
        ),
      ),
    );
    if (existing == null) {
      return picker;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        existing,
        Flexible(child: picker),
      ],
    );
  }

  void _showCountryPicker() {
    final config = _config;
    final theme = Theme.of(host.context);
    final favorites = config.favoriteCountryCodes
        ?.where(_isCountryAllowed)
        .toList(growable: false);
    final generation = _pickerGeneration;
    final target = host.textController;
    country_picker.showCountryPicker(
      context: host.context,
      showPhoneCode: true,
      countryFilter: config.allowedCountryCodes,
      favorite: favorites ?? const [],
      customFlagBuilder: config.showFlag
          ? null
          : (country) => const SizedBox.shrink(),
      countryListTheme: country_picker.CountryListThemeData(
        backgroundColor: theme.colorScheme.surface,
        textStyle: theme.textTheme.bodyLarge,
        searchTextStyle: theme.textTheme.bodyLarge,
        inputDecoration: InputDecoration(
          hintText: config.countrySearchHint,
          prefixIcon: const Icon(Icons.search),
        ),
      ),
      onSelect: (country) {
        if (!_isCurrentPick(generation, target) ||
            !_isCountryAllowed(country.countryCode)) {
          return;
        }
        final config = _config;
        final selected = _toSmartCountry(country);
        selectedCountry = selected;
        host.rebuild();
        config.onCountryChanged?.call(selected);
        config.onPhoneChanged?.call(
          SmartPhoneValidation.parseValue(
            host.textController?.text ?? '',
            country: selected,
          ),
        );
        host.fieldKey.currentState?.validate();
      },
    );
  }

  void clear() {
    final controller = host.textController;
    if (controller == null || controller.text.isEmpty) {
      return;
    }
    controller.clear();
    host.notifyChanged('');
    host.fieldKey.currentState?.didChange('');
    host.fieldKey.currentState?.validate();
    host.rebuild();
  }

  bool _picking = false;

  Future<void> pickContact() async {
    if (_picking) {
      return;
    }
    _picking = true;
    try {
      await _runContactPicker();
    } finally {
      _picking = false;
    }
  }

  Future<void> _runContactPicker() async {
    final config = _config;
    final generation = _pickerGeneration;
    final target = host.textController;
    if (!_supportsContactPicker) {
      _reportPhonePickerError(
        const SmartPhonePickerError(
          SmartPhonePickerErrorCode.unsupportedPlatform,
          'Contact selection is unavailable on this platform.',
        ),
      );
      return;
    }
    try {
      String? number;
      if (config.contactPicker == null) {
        final contact = await FlutterNativeContactPicker().selectPhoneNumber();
        if (!_isCurrentPick(generation, target) || contact == null) {
          return;
        }
        number = contact.selectedPhoneNumber;
        if (number == null) {
          _reportPhonePickerError(
            const SmartPhonePickerError(
              SmartPhonePickerErrorCode.unavailableNumber,
              'The selected contact did not provide a phone number.',
            ),
          );
          return;
        }
      } else {
        number = await config.contactPicker!();
      }
      if (!_isCurrentPick(generation, target) || number == null) {
        return;
      }
      if (number.isEmpty) {
        _reportPhonePickerError(
          const SmartPhonePickerError(
            SmartPhonePickerErrorCode.unavailableNumber,
            'The selected contact did not provide a phone number.',
          ),
        );
        return;
      }
      final inferred = _countryForInternationalNumber(number);
      if (inferred.disallowed) {
        _reportPhonePickerError(
          const SmartPhonePickerError(
            SmartPhonePickerErrorCode.disallowedCountry,
            'The selected phone number is outside the allowed countries.',
          ),
        );
        return;
      }
      final country = inferred.country ?? selectedCountry;
      final parsed = SmartPhoneValidation.parseValue(number, country: country);
      if (!parsed.isValid) {
        _reportPhonePickerError(
          const SmartPhonePickerError(
            SmartPhonePickerErrorCode.invalidNumber,
            'The selected contact does not contain a valid phone number.',
          ),
        );
        return;
      }
      if (config.showCountryPicker &&
          inferred.country != null &&
          inferred.country != selectedCountry) {
        selectedCountry = inferred.country;
        host.rebuild();
        config.onCountryChanged?.call(inferred.country);
      }
      final controller = host.textController!;
      controller.value = TextEditingValue(
        text: number,
        selection: TextSelection.collapsed(offset: number.length),
      );
      host.notifyChanged(number);
      host.fieldKey.currentState?.didChange(number);
      host.fieldKey.currentState?.validate();
      if (host.mounted) {
        host.rebuild();
      }
    } on Object catch (error) {
      if (!_isCurrentPick(generation, target)) {
        return;
      }
      _reportPhonePickerError(
        SmartPhonePickerError(
          SmartPhonePickerErrorCode.platformFailure,
          'Unable to open the contact picker.',
          error,
        ),
      );
    }
  }

  void _reportPhonePickerError(SmartPhonePickerError original) {
    final builder = _config.contactPickerMessageBuilder;
    final error = builder == null
        ? original
        : SmartPhonePickerError(
            original.code,
            builder(original.code),
            original.cause,
          );
    final callback = _config.onContactPickerError;
    if (callback != null) {
      callback(error);
      return;
    }
    final messenger = ScaffoldMessenger.maybeOf(host.context);
    messenger?.showSnackBar(SnackBar(content: Text(error.message)));
  }

  bool get _supportsContactPicker {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  ({SmartPhoneCountry? country, bool disallowed})
  _countryForInternationalNumber(String value) {
    if (!value.contains('+')) {
      return (country: null, disallowed: false);
    }
    final parsedIsoCode = SmartPhoneValidation.parsedIsoCode(value);
    if (parsedIsoCode != null && !_isCountryAllowed(parsedIsoCode)) {
      return (country: null, disallowed: true);
    }
    final compact = smartCompactPhone(value);
    final all = _countryService.getAll();
    final matching = all
        .where((country) => compact.startsWith('+${country.phoneCode}'))
        .toList();
    if (matching.isEmpty) {
      return (country: null, disallowed: false);
    }
    final longest = matching
        .map((country) => country.phoneCode.length)
        .reduce((left, right) => left > right ? left : right);
    final candidates = matching
        .where((country) => country.phoneCode.length == longest)
        .toList();
    final selected = selectedCountry;
    if (selected != null &&
        candidates.any((country) => country.countryCode == selected.isoCode)) {
      return (country: selected, disallowed: false);
    }
    if (candidates.length != 1) {
      return (country: null, disallowed: false);
    }
    final candidate = candidates.single;
    if (!_isCountryAllowed(candidate.countryCode)) {
      return (country: null, disallowed: true);
    }
    return (country: _toSmartCountry(candidate), disallowed: false);
  }
}
