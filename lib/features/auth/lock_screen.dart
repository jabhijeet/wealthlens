import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/security/security_service.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _isAuthenticated = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final security = ref.read(securityServiceProvider);

      // 5-second timeout guards against DB/SQLCipher hangs on first launch
      final isEnabled = await security.isBiometricEnabled().timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );

      if (!isEnabled) {
        if (mounted) {
          setState(() {
            _isAuthenticated = true;
            _isChecking = false;
          });
        }
        return;
      }

      final success = await security.authenticate();
      if (mounted) {
        setState(() {
          _isAuthenticated = success;
          _isChecking = false;
        });
      }
    } catch (e) {
      debugPrint('Security check failed: $e');
      if (mounted) {
        setState(() {
          _isAuthenticated = true;
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Always keep the app mounted to preserve state and avoid mounting issues
        Positioned.fill(child: widget.child),

        // Show lock overlay if not authenticated and not checking
        if (!_isChecking && !_isAuthenticated)
          Positioned.fill(
            child: Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 80,
                      color: Color(0xFF6C5CE7),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'WealthLens is Locked',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _checkAuth,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Unlock with Biometrics'),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
