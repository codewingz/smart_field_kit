import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_field_kit/src/formatting/smart_date_utils.dart';
import 'package:smart_field_kit/src/formatting/smart_input_mask.dart';
import 'package:smart_field_kit/src/validation/smart_async_validation.dart';
import 'package:smart_field_kit/src/validation/smart_validators.dart';
import 'package:smart_field_kit/src/widgets/smart_field.dart';
import 'package:smart_field_kit/src/widgets/smart_field_design.dart';
import 'package:smart_field_kit/src/widgets/smart_field_support.dart';
import 'package:smart_field_kit/src/widgets/smart_listener_binding.dart';

enum SmartDateMode { manual, calendar, dropdowns, wheel }

enum SmartTimeMode { manual, picker, wheel }

enum SmartDateRestriction { none, pastOnly, futureOnly }

enum SmartDateTimeKind { date, time, dateTime }

const List<String> smartEnglishMonthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

final class SmartDateTimeConfig {
  SmartDateTimeConfig({
    required this.kind,
    this.dateMode = SmartDateMode.manual,
    this.timeMode = SmartTimeMode.manual,
    SmartDateFormat? dateFormat,
    this.timeFormat = const SmartTimeFormat(),
    this.minDate,
    this.maxDate,
    this.minTime,
    this.maxTime,
    this.restriction = SmartDateRestriction.none,
    this.initialDate,
    this.initialTime,
    this.now = DateTime.now,
    this.monthNames = smartEnglishMonthNames,
    this.showClearButton = false,
    this.invalidErrorText,
    this.incompleteErrorText = 'Select a complete date.',
    this.minErrorText,
    this.maxErrorText,
    this.pastErrorText = 'Choose a date in the past.',
    this.futureErrorText = 'Choose a date in the future.',
    this.onDateChanged,
    this.onTimeChanged,
    this.onDateTimeChanged,
    this.onRawChanged,
    this.onRawSaved,
    this.yearRange,
    this.pickerTooltip,
    this.clearLabel = 'Clear',
    this.dayLabel = 'Day',
    this.monthLabel = 'Month',
    this.yearLabel = 'Year',
    this.hourLabel = 'Hour',
    this.minuteLabel = 'Minute',
    this.periodLabel = 'AM or PM',
  }) : dateFormat = dateFormat ?? SmartDateFormat(),
       assert(monthNames.length == 12),
       assert(
         kind != SmartDateTimeKind.dateTime ||
             dateMode != SmartDateMode.dropdowns,
       ),
       assert(
         kind != SmartDateTimeKind.dateTime || timeMode != SmartTimeMode.wheel,
       ),
       assert(
         kind != SmartDateTimeKind.dateTime || dateMode != SmartDateMode.wheel,
       );

  final SmartDateTimeKind kind;
  final SmartDateMode dateMode;
  final SmartTimeMode timeMode;
  final SmartDateFormat dateFormat;
  final SmartTimeFormat timeFormat;
  final DateTime? minDate;
  final DateTime? maxDate;
  final TimeOfDay? minTime;
  final TimeOfDay? maxTime;
  final SmartDateRestriction restriction;
  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final DateTime Function() now;
  final List<String> monthNames;
  final bool showClearButton;
  final String? invalidErrorText;
  final String incompleteErrorText;
  final String? minErrorText;
  final String? maxErrorText;
  final String pastErrorText;
  final String futureErrorText;
  final ValueChanged<DateTime?>? onDateChanged;
  final ValueChanged<TimeOfDay?>? onTimeChanged;
  final ValueChanged<DateTime?>? onDateTimeChanged;
  final ValueChanged<String>? onRawChanged;
  final FormFieldSetter<String>? onRawSaved;
  final (int, int)? yearRange;
  final String? pickerTooltip;
  final String clearLabel;
  final String dayLabel;
  final String monthLabel;
  final String yearLabel;
  final String hourLabel;
  final String minuteLabel;
  final String periodLabel;

  bool get usesPicker {
    switch (kind) {
      case SmartDateTimeKind.date:
        return dateMode == SmartDateMode.calendar ||
            dateMode == SmartDateMode.wheel;
      case SmartDateTimeKind.time:
        return timeMode != SmartTimeMode.manual;
      case SmartDateTimeKind.dateTime:
        return timeMode != SmartTimeMode.manual ||
            dateMode != SmartDateMode.manual;
    }
  }

  bool get isManual => !usesPicker;

  String get displayPattern {
    switch (kind) {
      case SmartDateTimeKind.date:
        return dateFormat.pattern;
      case SmartDateTimeKind.time:
        return timeFormat.pattern;
      case SmartDateTimeKind.dateTime:
        return '${dateFormat.pattern} ${timeFormat.pattern}';
    }
  }

  String get maskPattern {
    switch (kind) {
      case SmartDateTimeKind.date:
        return dateFormat.inputMaskPattern;
      case SmartDateTimeKind.time:
        return timeFormat.inputMaskPattern;
      case SmartDateTimeKind.dateTime:
        return '${dateFormat.inputMaskPattern} ${timeFormat.inputMaskPattern}';
    }
  }

