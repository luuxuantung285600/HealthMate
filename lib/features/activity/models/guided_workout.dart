/// Editorial movement instructions. These are local workout content, not logs.
enum MovementPose {
  jack,
  wallSit,
  wallPush,
  crunch,
  squat,
  lunge,
  march,
  plank,
  bridge,
  birdDog,
  sideLeft,
  sideRight,
  calfRaise,
  hinge,
}

class WorkoutMovement {
  const WorkoutMovement(
    this.id,
    this.name,
    this.focus,
    this.pose,
    this.steps,
    this.easier,
  );
  final String id, name, focus;
  final MovementPose pose;
  final List<String> steps;
  final String easier;
}

class GuidedWorkout {
  const GuidedWorkout({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.tag,
    required this.equipment,
    required this.movements,
  });
  final String id, name, subtitle, tag, equipment;
  final List<WorkoutMovement> movements;
}

enum WorkoutPace {
  gentle('Nhẹ hơn', 20, 20, 1),
  standard('Tiêu chuẩn', 30, 10, 1),
  twoRounds('2 vòng', 30, 10, 2);

  const WorkoutPace(
    this.label,
    this.workSeconds,
    this.restSeconds,
    this.rounds,
  );
  final String label;
  final int workSeconds, restSeconds, rounds;
  Duration totalDuration(GuidedWorkout workout) {
    final count = workout.movements.length * rounds;
    return Duration(
      seconds: 5 + count * workSeconds + (count - 1) * restSeconds,
    );
  }
}

