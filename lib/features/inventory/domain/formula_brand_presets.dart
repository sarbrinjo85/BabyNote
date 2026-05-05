/// 가루분유 브랜드별 1스쿱 표준값 프리셋.
///
/// ── 사용 ─────────────────────────────────────────────────────────────
/// 등록 페이지에서 사용자가 브랜드를 선택하면 g_per_scoop / ml_per_scoop
/// 필드를 자동으로 채워 입력 부담을 줄임.
///
/// ── 출처 ─────────────────────────────────────────────────────────────
/// 각 제조사 권장 조유 비율 (제품 라벨 기준). 동일 브랜드 안에서 단계
/// (1단/2단 등) 별 미세 차이가 있을 수 있어 사용자가 라벨 보고 수정 가능.
class FormulaBrandPreset {
  const FormulaBrandPreset({
    required this.gPerScoop,
    required this.mlPerScoop,
  });

  final double gPerScoop;
  final double mlPerScoop;
}

/// 한국에서 흔한 분유 브랜드.
const Map<String, FormulaBrandPreset> kFormulaBrandPresets = {
  '남양 임페리얼XO':   FormulaBrandPreset(gPerScoop: 4.4, mlPerScoop: 30),
  '매일 앱솔루트':     FormulaBrandPreset(gPerScoop: 4.4, mlPerScoop: 30),
  '매일 페어리':       FormulaBrandPreset(gPerScoop: 4.3, mlPerScoop: 30),
  '일동 산양 아기밀':  FormulaBrandPreset(gPerScoop: 4.5, mlPerScoop: 30),
  '네슬레 NAN':        FormulaBrandPreset(gPerScoop: 4.3, mlPerScoop: 30),
  '압타밀(Aptamil)':   FormulaBrandPreset(gPerScoop: 4.5, mlPerScoop: 30),
  '힙(HiPP)':          FormulaBrandPreset(gPerScoop: 4.4, mlPerScoop: 30),
  '거버(Gerber)':      FormulaBrandPreset(gPerScoop: 4.3, mlPerScoop: 30),
};
