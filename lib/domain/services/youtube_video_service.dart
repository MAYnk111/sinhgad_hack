import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class PregnancyLearningVideo {
  final String title;
  final String videoId;
  final String? description;
  final String? duration;

  const PregnancyLearningVideo({
    required this.title,
    required this.videoId,
    this.description,
    this.duration,
  });
}

class YoutubeVideoService {
  final Map<String, List<PregnancyLearningVideo>> pregnancyVideos = {
    'First Trimester': const [
      PregnancyLearningVideo(
        title: 'Pregnancy week by week: Weeks 1-9 (BabyCenter)',
        videoId: 'Hx_EM7ibcsY',
      ),
      PregnancyLearningVideo(
        title: 'Pregnancy week by week: Weeks 10-14 (BabyCenter)',
        videoId: 'mxT59fGyK1I',
      ),
      PregnancyLearningVideo(
        title: 'Pregnancy week by week: Weeks 15-20 (BabyCenter)',
        videoId: 'O4WzIMrb9Vs',
      ),
    ],
    'Second Trimester': const [
      PregnancyLearningVideo(
        title: 'Pregnancy week by week: Weeks 21-27 (BabyCenter)',
        videoId: '-d5eIKwg5e8',
      ),
      PregnancyLearningVideo(
        title: 'Does Lifestyle Affect Pregnancy and Congenital Birth Defects? (Mayo Clinic)',
        videoId: '2UqpIiMci3U',
      ),
      PregnancyLearningVideo(
        title: 'ER doctor: "Penguin trick" pregnant moms can use to prevent falls (BabyCenter)',
        videoId: 'npaFLc47N1Q',
      ),
    ],
    'Third Trimester': const [
      PregnancyLearningVideo(
        title: 'Pregnancy week by week: Weeks 28-37 (BabyCenter)',
        videoId: 'BGKm7-2-CPo',
      ),
      PregnancyLearningVideo(
        title: 'Labor and Birth (BabyCenter)',
        videoId: '9NQpIW6tYDM',
      ),
      PregnancyLearningVideo(
        title: 'Women’s health is more than reproduction (WHO)',
        videoId: 'U2AUIJT0zXw',
      ),
    ],
  };

  YoutubePlayerController createController(String videoId) {
    return YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
      ),
    );
  }

  String thumbnailFor(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }
}
