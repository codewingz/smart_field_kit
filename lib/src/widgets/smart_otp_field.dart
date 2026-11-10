import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_field_kit/src/formatting/smart_composing.dart';
import 'package:smart_field_kit/src/models/smart_otp_style.dart';
import 'package:smart_field_kit/src/validation/smart_validators.dart';
import 'package:smart_field_kit/src/widgets/smart_field.dart';
import 'package:smart_field_kit/src/widgets/smart_field_support.dart';
import 'package:smart_field_kit/src/widgets/smart_listener_binding.dart';

class SmartOtpConfiguration {
  const SmartOtpConfiguration({
    required this.length,
    required this.obscureText,
    required this.onCompleted,
    required this.errorText,
    required this.notifyOnProgrammaticChanges,
    required this.style,
  });

  final int length;
  final bool obscureText;
  final ValueChanged<String>? onCompleted;
  final String? errorText;
  final bool notifyOnProgrammaticChanges;
  final SmartOtpStyle style;
}

class SmartOtpField extends StatefulWidget {
  const SmartOtpField({
    super.key,
    required this.configuration,
    required this.source,
    required this.controller,
    required this.onChanged,
    required this.validator,
    required this.decoration,
  });

  final SmartOtpConfiguration configuration;
  final SmartField source;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final SmartValidator validator;
  final InputDecoration decoration;

  @override
  State<SmartOtpField> createState() => _SmartOtpFieldState();
}

class _SmartOtpFieldState extends State<SmartOtpField> {
  final GlobalKey<FormFieldState<String>> _formFieldKey = GlobalKey();
  final GlobalKey<EditableTextState> _editableKey = GlobalKey();
  final SmartInputHandle _input = SmartInputHandle();
  final SmartListenerGroup _listeners = SmartListenerGroup();
  late final SmartListenerBinding _controllerBinding = _listeners.add(
    _handleControllerChange,
  );
  late final SmartListenerBinding _focusBinding = _listeners.add(
    _handleFocusChange,
  );
  late String _initialValue;
  late String _lastText;
  bool _nextChangeIsUser = false;
  bool _composing = false;
  bool _wasComplete = false;
  String? _lastCompleted;
  bool _resetting = false;

  TextEditingController get _controller => _input.controller;

  FocusNode get _focusNode => _input.focusNode;

  bool get _enabled =>
      smartResolveEnabled(widget.source.enabled, widget.decoration);

  @override
  void initState() {
    super.initState();
    _input.update(
      controller: widget.controller,
      focusNode: widget.source.focusNode,
    );
    _initialValue = _controller.text;
    _lastText = _controller.text;
    _wasComplete = _isComplete(_lastText);
    _controllerBinding.bind(_controller);
    _focusBinding.bind(_focusNode);
  }

  @override
  void didUpdateWidget(covariant SmartOtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controllerChanged = oldWidget.controller != widget.controller;
    if (controllerChanged ||
        oldWidget.source.focusNode != widget.source.focusNode) {
      final previousValue = _controller.value;
      _listeners.unbindAll();
      _input.update(
        controller: widget.controller,
        focusNode: widget.source.focusNode,
        seed: previousValue,
      );
      _input.releaseUnused();
      if (controllerChanged) {
        _initialValue = _controller.text;
        _lastText = _controller.text;
        _wasComplete = _isComplete(_controller.text);
      }
      _controllerBinding.bind(_controller);
      _focusBinding.bind(_focusNode);
    }
    if (oldWidget.configuration.length != widget.configuration.length ||
        oldWidget.validator != widget.validator) {
      _wasComplete = _isComplete(_controller.text);
    }
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _markUserEdit() {
    _nextChangeIsUser = true;
  }

  void _handleControllerChange() {
    final value = _controller.value;
    if (_resetting) {
      _lastText = value.text;
      return;
    }
    if (smartIsComposing(value)) {
      _composing = true;
      _nextChangeIsUser = false;
      if (mounted) {
        setState(() {});
      }
      return;
    }
    final committedComposition = _composing;
    _composing = false;
    final textChanged = value.text != _lastText;
    if (!textChanged) {
      _nextChangeIsUser = false;
      if (mounted) {
        setState(() {});
      }
      return;
    }
    final isUserChange = _nextChangeIsUser || committedComposition;
    _nextChangeIsUser = false;
    _lastText = value.text;
    _formFieldKey.currentState?.didChange(value.text);
    if (isUserChange || widget.configuration.notifyOnProgrammaticChanges) {
      widget.onChanged?.call(value.text);
      _handleCompletion(value.text);
    } else {
      _wasComplete = _isComplete(value.text);
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _handleCompletion(String value) {
    final complete = _isComplete(value);
    if (complete && (!_wasComplete || value != _lastCompleted)) {
      _lastCompleted = value;
      widget.configuration.onCompleted?.call(value);
    }
    if (!complete) {
      _lastCompleted = null;
    }
    _wasComplete = complete;
  }

  bool _isComplete(String value) {
    return value.length == widget.configuration.length &&
        widget.validator(value) == null;
  }

  void _reset() {
    _resetting = true;
    try {
      _controller.value = TextEditingValue(
        text: _initialValue,
        selection: TextSelection.collapsed(offset: _initialValue.length),
      );
    } finally {
      _resetting = false;
    }
    _lastText = _initialValue;
    _wasComplete = _isComplete(_initialValue);
    if (mounted) {
      setState(() {});
    }
  }

  void _selectBox(int index) {
    if (!_enabled) {
      return;
    }
    final hadFocus = _focusNode.hasFocus;
    _focusNode.requestFocus();
    final target = _controller;
    final offset = math.min(index, target.text.length);
    target.selection = TextSelection.collapsed(offset: offset);
    if (hadFocus) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          identical(_controller, target) &&
          _focusNode.hasFocus &&
          offset <= target.text.length) {
        target.selection = TextSelection.collapsed(offset: offset);
      }
    });
  }

