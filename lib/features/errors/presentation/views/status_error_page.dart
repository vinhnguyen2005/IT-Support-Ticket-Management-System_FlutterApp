import 'package:flutter/material.dart';

class ClientErrorPage extends StatelessWidget {
  const ClientErrorPage({
    super.key,
    required this.statusCode,
    this.message,
    required this.fallbackRoute,
  });

  final int statusCode;
  final String? message;
  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    return _StatusErrorPage(
      statusCode: statusCode,
      title: _titleFor(statusCode),
      message: message ?? _messageFor(statusCode),
      icon: _iconFor(statusCode),
      fallbackRoute: fallbackRoute,
    );
  }

  static String _titleFor(int statusCode) => switch (statusCode) {
    400 => 'Bad request',
    401 => 'Authentication required',
    403 => 'Access denied',
    404 => 'Page not found',
    408 => 'Request timed out',
    429 => 'Too many requests',
    _ => 'Request could not be completed',
  };

  static String _messageFor(int statusCode) => switch (statusCode) {
    400 =>
      'The request was invalid. Please check your information and try again.',
    401 => 'Your session may have expired. Please sign in and try again.',
    403 => 'You do not have permission to view this page.',
    404 => 'The page you requested does not exist or may have been moved.',
    408 =>
      'The request took too long. Please check your connection and try again.',
    429 =>
      'There have been too many requests. Please wait a moment and try again.',
    _ =>
      'Something was wrong with the request. Please review it and try again.',
  };

  static IconData _iconFor(int statusCode) => switch (statusCode) {
    401 => Icons.lock_outline,
    403 => Icons.gpp_bad_outlined,
    404 => Icons.search_off_outlined,
    408 => Icons.timer_off_outlined,
    429 => Icons.hourglass_top_outlined,
    _ => Icons.warning_amber_rounded,
  };
}

class ServerErrorPage extends StatelessWidget {
  const ServerErrorPage({
    super.key,
    required this.statusCode,
    this.message,
    required this.fallbackRoute,
  });

  final int statusCode;
  final String? message;
  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    return _StatusErrorPage(
      statusCode: statusCode,
      title: statusCode == 503 ? 'Service unavailable' : 'Server error',
      message:
          message ??
          (statusCode == 503
              ? 'The service is temporarily unavailable. Please try again shortly.'
              : 'The server encountered a problem. Please try again later.'),
      icon: Icons.cloud_off_outlined,
      fallbackRoute: fallbackRoute,
    );
  }
}

class _StatusErrorPage extends StatelessWidget {
  const _StatusErrorPage({
    required this.statusCode,
    required this.title,
    required this.message,
    required this.icon,
    required this.fallbackRoute,
  });

  final int statusCode;
  final String title;
  final String message;
  final IconData icon;
  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('Error $statusCode')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(icon, size: 56, color: colors.primary),
                      const SizedBox(height: 16),
                      Text(
                        '$statusCode - $title',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => _leaveErrorPage(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            Navigator.of(context).canPop()
                                ? 'Go back'
                                : 'Go home',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _leaveErrorPage(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacementNamed(fallbackRoute);
  }
}
