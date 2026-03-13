import 'package:flutter/material.dart';
import 'package:maternal_infant_care/presentation/pages/careflow_ai_page.dart';
import 'package:maternal_infant_care/presentation/pages/consultation_healing_stories_page.dart';
import 'package:maternal_infant_care/presentation/pages/consultation_recovery_guidance_page.dart';
import 'package:maternal_infant_care/presentation/pages/consultation_meditation_page.dart';
import 'package:maternal_infant_care/presentation/pages/consultation_recovery_videos_page.dart';

class ConsultationResourcesPage extends StatelessWidget {
  const ConsultationResourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    const videos = [
      RecoveryVideoItem(
        title: 'Women\'s health is more than reproduction',
        videoId: 'U2AUIJT0zXw',
        channel: 'World Health Organization (WHO)',
      ),
      RecoveryVideoItem(
        title: 'Lifestyle and pregnancy health guidance',
        videoId: '2UqpIiMci3U',
        channel: 'Mayo Clinic',
      ),
      RecoveryVideoItem(
        title: 'Labor and birth education',
        videoId: '9NQpIW6tYDM',
        channel: 'BabyCenter',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultation Resources'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ResourceNavCard(
            title: 'Healing Stories',
            subtitle: 'Read personal recovery journeys and hopeful reflections.',
            icon: Icons.menu_book_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ConsultationHealingStoriesPage(),
              ),
            ),
          ),
          _ResourceNavCard(
            title: 'Recovery Guidance',
            subtitle: 'Practical physical healing information and self-care.',
            icon: Icons.health_and_safety_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ConsultationRecoveryGuidancePage(),
              ),
            ),
          ),
          _ResourceNavCard(
            title: 'Meditation & Relaxation',
            subtitle: 'Guided calm sessions, breathing, and soothing audio.',
            icon: Icons.self_improvement,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ConsultationMeditationPage(),
              ),
            ),
          ),
          _ResourceNavCard(
            title: 'Support Chat',
            subtitle: 'Ask Vatsalya AI about emotional healing and recovery care.',
            icon: Icons.chat_bubble_outline,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VatsalyaAiPage()),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Recovery Videos',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          ...videos.map(
            (video) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 2,
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    'https://img.youtube.com/vi/${video.videoId}/hqdefault.jpg',
                    width: 90,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(video.channel),
                trailing: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ConsultationRecoveryVideosPage(
                        videos: videos,
                        initialVideo: video,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceNavCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ResourceNavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }
}
