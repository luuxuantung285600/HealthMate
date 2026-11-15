cimport '../../../core/utils/local_date_key.dart';

class WorkoutExercise {
  const WorkoutExercise({
    required this.id,
    required this.name,
    required this.instruction,
    required this.workSeconds,
    this.restSeconds = 15,
    this.icon = 'fitness_center',
  });

  final String id;
  final String name;
  final String instruction;
  final int workSeconds;
  final int restSeconds;
  final String icon;
}

class WorkoutPlan {
  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.category,
    required this.durationMinutes,
    required this.equipment,
    required this.description,
    required this.exercises,
    required this.color,
  });

  final String id;
  final String name;
  final String category;
  final int durationMinutes;
  final String equipment;
  final String description;
  final List<WorkoutExercise> exercises;
  final int color;
}

abstract final class WorkoutCatalog {
  static const plans = <WorkoutPlan>[
    WorkoutPlan(
      id: 'full_body_easy',
      name: 'Toàn thân nhẹ nhàng',
      category: 'Toàn thân',
      durationMinutes: 12,
      equipment: 'Không cần dụng cụ',
      description: 'Khởi động toàn thân với nhịp độ vừa phải, phù hợp để bắt đầu.',
      color: 0xFF2E7D6B,
      exercises: [
        WorkoutExercise(id: 'march', name: 'Đi bộ tại chỗ', instruction: 'Nâng gối vừa sức, giữ lưng thẳng và thở đều.', workSeconds: 45, icon: 'directions_walk'),
        WorkoutExercise(id: 'squat', name: 'Squat cơ bản', instruction: 'Đẩy hông ra sau, gối hướng theo mũi chân.', workSeconds: 40, icon: 'accessibility_new'),
        WorkoutExercise(id: 'wall_push', name: 'Chống đẩy tường', instruction: 'Giữ thân người thành một đường thẳng, hạ chậm.', workSeconds: 40, icon: 'pan_tool'),
        WorkoutExercise(id: 'bird_dog', name: 'Bird-dog', instruction: 'Duỗi tay và chân đối diện, siết nhẹ cơ bụng.', workSeconds: 40, icon: 'self_improvement'),
      ],
    ),
    WorkoutPlan(
      id: 'mobility_morning',
      name: 'Vận động buổi sáng',
      category: 'Vận động nhẹ',
      durationMinutes: 10,
      equipment: 'Không cần dụng cụ',
      description: 'Đánh thức cơ thể bằng các động tác đơn giản và có kiểm soát.',
      color: 0xFFB56B3C,
      exercises: [
        WorkoutExercise(id: 'reach', name: 'Vươn người', instruction: 'Đưa hai tay lên cao, hít vào và thả lỏng khi hạ xuống.', workSeconds: 35, icon: 'north'),
        WorkoutExercise(id: 'side_step', name: 'Bước sang bên', instruction: 'Bước đều sang hai bên, giữ nhịp thở ổn định.', workSeconds: 45, icon: 'swap_horiz'),
        WorkoutExercise(id: 'shoulder_roll', name: 'Xoay vai', instruction: 'Xoay vai chậm theo vòng tròn, không nhún cổ.', workSeconds: 35, icon: 'rotate_right'),
        WorkoutExercise(id: 'heel_raise', name: 'Nhón gót', instruction: 'Bám nhẹ nếu cần, nâng gót và hạ xuống có kiểm soát.', workSeconds: 40, icon: 'height'),
      ],
    ),
    WorkoutPlan(
      id: 'core_balance',
      name: 'Core & thăng bằng',
      category: 'Toàn thân',
      durationMinutes: 14,
      equipment: 'Thảm tập (tùy chọn)',
      description: 'Tập trung vào cơ bụng và khả năng kiểm soát cơ thể.',
      color: 0xFF5273A6,
      exercises: [
        WorkoutExercise(id: 'dead_bug', name: 'Dead bug', instruction: 'Nằm ngửa, hạ tay và chân đối diện thật chậm.', workSeconds: 40, icon: 'horizontal_rule'),
        WorkoutExercise(id: 'glute_bridge', name: 'Nâng hông', instruction: 'Siết cơ mông ở đỉnh, không ưỡn lưng quá mức.', workSeconds: 45, icon: 'north'),
        WorkoutExercise(id: 'side_balance', name: 'Đứng thăng bằng', instruction: 'Đứng một chân trong khả năng an toàn, đổi bên giữa hiệp.', workSeconds: 35, icon: 'balance'),
      ],
    ),
    WorkoutPlan(
      id: 'stretch_reset',
      name: 'Giãn cơ thư giãn',
      category: 'Giãn cơ',
      durationMinutes: 8,
      equipment: 'Không cần dụng cụ',
      description: 'Chuỗi giãn cơ chậm để kết thúc ngày hoặc sau khi ngồi lâu.',
      color: 0xFF8066A6,
      exercises: [
        WorkoutExercise(id: 'neck', name: 'Giãn cổ', instruction: 'Nghiêng đầu nhẹ sang mỗi bên, không kéo mạnh.', workSeconds: 30, icon: 'accessibility'),
        WorkoutExercise(id: 'chest', name: 'Mở ngực', instruction: 'Đưa vai ra sau, mở ngực và hít thở sâu.', workSeconds: 40, icon: 'open_in_full'),
        WorkoutExercise(id: 'hamstring', name: 'Giãn mặt sau đùi', instruction: 'Giữ lưng dài, chỉ nghiêng đến mức căng nhẹ.', workSeconds: 40, icon: 'airline_seat_legroom_extra'),
        WorkoutExercise(id: 'child_pose', name: 'Tư thế em bé', instruction: 'Thả lỏng vai, thở chậm và đều.', workSeconds: 45, icon: 'self_improvement'),
      ],
    ),
    WorkoutPlan(
      id: 'low_impact_cardio',
      name: 'Cardio không bật nhảy',
      category: 'Vận động nhẹ',
      durationMinutes: 11,
      equipment: 'Không cần dụng cụ',
      description: 'Tăng nhịp tim vừa phải, hạn chế tác động lên khớp.',
      color: 0xFF4E7C86,
      exercises: [
        WorkoutExercise(id: 'step_touch', name: 'Bước chạm', instruction: 'Bước sang bên và chạm chân, giữ vai thả lỏng.', workSeconds: 45, icon: 'directions_walk'),
        WorkoutExercise(id: 'knee_lift', name: 'Nâng gối thấp', instruction: 'Đổi bên đều, nâng gối trong biên độ thoải mái.', workSeconds: 40, icon: 'vertical_align_top'),
        WorkoutExercise(id: 'boxer', name: 'Đấm nhẹ', instruction: 'Đấm thẳng về trước, xoay thân nhẹ và không khóa khuỷu.', workSeconds: 45, icon: 'sports_mma'),
      ],
    ),
    WorkoutPlan(
      id: 'back_hips_relief',
      name: 'Thả lỏng lưng và hông',
      category: 'Giãn cơ',
      durationMinutes: 9,
      equipment: 'Thảm tập (tùy chọn)',
      description: 'Các chuyển động chậm giúp cơ thể dễ chịu hơn sau khi ngồi lâu.',
      color: 0xFF6E8A62,
      exercises: [
        WorkoutExercise(id: 'cat_cow', name: 'Mèo-bò', instruction: 'Di chuyển cột sống theo nhịp thở, không ép biên độ.', workSeconds: 45, icon: 'swap_vert'),
        WorkoutExercise(id: 'hip_flexor', name: 'Giãn gập hông', instruction: 'Giữ thân thẳng, đẩy hông nhẹ về trước.', workSeconds: 40, icon: 'accessibility_new'),
        WorkoutExercise(id: 'spinal_twist', name: 'Xoay lưng nhẹ', instruction: 'Xoay từ ngực, giữ hai vai thấp và thở đều.', workSeconds: 40, icon: 'rotate_90_degrees_ccw'),
      ],
    ),
  ];

  static WorkoutPlan? find(String id) => plans.where((item) => item.id == id).firstOrNull;
}

class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.workoutId,
    required this.workoutName,
    required this.startedAt,
    required this.completedAt,
    required this.activeSeconds,
    required this.caloriesBurned,
    required this.completedExerciseIds,
    required this.dateKey,
    this.createdAt,
  });

  final String id;
  final String workoutId;
  final String workoutName;
  final DateTime startedAt;
  final DateTime completedAt;
  final int activeSeconds;
  final double caloriesBurned;
  final List<String> completedExerciseIds;
  final String dateKey;
  final DateTime? createdAt;

  int get activeMinutes => (activeSeconds / 60).ceil().clamp(1, 1440);
  int get timezoneOffsetMinutes => startedAt.timeZoneOffset.inMinutes;
  String get localDateKey => dateKeyFromTimestampAndOffset(
    completedAt,
    completedAt.timeZoneOffset.inMinutes,
  );
}
