import 'dart:async';

import 'package:flutter/material.dart';
import 'package:benhvien7c/core/theme/AppColors.dart';

class OtpCountdown extends StatefulWidget {
  const OtpCountdown({
    required this.onResend,
    super.key,
    this.seconds = 30,
    this.isBusy = false,
  });

  final Future<bool> Function() onResend;
  final int seconds;
  final bool isBusy;

  @override
  State<OtpCountdown> createState() => _OtpCountdownState();
}

class _OtpCountdownState extends State<OtpCountdown> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.seconds;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _remainingSeconds = 0;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  Future<void> _handleResend() async {
    final isSuccess = await widget.onResend();
    if (!mounted || !isSuccess) {
      return;
    }

    setState(() {
      _remainingSeconds = widget.seconds;
    });
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _remainingSeconds == 0 && !widget.isBusy;

    return Column(
      children: [
        TextButton(
          onPressed: canResend ? _handleResend : null,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: widget.isBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Gửi lại mã'),
        ),
        if (_remainingSeconds > 0)
          Text(
            'Có thể gửi lại sau ${_remainingSeconds}s',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}
