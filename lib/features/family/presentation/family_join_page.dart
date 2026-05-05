import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:babynote/l10n/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import 'family_providers.dart';

/// 초대 코드 입력 페이지 — 다른 부모가 보내준 6자리 코드를 입력해서 가족에 참여.
class FamilyJoinPage extends ConsumerStatefulWidget {
  const FamilyJoinPage({super.key});

  @override
  ConsumerState<FamilyJoinPage> createState() => _FamilyJoinPageState();
}

class _FamilyJoinPageState extends ConsumerState<FamilyJoinPage> {
  final _ctrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final code = _ctrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(familyControllerProvider.notifier).redeemInvite(code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.familyJoined)),
      );
      context.pop();
    } on PostgrestException catch (e) {
      if (!mounted) return;
      // RPC raise exception이 PostgrestException으로 옴. message에서 분기.
      final msg = e.message;
      String userMsg;
      if (msg.contains('INVITE_NOT_FOUND')) {
        userMsg = l10n.familyInviteInvalid;
      } else if (msg.contains('INVITE_EXPIRED')) {
        userMsg = l10n.familyInviteExpired;
      } else {
        userMsg = l10n.errorFailed(msg);
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(userMsg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorFailed(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.familyJoinTitle)),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            children: [
              const Text('🤝', style: TextStyle(fontSize: 64)),
              const SizedBox(height: Spacing.md),
              Text(l10n.familyJoinHelp,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: Spacing.xl),
              TextField(
                controller: _ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 6,
                ),
                decoration: InputDecoration(
                  labelText: l10n.familyCodeLabel,
                  hintText: l10n.familyCodeHint,
                ),
              ),
              const SizedBox(height: Spacing.xl),
              FilledButton.icon(
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.group_add),
                label: Text(l10n.familyJoinButton),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(TouchTarget.huge),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