  int get _dateTextLength => dateFormat.format(DateTime(2000, 1, 1)).length;

  DateTime? parseDateTime(String text) {
    final length = _dateTextLength;
    if (text.length <= length + 1 || text[length] != ' ') {
      return null;
    }
    final date = dateFormat.tryParse(text.substring(0, length));
    final time = timeFormat.tryParse(text.substring(length + 1));
    if (date == null || time == null) {
      return null;
    }
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String formatDateTime(DateTime value) {
    return '${dateFormat.format(value)} '
        '${timeFormat.format(TimeOfDay(hour: value.hour, minute: value.minute))}';
  }

  Object? parse(String text) {
    switch (kind) {
      case SmartDateTimeKind.date:
        return dateFormat.tryParse(text);
      case SmartDateTimeKind.time:
        return timeFormat.tryParse(text);
      case SmartDateTimeKind.dateTime:
        return parseDateTime(text);
    }
  }

  String? serialize(String text) {
    final value = parse(text);
    if (value == null) {
      return null;
    }
    switch (kind) {
      case SmartDateTimeKind.date:
        return SmartDateUtils.toIsoDate(value as DateTime);
      case SmartDateTimeKind.time:
        return SmartDateUtils.toIsoTime(value as TimeOfDay);
      case SmartDateTimeKind.dateTime:
        return SmartDateUtils.toIsoDateTime(value as DateTime);
    }
  }

  String? validateValue(Object value) {
    final today = SmartDateUtils.dateOnly(now());
    switch (kind) {
      case SmartDateTimeKind.date:
        final date = value as DateTime;
        return _validateDate(date, today);
      case SmartDateTimeKind.time:
        final time = value as TimeOfDay;
        if (minTime != null && SmartDateUtils.compareTime(time, minTime!) < 0) {
          return minErrorText ??
              'Choose ${timeFormat.format(minTime!)} or later.';
        }
        if (maxTime != null && SmartDateUtils.compareTime(time, maxTime!) > 0) {
          return maxErrorText ??
              'Choose ${timeFormat.format(maxTime!)} or earlier.';
        }
        return null;
      case SmartDateTimeKind.dateTime:
        final dateTime = value as DateTime;
        final current = now();
        final minute = DateTime(
          current.year,
          current.month,
          current.day,
          current.hour,
          current.minute,
        );
        if (minDate != null && dateTime.isBefore(minDate!)) {
          return minErrorText ?? 'Choose ${formatDateTime(minDate!)} or later.';
        }
        if (maxDate != null && dateTime.isAfter(maxDate!)) {
          return maxErrorText ??
              'Choose ${formatDateTime(maxDate!)} or earlier.';
        }
        if (restriction == SmartDateRestriction.pastOnly &&
            !dateTime.isBefore(minute)) {
          return pastErrorText;
        }
        if (restriction == SmartDateRestriction.futureOnly &&
            !dateTime.isAfter(minute)) {
          return futureErrorText;
        }
        return null;
    }
  }

  String? _validateDate(DateTime date, DateTime today) {
    final min = minDate == null ? null : SmartDateUtils.dateOnly(minDate!);
    final max = maxDate == null ? null : SmartDateUtils.dateOnly(maxDate!);
    if (min != null && date.isBefore(min)) {
      return minErrorText ?? 'Choose ${dateFormat.format(min)} or later.';
    }
    if (max != null && date.isAfter(max)) {
      return maxErrorText ?? 'Choose ${dateFormat.format(max)} or earlier.';
    }
    if (restriction == SmartDateRestriction.pastOnly && !date.isBefore(today)) {
      return pastErrorText;
    }
    if (restriction == SmartDateRestriction.futureOnly &&
        !date.isAfter(today)) {
      return futureErrorText;
    }
    return null;
  }

  String get defaultInvalidText =>
      invalidErrorText ?? 'Enter a valid value ($displayPattern).';

  void notifyTyped(String text) {
    final value = parse(text);
    switch (kind) {
      case SmartDateTimeKind.date:
        onDateChanged?.call(value as DateTime?);
      case SmartDateTimeKind.time:
        onTimeChanged?.call(value as TimeOfDay?);
      case SmartDateTimeKind.dateTime:
        onDateTimeChanged?.call(value as DateTime?);
    }
  }
}

class SmartDateTimeField extends StatefulWidget {
  const SmartDateTimeField({
    super.key,
    required this.config,
    required this.source,
  });

  final SmartDateTimeConfig config;
  final SmartField source;

