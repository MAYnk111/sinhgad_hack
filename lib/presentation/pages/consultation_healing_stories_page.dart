import 'package:flutter/material.dart';
import 'package:maternal_infant_care/presentation/pages/consultation_story_detail_page.dart';

class ConsultationHealingStoriesPage extends StatelessWidget {
  const ConsultationHealingStoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    const stories = [
      HealingStory(
        title: 'A Journey Through Loss and Healing',
        preview:
            'A mother reflects on grief, family support, and rebuilding hope step by step.',
        contentSections: [
          'When I first faced loss, I felt numb and overwhelmed. Recovery started when I allowed myself to feel every emotion without guilt.',
          'I created a small daily routine: hydration, short walks, and talking openly with my partner. This gave me stability.',
          'With medical follow-up and counseling, I slowly felt stronger. Healing did not erase the loss, but it helped me carry it with compassion.',
        ],
      ),
      HealingStory(
        title: 'Finding Strength After Miscarriage',
        preview:
            'A story about practical self-care, doctor guidance, and emotional resilience.',
        contentSections: [
          'My recovery plan started with clear medical instructions and strict rest. Following those steps reduced fear and confusion.',
          'I began journaling each day and noticed gradual progress in sleep, appetite, and mood.',
          'I learned that asking for help is a strength. Support groups and trusted friends gave me perspective and comfort.',
        ],
      ),
      HealingStory(
        title: 'Stories of Hope and Recovery',
        preview:
            'Collective reflections on healing, support systems, and moving forward with confidence.',
        contentSections: [
          'Many women shared that emotional recovery took time, but consistent care made a real difference.',
          'Gentle breathing practice, balanced meals, and regular follow-up appointments were common foundations of progress.',
          'Hope returned gradually. Healing became possible through patience, support, and informed medical care.',
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Healing Stories')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: Text(
                story.title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(story.preview),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ConsultationStoryDetailPage(story: story),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
