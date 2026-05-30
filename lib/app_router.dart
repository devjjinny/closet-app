import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'presentation/providers/providers.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/closet/closet_screen.dart';
import 'presentation/screens/add_garment/bulk_add_garments_screen.dart';
import 'presentation/screens/add_garment/add_garment_screen.dart';
import 'presentation/screens/save_outfit/ootd_pin_save_screen.dart';
import 'presentation/screens/save_outfit/save_outfit_screen.dart';
import 'presentation/screens/today_outfit/today_outfit_screen.dart';
import 'presentation/screens/history/history_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/shell_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final onboardingAsync = ref.watch(onboardingCompleteProvider);

  return GoRouter(
    initialLocation: '/today',
    redirect: (context, state) {
      // 온보딩 로딩 중 → 이동 없음
      if (onboardingAsync.isLoading) return null;

      final isOnboardingDone = onboardingAsync.value ?? false;
      final isOnboardingRoute = state.matchedLocation == '/onboarding';

      if (!isOnboardingDone && !isOnboardingRoute) return '/onboarding';
      if (isOnboardingDone && isOnboardingRoute) return '/today';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/closet',
                builder: (context, state) => const ClosetScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                builder: (context, state) => const TodayOutfitScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/add-garment',
        builder: (context, state) => const AddGarmentScreen(),
      ),
      GoRoute(
        path: '/add-garments-bulk',
        builder: (context, state) => const BulkAddGarmentsScreen(),
      ),
      GoRoute(
        path: '/save-outfit',
        builder: (context, state) => const SaveOutfitScreen(),
      ),
      GoRoute(
        path: '/save-ootd',
        builder: (context, state) => const OotdPinSaveScreen(),
      ),
    ],
  );
});