  @override
  State<SmartDateTimeField> createState() => _SmartDateTimeFieldState();
}

class _SmartDateTimeFieldState extends State<SmartDateTimeField> {
  late final SmartInputHandle _input = SmartInputHandle(
    initialText: _initialText(),
  );
  final SmartListenerGroup _listeners = SmartListenerGroup();
  late final SmartListenerBinding _textBinding = _listeners.add(
    _handleControllerChange,
  );
  late final SmartListenerBinding _serverBinding = _listeners.add(
    _handleServerChange,
  );
  final GlobalKey<FormFieldState<DateTime?>> _dropdownKey = GlobalKey();
  final Map<int, Offset> _pointerStarts = {};
  final Set<int> _suffixPointers = {};
  bool _writingController = false;
  SmartAsyncValidationEngine? _engine;
  int _pickerGeneration = 0;
  int _seedGeneration = 0;
  String? _seededText;
  DateTime? _resetBaseline;
  bool _dropdownFocused = false;
  final Map<String, List<DropdownMenuItem<int>>> _menuItems = {};

  List<DropdownMenuItem<int>> _cachedItems(
    String key,
    List<int> values,
    String Function(int value) labelOf,
  ) {
    return _menuItems.putIfAbsent(key, () {
      return [
        for (final value in values)
          DropdownMenuItem<int>(
            value: value,
            child: Text(labelOf(value), overflow: TextOverflow.ellipsis),
          ),
      ];
    });
  }

  void _clearParts(FormFieldState<DateTime?> state) {
    setState(() => _loadPartsFrom(null));
    state.didChange(null);
    widget.source.serverError?.notifyFieldChanged();
    _writeController('');
    _engine?.observe('');
    widget.source.onChanged?.call('');
    _config.onDateChanged?.call(null);
    _emitRaw(null);
  }

  int? _day;
  int? _month;
  int? _year;

  SmartDateTimeConfig get _config => widget.config;

  TextEditingController get _controller => _input.controller;

  bool get _enabled =>
      smartResolveEnabled(widget.source.enabled, widget.source.decoration);

  bool get _isDropdown =>
      _config.kind == SmartDateTimeKind.date &&
      _config.dateMode == SmartDateMode.dropdowns;

  @override
  void initState() {
    super.initState();
    _syncBindings();
    _scheduleInitialSeed();
    _loadPartsFromController();
    _resetBaseline = _composeDate();
    final initialText = _controller.text.isEmpty
        ? _initialText()
        : _controller.text;
    _lastRaw = _config.serialize(initialText);
  }

