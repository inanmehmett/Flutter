import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/xp_state_service.dart';

/// Vocabulary notebook promotional card.
/// 
/// Features:
/// - Purple gradient theme
/// - Spaced repetition messaging
/// - Social proof (user count)
/// - CTA button to vocabulary page
class VocabularyNotebookCard extends StatelessWidget {
  const VocabularyNotebookCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(AppSpacing.paddingL),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.accent],
        ),
        borderRadius: BorderRadius.circular(AppRadius.cardRadius),
        boxShadow: AppShadows.cardShadowElevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 16),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCTAButton(context),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 56,
      height: 56,
        decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, AppColors.accentContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.shade900.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          '📚',
          style: TextStyle(fontSize: 28),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kelime Defterim',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Öğrendiğin tüm kelimeleri tek yerde topla ve düzenli tekrar et.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.95),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              Icons.people_outline,
              size: 14,
              color: Colors.white.withOpacity(0.9),
            ),
            const SizedBox(width: 4),
            Text(
              '10,000+ öğrenci aktif kullanıyor',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCTAButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Semantics(
        label: 'Kelime Defterini Aç',
        hint: 'Kaydettiğin kelimeleri görüntülemek için dokunun',
        button: true,
        child: ElevatedButton(
          onPressed: () async {
            // Navigate and refresh XP when returning
            await Navigator.of(context).pushNamed('/vocabulary');
            
            // Refresh XP cache after returning from vocabulary study
            try {
              final xpService = getIt<XPStateService>();
              final cachedDailyXP = await xpService.getDailyXP();
              final cachedTotalXP = await xpService.getTotalXP();
              print('🔄 [VocabularyCard] Refreshed XP after study: Daily=$cachedDailyXP, Total=$cachedTotalXP');
            } catch (e) {
              print('⚠️ [VocabularyCard] Failed to refresh XP: $e');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.surface,
            foregroundColor: Colors.purple.shade400,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.paddingM),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'Kelimelerimi Tekrar Et',
                style: AppTypography.buttonMedium,
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

