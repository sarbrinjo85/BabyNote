import 'package:flutter/material.dart';
import '../../../core/widgets/baby_loading.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/child_picker_action.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../child/presentation/child_providers.dart';
import 'family_providers.dart';

/// 가족 공유 메인 페이지 — 자녀별 caregivers + 활성 초대 코드.
///
/// ── 흐름 ─────────────────────────────────────────────────────────────
/// 1. 자녀 1명이면 자동 선택, 2명+면 상단 드롭다운으로 선택
/// 2. 케어기버 목록 (본인 포함) + 본인 외 제거 가능 + 본인은 "나가기"
/// 3. 활성 초대 코드 목록 + 새 코드 발급 버튼
class FamilyPage extends ConsumerStatefulWidget {
  const FamilyPage({super.key});

  @override
  ConsumerState<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends ConsumerState<FamilyPage> {
  String? _selectedChildId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final asyncChildren = ref.watch(myChildrenProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.familyTitle),
        actions: const [ChildPickerAction()],
      ),
      body: SafeArea(top: false, child: asyncChildren.when(
        loading: () => const Center(child: BabyLoading()),
        error: (err, _) =>
            Center(child: Text(l10n.errorChildrenLoadFailed(err))),
        data: (children) {
          if (children.isEmpty) {
            return _NoChildPlaceholder();
          }
          // 첫 진입 시 자녀 1명 자동 선택
          final childId = _selectedChildId ?? children.first.id;
          if (_selectedChildId == null) {
            // post-frame에서 setState 호출 (build 중 setState 금지)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedChildId = childId);
            });
          }

          return ListView(
            padding: const EdgeInsets.all(Spacing.md),
            children: [
              // 자녀 2명 이상이면 picker
              if (children.length > 1) ...[
                DropdownButtonFormField<String>(
                  decoration:
                      InputDecoration(labelText: l10n.familyChildPicker),
                  initialValue: childId,
                  items: children
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedChildId = v),
                ),
                const SizedBox(height: Spacing.lg),
              ],

              _CaregiversSection(childId: childId),
              const SizedBox(height: Spacing.xl),
              _InvitesSection(childId: childId),
            ],
          );
        },
      )),
    );
  }
}

class _CaregiversSection extends ConsumerWidget {
  const _CaregiversSection({required this.childId});
  final String childId;