  void _scheduleInitialSeed() {
    final target = widget.source.controller;
    if (target == null || target.text.isNotEmpty) {
      return;
    }
    final initial = _initialText();
    if (initial.isEmpty) {
      return;
    }
    final generation = ++_seedGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          generation != _seedGeneration ||
          !identical(widget.source.controller, target) ||
          target.text.isNotEmpty) {
        return;
      }
      _writeController(initial);
      setState(() => _seededText = initial);
    });
  }

  void _restoreSeedAfterReset() {
    final seeded = _seededText;
    final target = widget.source.controller;
    if (seeded == null || target == null) {
      return;
    }
    scheduleMicrotask(() {
      if (mounted &&
          identical(widget.source.controller, target) &&
          target.text.isEmpty) {
        _writeController(seeded);
      }
    });
  }

  bool get _interactive => _enabled && !widget.source.readOnly;

  bool _isCurrentPick(int generation, TextEditingController target) {
    return mounted &&
        _interactive &&
        generation == _pickerGeneration &&
        identical(_controller, target);
  }

  @override
  void didUpdateWidget(covariant SmartDateTimeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controllerChanged = !identical(
      oldWidget.source.controller,
      widget.source.controller,
    );
    _syncBindings();
    if (controllerChanged ||
        !_interactive ||
        oldWidget.config.kind != _config.kind ||
        oldWidget.config.dateMode != _config.dateMode ||
        oldWidget.config.timeMode != _config.timeMode) {
      _pickerGeneration++;
    }
    if (controllerChanged) {
      _seedGeneration++;
      _seededText = null;
    }
    final wasDropdown =
        oldWidget.config.kind == SmartDateTimeKind.date &&
        oldWidget.config.dateMode == SmartDateMode.dropdowns;
    if (_isDropdown &&
        (!wasDropdown ||
            !identical(
              oldWidget.source.controller,
              widget.source.controller,
            ))) {
      _loadPartsFromController();
      _resetBaseline = _composeDate();
      scheduleMicrotask(() {
        if (mounted) {
          _dropdownKey.currentState?.didChange(_composeDate());
        }
      });
    }
  }

  void _syncBindings() {
    _textBinding.bind(null);
    _input.update(controller: widget.source.controller);
    _input.releaseUnused();
    _textBinding.bind(_controller);
    _serverBinding.bind(widget.source.serverError);
    _syncAsync();
  }

  void _syncAsync() {
    final config = _isDropdown ? widget.source.asyncValidation : null;
    if (config == null) {
      _engine?.dispose();
      _engine = null;
      return;
    }
    final engine = _engine ??= SmartAsyncValidationEngine(
      readText: _dropdownText,
      toRaw: _config.serialize,
      syncError: (_) => _syncPartsError(),
      isActive: () => mounted && _interactive,
      onUpdate: _asyncUpdated,
      onResultDropped: () {
        if (mounted) {
          _dropdownKey.currentState?.validate();
        }
      },
    );
    engine.configure(config);
  }

  void _asyncUpdated() {
    if (!mounted) {
      return;
    }
    setState(() {});
    final status = _engine?.status;
    if (status == SmartAsyncValidationStatus.valid ||
        status == SmartAsyncValidationStatus.invalid ||
        status == SmartAsyncValidationStatus.unavailable) {
      scheduleMicrotask(() {
        if (mounted) {
          _dropdownKey.currentState?.validate();
        }
      });
    }
  }

  String _dropdownText() {
    final value = _composeDate();
    return value == null ? '' : _config.dateFormat.format(value);
  }

  void _writeController(String text) {
    if (_controller.text == text) {
      return;
    }
    _writingController = true;
    try {
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    } finally {
      _writingController = false;
    }
  }

  void _loadPartsFromController() {
    final text = _controller.text;
    final parsed = _config.dateFormat.tryParse(text);
    if (parsed == null &&
        text.isEmpty &&
        _config.kind == SmartDateTimeKind.date &&
        widget.source.controller != null) {
      _loadPartsFrom(_config.initialDate);
      return;
    }
    _loadPartsFrom(parsed);
  }

  @override
  void dispose() {
    _pickerGeneration++;
    _seedGeneration++;
    _engine?.dispose();
    _engine = null;
    _listeners.unbindAll();
    _input.dispose();
    super.dispose();
  }

  String _initialText() {
    switch (_config.kind) {
      case SmartDateTimeKind.date:
        final date = _config.initialDate;
        return date == null ? '' : _config.dateFormat.format(date);
      case SmartDateTimeKind.time:
        final time = _config.initialTime;
        return time == null ? '' : _config.timeFormat.format(time);
      case SmartDateTimeKind.dateTime:
        final date = _config.initialDate;
        return date == null ? '' : _config.formatDateTime(date);
    }
  }

  void _loadPartsFrom(DateTime? date) {
    _day = date?.day;
    _month = date?.month;
    _year = date?.year;
  }

  void _handleControllerChange() {
    if (!mounted) {
      return;
    }
    if (_isDropdown && !_writingController) {
      final text = _controller.text;
      if (text != _dropdownText()) {
        _loadPartsFromController();
        _dropdownKey.currentState?.didChange(_composeDate());
        _engine?.observe(_dropdownText());
      }
    }
    setState(() {});
  }

  void _handleServerChange() {
    if (mounted) {
      setState(() {});
    }
  }

  String? _combine(String? value, String? Function() builtIn) {
    return SmartValidators.modeAware(
      mode: widget.source.validationMode,
      checks: widget.source.builtInChecks,
      builtIn: (_) => builtIn(),
      custom: widget.source.validator,
    )(value);
  }

  String? _validateText(String? value) {
    return _combine(value, () {
      if (value == null || value.isEmpty) {
        return null;
      }
      final parsed = _config.parse(value);
      if (parsed == null) {
        return _config.defaultInvalidText;
      }
      return _config.validateValue(parsed);
    });
  }

  void _onTextChanged(String text) {
    widget.source.onChanged?.call(text);
    _config.notifyTyped(text);
    _emitRaw(_config.serialize(text));
  }

  String? _lastRaw;

  void _emitRaw(String? raw) {
    if (raw != null) {
      _lastRaw = raw;
      _config.onRawChanged?.call(raw);
    } else if (_lastRaw != null && _lastRaw!.isNotEmpty) {
      _lastRaw = '';
      _config.onRawChanged?.call('');
    }
  }

  void _applyText(String text) {
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    widget.source.serverError?.notifyFieldChanged();
    _onTextChanged(text);
  }

  void _clear() {
    _controller.clear();
    widget.source.serverError?.notifyFieldChanged();
    widget.source.onChanged?.call('');
    switch (_config.kind) {
      case SmartDateTimeKind.date:
        _config.onDateChanged?.call(null);
      case SmartDateTimeKind.time:
        _config.onTimeChanged?.call(null);
      case SmartDateTimeKind.dateTime:
        _config.onDateTimeChanged?.call(null);
    }
    _emitRaw(null);
  }

  DateTime _clampDate(DateTime value, DateTime first, DateTime last) {
    if (value.isBefore(first)) {
      return first;
    }
    if (value.isAfter(last)) {
      return last;
    }
    return value;
  }

  ({DateTime first, DateTime last}) _dateBounds() {
    final today = SmartDateUtils.dateOnly(_config.now());
    var first = _config.minDate == null
        ? DateTime(1900)
        : SmartDateUtils.dateOnly(_config.minDate!);
    var last = _config.maxDate == null
        ? DateTime(2100, 12, 31)
        : SmartDateUtils.dateOnly(_config.maxDate!);
    final includesToday = _config.kind == SmartDateTimeKind.dateTime;
    if (_config.restriction == SmartDateRestriction.pastOnly) {
      final limit = includesToday
          ? today
          : today.subtract(const Duration(days: 1));
      if (limit.isBefore(last)) {
        last = limit;
      }
    } else if (_config.restriction == SmartDateRestriction.futureOnly) {
      final limit = includesToday
          ? today
          : DateTime(today.year, today.month, today.day + 1);
      if (limit.isAfter(first)) {
        first = limit;
      }
    }
    if (last.isBefore(first)) {
      last = first;
    }
    return (first: first, last: last);
  }

  Future<void> _openPicker() async {
    if (!_interactive) {
      return;
    }
    final generation = ++_pickerGeneration;
    final target = _controller;
    final config = _config;
    switch (config.kind) {
      case SmartDateTimeKind.date:
        final picked = config.dateMode == SmartDateMode.wheel
            ? await _pickWheelDate()
            : await _pickCalendarDate();
        if (picked != null && _isCurrentPick(generation, target)) {
          _applyText(_config.dateFormat.format(picked));
        }
      case SmartDateTimeKind.time:
        final picked = config.timeMode == SmartTimeMode.wheel
            ? await _pickWheelTime()
            : await _pickClockTime();
        if (picked != null && _isCurrentPick(generation, target)) {
          _applyText(_config.timeFormat.format(picked));
        }
      case SmartDateTimeKind.dateTime:
        final date = await _pickCalendarDate();
        if (date == null || !_isCurrentPick(generation, target)) {
          return;
        }
        final time = await _pickClockTime();
        if (time == null || !_isCurrentPick(generation, target)) {
          return;
        }
        _applyText(
          _config.formatDateTime(
            DateTime(date.year, date.month, date.day, time.hour, time.minute),
          ),
        );
    }
  }

  DateTime? _currentDate() {
    final text = _controller.text;
    final parsed = _config.parse(text);
    if (parsed is DateTime) {
      return SmartDateUtils.dateOnly(parsed);
    }
    return _config.initialDate == null
        ? null
        : SmartDateUtils.dateOnly(_config.initialDate!);
  }

  TimeOfDay _currentTime() {
    final parsed = _config.parse(_controller.text);
    if (parsed is TimeOfDay) {
      return parsed;
    }
    if (parsed is DateTime) {
      return TimeOfDay(hour: parsed.hour, minute: parsed.minute);
    }
    return _config.initialTime ?? TimeOfDay.fromDateTime(_config.now());
  }

  Future<DateTime?> _pickCalendarDate() {
    final bounds = _dateBounds();
    final initial = _clampDate(
      _currentDate() ?? SmartDateUtils.dateOnly(_config.now()),
      bounds.first,
      bounds.last,
    );
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: bounds.first,
      lastDate: bounds.last,
    );
  }

  Future<TimeOfDay?> _pickClockTime() {
    return showTimePicker(
      context: context,
      initialTime: _currentTime(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(alwaysUse24HourFormat: _config.timeFormat.use24Hour),
          child: child!,
        );
      },
    );
  }

  Future<DateTime?> _pickWheelDate() {
    final bounds = _dateBounds();
    final initial = _clampDate(
      _currentDate() ?? SmartDateUtils.dateOnly(_config.now()),
      bounds.first,
      bounds.last,
    );
    return showModalBottomSheet<DateTime>(
      context: context,
      builder: (context) => _DateWheelSheet(
        initial: initial,
        firstYear: _config.yearRange?.$1 ?? bounds.first.year,
        lastYear: _config.yearRange?.$2 ?? bounds.last.year,
        monthNames: _config.monthNames,
        dayLabel: _config.dayLabel,
        monthLabel: _config.monthLabel,
        yearLabel: _config.yearLabel,
      ),
    );
  }

  Future<TimeOfDay?> _pickWheelTime() {
    return showModalBottomSheet<TimeOfDay>(
      context: context,
      builder: (context) => _TimeWheelSheet(
        initial: _currentTime(),
        use24Hour: _config.timeFormat.use24Hour,
        hourLabel: _config.hourLabel,
        minuteLabel: _config.minuteLabel,
        periodLabel: _config.periodLabel,
      ),
    );
  }

  Widget? _suffix() {
    final children = <Widget>[];
    final existing = widget.source.decoration.suffixIcon;
    if (existing != null) {
      children.add(existing);
    }
    if (_config.showClearButton &&
        _controller.text.isNotEmpty &&
        _enabled &&
        !widget.source.readOnly) {
      children.add(
        smartClearButton(tooltip: _config.clearLabel, onPressed: _clear),
      );
    }
    if (_config.usesPicker) {
      final isTime = _config.kind == SmartDateTimeKind.time;
      children.add(
        IconButton(
          tooltip:
              _config.pickerTooltip ?? (isTime ? 'Choose time' : 'Choose date'),
          onPressed: _interactive ? _openPicker : null,
          icon: Icon(isTime ? Icons.access_time : Icons.calendar_today),
        ),
      );
    }
    final composed = composeSuffixActions(children);
    if (composed == null || !_config.usesPicker) {
      return composed;
    }
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) => _suffixPointers.add(event.pointer),
      child: composed,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDropdown) {
      return _buildDropdowns(context);
    }
    final decoration = widget.source.decoration.copyWith(suffixIcon: _suffix());
    final Widget field = SmartLtrContentScope(
      child: _withSeedReset(_buildTextField(decoration)),
    );
    if (!_config.usesPicker) {
      return field;
    }
    final canOpen = _interactive;
    return SmartPickerScope(
      interactive: canOpen,
      child: _buildPicker(canOpen, field),
    );
  }

  Widget _withSeedReset(Widget field) {
    if (widget.source.controller == null || _initialText().isEmpty) {
      return field;
    }
    return FormField<String>(
      onReset: _restoreSeedAfterReset,
      builder: (_) => field,
    );
  }

  Widget _buildTextField(InputDecoration decoration) {
    return SmartField.text(
      label: widget.source.label,
      hintText: widget.source.hintText ?? _config.displayPattern,
      controller: _controller,
      focusNode: widget.source.focusNode,
      autofocus: widget.source.autofocus,
      enabled: widget.source.enabled,
      readOnly: widget.source.readOnly || _config.usesPicker,
      keyboardType: TextInputType.datetime,
      textInputAction: widget.source.textInputAction,
      onChanged: _onTextChanged,
      onSaved: widget.source.onSaved,
      onRawSaved: _config.onRawSaved,
      isRequired: widget.source.isRequired,
      requiredErrorText: widget.source.requiredErrorText,
      validator: _validateText,
      autovalidateMode: widget.source.autovalidateMode,
      asyncValidation: widget.source.asyncValidation,
      serverError: widget.source.serverError,
      decoration: decoration,
      rawValueBuilder: _config.serialize,
      inputFormatters: _config.isManual
          ? [SmartMaskFormatter(SmartInputMask(_config.maskPattern))]
          : null,
    );
  }

  Widget _buildPicker(bool canOpen, Widget field) {
    return Semantics(
      onTap: canOpen ? _openPicker : null,
      child: smartPassiveFocus(
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent || !canOpen) {
            return KeyEventResult.ignored;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter ||
              event.logicalKey == LogicalKeyboardKey.space) {
            _openPicker();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) =>
              _pointerStarts[event.pointer] = event.position,
          onPointerCancel: (event) {
            _pointerStarts.remove(event.pointer);
            _suffixPointers.remove(event.pointer);
          },
          onPointerUp: (event) {
            final start = _pointerStarts.remove(event.pointer);
            final onSuffix = _suffixPointers.remove(event.pointer);
            if (start != null &&
                !onSuffix &&
                (event.position - start).distance < kTouchSlop) {
              _openPicker();
            }
          },
          child: field,
        ),
      ),
    );
  }

  DateTime? _composeDate() {
    final year = _year;
    final month = _month;
    final day = _day;
    if (year == null ||
        month == null ||
        day == null ||
        !SmartDateUtils.isValidDate(year, month, day)) {
      return null;
    }
    return DateTime(year, month, day);
  }

  String? _validateParts(DateTime? ignored) {
    return _syncPartsError() ?? _engine?.errorFor(_dropdownText());
  }

  String? _syncPartsError() {
    final value = _composeDate();
    final anySet = _day != null || _month != null || _year != null;
    if (!anySet) {
      final raw = _controller.text;
      if (raw.isNotEmpty && _config.dateFormat.tryParse(raw) == null) {
        return _config.defaultInvalidText;
      }
      if (widget.source.isRequired) {
        return widget.source.requiredErrorText;
      }
      return _combine(null, () => null);
    }
    if (value == null) {
      return _config.incompleteErrorText;
    }
    final range = _config.yearRange;
    if (range != null && (value.year < range.$1 || value.year > range.$2)) {
      return _combine(
        _config.dateFormat.format(value),
        () => _config.defaultInvalidText,
      );
    }
    return _combine(_config.dateFormat.format(value), () {
      return _config.validateValue(value);
    });
  }

  void _setPart(
    FormFieldState<DateTime?> state, {
    int? day,
    int? month,
    int? year,
  }) {
    setState(() {
      if (day != null) {
        _day = day;
      }
      if (month != null) {
        _month = month;
      }
      if (year != null) {
        _year = year;
      }
      final y = _year;
      final m = _month;
      if (_day != null &&
          m != null &&
          _day! > SmartDateUtils.daysInMonth(y ?? 2000, m)) {
        _day = null;
      }
    });
    final value = _composeDate();
    state.didChange(value);
    widget.source.serverError?.notifyFieldChanged();
    final text = value == null ? '' : _config.dateFormat.format(value);
    _writeController(text);
    _engine?.observe(text);
    widget.source.onChanged?.call(text);
    _config.onDateChanged?.call(value);
    _emitRaw(value == null ? null : SmartDateUtils.toIsoDate(value));
  }

  Widget _buildDropdowns(BuildContext context) {
    final bounds = _dateBounds();
    final firstYear = _config.yearRange?.$1 ?? bounds.first.year;
    final lastYear = _config.yearRange?.$2 ?? bounds.last.year;
    final years = [for (var y = firstYear; y <= lastYear; y++) y];
    final selectedYear = _year;
    if (selectedYear != null && !years.contains(selectedYear)) {
      years
        ..add(selectedYear)
        ..sort();
    }
    final maxDay = _month == null
        ? 31
        : SmartDateUtils.daysInMonth(_year ?? 2000, _month!);
    final interactive = _interactive;
    final days = [for (var d = 1; d <= maxDay; d++) d];
    final selectedDay = _day;
    if (selectedDay != null && !days.contains(selectedDay)) {
      days.add(selectedDay);
    }
    return smartPassiveFocus(
      onFocusChange: (focused) {
        if (mounted && focused != _dropdownFocused) {
          setState(() => _dropdownFocused = focused);
        }
        if (!focused) {
          _engine?.focusLost();
        }
      },
      child: FormField<DateTime?>(
        key: _dropdownKey,
        initialValue: _resetBaseline,
        enabled: _enabled,
        autovalidateMode: widget.source.autovalidateMode,
        forceErrorText: widget.source.serverError?.errorText,
        validator: _validateParts,
        onSaved: (value) {
          widget.source.onSaved?.call(
            value == null ? null : _config.dateFormat.format(value),
          );
          _config.onRawSaved?.call(
            value == null ? null : SmartDateUtils.toIsoDate(value),
          );
        },
        onReset: () {
          setState(() => _loadPartsFrom(_resetBaseline));
          _writeController(_dropdownText());
          _engine?.reset();
        },
        builder: (state) {
          Widget dropdown({
            required int flex,
            required String hint,
            required int? value,
            required List<DropdownMenuItem<int>> items,
            required ValueChanged<int?> onChanged,
          }) {
            return Expanded(
              flex: flex,
              child: Semantics(
                label: value == null ? null : hint,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    hint: Text(hint),
                    value: value,
                    items: items,
                    onChanged: interactive ? onChanged : null,
                  ),
                ),
              ),
            );
          }

          final source = widget.source.decoration;
          final compact =
              source.contentPadding == null &&
              Theme.of(context).inputDecorationTheme.contentPadding == null &&
              !(source.isCollapsed ?? false);
          final anySet = _day != null || _month != null || _year != null;
          final suffix = composeSuffixActions([
            ?source.suffixIcon,
            if (_config.showClearButton && anySet && interactive)
              smartClearButton(
                tooltip: _config.clearLabel,
                onPressed: () => _clearParts(state),
              ),
          ]);
          final decoration = SmartFieldDesign.resolve(
            context,
            source.copyWith(
              labelText: widget.source.label,
              errorText: state.errorText,
              enabled: _enabled,
              suffixIcon: suffix,
              contentPadding: compact
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
                  : null,
            ),
          );
          final monthNames = _config.monthNames;
          return InputDecorator(
            decoration: decoration,
            isEmpty: false,
            isFocused: _dropdownFocused,
            child: Row(
              children: [
                dropdown(
                  flex: 3,
                  hint: _config.dayLabel,
                  value: _day,
                  items: _cachedItems(
                    'd:${days.join(',')}',
                    days,
                    (value) => value.toString(),
                  ),
                  onChanged: (value) => _setPart(state, day: value),
                ),
                const SizedBox(width: 8),
                dropdown(
                  flex: 5,
                  hint: _config.monthLabel,
                  value: _month,
                  items: _cachedItems('m:${monthNames.join('|')}', const [
                    1,
                    2,
                    3,
                    4,
                    5,
                    6,
                    7,
                    8,
                    9,
                    10,
                    11,
                    12,
                  ], (value) => monthNames[value - 1]),
                  onChanged: (value) => _setPart(state, month: value),
                ),
                const SizedBox(width: 8),
                dropdown(
                  flex: 4,
                  hint: _config.yearLabel,
                  value: _year,
                  items: _cachedItems(
                    'y:${years.first}-${years.last}-${years.length}',
                    years,
                    (value) => value.toString(),
                  ),
                  onChanged: (value) => _setPart(state, year: value),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WheelColumn extends StatelessWidget {
  const _WheelColumn({
    required this.label,
    required this.items,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final List<String> items;
  final FixedExtentScrollController controller;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        label: label,
        child: CupertinoPicker(
          scrollController: controller,
          itemExtent: 36,
          onSelectedItemChanged: onChanged,
          children: [
            for (final item in items)
              Center(
                child: Text(
                  item,
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.children,
    required this.onCancel,
    required this.onDone,
  });

  final List<Widget> children;
  final VoidCallback onCancel;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: onCancel,
                child: Text(localizations.cancelButtonLabel),
              ),
              TextButton(
                onPressed: onDone,
                child: Text(localizations.okButtonLabel),
              ),
            ],
          ),
          SizedBox(
            height: 180,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(children: children),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateWheelSheet extends StatefulWidget {
  const _DateWheelSheet({
    required this.initial,
    required this.firstYear,
    required this.lastYear,
    required this.monthNames,
    required this.dayLabel,
    required this.monthLabel,
    required this.yearLabel,
  });

  final DateTime initial;
  final int firstYear;
  final int lastYear;
  final List<String> monthNames;
  final String dayLabel;
  final String monthLabel;
  final String yearLabel;

  @override
  State<_DateWheelSheet> createState() => _DateWheelSheetState();
}

class _DateWheelSheetState extends State<_DateWheelSheet> {
  late int _day = widget.initial.day;
  late int _month = widget.initial.month;
  late int _year = widget.initial.year.clamp(widget.firstYear, widget.lastYear);
  late final FixedExtentScrollController _dayController =
      FixedExtentScrollController(initialItem: _day - 1);
  late final FixedExtentScrollController _monthController =
      FixedExtentScrollController(initialItem: _month - 1);
  late final FixedExtentScrollController _yearController =
      FixedExtentScrollController(initialItem: _year - widget.firstYear);

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _clampDay() {
    final max = SmartDateUtils.daysInMonth(_year, _month);
    if (_day > max) {
      _day = max;
      _dayController.jumpToItem(max - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = SmartDateUtils.daysInMonth(_year, _month);
    return _SheetFrame(
      onCancel: () => Navigator.of(context).pop(),
      onDone: () => Navigator.of(context).pop(DateTime(_year, _month, _day)),
      children: [
        _WheelColumn(
          label: widget.dayLabel,
          items: [for (var d = 1; d <= days; d++) d.toString()],
          controller: _dayController,
          onChanged: (index) => _day = index + 1,
        ),
        _WheelColumn(
          label: widget.monthLabel,
          items: widget.monthNames,
          controller: _monthController,
          onChanged: (index) => setState(() {
            _month = index + 1;
            _clampDay();
          }),
        ),
        _WheelColumn(
          label: widget.yearLabel,
          items: [
            for (var y = widget.firstYear; y <= widget.lastYear; y++)
              y.toString(),
          ],
          controller: _yearController,
          onChanged: (index) => setState(() {
            _year = widget.firstYear + index;
            _clampDay();
          }),
        ),
      ],
    );
  }
}

class _TimeWheelSheet extends StatefulWidget {
  const _TimeWheelSheet({
    required this.initial,
    required this.use24Hour,
    required this.hourLabel,
    required this.minuteLabel,
    required this.periodLabel,
  });

  final TimeOfDay initial;
  final bool use24Hour;
  final String hourLabel;
  final String minuteLabel;
  final String periodLabel;

  @override
  State<_TimeWheelSheet> createState() => _TimeWheelSheetState();
}

class _TimeWheelSheetState extends State<_TimeWheelSheet> {
  late int _hour = widget.use24Hour
      ? widget.initial.hour
      : (widget.initial.hour % 12 == 0 ? 12 : widget.initial.hour % 12);
  late int _minute = widget.initial.minute;
  late bool _pm = widget.initial.hour >= 12;
  late final FixedExtentScrollController _hourController =
      FixedExtentScrollController(
        initialItem: widget.use24Hour ? _hour : _hour - 1,
      );
  late final FixedExtentScrollController _minuteController =
      FixedExtentScrollController(initialItem: _minute);
  late final FixedExtentScrollController _periodController =
      FixedExtentScrollController(initialItem: _pm ? 1 : 0);

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  TimeOfDay get _result {
    if (widget.use24Hour) {
      return TimeOfDay(hour: _hour, minute: _minute);
    }
    return TimeOfDay(hour: _hour % 12 + (_pm ? 12 : 0), minute: _minute);
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      onCancel: () => Navigator.of(context).pop(),
      onDone: () => Navigator.of(context).pop(_result),
      children: [
        _WheelColumn(
          label: widget.hourLabel,
          items: widget.use24Hour
              ? [for (var h = 0; h < 24; h++) h.toString().padLeft(2, '0')]
              : [for (var h = 1; h <= 12; h++) h.toString().padLeft(2, '0')],
          controller: _hourController,
          onChanged: (index) => _hour = widget.use24Hour ? index : index + 1,
        ),
        _WheelColumn(
          label: widget.minuteLabel,
          items: [for (var m = 0; m < 60; m++) m.toString().padLeft(2, '0')],
          controller: _minuteController,
          onChanged: (index) => _minute = index,
        ),
        if (!widget.use24Hour)
          _WheelColumn(
            label: widget.periodLabel,
            items: const ['AM', 'PM'],
            controller: _periodController,
            onChanged: (index) => _pm = index == 1,
          ),
      ],
    );
  }
}
