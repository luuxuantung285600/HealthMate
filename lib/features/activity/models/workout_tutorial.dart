/// Curated public tutorials played through YouTube's official embedded player.
/// This manifest grants no right to download or redistribute the source files.
class WorkoutTutorial {
  const WorkoutTutorial({
    required this.videoId,
    required this.title,
    required this.publisher,
    this.note,
    this.endSeconds,
  });

  final String videoId, title, publisher;
  final String? note;
  final double? endSeconds;

  Uri get watchUri => Uri.https('www.youtube.com', '/watch', {'v': videoId});
  Uri get thumbnailUri =>
      Uri.https('i.ytimg.com', '/vi/$videoId/hqdefault.jpg');
}

/// Sources and variant review: docs/workout-media-sourcing-2026-11-10.md.
abstract final class WorkoutTutorials {
  static const byMovement = <String, WorkoutTutorial>{
    'step_jack': WorkoutTutorial(
      videoId: 'JHdVMkRBuRA',
      title: 'Exercise Library: Step Jacks',
      publisher: 'DAREBEE',
    ),
    'wall_sit': WorkoutTutorial(
      videoId: 'tloL0ZiDN3g',
      title: 'Quarter wall squat',
      publisher: 'Rehab My Patient',
      note: 'Hạ nông và giữ yên trong lượt tập; không cần xuống sâu.',
    ),
    'wall_push': WorkoutTutorial(
      videoId: 'IlgO8Sppw0Y',
      title: 'Wall assisted push-up',
      publisher: 'Nuffield Health',
      endSeconds: 36,
      note:
          'Trình phát dừng sau phần chống đẩy tường. Video gốc còn có biến thể dùng ghế, không thuộc lượt tập này.',
    ),
    'standing_crunch': WorkoutTutorial(
      videoId: 'ZL9Y-IIedb0',
      title:
          'Exercise Library: Knee-to-Elbows Home Fitness Abs & Core Exercise',
      publisher: 'DAREBEE',
      note: 'Nâng gối thấp vừa sức, không kéo đầu hoặc cố chạm khuỷu vào gối.',
    ),
    'bodyweight_squat': WorkoutTutorial(
      videoId: 'L61HQqjYFdQ',
      title: 'How to Do Squats: A Guide from Physical Therapists',
      publisher: 'Hinge Health',
    ),
    'reverse_lunge': WorkoutTutorial(
      videoId: '6rKA_et3dGk',
      title: 'How to Do a Reverse Lunge: A Guide from Physical Therapists',
      publisher: 'Hinge Health',
      note: 'Đổi chân sau mỗi lần trở về vị trí đứng.',
    ),
    'march_in_place': WorkoutTutorial(
      videoId: '9wl_AiNhYP0',
      title: 'How to march on the spot',
      publisher: 'Rehab My Patient',
      note: 'Chọn nhịp chậm, nâng gối vừa sức; không cần nâng tay qua đầu.',
    ),
    'kneeling_plank': WorkoutTutorial(
      videoId: 'UOXuHkBfDhU',
      title: 'How to do a kneeling plank',
      publisher: 'Rehab My Patient',
    ),
    'glute_bridge': WorkoutTutorial(
      videoId: 'AQOJhgB1O-I',
      title: 'Hip Bridge',
      publisher: 'Nuffield Health',
    ),
    'bird_dog': WorkoutTutorial(
      videoId: 'xEDnlOxeJH4',
      title:
          'How to Do the Bird Dog Exercise: A Guide from Physical Therapists',
      publisher: 'Hinge Health',
    ),
    'side_plank_left': WorkoutTutorial(
      videoId: 'UurF0EhHFLg',
      title: 'How to do a Side plank kneeling',
      publisher: 'Rehab My Patient',
      note:
          'Video minh họa kỹ thuật một bên. Lượt này chống cẳng tay TRÁI, gối gập trên thảm.',
    ),
    'side_plank_right': WorkoutTutorial(
      videoId: 'UurF0EhHFLg',
      title: 'How to do a Side plank kneeling',
      publisher: 'Rehab My Patient',
      note:
          'Video minh họa kỹ thuật một bên. Lượt này chống cẳng tay PHẢI, gối gập trên thảm.',
    ),
    'calf_raise': WorkoutTutorial(
      videoId: 'MikhwO7lrLI',
      title: 'Standing Heel Raises',
      publisher: 'NHS Lanarkshire',
    ),
    'hip_hinge': WorkoutTutorial(
      videoId: '2W_gXhut5S8',
      title: 'How to Do a Hip Hinge: A Guide from Physical Therapists',
      publisher: 'Hinge Health',
    ),
  };
}
