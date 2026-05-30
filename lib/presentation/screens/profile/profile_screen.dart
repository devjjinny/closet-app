import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(userPrefsProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            const Text(
              '나',
              style: TextStyle(
                color: AppTheme.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '추천에 쓰는 기본 설정을 관리해요.',
              style: TextStyle(color: AppTheme.inkSoft, fontSize: 12),
            ),
            const SizedBox(height: 16),
            _ProfileCard(
              title: '캐릭터',
              child: Row(
                children: Gender.values.map((gender) {
                  final selected = prefs.gender == gender;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: OutlinedButton.icon(
                        onPressed: () => ref
                            .read(userPrefsProvider.notifier)
                            .saveGender(gender),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: selected
                              ? AppTheme.lavender50
                              : AppTheme.surface,
                          side: BorderSide(
                            color: selected ? AppTheme.ink : AppTheme.line,
                          ),
                        ),
                        icon: Icon(
                          gender == Gender.female ? Icons.face_3 : Icons.face,
                        ),
                        label: Text(gender.label),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            _ProfileCard(
              title: '단위',
              child: _ReadonlySetting(
                icon: Icons.thermostat_outlined,
                label: prefs.units == UnitSystem.metric ? '섭씨 · °C' : '화씨 · °F',
              ),
            ),
            const SizedBox(height: 10),
            _ProfileCard(
              title: '개인화',
              child: Column(
                children: [
                  _ReadonlySetting(
                    icon: Icons.style_outlined,
                    label: prefs.defaultStyleTag?.label ?? '스타일 기본값 없음',
                  ),
                  const SizedBox(height: 8),
                  const _ReadonlySetting(
                    icon: Icons.location_on_outlined,
                    label: '현재 위치 날씨 사용',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.ink,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ReadonlySetting extends StatelessWidget {
  const _ReadonlySetting({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.inkSoft, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.inkSoft,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