String workoutTime(Duration duration) {
  final seconds = duration.inSeconds;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

abstract final class GuidedWorkouts {
  static const jack = WorkoutMovement(
    'step_jack',
    'Bước ngang mở tay',
    'Toàn thân',
    MovementPose.jack,
    [
      'Đứng thẳng, hai chân gần nhau.',
      'Bước một chân sang bên và nâng hai tay trong tầm thoải mái.',
      'Thu chân về rồi đổi bên; giữ nhịp thở đều.',
    ],
    'Bước ngắn hơn và giữ tay dưới vai.',
  );
  static const wallSit = WorkoutMovement(
    'wall_sit',
    'Tựa tường hạ người',
    'Chân',
    MovementPose.wallSit,
    [
      'Tựa lưng vào tường, hai chân đặt phía trước.',
      'Hạ người một đoạn vừa sức, gối hướng cùng mũi chân.',
      'Giữ lưng tựa tường và thở đều; không cần xuống sâu.',
    ],
    'Đứng cao hơn hoặc nghỉ sớm khi mỏi.',
  );
  static const wallPush = WorkoutMovement(
    'wall_push',
    'Chống đẩy tường',
    'Ngực & tay',
    MovementPose.wallPush,
    [
      'Đặt hai bàn tay lên tường ngang vai.',
      'Giữ thân người thẳng, gập khuỷu để đưa ngực gần tường.',
      'Đẩy chậm về vị trí đầu, tránh nín thở.',
    ],
    'Đứng gần tường hơn để giảm lực.',
  );
  static const crunch = WorkoutMovement(
    'standing_crunch',
    'Co gối chéo',
    'Thân giữa',
    MovementPose.crunch,
    [
      'Đứng thẳng, gập tay trước ngực hoặc đặt nhẹ cạnh đầu; không kéo cổ.',
      'Nâng một gối về phía khuỷu tay đối diện, xoay thân nhẹ trong tầm thoải mái.',
      'Hạ chậm, đổi bên; không giật hoặc kéo cổ.',
    ],
    'Giữ tay trước ngực và nâng gối thấp; có thể vịn tường.',
  );
  static const squat = WorkoutMovement(
    'bodyweight_squat',
    'Squat vừa sức',
    'Chân & mông',
    MovementPose.squat,
    [
      'Đặt chân rộng khoảng vai.',
      'Đẩy hông ra sau, hạ người trong tầm thoải mái; gối theo mũi chân.',
      'Đạp bàn chân xuống sàn để đứng lên, giữ lưng tự nhiên.',
    ],
    'Hạ nông hơn hoặc vịn một điểm tựa cố định.',
  );
  static const lunge = WorkoutMovement(
    'reverse_lunge',
    'Chùng chân lùi',
    'Chân & thăng bằng',
    MovementPose.lunge,
    [
      'Đứng thẳng, chân rộng bằng hông.',
      'Bước một chân ra sau, hạ nhẹ cả hai gối.',
      'Trở về rồi đổi bên; giữ chân trước bám sàn.',
    ],
    'Chỉ chạm mũi chân ra sau, không hạ gối.',
  );
  static const march = WorkoutMovement(
    'march_in_place',
    'Đi bộ tại chỗ',
    'Vận động nhẹ',
    MovementPose.march,
    [
      'Đứng thẳng trên mặt sàn phẳng.',
      'Nâng chân luân phiên, đánh tay tự nhiên.',
      'Đi ở nhịp bạn vẫn có thể nói chuyện thoải mái.',
    ],
    'Bước chậm và thấp; vịn tường nếu cần.',
  );
  static const plank = WorkoutMovement(
    'kneeling_plank',
    'Plank chống gối',
    'Thân giữa',
    MovementPose.plank,
    [
      'Đặt cẳng tay và đầu gối lên thảm, khuỷu dưới vai.',
      'Giữ một đường thẳng từ đầu đến gối, mắt nhìn sàn.',
      'Thở đều, tránh võng lưng hoặc nhấc vai.',
    ],
    'Giữ ngắn hơn rồi nghỉ, hoặc chống tay vào tường.',
  );
  static const bridge = WorkoutMovement(
    'glute_bridge',
    'Nâng hông',
    'Mông & thân giữa',
    MovementPose.bridge,
    [
      'Nằm ngửa trên thảm, gập gối và đặt chân xuống sàn.',
      'Siết nhẹ mông, nâng hông trong tầm thoải mái.',
      'Hạ chậm; không ưỡn lưng hay đẩy lực lên cổ.',
    ],
    'Nâng hông thấp hơn, giữ nhịp chậm.',
  );
  static const birdDog = WorkoutMovement(
    'bird_dog',
    'Duỗi tay chân đối bên',
    'Thăng bằng',
    MovementPose.birdDog,
    [
      'Chống hai tay và hai gối lên thảm.',
      'Duỗi tay và chân đối diện, giữ hông cân bằng.',
      'Thu về chậm rồi đổi bên, mắt nhìn sàn.',
    ],
    'Chỉ duỗi một tay hoặc một chân mỗi lần.',
  );
  static const sideLeft = WorkoutMovement(
    'side_plank_left',
    'Plank nghiêng trái',
    'Thân giữa',
    MovementPose.sideLeft,
    [
      'Nằm nghiêng trái, chống cẳng tay trái; gối gập trên thảm.',
      'Nâng hông nhẹ, khuỷu nằm dưới vai.',
      'Giữ trong tầm thoải mái, thở đều rồi hạ xuống.',
    ],
    'Giữ hông trên thảm và chỉ siết nhẹ thân giữa.',
  );
  static const sideRight = WorkoutMovement(
    'side_plank_right',
    'Plank nghiêng phải',
    'Thân giữa',
    MovementPose.sideRight,
    [
      'Nằm nghiêng phải, chống cẳng tay phải; gối gập trên thảm.',
      'Nâng hông nhẹ, khuỷu nằm dưới vai.',
      'Giữ trong tầm thoải mái, thở đều rồi hạ xuống.',
    ],
    'Giữ hông trên thảm và chỉ siết nhẹ thân giữa.',
  );
  static const calfRaise = WorkoutMovement(
    'calf_raise',
    'Nhón gót',
    'Bắp chân',
    MovementPose.calfRaise,
    [
      'Đứng thẳng, có thể vịn tường.',
      'Nâng hai gót từ từ, giữ trọng tâm cân bằng.',
      'Hạ gót nhẹ nhàng về sàn, không nảy người.',
    ],
    'Nâng thấp hơn và luôn giữ điểm tựa.',
  );
  static const hinge = WorkoutMovement(
    'hip_hinge',
    'Gập hông đứng',
    'Hông & mông',
    MovementPose.hinge,
    [
      'Đứng chân rộng bằng hông, gối hơi chùng.',
      'Đẩy hông ra sau, nghiêng thân vừa phải và giữ lưng tự nhiên.',
      'Trở lại tư thế đứng bằng lực hông, không giật lưng.',
    ],
    'Nghiêng ít hơn và đặt tay lên hông.',
  );

  static const all = [
    GuidedWorkout(
      id: 'full_body',
      name: 'Toàn thân',
      subtitle:
          'Một khoảng nghỉ cho bạn. Vận động từng chút, đều đặn mỗi ngày.',
      tag: 'Toàn thân',
      equipment: 'Tường chắc chắn · thảm · khoảng trống',
      movements: [
        jack,
        wallSit,
        wallPush,
        crunch,
        squat,
        lunge,
        march,
        plank,
        bridge,
        birdDog,
        sideLeft,
        sideRight,
      ],
    ),
    GuidedWorkout(
      id: 'gentle_start',
      name: 'Bắt đầu nhẹ nhàng',
      subtitle: 'Các động tác đứng, không bật nhảy và không cần nằm sàn.',
      tag: 'Không bật nhảy',
      equipment: 'Tường chắc chắn · khoảng trống',
      movements: [
        march,
        jack,
        wallPush,
        calfRaise,
        hinge,
        crunch,
        squat,
        march,
      ],
    ),
    GuidedWorkout(
      id: 'core_stability',
      name: 'Vững thân giữa',
      subtitle:
          'Chuyển động có kiểm soát, tập trung vào thăng bằng và giữ thân.',
      tag: 'Thân giữa',
      equipment: 'Thảm · khoảng trống',
      movements: [
        crunch,
        plank,
        bridge,
        birdDog,
        sideLeft,
        sideRight,
        bridge,
        birdDog,
      ],
    ),
  ];
}
