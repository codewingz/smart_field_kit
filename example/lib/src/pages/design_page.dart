import 'package:flutter/material.dart';
import 'package:smart_field_kit/smart_field_kit.dart';

import '../demo_widgets.dart';
import '../settings.dart';

enum _BorderKind { packageDefault, outline, underline }

class DesignPage extends StatefulWidget {
  const DesignPage({super.key, required this.settings});

  final ShowcaseSettings settings;

  @override
  State<DesignPage> createState() => _DesignPageState();
}

class _DesignPageState extends State<DesignPage> {
  _BorderKind _border = _BorderKind.packageDefault;
  double _radius = 12;
  double _width = 1;
  double _padH = 16;
  double _padV = 12;
  bool _filled = false;
  bool _icons = false;
  Color _accent = Colors.deepPurple;
  bool _otpCustom = false;

  InputBorder? _borderFor(Color color, double width) {
    switch (_border) {
      case _BorderKind.packageDefault:
        return null;
      case _BorderKind.outline:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: color, width: width),
        );
      case _BorderKind.underline:
        return UnderlineInputBorder(
          borderSide: BorderSide(color: color, width: width),
        );
    }
  }

  InputDecoration _decoration({String? helper}) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      border: _borderFor(scheme.outline, _width),
      enabledBorder: _borderFor(scheme.outline, _width),
      focusedBorder: _borderFor(_accent, _width + 1),
      errorBorder: _borderFor(scheme.error, _width),
      focusedErrorBorder: _borderFor(scheme.error, _width + 1),
      contentPadding: _border == _BorderKind.packageDefault
          ? null
          : EdgeInsets.symmetric(horizontal: _padH, vertical: _padV),
      filled: _filled,
      fillColor: _filled ? _accent.withValues(alpha: 0.08) : null,
      labelStyle: TextStyle(color: _accent),
      helperText: helper,
      prefixIcon: _icons ? const Icon(Icons.person_outline) : null,
      suffixIcon: _icons ? const Icon(Icons.info_outline) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final themed = Theme.of(context).copyWith(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Theme.of(context).colorScheme.secondaryContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
      ),
    );
    return PageBody(
      children: [
        DemoCard(
          title: 'Environment',
          description:
              'Light, dark, RTL, and text scaling apply to every field in '
              'this app. Resize the window to see narrow and wide layouts.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OptionChips<ThemeMode>(
                options: const {
                  ThemeMode.light: 'Light',
                  ThemeMode.dark: 'Dark',
                  ThemeMode.system: 'System',
                },
                selected: settings.themeMode,
                onChanged: (value) => settings.themeMode = value,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Right-to-left layout'),
                value: settings.rtl,
                onChanged: (value) => settings.rtl = value,
              ),
              ListenableBuilder(
                listenable: settings,
                builder: (context, _) => Slider(
                  min: 0.8,
                  max: 2,
                  divisions: 12,
                  label: 'Text ×${settings.textScale.toStringAsFixed(1)}',
                  value: settings.textScale,
                  onChanged: (value) => settings.textScale = value,
                ),
              ),
            ],
          ),
        ),
        DemoCard(
          title: 'Application theme versus per-field decoration',
          description:
              'Priority: the field\'s own decoration, then the app\'s '
              'InputDecorationTheme, then the package fallback. The first field '
              'inherits a pill-shaped app theme; the second overrides it with '
              'its own decoration; the third uses the package fallback.',
          snippet:
              "Theme(\n  data: theme.copyWith(inputDecorationTheme: ...),\n  child: SmartField(label: 'Inherits theme'),\n)\nSmartField(decoration: InputDecoration(border: ...))",
          child: Column(
            children: [
              Theme(
                data: themed,
                child: const SmartField(label: 'Inherits the app theme'),
              ),
              const SizedBox(height: fieldGap),
              Theme(
                data: themed,
                child: SmartField(
                  label: 'Per-field decoration wins',
                  decoration: InputDecoration(
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: _accent, width: 2),
                    ),
                    filled: false,
                  ),
                ),
              ),
              const SizedBox(height: fieldGap),
              const SmartField(label: 'Package fallback (this page\'s theme)'),
            ],
          ),
        ),
        DemoCard(
          title: 'Interactive styling',
          description:
              'Real InputDecoration options passed through decoration:. '
              'Focus styling follows the field that actually has focus.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OptionChips<_BorderKind>(
                options: const {
                  _BorderKind.packageDefault: 'Default',
                  _BorderKind.outline: 'Outline',
                  _BorderKind.underline: 'Underline',
                },
                selected: _border,
                onChanged: (value) => setState(() => _border = value),
              ),
              _slider('Radius', _radius, 0, 32, (v) => _radius = v),
              _slider('Border width', _width, 0.5, 4, (v) => _width = v),
              _slider('Padding horizontal', _padH, 0, 32, (v) => _padH = v),
              _slider('Padding vertical', _padV, 0, 32, (v) => _padV = v),
              Wrap(
                spacing: 8,
                children: [
                  for (final color in [
                    Colors.deepPurple,
                    Colors.teal,
                    Colors.orange,
                    Colors.pink,
                  ])
                    ChoiceChip(
                      avatar: CircleAvatar(backgroundColor: color),
                      label: const Text('Accent'),
                      selected: _accent == color,
                      onSelected: (_) => setState(() => _accent = color),
                    ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Filled background'),
                value: _filled,
                onChanged: (value) => setState(() => _filled = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Prefix and suffix icons'),
                value: _icons,
                onChanged: (value) => setState(() => _icons = value),
              ),
              const SizedBox(height: 8),
              SmartField(
                label: 'Normal (focus me)',
                hintText: 'Hint text',
                decoration: _decoration(helper: 'Helper text'),
              ),
              const SizedBox(height: fieldGap),
              SmartField(
                label: 'Error state',
                isRequired: true,
                autovalidateMode: AutovalidateMode.always,
                decoration: _decoration(),
              ),
              const SizedBox(height: fieldGap),
              SmartField(
                label: 'Disabled',
                enabled: false,
                decoration: _decoration(),
              ),
              const SizedBox(height: fieldGap),
              SmartField(
                label: 'Read-only',
                readOnly: true,
                controller: TextEditingController(text: 'Cannot edit'),
                decoration: _decoration(),
              ),
              const SizedBox(height: fieldGap),
              SmartField.password(
                label: 'Password (visibility toggle)',
                decoration: _decoration(),
              ),
              const SizedBox(height: fieldGap),
              SmartField.search(
                label: 'Search (clear button)',
                decoration: _decoration(),
              ),
              const SizedBox(height: fieldGap),
              SmartField.phone(
                label: 'Phone (country selector)',
                showCountryPicker: true,
                initialCountryCode: 'PK',
                decoration: _decoration(),
              ),
            ],
          ),
        ),
        DemoCard(
          title: 'OTP box styling',
          description:
              'SmartOtpStyle controls box size, spacing, borders, fills, text, '
              'cursor, and animation. OTP draws its own boxes, so it does not '
              'use InputDecoration.',
          snippet:
              "SmartField.otp(\n  style: SmartOtpStyle(\n    boxWidth: 40,\n    borderRadius: BorderRadius.circular(24),\n    focusedBorderColor: Colors.teal,\n  ),\n)",
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Custom OTP style'),
                value: _otpCustom,
                onChanged: (value) => setState(() => _otpCustom = value),
              ),
              Center(
                child: SmartField.otp(
                  key: ValueKey(_otpCustom),
                  length: 6,
                  style: _otpCustom
                      ? SmartOtpStyle(
                          boxWidth: 40,
                          boxHeight: 48,
                          spacing: 6,
                          borderRadius: BorderRadius.circular(24),
                          focusedBorderColor: _accent,
                          filledBorderColor: _accent,
                          fillColor: _accent.withValues(alpha: 0.06),
                        )
                      : const SmartOtpStyle(),
                ),
              ),
            ],
          ),
        ),
        const DemoCard(
          title: 'Limitations',
          description:
              'There is no separate "loading" decoration: asynchronous '
              'validation shows a spinner in the suffix and a live-region '
              'label, and search shows its own loading indicator. Colors '
              'for individual validation states come from the decoration '
              'and theme; the package adds no extra style options beyond '
              'those shown here.',
          child: SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    void Function(double) assign,
  ) {
    return Row(
      children: [
        SizedBox(width: 140, child: Text(label)),
        Expanded(
          child: Slider(
            min: min,
            max: max,
            value: value,
            label: value.toStringAsFixed(1),
            onChanged: (v) => setState(() => assign(v)),
          ),
        ),
      ],
    );
  }
}
