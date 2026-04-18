import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ──────────────────────────────────────────────────────────────
// AppLoadingWidget
// ──────────────────────────────────────────────────────────────

class AppLoadingWidget extends StatelessWidget {
  const AppLoadingWidget({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFF6C5CE7)),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// AppErrorWidget
// ──────────────────────────────────────────────────────────────

class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('다시 시도'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6C5CE7),
                  side: const BorderSide(color: Color(0xFF6C5CE7)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// AsyncValue extension
// ──────────────────────────────────────────────────────────────

extension AsyncValueX<T> on AsyncValue<T> {
  /// AsyncValue를 위젯으로 변환하는 편의 메서드.
  /// loading → AppLoadingWidget, error → AppErrorWidget, data → onData
  Widget buildWidget({
    required Widget Function(T data) onData,
    String? loadingMessage,
    VoidCallback? onRetry,
  }) {
    return when(
      loading: () => AppLoadingWidget(message: loadingMessage),
      error: (e, _) => AppErrorWidget(
        message: _friendlyMessage(e),
        onRetry: onRetry,
      ),
      data: onData,
    );
  }

  String _friendlyMessage(Object error) {
    final msg = error.toString();
    // Firebase 에러 코드 친화적으로 변환
    if (msg.contains('network-request-failed') ||
        msg.contains('SocketException')) {
      return '네트워크 연결을 확인해주세요';
    }
    if (msg.contains('permission-denied')) return '접근 권한이 없어요';
    if (msg.contains('unavailable')) return '서비스가 일시적으로 불안정해요';
    return '문제가 발생했어요\n잠시 후 다시 시도해주세요';
  }
}
