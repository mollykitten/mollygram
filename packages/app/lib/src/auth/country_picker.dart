import 'package:flutter/material.dart';
import 'package:mollygram_core/mollygram_core.dart';
import 'package:mollygram_ui_kit/mollygram_ui_kit.dart';

/// The country list of the phone form, with a search by name or code.
class CountryPicker extends StatefulWidget {
  const CountryPicker({
    super.key,
    required this.countries,
    required this.searchHint,
    required this.emptyText,
    required this.onSelected,
  });

  final List<PhoneCountry> countries;
  final String searchHint;
  final String emptyText;
  final ValueChanged<PhoneCountry> onSelected;

  @override
  State<CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<CountryPicker> {
  final _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<PhoneCountry> get _shown {
    final query = _query.text;
    return [
      for (final country in widget.countries)
        if (country.matches(query)) country,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = MgColors.of(context);
    final shown = _shown;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MgSearchField(
          hintText: widget.searchHint,
          controller: _query,
          onSubmitted: (_) {
            if (shown.isNotEmpty) widget.onSelected(shown.first);
          },
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 360,
          child: shown.isEmpty
              ? Center(
                  child: Text(widget.emptyText, style: TextStyle(color: c.fg2)),
                )
              : ListView.builder(
                  itemCount: shown.length,
                  itemExtent: MgMetrics.scaled(context, 40),
                  itemBuilder: (context, i) =>
                      _CountryRow(shown[i], onTap: widget.onSelected),
                ),
        ),
      ],
    );
  }
}

class _CountryRow extends StatefulWidget {
  const _CountryRow(this.country, {required this.onTap});

  final PhoneCountry country;
  final ValueChanged<PhoneCountry> onTap;

  @override
  State<_CountryRow> createState() => _CountryRowState();
}

class _CountryRowState extends State<_CountryRow> {
  @override
  Widget build(BuildContext context) {
    final c = MgColors.of(context);
    final country = widget.country;
    return MgPressable(
      onTap: () => widget.onTap(country),
      scale: 1,
      focusRadius: 8,
      builder: (context, state) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: state.hovered ? c.hover : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                country.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: mgTextStyle(c, size: 14),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '+${country.callingCodes.first}',
              style: mgTextStyle(c, size: 14, color: c.fg2),
            ),
          ],
        ),
      ),
    );
  }
}
