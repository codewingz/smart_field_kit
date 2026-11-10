part of 'smart_field.dart';

abstract interface class _FieldHost {
  BuildContext get context;
  bool get mounted;
  SmartField get field;
  TextEditingController? get textController;
  FocusNode? get focusNode;
  GlobalKey<FormFieldState<String>> get fieldKey;
  bool get isEnabled;
  bool get isInteractive;
  String get currentText;
  String? validateSync(String? value);
  void rebuild();
  void notifyChanged(String value);
  bool get showsMask;
  bool get pickerInteractive;
  TextEditingValue? get currentEditingValue;
  TextEditingController? get currentEditingController;
}

abstract class _FieldFeature {
  _FieldFeature(this.host);

  final _FieldHost host;

  void bind() {}

  void unbind() {}

  void didUpdate(SmartField previous) {}

  InputDecoration decorate(InputDecoration decoration) => decoration;

  InputDecoration present(InputDecoration decoration) => decoration;

  Widget? prefix(Widget? existing) => existing;

  void addSuffix(List<Widget> actions) {}

  Widget wrap(Widget child) => child;

  void textChanged(String value) {}

  void dispose() {}

  void retire() => dispose();
}

final class _RebuildFeature extends _FieldFeature {
  _RebuildFeature(super.host, this._target) {
    _binding = SmartListenerBinding(host.rebuild);
  }

  final Listenable? Function() _target;
  late final SmartListenerBinding _binding;

  @override
  void bind() => _binding.bind(_target());

  @override
  void unbind() => _binding.dispose();

  @override
  void dispose() => _binding.dispose();
}

final class _MatchFeature extends _FieldFeature {
  _MatchFeature(super.host) {
    _binding = SmartListenerBinding(_revalidate);
  }

  late final SmartListenerBinding _binding;

  void _revalidate() {
    if (host.mounted && host.currentText.isNotEmpty) {
      host.fieldKey.currentState?.validate();
    }
  }

  @override
  void bind() => _binding.bind(host.field._core.matchController);

  @override
  void unbind() => _binding.dispose();

  @override
  void dispose() => _binding.dispose();
}

final class _WordCountFeature extends _FieldFeature {
  _WordCountFeature(super.host) {
    _binding = SmartListenerBinding(host.rebuild);
  }

  late final SmartListenerBinding _binding;

  @override
  void bind() => _binding.bind(host.textController);

  @override
  void unbind() => _binding.dispose();

  @override
  void dispose() => _binding.dispose();

  @override
  void textChanged(String value) {
    if (!_binding.isBound) {
      host.rebuild();
    }
  }

  @override
  InputDecoration decorate(InputDecoration decoration) {
    final original = host.field.decoration;
    if (original.counter != null || original.counterText != null) {
      return decoration;
    }
    final count = SmartTextUtils.countWords(host.currentText);
    final maxWords = host.field._core.maxWords;
    final builder = host.field._core.wordCountBuilder;
    final text = builder != null
        ? builder(count, maxWords)
        : maxWords != null
        ? '$count / $maxWords words'
        : count == 1
        ? '1 word'
        : '$count words';
    return decoration.copyWith(counterText: text);
  }
}

final class _StrengthFeature extends _FieldFeature {
  _StrengthFeature(super.host);

  @override
  Widget wrap(Widget child) {
    final config = host.field._core.strength;
    final controller = host.textController;
    if (config == null || controller == null || host.showsMask) {
      return child;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        child,
        const SizedBox(height: 8),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => SmartPasswordStrengthIndicator(
            password: controller.text,
            criteria: config.criteria,
            labels: config.labels,
            showChecklist: config.showChecklist,
            title: config.title,
          ),
        ),
      ],
    );
  }
}

final class _PasswordFeature extends _FieldFeature {
  _PasswordFeature(super.host) : obscure = host.field._isPassword;

  bool obscure;

  @override
  void didUpdate(SmartField previous) {
    final field = host.field;
    if (previous._isPassword != field._isPassword ||
        previous.showVisibilityToggle && !field.showVisibilityToggle) {
      obscure = field._isPassword;
    }
  }

  @override
  void addSuffix(List<Widget> actions) {
    if (!host.field.showVisibilityToggle) {
      return;
    }
    final core = host.field._core;
    final label = obscure ? core.showPasswordLabel : core.hidePasswordLabel;
    final enabled = host.isEnabled;
    void toggle() {
      obscure = !obscure;
      host.rebuild();
    }

    actions.add(
      Semantics(
        label: label,
        button: true,
        enabled: enabled,
        onTap: enabled ? toggle : null,
        child: ExcludeSemantics(
          child: IconButton(
            tooltip: label,
            onPressed: enabled ? toggle : null,
            icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
          ),
        ),
      ),
    );
  }
}

