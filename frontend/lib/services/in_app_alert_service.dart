import 'package:flutter/material.dart';
import '../main.dart'; // Para globalNavigatorKey
import '../core/theme.dart';

enum AlertType { info, warning, success, error }

class InAppAlertService {
  static void show({
    required String title,
    required String message,
    AlertType type = AlertType.info,
    IconData? icon,
    Duration duration = const Duration(seconds: 6),
    VoidCallback? onTap,
    String? actionLabel,
  }) {
    final overlay = globalNavigatorKey.currentState?.overlay;
    if (overlay == null) return;

    late OverlayEntry overlayEntry;

    Color bgColor;
    IconData defaultIcon;

    switch (type) {
      case AlertType.success:
        bgColor = AppTheme.success;
        defaultIcon = Icons.check_circle_rounded;
        break;
      case AlertType.warning:
        bgColor = Colors.orange.shade700;
        defaultIcon = Icons.warning_rounded;
        break;
      case AlertType.error:
        bgColor = AppTheme.danger;
        defaultIcon = Icons.error_rounded;
        break;
      case AlertType.info:
      default:
        bgColor = AppTheme.accent;
        defaultIcon = Icons.info_rounded;
        break;
    }

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: _SlideDownAlert(
              title: title,
              message: message,
              bgColor: bgColor,
              icon: icon ?? defaultIcon,
              duration: duration,
              onTap: () {
                overlayEntry.remove();
                if (onTap != null) onTap();
              },
              actionLabel: actionLabel,
              onDismiss: () => overlayEntry.remove(),
            ),
          ),
        );
      },
    );

    overlay.insert(overlayEntry);
  }
}

class _SlideDownAlert extends StatefulWidget {
  final String title;
  final String message;
  final Color bgColor;
  final IconData icon;
  final Duration duration;
  final VoidCallback onTap;
  final String? actionLabel;
  final VoidCallback onDismiss;

  const _SlideDownAlert({
    required this.title,
    required this.message,
    required this.bgColor,
    required this.icon,
    required this.duration,
    required this.onTap,
    this.actionLabel,
    required this.onDismiss,
  });

  @override
  State<_SlideDownAlert> createState() => _SlideDownAlertState();
}

class _SlideDownAlertState extends State<_SlideDownAlert>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    Future.delayed(widget.duration, () async {
      if (mounted) {
        await _controller.reverse();
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(widget.icon, color: Colors.white, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.message,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                    if (widget.actionLabel != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.actionLabel!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  await _controller.reverse();
                  widget.onDismiss();
                },
                child: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
