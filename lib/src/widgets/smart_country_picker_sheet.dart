import 'package:country_picker/country_picker.dart' as country_picker;
import 'package:material_ui/material_ui.dart';

Future<void> showSmartCountryPicker({
  required BuildContext context,
  required ValueChanged<country_picker.Country> onSelect,
  required String searchHint,
  required bool showFlag,
  List<String>? allowedCountryCodes,
  List<String> favoriteCountryCodes = const [],
}) {
  final theme = Theme.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SizedBox(
      height:
          MediaQuery.sizeOf(sheetContext).height -
          (MediaQuery.paddingOf(sheetContext).top + kToolbarHeight / 1.5),
      child: _SmartCountryList(
        onSelect: onSelect,
        searchHint: searchHint,
        showFlag: showFlag,
        allowedCountryCodes: allowedCountryCodes,
        favoriteCountryCodes: favoriteCountryCodes,
      ),
    ),
  );
}

class _SmartCountryList extends StatefulWidget {
  const _SmartCountryList({
    required this.onSelect,
    required this.searchHint,
    required this.showFlag,
    required this.allowedCountryCodes,
    required this.favoriteCountryCodes,
  });

  final ValueChanged<country_picker.Country> onSelect;
  final String searchHint;
  final bool showFlag;
  final List<String>? allowedCountryCodes;
  final List<String> favoriteCountryCodes;

  @override
  State<_SmartCountryList> createState() => _SmartCountryListState();
}

class _SmartCountryListState extends State<_SmartCountryList> {
  final country_picker.CountryService _service =
      country_picker.CountryService();
  final TextEditingController _search = TextEditingController();
  late final List<country_picker.Country> _countries;
  late final List<country_picker.Country> _favorites;
  late List<country_picker.Country> _visible;

  @override
  void initState() {
    super.initState();
    final allowed = widget.allowedCountryCodes;
    _countries = _service
        .getAll()
        .where((c) => allowed == null || allowed.contains(c.countryCode))
        .toList(growable: false);
    _favorites = _service.findCountriesByCode(widget.favoriteCountryCodes);
    _visible = _countries;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final localizations = country_picker.CountryLocalizations.of(context);
    setState(() {
      _visible = query.isEmpty
          ? _countries
          : _countries
                .where((c) => c.startsWith(query, localizations))
                .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyLarge;
    final searching = _search.text.isNotEmpty;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: TextField(
            controller: _search,
            style: textStyle,
            decoration: InputDecoration(
              hintText: widget.searchHint,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: _filter,
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              if (!searching && _favorites.isNotEmpty) ...[
                for (final country in _favorites) _row(country, textStyle),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(thickness: 1),
                ),
              ],
              for (final country in _visible) _row(country, textStyle),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(country_picker.Country country, TextStyle? textStyle) {
    final localizations = country_picker.CountryLocalizations.of(context);
    final name =
        localizations
            ?.countryName(countryCode: country.countryCode)
            ?.replaceAll(RegExp(r'\s+'), ' ') ??
        country.name;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return InkWell(
      onTap: () {
        country.nameLocalized = name;
        widget.onSelect(country);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            const SizedBox(width: 20),
            if (widget.showFlag)
              SizedBox(
                width: rtl ? 50 : null,
                child: Text(
                  country.flagEmoji,
                  style: const TextStyle(fontSize: 25),
                ),
              ),
            const SizedBox(width: 15),
            SizedBox(
              width: 45,
              child: Text(
                '${rtl ? '' : '+'}${country.phoneCode}${rtl ? '+' : ''}',
                style: textStyle,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(child: Text(name, style: textStyle)),
          ],
        ),
      ),
    );
  }
}
