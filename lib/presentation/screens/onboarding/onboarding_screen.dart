import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/enums.dart';
import '../../providers/providers.dart';

const _kOnboardingKey = 'onboarding_complete';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  Gender? _selected;
  bool _loading = false;

  Future<void> _confirm() async {
    if (_selected == null || _loading) return;
    setState(() => _loading = true);
    try {
      await ref.read(userPrefsProvider.notifier).saveGender(_selected!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kOnboardingKey, true);
      ref.invalidate(onboardingCompleteProvider);
      if (mounted) context.go('/today');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.checkroom, size: 64, color: Color(0xFF6C5CE7)),
              const SizedBox(height: 32),
              Text(
                '안녕하세요!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '맞춤 코디 추천을 위해\n성별을 알려주세요',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 48),
              Row(
                children: Gender.values.map((g) {
                  final selected = _selected == g;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: g == Gender.male ? 0 : 8,
                        right: g == Gender.male ? 8 : 0,
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() => _selected = g),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF6C5CE7)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF6C5CE7)
                                  : Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                g == Gender.male
                                    ? Icons.male
                                    : Icons.female,
                                size: 40,
                                color:
                                    selected ? Colors.white : Colors.grey[600],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                g.label,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? Colors.white
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected == null ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          '시작하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
