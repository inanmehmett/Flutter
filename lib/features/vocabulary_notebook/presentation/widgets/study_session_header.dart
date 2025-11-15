import 'package:flutter/material.dart';
import '../../domain/services/review_session.dart';
import '../../domain/entities/study_mode.dart';
import 'study_mode_selector.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';

class StudySessionHeader extends StatelessWidget {
  final StudyMode mode;
  final ValueChanged<StudyMode> onModeChanged;
  final ReviewSession session;

  const StudySessionHeader({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            // Modern gradient header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.accent],
                ),
                borderRadius: BorderRadius.circular(AppRadius.cardRadius),
                boxShadow: AppShadows.cardShadow,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Çalışma Modu',
                          style: AppTypography.title1.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.school_rounded,
                              size: 18,
                              color: AppColors.textQuaternary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${session.totalWords} kelime • ${_calculateEstimatedTime()} dk',
                                style: AppTypography.subhead.copyWith(
                                  color: AppColors.textQuaternary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Mode selector
            StudyModeSelector(
              selectedMode: mode,
              onModeChanged: onModeChanged,
            ),
          ],
        ),
      ),
    );
  }

  int _calculateEstimatedTime() {
    // Her kelime için ortalama 15 saniye
    return (session.totalWords * 15 / 60).round().clamp(1, 60);
  }
}
