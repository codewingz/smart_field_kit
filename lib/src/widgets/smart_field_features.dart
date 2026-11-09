part of 'smart_field.dart';

abstract interface class _FieldHost {
  BuildContext get context;
  bool get mounted;
  SmartField get field;
  TextEditingController? get textController;
  FocusNode? get focusNode;
  GlobalKey<FormFieldState<String>> get fieldKey;
  bool get isInteractive;
  String get currentText;
  String? validateSync(String? value);
  void rebuild();
  void notifyChanged(String value);
  bool get showsMask;
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
    final text = maxWords != null
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
    final label = obscure ? 'Show password' : 'Hide password';
    final enabled = host.field.enabled ?? host.field.decoration.enabled;
    actions.add(
      Semantics(
        label: label,
        button: true,
        enabled: enabled,
        child: ExcludeSemantics(
          child: IconButton(
            tooltip: label,
            onPressed: !enabled
                ? null
                : () {
                    obscure = !obscure;
                    host.rebuild();
                  },
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
    final enabled = host.field.enabled ?? original.enabled;
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

  void _controllerChanged() {
    _display.handleControllerChange(
      _formatter,
      host.textController,
      host.focusNode,
    );
  }

  void _focusChanged() {
    _display.handleFocus(_formatter, host.textController, host.focusNode);
  }

  @override
  void bind() {
    _controllerBinding.bind(host.textController);
    _focusBinding.bind(host.focusNode);
    if (!(host.focusNode?.hasFocus ?? false)) {
      _display.showDisplay(_formatter, host.textController);
    }
  }

  @override
  void unbind() {
    _controllerBinding.dispose();
    _focusBinding.dispose();
  }

  @override
  void dispose() => unbind();
}

final class _MaskFeature extends _FieldFeature {
  _MaskFeature(super.host) {
    _controllerBinding = SmartListenerBinding(host.rebuild);
    _focusBinding = SmartListenerBinding(host.rebuild);
  }

  late final SmartListenerBinding _controllerBinding;
  late final SmartListenerBinding _focusBinding;

  _SmartMaskConfig get config => host.field._maskConfig!;

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

  String get maskedText => config.render(
    host.textController?.text ?? '',
    host.field._amountFormatter,
  );

  @override
  void bind() {
    _controllerBinding.bind(config.enabled ? host.textController : null);
    _focusBinding.bind(config.enabled ? host.focusNode : null);
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
    return decoration.copyWith(
      prefixText: '${decoration.prefixText ?? ''}$maskedText',
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
    final enabled = field.enabled ?? decoration.enabled;
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

  void _controllerChanged() {
    _debouncer.cancel();
    final empty = host.textController?.text.isEmpty ?? true;
    if (empty != _wasEmpty) {
      _wasEmpty = empty;
      host.rebuild();
    }
  }

  @override
  void bind() {
    _binding.bind(host.textController);
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
        !old.hasSameDebounceBehavior(current) ||
        !host.isInteractive) {
      _debouncer.cancel();
    }
  }

  @override
  void textChanged(String value) {
    _debouncer.schedule(
      query: value,
      onSearch: _config.onSearch,
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
          label: 'Loading search',
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
          label: 'Clear search',
          button: true,
          child: ExcludeSemantics(
            child: IconButton(
              tooltip: 'Clear search',
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
      isActive: () => host.mounted && host.isInteractive,
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
      _ownedOtpController ??= TextEditingController();
    } else {
      _releaseOwnedController();
    }
    engine.configure(_config);
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
    if (!(host.field.enabled ?? host.field.decoration.enabled)) {
      engine.reset();
    } else if (observeExisting && !_observedExisting) {
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
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
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
