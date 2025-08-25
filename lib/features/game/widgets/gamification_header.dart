import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/game_cubit.dart';

class GamificationHeader extends StatelessWidget {
  const GamificationHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, state) {
        if (state is GameLoading || state is GameInitial) {
          return const _HeaderSkeleton();
        }
        if (state is GameError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text(state.message, style: const TextStyle(color: Colors.red))),
              ],
            ),
          );
        }
        final loaded = state as GameLoaded;
        final summary = loaded.summary;
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.blue.shade50,
                child: Text((summary.currentLevelLabel ?? 'L').substring(0, 1), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((summary.currentLevelLabel ?? '').isNotEmpty)
                      Text(
                        summary.currentLevelLabel!,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text('XP: ${summary.xp}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderSkeleton extends StatelessWidget {
  const _HeaderSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 14, width: 120, color: Colors.grey.shade200),
                const SizedBox(height: 8),
                Container(height: 8, width: double.infinity, color: Colors.grey.shade200),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(height: 28, width: 60, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20))),
        ],
      ),
    );
  }
}

class _StreakPill extends StatelessWidget {
  final int value;
  const _StreakPill({required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department, color: Colors.orange.shade700, size: 18),
          const SizedBox(width: 6),
          Text('${value}d', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}