  Future<void> _showPasteMenu(Offset position) async {
    if (!_enabled || widget.source.readOnly) {
      return;
    }
    _focusNode.requestFocus();
    final label = MaterialLocalizations.of(context).pasteButtonLabel;
    final target = _controller;
    final selected = await showMenu<bool>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [PopupMenuItem<bool>(value: true, child: Text(label))],
    );
    if (selected != true ||
        !mounted ||
        !_enabled ||
        widget.source.readOnly ||
        !identical(_controller, target)) {
      return;
    }
    target.selection = TextSelection(
      baseOffset: 0,
      extentOffset: target.text.length,
    );
    await _editableKey.currentState?.pasteText(SelectionChangedCause.toolbar);
  }

  @override
  void dispose() {
    _listeners.unbindAll();
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final forcedError =
        widget.configuration.errorText ?? widget.decoration.errorText;
    return FormField<String>(
      key: _formFieldKey,
      initialValue: _initialValue,
      enabled: _enabled,
      forceErrorText: forcedError,
      validator: widget.validator,
      onSaved: widget.source.onSaved,
      onReset: _reset,
      autovalidateMode: widget.source.autovalidateMode,
      builder: (field) => _buildField(context, field),
    );
  }

  Widget _buildField(BuildContext context, FormFieldState<String> field) {
    final theme = Theme.of(context);
    final inputTheme = theme.inputDecorationTheme;
    final label = widget.decoration.labelText ?? widget.source.label;
    final hint = widget.decoration.hintText ?? widget.source.hintText;
    final error = field.errorText;
    final labelStyle = widget.decoration.labelStyle ?? inputTheme.labelStyle;
    final helperStyle = widget.decoration.hintStyle ?? inputTheme.hintStyle;
    final errorStyle = widget.decoration.errorStyle ?? inputTheme.errorStyle;
    return MergeSemantics(
      child: Semantics(
        label: label,
        hint: hint,
        enabled: _enabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != null) ...[
              ExcludeSemantics(
                child: Text(
                  label,
                  style: labelStyle ?? theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 8),
            ],
            _buildInput(context, error != null),
            if (hint != null && _controller.text.isEmpty && error == null) ...[
              const SizedBox(height: 6),
              Text(hint, style: helperStyle ?? theme.textTheme.bodySmall),
            ],
            if (error != null) ...[
              const SizedBox(height: 6),
              Semantics(
                liveRegion: true,
                child: Text(
                  error,
                  style:
                      errorStyle ??
                      theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInput(BuildContext context, bool hasError) {
    final style = widget.configuration.style;
    final textStyle =
        style.textStyle ??
        Theme.of(context).textTheme.titleLarge ??
        const TextStyle();
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : style.boxWidth * widget.configuration.length +
                  style.spacing * (widget.configuration.length - 1);
        final gaps = math.max(0, widget.configuration.length - 1);
        final maxSpacing = gaps == 0
            ? 0.0
            : math.max(0.0, (available - widget.configuration.length) / gaps);
        final spacing = math.min(style.spacing, maxSpacing);
        final spacingTotal = spacing * gaps;
        final width = math.min(
          style.boxWidth,
          math.max(
            1.0,
            (available - spacingTotal) / widget.configuration.length,
          ),
        );
        return SizedBox(
          height: style.boxHeight,
          width: available,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ExcludeFocus(
                excluding: !_enabled,
                child: EditableText(
                  key: _editableKey,
                  controller: _controller,
                  focusNode: _focusNode,
                  readOnly: widget.source.readOnly || !_enabled,
                  obscureText: widget.configuration.obscureText,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofocus: widget.source.autofocus,
                  keyboardType: TextInputType.number,
                  textInputAction:
                      widget.source.textInputAction ?? TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  textDirection: TextDirection.ltr,
                  inputFormatters: [
                    _SmartOtpInputFormatter(
                      length: widget.configuration.length,
                      onAccepted: _markUserEdit,
                    ),
                  ],
                  style: textStyle.copyWith(color: Colors.transparent),
                  cursorColor: Colors.transparent,
                  backgroundCursorColor: Colors.transparent,
                  selectionColor: Colors.transparent,
                  showCursor: false,
                ),
              ),
              ExcludeSemantics(
                child: Row(
                  textDirection: TextDirection.ltr,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.configuration.length, (index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        right: index == widget.configuration.length - 1
                            ? 0
                            : spacing,
                      ),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _selectBox(index),
                        onLongPressStart: (details) =>
                            _showPasteMenu(details.globalPosition),
                        child: _buildBox(
                          context,
                          index,
                          width,
                          hasError,
                          textStyle,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBox(
    BuildContext context,
    int index,
    double width,
    bool hasError,
    TextStyle textStyle,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final style = widget.configuration.style;
    final text = _controller.text;
    final isFilled = index < text.length;
    final selectionOffset = _controller.selection.isValid
        ? _controller.selection.extentOffset
        : text.length;
    final focusedIndex = math.min(
      math.max(selectionOffset, 0),
      widget.configuration.length - 1,
    );
    final isFocused = _focusNode.hasFocus && focusedIndex == index;
    final borderColor = !_enabled
        ? style.disabledBorderColor ?? colors.outline.withValues(alpha: 0.38)
        : hasError
        ? style.errorBorderColor ?? colors.error
        : isFocused
        ? style.focusedBorderColor ?? colors.primary
        : isFilled
        ? style.filledBorderColor ?? colors.outline
        : style.borderColor ?? colors.outlineVariant;
    final fillColor = !_enabled
        ? style.disabledFillColor ??
              colors.surfaceContainerHighest.withValues(alpha: 0.38)
        : hasError
        ? style.errorFillColor ?? colors.errorContainer.withValues(alpha: 0.18)
        : isFocused
        ? style.focusedFillColor ??
              colors.primaryContainer.withValues(alpha: 0.12)
        : isFilled
        ? style.filledFillColor ??
              colors.surfaceContainerHighest.withValues(alpha: 0.4)
        : style.fillColor ?? colors.surface;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : style.animationDuration;
    final value = isFilled
        ? widget.configuration.obscureText
              ? '•'
              : text[index]
        : '';
    return AnimatedContainer(
      duration: duration,
      curve: style.animationCurve,
      width: width,
      height: style.boxHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: style.borderRadius,
        border: Border.all(
          color: borderColor,
          width: isFocused ? style.focusedBorderWidth : style.borderWidth,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: value.isEmpty && isFocused && !widget.source.readOnly
            ? Container(
                width: 2,
                height: (textStyle.fontSize ?? 20) * 1.15,
                color: style.cursorColor ?? colors.primary,
              )
            : Text(value, style: textStyle),
      ),
    );
  }
}

class _SmartOtpInputFormatter extends TextInputFormatter {
  _SmartOtpInputFormatter({required this.length, required this.onAccepted});

  final int length;
  final VoidCallback onAccepted;

  static final RegExp _separators = RegExp(r'[ \-\u00a0]');
  static final RegExp _digits = RegExp(r'^[0-9]*$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (smartIsComposing(newValue)) {
      return newValue;
    }
    final stripped = newValue.text.replaceAll(_separators, '');
    if (!_digits.hasMatch(stripped)) {
      return smartBeforeComposition(oldValue);
    }
    var result = stripped == newValue.text
        ? newValue
        : TextEditingValue(
            text: stripped,
            selection: TextSelection.collapsed(offset: stripped.length),
          );
    final wasOversized = oldValue.text.length > length;
    final reducesOversizedValue =
        wasOversized && result.text.length < oldValue.text.length;
    if (result.text.length > length && !reducesOversizedValue) {
      final caret = oldValue.selection.isValid && oldValue.selection.isCollapsed
          ? oldValue.selection.baseOffset
          : -1;
      final typedOne =
          oldValue.text.length == length &&
          result.text.length == length + 1 &&
          caret >= 0 &&
          result.selection.isCollapsed &&
          result.selection.baseOffset == caret + 1 &&
          result.text.substring(0, caret) ==
              oldValue.text.substring(0, caret) &&
          result.text.substring(caret + 1) == oldValue.text.substring(caret);
      if (typedOne && caret < length) {
        final text =
            oldValue.text.substring(0, caret) +
            result.text[caret] +
            oldValue.text.substring(caret + 1);
        result = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: caret + 1),
        );
      } else if (typedOne) {
        return oldValue;
      } else {
        result = TextEditingValue(
          text: result.text.substring(0, length),
          selection: TextSelection.collapsed(offset: length),
        );
      }
    }
    if (result != oldValue) {
      onAccepted();
    }
    return result;
  }
}
