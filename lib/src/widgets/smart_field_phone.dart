part of 'smart_field.dart';

abstract interface class _PhoneHost {
  BuildContext get context;
  bool get mounted;
  _SmartPhoneConfig get phoneConfig;
  TextEditingController? get textController;
  GlobalKey<FormFieldState<String>> get phoneFieldKey;
  bool get isInteractive;
  ValueChanged<String>? get onChanged;
  void rebuild();
}

final class _PhoneBehavior {
  _PhoneBehavior(this.host);

  final _PhoneHost host;
  final country_picker.CountryService _countryService =
      country_picker.CountryService();
  SmartPhoneCountry? selectedCountry;
  String? _lastText;

  void initialize() {
    selectedCountry =
        _resolveCountry(selectedCountry?.isoCode) ??
        _resolveCountry(host.phoneConfig.initialCountryCode);
    _lastText = host.textController?.text;
  }

  List<Widget> suffixActions() {
    final phone = host.phoneConfig;
    return [
      if (phone.showContactPicker && _supportsContactPicker)
        IconButton(
          tooltip: 'Select phone number from contacts',
          onPressed: host.isInteractive ? pickContact : null,
          icon: const Icon(Icons.contact_phone),
        ),
      if (phone.showClearButton)
        IconButton(
          tooltip: 'Clear phone number',
          onPressed:
              host.isInteractive &&
                  (host.textController?.text.isNotEmpty ?? false)
              ? clear
              : null,
          icon: const Icon(Icons.clear),
        ),
    ];
  }

  SmartPhoneCountry? _resolveCountry(String? isoCode) {
    if (isoCode == null || !_isCountryAllowed(isoCode)) {
      return null;
    }
    final country = _countryService.findByCode(isoCode);
    return country == null ? null : _toSmartCountry(country);
  }

  bool _isCountryAllowed(String isoCode) {
    final allowed = host.phoneConfig.allowedCountryCodes;
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

  void handleControllerChange() {
    final text = host.textController?.text ?? '';
    if (text == _lastText) {
      return;
    }
    _lastText = text;
    host.phoneConfig.onPhoneChanged?.call(
      SmartPhoneValidation.parseValue(text, country: selectedCountry),
    );
    if (host.mounted) {
      host.rebuild();
    }
  }

  Widget? prefixIcon(Widget? existing) {
    final config = host.phoneConfig;
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
                style:
                    config.countryTextStyle ??
                    Theme.of(host.context).textTheme.bodyMedium,
              ),
            ],
          );
    final picker = Semantics(
      label: selected == null
          ? 'Select country'
          : 'Change country, ${selected.name}, ${selected.dialCode}',
      button: true,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? _showCountryPicker : null,
        child: Padding(
          padding:
              config.countryPadding ??
              const EdgeInsetsDirectional.symmetric(horizontal: 12),
          child: content,
        ),
      ),
    );
    if (existing == null) {
      return picker;
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [existing, picker]);
  }

  void _showCountryPicker() {
    final config = host.phoneConfig;
    final theme = Theme.of(host.context);
    final favorites = config.favoriteCountryCodes
        ?.where(_isCountryAllowed)
        .toList(growable: false);
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
        inputDecoration: const InputDecoration(
          hintText: 'Search country',
          prefixIcon: Icon(Icons.search),
        ),
      ),
      onSelect: (country) {
        if (!_isCountryAllowed(country.countryCode)) {
          return;
        }
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
        host.phoneFieldKey.currentState?.validate();
      },
    );
  }

  void clear() {
    final controller = host.textController;
    if (controller == null || controller.text.isEmpty) {
      return;
    }
    controller.clear();
    host.onChanged?.call('');
    host.phoneFieldKey.currentState?.didChange('');
    host.phoneFieldKey.currentState?.validate();
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
    final config = host.phoneConfig;
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
        if (!host.mounted || contact == null) {
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
      if (!host.mounted || number == null) {
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
      host.onChanged?.call(number);
      host.phoneFieldKey.currentState?.didChange(number);
      host.phoneFieldKey.currentState?.validate();
      if (host.mounted) {
        host.rebuild();
      }
    } on Object catch (error) {
      if (!host.mounted) {
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

  void _reportPhonePickerError(SmartPhonePickerError error) {
    final callback = host.phoneConfig.onContactPickerError;
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
    if (!value.startsWith('+')) {
      return (country: null, disallowed: false);
    }
    final parsedIsoCode = SmartPhoneValidation.parsedIsoCode(value);
    if (parsedIsoCode != null && !_isCountryAllowed(parsedIsoCode)) {
      return (country: null, disallowed: true);
    }
    final compact = value.replaceAll(RegExp(r'[ ()-]'), '');
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
