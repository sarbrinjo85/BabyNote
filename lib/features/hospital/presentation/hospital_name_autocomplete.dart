import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../data/places_service.dart';

/// 병원 이름 + Google Places 자동완성 입력 위젯.
///
/// 사용자가 텍스트 입력하면 debounce 후 autocomplete 호출 → 드롭다운 후보 표시.
/// 후보 탭 → place details 조회 → onPlaceSelected 콜백으로 부모에게 데이터 전달.
class HospitalNameAutocomplete extends ConsumerStatefulWidget {
  const HospitalNameAutocomplete({
    super.key,
    required this.controller,
    required this.onPlaceSelected,
    this.validator,
    this.autofocus = false,
  });

  final TextEditingController controller;
  /// 자동완성 후보 선택 시 호출. name/address/phone/lat/lng 채워줌.
  final ValueChanged<PlaceDetails> onPlaceSelected;
  final FormFieldValidator<String>? validator;
  final bool autofocus;

  @override
  ConsumerState<HospitalNameAutocomplete> createState() =>
      _HospitalNameAutocompleteState();
}

class _HospitalNameAutocompleteState
    extends ConsumerState<HospitalNameAutocomplete> {
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  List<PlacePrediction> _predictions = const [];
  bool _loading = false;
  bool _hideSuggestions = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      // 포커스 잃으면 후보 숨김
      if (!_focusNode.hasFocus) {
        setState(() => _hideSuggestions = true);
      } else {
        setState(() => _hideSuggestions = false);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onChanged(String value) async {
    setState(() => _hideSuggestions = false);

    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _predictions = const [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final svc = ref.read(placesServiceProvider);
      // 시스템 언어 — 한국어 default. (사용자 country 따라 분기는 추후)
      final lang = Localizations.localeOf(context).languageCode;
      final country = lang == 'ja' ? 'jp' : (lang == 'en' ? null : 'kr');
      final results = await svc.autocomplete(
        value,
        language: lang,
        components: country != null ? 'country:$country' : null,
      );
      if (!mounted) return;
      setState(() {
        _predictions = results;
        _loading = false;
      });
    });
  }

  Future<void> _onTapPrediction(PlacePrediction p) async {
    final svc = ref.read(placesServiceProvider);
    final lang = Localizations.localeOf(context).languageCode;
    final details = await svc.details(p.placeId, language: lang);
    if (!mounted || details == null) return;

    // 컨트롤러에 이름 채우고 부모에게 details 전달
    widget.controller.text = details.name;
    widget.onPlaceSelected(details);

    // 후보 닫기 + 포커스 해제
    setState(() {
      _hideSuggestions = true;
      _predictions = const [];
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          decoration: InputDecoration(
            labelText: l10n.hospitalNameLabel,
            hintText: l10n.hospitalNameHint,
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          validator: widget.validator,
          onChanged: _onChanged,
        ),
        // 자동완성 후보 목록 — 비었거나 숨김 상태면 표시 X
        if (!_hideSuggestions && _predictions.isNotEmpty) ...[
          const SizedBox(height: Spacing.xs),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: Radii.brMd,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                for (final p in _predictions.take(5))
                  InkWell(
                    onTap: () => _onTapPrediction(p),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.md, vertical: Spacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.mainText ?? p.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600),
                          ),
                          if (p.secondaryText != null)
                            Text(
                              p.secondaryText!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
