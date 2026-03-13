import 'package:flutter/material.dart';
import 'package:maternal_infant_care/presentation/pages/careflow_ai_page.dart';
import 'package:maternal_infant_care/presentation/pages/consultation_daily_healing_activity_page.dart';
import 'package:maternal_infant_care/presentation/pages/consultation_emotional_check_in_page.dart';
import 'package:maternal_infant_care/presentation/pages/consultation_healing_stories_page.dart';
import 'package:maternal_infant_care/presentation/pages/consultation_meditation_page.dart';
import 'package:maternal_infant_care/presentation/pages/consultation_recovery_tracker_page.dart';

class ConsultationDashboardPage extends StatelessWidget {
  const ConsultationDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultation Dashboard'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SupportBanner(colorScheme: colorScheme),
          const SizedBox(height: 14),
          Text(
            'Today\'s Support',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
          ),
          const SizedBox(height: 10),
          _TodaySuggestionCard(
            icon: Icons.self_improvement,
            title: 'Breathing Meditation',
            subtitle: 'Take a 2-minute calm breathing pause for emotional balance.',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ConsultationMeditationPage(),
              ),
            ),
          ),
          _TodaySuggestionCard(
            icon: Icons.menu_book_rounded,
            title: 'Healing Story',
            subtitle: 'Read a supportive recovery story to build strength and hope.',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ConsultationHealingStoriesPage(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.0,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _SupportCard(
                title: 'Emotional Check-In',
                subtitle: 'Pick how you feel and get guided support.',
                icon: Icons.support_rounded,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ConsultationEmotionalCheckInPage(),
                  ),
                ),
              ),
              _SupportCard(
                title: 'Recovery Tracker',
                subtitle: 'Track physical, emotional, and follow-up progress.',
                icon: Icons.monitor_heart_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ConsultationRecoveryTrackerPage(),
                  ),
                ),
              ),
              _SupportCard(
                title: 'Ask Support',
                subtitle: 'Ask recovery and wellbeing questions instantly.',
                icon: Icons.chat_bubble_outline,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VatsalyaAiPage()),
                ),
              ),
              _SupportCard(
                title: 'Daily Healing Activity',
                subtitle: 'Get one guided activity and take action now.',
                icon: Icons.event_available_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ConsultationDailyHealingActivityPage(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 96),
        ],
      ),
    );
  }
}

class _SupportBanner extends StatelessWidget {
  final ColorScheme colorScheme;

  const _SupportBanner({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.92),
            colorScheme.secondary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.22),
            ),
            child: const Icon(
              Icons.spa_rounded,
              size: 34,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We\'re here to support you',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Personalized recovery guidance, emotional care, and practical support tools for each day.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaySuggestionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TodaySuggestionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
          child: Icon(icon, color: colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Icon(Icons.arrow_forward_rounded, color: colorScheme.primary),
        onTap: onTap,
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SupportCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.38),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                child: Icon(icon, color: colorScheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                color: colorScheme.primary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
