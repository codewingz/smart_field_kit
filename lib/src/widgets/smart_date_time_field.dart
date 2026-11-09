import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smart_field_kit/src/formatting/smart_date_utils.dart';
import 'package:smart_field_kit/src/formatting/smart_input_mask.dart';
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
    final raw = serialize(text);
    if (raw != null) {
      onRawChanged?.call(raw);
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
  int? _day;
  int? _month;
  int? _year;

  SmartDateTimeConfig get _config => widget.config;

  TextEditingController get _controller => _input.controller;

  bool get _enabled =>
      widget.source.enabled ?? widget.source.decoration.enabled;

  bool get _isDropdown =>
      _config.kind == SmartDateTimeKind.date &&
      _config.dateMode == SmartDateMode.dropdowns;

  @override
  void initState() {
    super.initState();
    _syncBindings();
    if (widget.source.controller != null &&
        widget.source.controller!.text.isEmpty) {
      final initial = _initialText();
      if (initial.isNotEmpty) {
        widget.source.controller!.text = initial;
      }
    }
    _loadPartsFrom(_config.initialDate);
  }

  @override
  void didUpdateWidget(covariant SmartDateTimeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncBindings();
  }

  void _syncBindings() {
    _textBinding.bind(null);
    _input.update(controller: widget.source.controller);
    _input.releaseUnused();
    _textBinding.bind(_controller);
    _serverBinding.bind(widget.source.serverError);
  }

  @override
  void dispose() {
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
    if (mounted) {
      setState(() {});
    }
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
    if (_config.restriction == SmartDateRestriction.pastOnly) {
      final yesterday = today.subtract(const Duration(days: 1));
      if (yesterday.isBefore(last)) {
        last = yesterday;
      }
    } else if (_config.restriction == SmartDateRestriction.futureOnly) {
      final tomorrow = DateTime(today.year, today.month, today.day + 1);
      if (tomorrow.isAfter(first)) {
        first = tomorrow;
      }
    }
    if (last.isBefore(first)) {
      last = first;
    }
    return (first: first, last: last);
  }

  Future<void> _openPicker() async {
    if (!_enabled || widget.source.readOnly) {
      return;
    }
    switch (_config.kind) {
      case SmartDateTimeKind.date:
        final picked = _config.dateMode == SmartDateMode.wheel
            ? await _pickWheelDate()
            : await _pickCalendarDate();
        if (picked != null && mounted) {
          _applyText(_config.dateFormat.format(picked));
        }
      case SmartDateTimeKind.time:
        final picked = _config.timeMode == SmartTimeMode.wheel
            ? await _pickWheelTime()
            : await _pickClockTime();
        if (picked != null && mounted) {
          _applyText(_config.timeFormat.format(picked));
        }
      case SmartDateTimeKind.dateTime:
        final date = await _pickCalendarDate();
        if (date == null || !mounted) {
          return;
        }
        final time = await _pickClockTime();
        if (time == null || !mounted) {
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
          data: MediaQuery.of(context)
              .copyWith(alwaysUse24HourFormat: _config.timeFormat.use24Hour),
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
      ),
    );
  }

  Future<TimeOfDay?> _pickWheelTime() {
    return showModalBottomSheet<TimeOfDay>(
      context: context,
      builder: (context) => _TimeWheelSheet(
        initial: _currentTime(),
        use24Hour: _config.timeFormat.use24Hour,
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
        IconButton(
          tooltip: 'Clear',
          onPressed: _clear,
          icon: const Icon(Icons.clear),
        ),
      );
    }
    if (_config.usesPicker) {
      final isTime = _config.kind == SmartDateTimeKind.time;
      children.add(
        IconButton(
          tooltip:
              _config.pickerTooltip ?? (isTime ? 'Choose time' : 'Choose date'),
          onPressed: _enabled && !widget.source.readOnly ? _openPicker : null,
          icon: Icon(isTime ? Icons.access_time : Icons.calendar_today),
        ),
      );
    }
    return composeSuffixActions(children);
  }

  @override
  Widget build(BuildContext context) {
    if (_isDropdown) {
      return _buildDropdowns(context);
    }
    final decoration = widget.source.decoration.copyWith(suffixIcon: _suffix());
    final field = SmartField.text(
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
    if (!_config.usesPicker) {
      return field;
    }
    return Semantics(
      container: true,
      button: true,
      enabled: _enabled && !widget.source.readOnly,
      label: widget.source.label,
      value: _controller.text,
      onTap: _enabled && !widget.source.readOnly ? _openPicker : null,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _enabled && !widget.source.readOnly ? _openPicker : null,
        child: AbsorbPointer(
          absorbing: true,
          child: ExcludeFocus(child: field),
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
    final value = _composeDate();
    final anySet = _day != null || _month != null || _year != null;
    if (!anySet) {
      if (widget.source.isRequired) {
        return widget.source.requiredErrorText;
      }
      return _combine(null, () => null);
    }
    if (value == null) {
      return _config.incompleteErrorText;
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
    widget.source.onChanged?.call(text);
    _config.onDateChanged?.call(value);
    if (value != null) {
      _config.onRawChanged?.call(SmartDateUtils.toIsoDate(value));
    }
  }

  Widget _buildDropdowns(BuildContext context) {
    final bounds = _dateBounds();
    final firstYear = _config.yearRange?.$1 ?? bounds.first.year;
    final lastYear = _config.yearRange?.$2 ?? bounds.last.year;
    final years = [for (var y = firstYear; y <= lastYear; y++) y];
    final maxDay = _month == null
        ? 31
        : SmartDateUtils.daysInMonth(_year ?? 2000, _month!);
    final days = [for (var d = 1; d <= maxDay; d++) d];
    return FormField<DateTime?>(
      key: _dropdownKey,
      initialValue: _config.initialDate == null
          ? null
          : SmartDateUtils.dateOnly(_config.initialDate!),
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
        setState(() => _loadPartsFrom(_config.initialDate));
      },
      builder: (state) {
        Widget dropdown<T>({
          required String hint,
          required T? value,
          required List<T> items,
          required String Function(T) labelOf,
          required ValueChanged<T?> onChanged,
        }) {
          return Expanded(
            child: Semantics(
              label: hint,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<T>(
                  isExpanded: true,
                  isDense: true,
                  hint: Text(hint),
                  value: value,
                  items: [
                    for (final item in items)
                      DropdownMenuItem<T>(
                        value: item,
                        child: Text(
                          labelOf(item),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _enabled && !widget.source.readOnly
                      ? onChanged
                      : null,
                ),
              ),
            ),
          );
        }

        final decoration = SmartFieldDesign.resolve(
          context,
          widget.source.decoration.copyWith(
            labelText: widget.source.label,
            errorText: state.errorText,
            enabled: _enabled,
          ),
        );
        return InputDecorator(
          decoration: decoration,
          isEmpty: false,
          child: Row(
            children: [
              dropdown<int>(
                hint: 'Day',
                value: _day,
                items: days,
                labelOf: (value) => value.toString(),
                onChanged: (value) => _setPart(state, day: value),
              ),
              const SizedBox(width: 8),
              dropdown<int>(
                hint: 'Month',
                value: _month,
                items: [for (var m = 1; m <= 12; m++) m],
                labelOf: (value) => _config.monthNames[value - 1],
                onChanged: (value) => _setPart(state, month: value),
              ),
              const SizedBox(width: 8),
              dropdown<int>(
                hint: 'Year',
                value: _year,
                items: years,
                labelOf: (value) => value.toString(),
                onChanged: (value) => _setPart(state, year: value),
              ),
            ],
          ),
        );
      },
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
  });

  final DateTime initial;
  final int firstYear;
  final int lastYear;
  final List<String> monthNames;

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
          label: 'Day',
          items: [for (var d = 1; d <= days; d++) d.toString()],
          controller: _dayController,
          onChanged: (index) => _day = index + 1,
        ),
        _WheelColumn(
          label: 'Month',
          items: widget.monthNames,
          controller: _monthController,
          onChanged: (index) => setState(() {
            _month = index + 1;
            _clampDay();
          }),
        ),
        _WheelColumn(
          label: 'Year',
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
  const _TimeWheelSheet({required this.initial, required this.use24Hour});

  final TimeOfDay initial;
  final bool use24Hour;

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
          label: 'Hour',
          items: widget.use24Hour
              ? [for (var h = 0; h < 24; h++) h.toString().padLeft(2, '0')]
              : [for (var h = 1; h <= 12; h++) h.toString().padLeft(2, '0')],
          controller: _hourController,
          onChanged: (index) => _hour = widget.use24Hour ? index : index + 1,
        ),
        _WheelColumn(
          label: 'Minute',
          items: [for (var m = 0; m < 60; m++) m.toString().padLeft(2, '0')],
          controller: _minuteController,
          onChanged: (index) => _minute = index,
        ),
        if (!widget.use24Hour)
          _WheelColumn(
            label: 'AM or PM',
            items: const ['AM', 'PM'],
            controller: _periodController,
            onChanged: (index) => _pm = index == 1,
          ),
      ],
    );
  }
}