final class _PercentageFeature extends _FieldFeature {
  _PercentageFeature(super.host);

  String get _symbol => host.field._percentageSuffix!;

  @override
  InputDecoration decorate(InputDecoration decoration) {
    final original = host.field.decoration;
    if (original.suffix == null &&
        original.suffixText == null &&
        original.suffixIcon != null) {
      return decoration.copyWith(suffixText: _symbol);
    }
    return decoration;
  }

  @override
  void addSuffix(List<Widget> actions) {
    final original = host.field.decoration;
    if (original.suffixIcon != null ||
        original.suffix != null ||
        original.suffixText != null) {
      return;
    }
    final theme = Theme.of(host.context);
    final enabled = host.isEnabled;
    final color = enabled
        ? theme.colorScheme.onSurfaceVariant
        : theme.disabledColor;
    actions.add(
      Padding(
        padding: const EdgeInsetsDirectional.only(end: 12),
        child: Center(
          widthFactor: 1,
          child: Text(
            _symbol,
            style:
                original.suffixStyle ??
                theme.textTheme.bodyLarge?.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}

final class _AmountFeature extends _FieldFeature {
  _AmountFeature(super.host) {
    _controllerBinding = SmartListenerBinding(_controllerChanged);
    _focusBinding = SmartListenerBinding(_focusChanged);
  }

  final SmartAmountDisplay _display = SmartAmountDisplay();
  late final SmartListenerBinding _controllerBinding;
  late final SmartListenerBinding _focusBinding;

  SmartAmountFormatter get _formatter => host.field._amountFormatter!;
  int _displayGeneration = 0;

  void _scheduleDisplay() {
    final controller = host.textController;
    if (controller == null ||
        _formatter.toDisplayValue(controller.value) == controller.value) {
      return;
    }
    final generation = ++_displayGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!host.mounted ||
          generation != _displayGeneration ||
          !identical(host.textController, controller) ||
          host.field._amountFormatter == null ||
          (host.focusNode?.hasFocus ?? false)) {
        return;
      }
      _display.showDisplay(_formatter, controller, beforeWrite: _syncFormValue);
    });
  }

  void _syncFormValue(String text) {
    SmartFormFieldValue.set(host.fieldKey.currentState, text);
  }

  void _controllerChanged() {
    _display.handleControllerChange(
      _formatter,
      host.textController,
      host.focusNode,
    );
    if (_alignScheduled) {
      return;
    }
    _alignScheduled = true;
    scheduleMicrotask(() {
      _alignScheduled = false;
      final controller = host.textController;
      final state = host.fieldKey.currentState;
      if (host.mounted &&
          controller != null &&
          state != null &&
          state.value != controller.text) {
        _syncFormValue(controller.text);
      }
    });
  }

  bool _alignScheduled = false;

  void _focusChanged() {
    _display.handleFocus(
      _formatter,
      host.textController,
      host.focusNode,
      beforeWrite: _syncFormValue,
    );
  }

  @override
  void bind() {
    _controllerBinding.bind(host.textController);
    _focusBinding.bind(host.focusNode);
    if (!(host.focusNode?.hasFocus ?? false)) {
      _scheduleDisplay();
    }
  }

  @override
  void unbind() {
    _displayGeneration++;
    _controllerBinding.dispose();
    _focusBinding.dispose();
  }

  @override
  void dispose() => unbind();
}

final class _MaskFeature extends _FieldFeature {
  _MaskFeature(super.host) {
    _controllerBinding = SmartListenerBinding(_controllerChanged);
    _focusBinding = SmartListenerBinding(_focusChanged);
  }

  late final SmartListenerBinding _controllerBinding;
  late final SmartListenerBinding _focusBinding;
  bool _lastShows = false;

  _SmartMaskConfig get config => host.field._maskConfig!;

  void _controllerChanged() {
    final now = shows;
    if (now || now != _lastShows) {
      _lastShows = now;
      host.rebuild();
    }
  }

  void _focusChanged() {
    _lastShows = shows;
    host.rebuild();
  }

  bool get shows {
    final controller = host.textController;
    if (!config.enabled || controller == null || controller.text.isEmpty) {
      return false;
    }
    if (!host.isInteractive || !config.revealOnFocus) {
      return true;
    }
    return !(host.focusNode?.hasFocus ?? false);
  }

  String get maskedText {
    final text = host.textController?.text ?? '';
    final formatter = host.field._amountFormatter;
    final focused = host.focusNode?.hasFocus ?? false;
    final shown = formatter == null || focused
        ? text
        : formatter.format(text) ?? text;
    return config.render(shown, formatter);
  }

  @override
  void bind() {
    _controllerBinding.bind(config.enabled ? host.textController : null);
    _focusBinding.bind(config.enabled ? host.focusNode : null);
    _lastShows = shows;
  }

  @override
  void unbind() {
    _controllerBinding.dispose();
    _focusBinding.dispose();
  }

  @override
  void dispose() => unbind();

  @override
  InputDecoration present(InputDecoration decoration) {
    if (!shows) {
      return decoration;
    }
    final rtl = Directionality.of(host.context) == TextDirection.rtl;
    final masked = rtl ? smartIsolateLtr(maskedText) : maskedText;
    return decoration.copyWith(
      prefixText: '${decoration.prefixText ?? ''}$masked',
      prefixStyle:
          decoration.prefixStyle ?? Theme.of(host.context).textTheme.bodyLarge,
    );
  }

  String? _textOf(Widget? widget) => widget is Text ? widget.data : null;

  @override
  Widget wrap(Widget child) {
    if (!shows) {
      return child;
    }
    final field = host.field;
    final decoration = field.decoration;
    final enabled = host.isEnabled;
    final canReveal = host.isInteractive && config.revealOnFocus;
    final label =
        decoration.labelText ?? _textOf(decoration.label) ?? field.label;
    final hint =
        decoration.hintText ?? _textOf(decoration.hint) ?? field.hintText;
    final error =
        field.serverError?.errorText ??
        decoration.errorText ??
        host.fieldKey.currentState?.errorText;
    final details = [
      ?hint,
      ?decoration.helperText,
      ?error,
    ].where((part) => part.isNotEmpty).join('. ');
    return Semantics(
      container: true,
      excludeSemantics: true,
      textField: true,
      enabled: enabled,
      readOnly: !canReveal,
      liveRegion: error != null && error.isNotEmpty,
      label: label,
      hint: details.isEmpty ? null : details,
      value: maskedText,
      onTap: canReveal ? () => host.focusNode?.requestFocus() : null,
      child: child,
    );
  }
}

final class _SearchFeature extends _FieldFeature {
  _SearchFeature(super.host) {
    _binding = SmartListenerBinding(_controllerChanged);
  }

  final SmartSearchDebouncer _debouncer = SmartSearchDebouncer();
  late final SmartListenerBinding _binding;
  bool _wasEmpty = true;

  _SmartSearchConfig get _config => host.field._searchConfig!;

  GestureTapCallback? get onTap => _config.onTap;

  String? _lastSearchText;

  void _controllerChanged() {
    final text = host.textController?.text ?? '';
    if (text == _lastSearchText) {
      return;
    }
    _lastSearchText = text;
    _debouncer.cancel();
    final empty = text.isEmpty;
    if (empty != _wasEmpty) {
      _wasEmpty = empty;
      host.rebuild();
    }
  }

  @override
  void bind() {
    _binding.bind(host.textController);
    _lastSearchText = host.textController?.text ?? '';
    _wasEmpty = host.textController?.text.isEmpty ?? true;
  }

  @override
  void unbind() => _binding.dispose();

  @override
  void dispose() {
    _binding.dispose();
    _debouncer.cancel();
  }

  @override
  void didUpdate(SmartField previous) {
    final old = previous._searchConfig;
    final current = _config;
    if (old == null ||
        previous.controller != host.field.controller ||
        old.debounceDuration != current.debounceDuration ||
        !host.isInteractive) {
      _debouncer.cancel();
    }
  }

  void _search(String query) {
    host.field._searchConfig?.onSearch?.call(query);
  }

  @override
  void textChanged(String value) {
    _debouncer.schedule(
      query: value,
      onSearch: _config.onSearch == null ? null : _search,
      debounce: _config.debounceDuration,
      canSearch: () => host.mounted && host.isInteractive,
      currentText: () => host.textController?.text ?? '',
    );
  }

  void submitted(String value) {
    _debouncer.cancel();
    _config.onSubmitted?.call(value);
  }

  void clear() {
    final controller = host.textController;
    if (controller == null || controller.text.isEmpty) {
      return;
    }
    _debouncer.cancel();
    controller.clear();
    host.fieldKey.currentState?.didChange('');
    host.notifyChanged('');
    _config.onCleared?.call();
  }

  @override
  Widget? prefix(Widget? existing) {
    final icon = _config.searchIcon;
    if (existing == null && icon != null) {
      return ExcludeSemantics(child: icon);
    }
    return existing;
  }

  @override
  void addSuffix(List<Widget> actions) {
    final config = _config;
    if (config.isLoading) {
      actions.add(
        Semantics(
          label: config.loadingLabel,
          child: ExcludeSemantics(
            child: SizedBox(
              width: 24,
              height: 24,
              child: Padding(
                padding: EdgeInsets.all(4),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      );
    }
    if (config.showClearButton &&
        config.clearIcon != null &&
        host.isInteractive &&
        (host.textController?.text.isNotEmpty ?? false)) {
      actions.add(
        Semantics(
          label: config.clearLabel,
          button: true,
          onTap: clear,
          child: ExcludeSemantics(
            child: IconButton(
              tooltip: config.clearLabel,
              onPressed: clear,
              icon: config.clearIcon!,
            ),
          ),
        ),
      );
    }
  }
}

final class _AsyncFeature extends _FieldFeature {
  _AsyncFeature(super.host, {this.observeExisting = false}) {
    _binding = SmartListenerBinding(_textChanged);
    engine = SmartAsyncValidationEngine(
      readText: () => currentText,
      toRaw: (text) {
        final normalizer = host.field._valueNormalizer;
        return normalizer == null ? text : normalizer(text);
      },
      syncError: host.validateSync,
      isActive: () =>
          host.mounted && (host.isInteractive || host.pickerInteractive),
      onUpdate: _updated,
      isComposing: () {
        final value =
            (textController ?? _inner)?.value ?? host.currentEditingValue;
        return value != null && smartIsComposing(value);
      },
    );
  }

  final bool observeExisting;
  bool _observedExisting = false;
  late final SmartAsyncValidationEngine engine;
  late final SmartListenerBinding _binding;
  TextEditingController? _ownedOtpController;
  TextEditingController? _lastController;
  TextEditingController? _inner;

  SmartAsyncValidation get _config => host.field.asyncValidation!;

  bool get _isOtp => host.field._otpConfig != null;

  String get currentText =>
      (textController ?? _inner)?.text ??
      host.fieldKey.currentState?.value ??
      '';

  TextEditingController? get otpController =>
      host.field.controller ?? _ownedOtpController;

  TextEditingController? get textController {
    if (_isOtp) {
      return host.field.controller ?? _ownedOtpController;
    }
    return host.textController;
  }

  @override
  void bind() {
    if (_isOtp && host.field.controller == null) {
      _ownedOtpController ??= TextEditingController.fromValue(
        host.currentEditingValue,
      );
    } else {
      _releaseOwnedController();
    }
    engine.configure(_config);
    final hadError =
        engine.status == SmartAsyncValidationStatus.invalid ||
        engine.status == SmartAsyncValidationStatus.unavailable;
    final controller = textController;
    _binding.bind(controller);
    _inner = null;
    if (controller == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!host.mounted || textController != null) {
          return;
        }
        _inner = host.currentEditingController;
        _binding.bind(_inner);
      });
    }
    if (_lastController != null && !identical(_lastController, controller)) {
      engine.reset();
    }
    _lastController = controller;
    if (!host.isEnabled) {
      engine.reset();
    }
    if (hadError &&
        !_isOtp &&
        engine.status == SmartAsyncValidationStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (host.mounted) {
          host.fieldKey.currentState?.validate();
        }
      });
    }
    if (!host.isEnabled) {
      return;
    }
    if (observeExisting && !_observedExisting) {
      _observedExisting = true;
      scheduleMicrotask(() {
        if (host.mounted) {
          engine.observe(currentText);
        }
      });
    }
  }

  @override
  void unbind() => _binding.dispose();

  @override
  void retire() {
    _binding.dispose();
    engine.dispose();
    _releaseOwnedController();
  }

  void _releaseOwnedController() {
    final owned = _ownedOtpController;
    if (owned == null) {
      return;
    }
    _ownedOtpController = null;
    WidgetsBinding.instance.addPostFrameCallback((_) => owned.dispose());
  }

  void _textChanged() {
    engine.observe(currentText);
  }

  void _updated() {
    if (!host.mounted) {
      return;
    }
    host.rebuild();
    final status = engine.status;
    if (!_isOtp &&
        (status == SmartAsyncValidationStatus.valid ||
            status == SmartAsyncValidationStatus.invalid ||
            status == SmartAsyncValidationStatus.unavailable)) {
      scheduleMicrotask(() {
        if (host.mounted) {
          host.fieldKey.currentState?.validate();
        }
      });
    }
  }

  @override
  void textChanged(String value) => engine.observe(value);

  String? errorFor(String? value) => engine.errorFor(value ?? '');

  @override
  void addSuffix(List<Widget> actions) {
    if (!engine.isPending) {
      return;
    }
    final config = _config;
    actions.add(
      Padding(
        padding: const EdgeInsetsDirectional.only(end: 12),
        child: Semantics(
          label: config.loadingSemanticsLabel,
          liveRegion: true,
          child:
              config.loadingIndicator ??
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
        ),
      ),
    );
  }

  @override
  Widget wrap(Widget child) {
    return smartPassiveFocus(
      onFocusChange: (focused) {
        if (!focused) {
          engine.focusLost();
        }
      },
      child: child,
    );
  }

  @override
  void dispose() {
    _binding.dispose();
    engine.dispose();
    _ownedOtpController?.dispose();
    _ownedOtpController = null;
  }
}
