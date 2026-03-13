import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ConsultationResourceDetailPage extends StatelessWidget {
  final String title;
  final String description;
  final List<String> details;
  final List<ConsultationVideoResource> videos;

  const ConsultationResourceDetailPage({
    super.key,
    required this.title,
    required this.description,
    required this.details,
    this.videos = const [],
  });

  Future<void> _openVideo(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open video link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(description),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Key Guidance',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  ...details.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 18, color: colorScheme.primary),
                          const SizedBox(width: 10),
                          Expanded(child: Text(item)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (videos.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Video Resources',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    ...videos.map(
                      (video) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.play_circle_fill,
                            color: colorScheme.primary),
                        title: Text(video.title),
                        trailing: const Icon(Icons.open_in_new),
                        onTap: () => _openVideo(context, video.url),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ConsultationVideoResource {
  final String title;
  final String url;

  const ConsultationVideoResource({required this.title, required this.url});
}
