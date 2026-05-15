-- =============================================================================
-- 09_seed_vaccine_us.sql — 미국 CDC 표준 예방접종 일정 시드 데이터
-- =============================================================================
--
-- 출처: CDC Recommended Child and Adolescent Immunization Schedule (2025).
-- https://www.cdc.gov/vaccines/schedules/hcp/imz/child-adolescent.html
--
-- ── KR/JP 와 다른 점 ─────────────────────────────────────────────────
-- 1. BCG 없음 (선택 접종). 결핵 노출 가능 영아만.
-- 2. HepA 권장 시작 12개월 (KR 동일, JP 보다 빠름).
-- 3. DTaP 5회 + IPV 4회 별도 접종 (JP 처럼 5종 혼합 아님).
-- 4. PCV15 또는 PCV20 사용 (PCV13 후속). 본 시드는 PCV13 코드 사용 — UI에서 동등 취급.
-- 5. Influenza 6개월부터 매년 권장 — 모든 국가 공통.
-- 6. HPV 시작 9~12세 (한국/일본은 11~12세).
-- 7. Meningococcal (MenACWY/MenB) 청소년기 추가 — 11-12세, 16세 부스터.
-- 8. COVID-19 권장은 매년 변동 — 시드 제외 (별도 컬럼 추가 권장).
--
-- 일수 환산: KR 시드와 동일.
-- =============================================================================

insert into public.vaccine_schedules (country, code, dose_number, name, description, recommended_age_days) values
-- Birth
('US', 'HEPB',        1, 'Hepatitis B (Dose 1)',  'Within 24 hours of birth.',                                       0),

-- 1-2 months
('US', 'HEPB',        2, 'Hepatitis B (Dose 2)',  '1-2 months after Dose 1.',                                       60),

-- 2 months
('US', 'ROTAVIRUS',   1, 'Rotavirus (Dose 1)',    'RV1 or RV5. Start by 14 weeks 6 days.',                          60),
('US', 'DTAP',        1, 'DTaP (Dose 1)',         'Diphtheria, tetanus, acellular pertussis.',                       60),
('US', 'HIB',         1, 'Hib (Dose 1)',          'Haemophilus influenzae type b.',                                 60),
('US', 'PCV13',       1, 'PCV (Dose 1)',          'Pneumococcal conjugate (PCV15 or PCV20).',                       60),
('US', 'IPV',         1, 'IPV (Dose 1)',          'Inactivated poliovirus.',                                        60),

-- 4 months
('US', 'ROTAVIRUS',   2, 'Rotavirus (Dose 2)',    'Second dose.',                                                   120),
('US', 'DTAP',        2, 'DTaP (Dose 2)',         'Second dose.',                                                   120),
('US', 'HIB',         2, 'Hib (Dose 2)',          'Second dose.',                                                   120),
('US', 'PCV13',       2, 'PCV (Dose 2)',          'Second dose.',                                                   120),
('US', 'IPV',         2, 'IPV (Dose 2)',          'Second dose.',                                                   120),

-- 6 months
('US', 'ROTAVIRUS',   3, 'Rotavirus (Dose 3)',    'RV5 only; RV1 ends at Dose 2.',                                  180),
('US', 'DTAP',        3, 'DTaP (Dose 3)',         'Third dose.',                                                    180),
('US', 'HIB',         3, 'Hib (Dose 3)',          'PRP-T (ActHIB/Pentacel) only; PRP-OMP ends at Dose 2.',          180),
('US', 'PCV13',       3, 'PCV (Dose 3)',          'Third dose.',                                                    180),
('US', 'IPV',         3, 'IPV (Dose 3)',          'Between 6-18 months.',                                           180),
('US', 'HEPB',        3, 'Hepatitis B (Dose 3)',  'Between 6-18 months.',                                           180),
('US', 'INFLUENZA',   1, 'Influenza (annual)',    'Annually from 6 months. Repeat each fall.',                      180),

-- 12-15 months
('US', 'MMR',         1, 'MMR (Dose 1)',          'Measles, mumps, rubella.',                                       365),
('US', 'VARICELLA',   1, 'Varicella (Dose 1)',    'Chickenpox.',                                                    365),
('US', 'HEPA',        1, 'Hepatitis A (Dose 1)',  '12-23 months. Start of 2-dose series.',                          365),
('US', 'HIB',         4, 'Hib (Booster)',         '12-15 months final dose.',                                       365),
('US', 'PCV13',       4, 'PCV (Booster)',         '12-15 months final dose.',                                       365),

-- 15-18 months
('US', 'DTAP',        4, 'DTaP (Dose 4)',         '15-18 months.',                                                  450),

-- 18-23 months
('US', 'HEPA',        2, 'Hepatitis A (Dose 2)',  '6 months after Dose 1.',                                         540),

-- 4-6 years
('US', 'DTAP',        5, 'DTaP (Dose 5)',         '4-6 years booster.',                                            1460),
('US', 'IPV',         4, 'IPV (Dose 4)',          '4-6 years booster.',                                            1460),
('US', 'MMR',         2, 'MMR (Dose 2)',          '4-6 years booster.',                                            1460),
('US', 'VARICELLA',   2, 'Varicella (Dose 2)',    '4-6 years booster.',                                            1460),

-- 11-12 years
('US', 'TDAP',        1, 'Tdap',                  'Tetanus, diphtheria, acellular pertussis booster.',             4015),
('US', 'HPV',         1, 'HPV (Dose 1)',          '11-12 years (can start at 9). 2-3 dose series.',                4015),
('US', 'HPV',         2, 'HPV (Dose 2)',          '6-12 months after Dose 1.',                                     4200),
('US', 'MENACWY',     1, 'MenACWY (Dose 1)',      'Meningococcal ACWY. 11-12 years.',                              4015),

-- 16 years
('US', 'MENACWY',     2, 'MenACWY (Booster)',     '16 years booster.',                                             5840),
('US', 'MENB',        1, 'MenB (Dose 1)',         '16-18 years, shared clinical decision-making.',                 5840)

on conflict (country, code, dose_number) do nothing;