  String _roleLabel(AppLocalizations l10n, String role) => switch (role) {
        'parent' => l10n.familyRoleParent,
        'guardian' => '보호자',
        'view_only' => '조회 전용',
        'grandparent' => l10n.familyRoleGrandparent,
        'nanny' => l10n.familyRoleNanny,
        _ => l10n.familyRoleOther,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final me = ref.watch(currentUserProvider);
    final asyncList = ref.watch(caregiversProvider(childId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.familyCaregivers,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: Spacing.xs),
        asyncList.when(
          loading: () => const Center(child: BabyLoading()),
          error: (err, _) => Text(l10n.errorFailed(err)),
          data: (caregivers) {
            return Column(
              children: caregivers.map((c) {
                final isMe = me != null && c.isSelf(me.id);
                final name = c.displayName ?? '—';
                final roleText = _roleLabel(l10n, c.role);
                final acceptedText = c.acceptedAt != null
                    ? l10n.familyAcceptedAt(_formatDate(c.acceptedAt!))
                    : '';
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isMe
                          ? const Color(0xFFFFB5A7)
                          : Theme.of(context)
                              .colorScheme
                              .secondaryContainer,
                      foregroundColor: const Color(0xFFA43F45),
                      child: Text(
                        (name.isNotEmpty ? name : l10n.familyMe)
                            .characters
                            .first
                            .toUpperCase(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(isMe ? '${l10n.familyMe} · $name' : name),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(roleText,
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                      ],
                    ),
                    subtitle: Text(acceptedText,
                        style: Theme.of(context).textTheme.bodySmall),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'remove') {
                          final ok = await _confirmRemove(context, isMe);
                          if (ok && context.mounted) {
                            try {
                              await ref
                                  .read(familyControllerProvider.notifier)
                                  .removeCaregiver(childId, c.id);
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e is StateError
                                      ? e.message
                                      : l10n.errorFailed(e)),
                                ),
                              );
                            }
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'remove',
                          child: Text(isMe
                              ? l10n.familyLeave
                              : l10n.familyRemoveCaregiver),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Future<bool> _confirmRemove(BuildContext context, bool isSelf) async {
    final l10n = AppLocalizations.of(context);
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSelf
            ? l10n.familyLeave
            : l10n.familyRemoveCaregiverConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.commonCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.commonDelete)),
        ],
      ),
    );
    return r ?? false;
  }

  String _formatDate(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}

class _InvitesSection extends ConsumerWidget {
  const _InvitesSection({required this.childId});
  final String childId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncInvites = ref.watch(activeInvitesProvider(childId));
    final ctrl = ref.watch(familyControllerProvider);
    final isLoading = ctrl.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.familyInvites,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: Spacing.xs),
        asyncInvites.when(
          loading: () => const Center(child: BabyLoading()),
          error: (err, _) => Text(l10n.errorFailed(err)),
          data: (invites) {
            return Column(
              children: invites.map((inv) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.qr_code_2),
                    title: Text(
                      inv.code,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                      ),
                    ),
                    subtitle: Text(
                      l10n.familyInviteExpiresAt(_formatDateTime(inv.expiresAt)),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'share') {
                          // 카카오톡/SMS 등 시스템 공유 시트로 보냄.
                          // 코드 + 안내문 + 딥링크.
                          final text =
                              '베이비노트 가족 공유 초대 코드: ${inv.code}\n'
                              '앱에서 "초대 코드로 참여" → 위 코드 입력.\n'
                              'babynote://invite/${inv.code}';
                          await Share.share(text, subject: '베이비노트 초대');
                        } else if (v == 'copy') {
                          await Clipboard.setData(
                              ClipboardData(text: inv.code));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${inv.code} 복사됨')),
                            );
                          }
                        } else if (v == 'revoke') {
                          await ref
                              .read(familyControllerProvider.notifier)
                              .revokeInvite(childId, inv.id);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'share',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: Icon(Icons.ios_share),
                            title: Text('카카오톡/문자로 공유'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'copy',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: const Icon(Icons.copy),
                            title: Text(l10n.familyShareCode),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'revoke',
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: const Icon(Icons.delete_outline),
                            title: Text(l10n.familyRevokeInvite),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: Spacing.sm),
        FilledButton.icon(
          onPressed: isLoading ? null : () => _onCreate(context, ref),
          icon: const Icon(Icons.add),
          label: Text(l10n.familyCreateInvite),
        ),
      ],
    );
  }

  Future<void> _onCreate(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    // 역할 선택 다이얼로그 — view_only / parent
    final role = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('초대할 가족의 역할'),
        children: [
          SimpleDialogOption(
            child: const ListTile(
              leading: Icon(Icons.edit),
              title: Text('보호자 (편집 가능)'),
              subtitle: Text('수유/수면/기저귀/성장 모두 추가·편집·삭제 가능'),
            ),
            onPressed: () => Navigator.pop(ctx, 'parent'),
          ),
          SimpleDialogOption(
            child: const ListTile(
              leading: Icon(Icons.visibility_outlined),
              title: Text('조회 전용'),
              subtitle: Text('기록을 볼 수만 있음 (예: 친척)'),
            ),
            onPressed: () => Navigator.pop(ctx, 'view_only'),
          ),
        ],
      ),
    );
    if (role == null) return;
    if (!context.mounted) return;

    try {
      final invite = await ref
          .read(familyControllerProvider.notifier)
          .createInvite(childId: childId, role: role);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.familyInviteCreated}  →  ${invite.code}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorFailed(e))));
    }
  }

  String _formatDateTime(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}

class _NoChildPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.child_friendly, size: 48),
            const SizedBox(height: Spacing.sm),
            Text(l10n.commonRegisterChildFirst),
            const SizedBox(height: Spacing.md),
            FilledButton.icon(
              onPressed: () => context.push('/child/new'),
              icon: const Icon(Icons.add),
              label: Text(l10n.commonGoRegisterChild),
            ),
          ],
        ),
      ),
    );
  }
}
