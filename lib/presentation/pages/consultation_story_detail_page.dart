import 'package:flutter/material.dart';

class HealingStory {
  final String title;
  final String preview;
  final List<String> contentSections;

  const HealingStory({
    required this.title,
    required this.preview,
    required this.contentSections,
  });
}

class ConsultationStoryDetailPage extends StatelessWidget {
  final HealingStory story;

  const ConsultationStoryDetailPage({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(story.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                story.preview,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...story.contentSections.asMap().entries.map(
            (entry) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key + 1}.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(entry.value)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
