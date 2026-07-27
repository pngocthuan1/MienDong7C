import 'package:flutter/material.dart';
import 'package:benhvien7c/features/patients/domain/entities/UserManagementVisitStatus.dart';

class UserManagementStatusChip extends StatelessWidget {
  const UserManagementStatusChip({
    required this.status,
    super.key,
    this.compact = false,
  });

  final UserManagementVisitStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final visual = _statusVisual(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: visual.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            visual.icon,
            size: compact ? 14 : 16,
            color: visual.foregroundColor,
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: visual.foregroundColor,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 11.5 : 12.5,
            ),
          ),
        ],
      ),
    );
  }

  _StatusVisual _statusVisual(UserManagementVisitStatus value) {
    return switch (value) {
      UserManagementVisitStatus.pendingApproval => const _StatusVisual(
        backgroundColor: Color(0xFFFFF3D6),
        foregroundColor: Color(0xFF9E6700),
        icon: Icons.hourglass_top_rounded,
      ),
      UserManagementVisitStatus.scheduled => const _StatusVisual(
        backgroundColor: Color(0xFFE8F1FF),
        foregroundColor: Color(0xFF235FB7),
        icon: Icons.event_available_rounded,
      ),
      UserManagementVisitStatus.waitingForExamination => const _StatusVisual(
        backgroundColor: Color(0xFFE8FBF7),
        foregroundColor: Color(0xFF0E7C66),
        icon: Icons.chair_alt_rounded,
      ),
      UserManagementVisitStatus.inProgress => const _StatusVisual(
        backgroundColor: Color(0xFFE8F4FF),
        foregroundColor: Color(0xFF1565C0),
        icon: Icons.local_hospital_rounded,
      ),
      UserManagementVisitStatus.completed => const _StatusVisual(
        backgroundColor: Color(0xFFE9F9EE),
        foregroundColor: Color(0xFF1E8E3E),
        icon: Icons.check_circle_rounded,
      ),
      UserManagementVisitStatus.rejected => const _StatusVisual(
        backgroundColor: Color(0xFFFFECEC),
        foregroundColor: Color(0xFFC62828),
        icon: Icons.block_rounded,
      ),
      UserManagementVisitStatus.canceled => const _StatusVisual(
        backgroundColor: Color(0xFFF0F2F5),
        foregroundColor: Color(0xFF5F6B7A),
        icon: Icons.cancel_rounded,
      ),
      UserManagementVisitStatus.noShow => const _StatusVisual(
        backgroundColor: Color(0xFFFFF4E6),
        foregroundColor: Color(0xFFB56A00),
        icon: Icons.person_off_rounded,
      ),
    };
  }
}

class _StatusVisual {
  const _StatusVisual({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
}
