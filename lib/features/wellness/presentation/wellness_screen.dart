import 'dart:async';
import '../../../core/widgets/help_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/local_date_key.dart';
import '../../../core/widgets/confirmed_save.dart';
import '../../auth/providers/auth_providers.dart';
import '../../food_library/presentation/food_nutrition_text.dart';
import '../../food_library/presentation/food_portion_dialog.dart';
import '../../nutrition/models/extra_nutrients.dart';
import '../../nutrition/models/food_catalog_search.dart';
import '../../nutrition/models/food_diet.dart';
import '../../nutrition/models/food_avoidance.dart';
import '../../nutrition_targets/providers/nutrition_target_providers.dart';
import '../../nutrition/presentation/food_diet_filter.dart';
import '../../profile/providers/profile_providers.dart';
import '../../nutrition/models/nutrition_models.dart';
import '../../nutrition/presentation/meal_form_dialog.dart';
import '../../nutrition/providers/nutrition_providers.dart';
import '../models/wellness_models.dart';
import '../models/meal_plan_suggestion.dart';
import '../providers/wellness_providers.dart';
import '../providers/sleep_insight_providers.dart';
import 'energy_panel.dart';
import 'sleep_insights.dart';
import 'weight_progress_panel.dart';
import 'wellness_hub.dart';
import '../../../core/theme/reference_palette.dart';

class WellnessScreen extends StatefulWidget {
  const WellnessScreen({super.key, this.initialTab = -1});
  final int initialTab;
  @override
  State<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends State<WellnessScreen> {
  late int _tab = widget.initialTab.clamp(-1, 5);
  final _tabScroll = ScrollController();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _tab >= 3 && _tabScroll.hasClients) {
        _tabScroll.jumpTo(_tabScroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _tabScroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant WellnessScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _tab = widget.initialTab.clamp(-1, 5);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _tab == -1,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && _tab >= 0) setState(() => _tab = -1);
    },
    child: Scaffold(
      body: _tab == -1
          ? WellnessHub(onOpen: (tab) => setState(() => _tab = tab))
          : AppCanvas(
              child: Column(
                children: [
                  AppBar(
                    title: Text(
                      const [
                        'Nhắc bữa',
                        'Thực đơn',
                        'Bước chân',
                        'Giấc ngủ',
                        'Dưỡng chất',
                        'Cân nặng',
                      ][_tab],
                    ),
                    leading: BackButton(
                      onPressed: () => setState(() => _tab = -1),
                    ),
                    actions: [
                      IconButton(
                        tooltip: 'Tất cả thói quen',
                        onPressed: () => setState(() => _tab = -1),
                        icon: const Icon(Icons.grid_view_rounded),
                      ),
                    ],
                  ),
                  SingleChildScrollView(
                    controller: _tabScroll,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        for (final e in [
                          'Nhắc bữa',
                          'Thực đơn',
                          'Bước chân',
                          'Giấc ngủ',
                          'Dưỡng chất',
                          'Cân nặng & ngân sách',
                        ].indexed)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              key: ValueKey('wellness-tab-${e.$1}'),
                              label: Text(e.$2),
                              selected: _tab == e.$1,
                              onSelected: (_) => setState(() => _tab = e.$1),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: KeyedSubtree(
                      key: ValueKey(_tab),
                      child: switch (_tab) {
                        0 => const ReminderPanel(),
                        1 => const MealPlannerPanel(),
                        2 => const StepPanel(),
                        3 => const SleepPanel(),
                        4 => const NutrientPanel(),
                        _ => const WeightProgressPanel(),
                      },
                    ),
                  ),
                ],
              ),
            ),
    ),
  );
}

Widget _problem(VoidCallback retry) => Column(
  children: [
    const Text(
      'Chưa tải/lưu được dữ liệu. Kiểm tra mạng và quyền truy cập, rồi thử lại.',
    ),
    TextButton(onPressed: retry, child: const Text('Thử lại')),
  ],
);

String _failure(Object error) => error is FormatException
    ? error.message
    : error is PlatformException
    ? (error.message ?? 'Chưa thể thực hiện trên thiết bị.')
    : 'Chưa xác nhận được thao tác. Kiểm tra mạng/quyền truy cập và thử lại.';

abstract class WellnessPanelState<T extends ConsumerStatefulWidget>
    extends ConsumerState<T> {
  bool busy = false;
  String? message;
  Future<bool> act(Future<void> Function(String uid) operation) async {
    if (busy) return false;
    final uid = ref.read(authSessionProvider).value?.uid;
    if (uid == null) return false;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await operation(uid);
      if (!mounted || ref.read(authSessionProvider).value?.uid != uid) {
        return false;
      }
      setState(() => message = 'Đã hoàn tất.');
      return true;
    } catch (e) {
      if (mounted && ref.read(authSessionProvider).value?.uid == uid) {
        setState(() => message = _failure(e));
      }
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget feedback() => Column(
    children: [
      if (busy) const LinearProgressIndicator(),
      if (message != null)
        Padding(padding: const EdgeInsets.all(8), child: Text(message!)),
    ],
  );
}

class ReminderPanel extends ConsumerStatefulWidget {
  const ReminderPanel({super.key});
  @override
  ConsumerState<ReminderPanel> createState() => _ReminderPanelState();
}

class _ReminderPanelState extends WellnessPanelState<ReminderPanel> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(localWellnessProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Nhắc ghi bữa trên thiết bị này'),
        const Text(
          'Miễn phí, không cần gửi thông báo từ máy chủ. Nếu bữa đã được app ghi nhận trên máy, lời nhắc hôm đó sẽ được bỏ qua.',
        ),
        const SizedBox(height: 12),
        feedback(),
        state.when(
          skipLoadingOnReload: false,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              _problem(() => ref.invalidate(localWellnessProvider)),
          data: (local) {
            if (!local.available) {
              return const Text(
                'Nhắc bữa cục bộ hiện hỗ trợ ứng dụng Android.',
              );
            }
            return Column(
              children: [
                if (!local.permission)
                  const Text(
                    'Thông báo đang tắt. Quyền chỉ được hỏi khi bạn bật một lời nhắc.',
                  ),
                for (final r in local.reminders)
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          key: ValueKey('reminder-${r.meal.name}'),
                          title: Text(r.meal.label),
                          subtitle: Text(
                            TimeOfDay(
                              hour: r.minute ~/ 60,
                              minute: r.minute % 60,
                            ).format(context),
                          ),
                          value: r.enabled,
                          onChanged: busy
                              ? null
                              : (enabled) => act(
                                  (_) => ref
                                      .read(localWellnessProvider.notifier)
                                      .saveReminders([
                                        for (final value in local.reminders)
                                          value.meal == r.meal
                                              ? MealReminder(
                                                  r.meal,
                                                  r.minute,
                                                  enabled: enabled,
                                                )
                                              : value,
                                      ]),
                                ),
                        ),
                        TextButton(
                          onPressed: busy
                              ? null
                              : () async {
                                  final ownerUid = ref
                                      .read(authSessionProvider)
                                      .value
                                      ?.uid;
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay(
                                      hour: r.minute ~/ 60,
                                      minute: r.minute % 60,
                                    ),
                                  );
                                  if (time == null ||
                                      !mounted ||
                                      ref
                                              .read(authSessionProvider)
                                              .value
                                              ?.uid !=
                                          ownerUid) {
                                    return;
                                  }
                                  await act(
                                    (_) => ref
                                        .read(localWellnessProvider.notifier)
                                        .saveReminders([
                                          for (final value in local.reminders)
                                            value.meal == r.meal
                                                ? MealReminder(
                                                    r.meal,
                                                    time.hour * 60 +
                                                        time.minute,
                                                    enabled: r.enabled,
                                                  )
                                                : value,
                                        ]),
                                  );
                                },
                          child: const Text('Đổi giờ'),
                        ),
                      ],
                    ),
                  ),
                OutlinedButton(
                  key: const ValueKey('test-meal-reminder'),
                  onPressed: busy
                      ? null
                      : () => act((uid) async {
                          final device = ref.read(wellnessDeviceProvider);
                          if (!await device.requestNotifications()) {
                            throw const FormatException(
                              'Chưa được cấp quyền thông báo.',
                            );
                          }
                          if (ref.read(authSessionProvider).value?.uid != uid) {
                            return;
                          }
                          await device.testReminder(uid);
                        }),
                  child: const Text('Thử thông báo'),
                ),
                const Text(
                  'Android có thể nhắc trễ khi tiết kiệm pin. Sau khi buộc dừng app, hãy mở lại để khôi phục lịch. Không yêu cầu quyền báo thức chính xác.',
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class SleepPanel extends ConsumerStatefulWidget {
  const SleepPanel({super.key});
  @override
  ConsumerState<SleepPanel> createState() => _SleepPanelState();
}

class _SleepPanelState extends WellnessPanelState<SleepPanel> {
  Timer? _tick;
  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String duration(Duration d) => d.isNegative
      ? 'Đồng hồ thiết bị đã thay đổi'
      : '${d.inHours} giờ ${d.inMinutes % 60} phút';
  Future<void> edit({SleepLog? log, DateTime? timerStart}) async {
    final now = DateTime.now();
    final uid = ref.read(authSessionProvider).value?.uid;
    if (uid == null) return;
    final result = await showDialog<(DateTime, DateTime)>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AccountBoundDialog(
        child: SleepTimeDialog(
          start:
              log?.start ??
              timerStart ??
              now.subtract(const Duration(hours: 8)),
          end: log?.end ?? now,
          onSave: (times) async {
            if (ref.read(authSessionProvider).value?.uid != uid) return false;
            await ref
                .read(wellnessRepositoryProvider)
                .saveSleep(
                  uid,
                  times.$1,
                  times.$2,
                  id: log?.id,
                  finishTimer: timerStart != null,
                  expectedTimerStart: timerStart,
                );
            if (ref.read(authSessionProvider).value?.uid == uid) {
              ref.invalidate(sleepRangeProvider);
            }
            return ref.read(authSessionProvider).value?.uid == uid;
          },
        ),
      ),
    );
    if (result == null ||
        !mounted ||
        ref.read(authSessionProvider).value?.uid != uid) {
      return;
    }
    setState(() => message = 'Đã lưu giờ ngủ.');
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(sleepStartProvider),
        history = ref.watch(sleepHistoryProvider);
    final format = DateFormat('dd/MM HH:mm');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Giờ ngủ do bạn tự ghi nhận'),
        const Text(
          'Bấm khi đi ngủ và khi thức dậy. Đây là khoảng thời gian tự ghi, không đo giai đoạn hay chất lượng giấc ngủ.',
        ),
        feedback(),
        active.when(
          skipLoadingOnReload: false,
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => _problem(() => ref.invalidate(sleepStartProvider)),
          data: (start) => start == null
              ? FilledButton(
                  key: const ValueKey('start-sleep'),
                  onPressed: busy
                      ? null
                      : () => act(
                          (uid) => ref
                              .read(wellnessRepositoryProvider)
                              .startSleep(uid),
                        ),
                  child: const Text('Bắt đầu ngủ'),
                )
              : Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('Bắt đầu: ${format.format(start.toLocal())}'),
                        Text(duration(DateTime.now().difference(start))),
                        FilledButton(
                          key: const ValueKey('finish-sleep'),
                          onPressed: busy
                              ? null
                              : () => edit(timerStart: start),
                          child: const Text('Đã thức dậy · kiểm tra giờ'),
                        ),
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => act(
                                  (uid) => ref
                                      .read(wellnessRepositoryProvider)
                                      .cancelSleep(uid),
                                ),
                          child: const Text('Hủy lần đếm'),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        OutlinedButton(
          key: const ValueKey('manual-sleep'),
          onPressed: busy ? null : () => edit(),
          child: const Text('Thêm giờ ngủ thủ công'),
        ),
        const SizedBox(height: 12),
        const SleepInsights(),
        const BedtimeReminderPanel(),
        const Text('Lịch sử · 60 lần gần nhất'),
        history.when(
          skipLoadingOnReload: false,
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => _problem(() => ref.invalidate(sleepHistoryProvider)),
          data: (logs) => logs.isEmpty
              ? const Text('Chưa ghi giờ ngủ.')
              : Column(
                  children: [
                    for (final log in logs)
                      Card(
                        child: ListTile(
                          title: Text(duration(log.duration)),
                          subtitle: Text(
                            '${format.format(log.start.toLocal())} → ${format.format(log.end.toLocal())}',
                          ),
                          onTap: busy ? null : () => edit(log: log),
                          trailing: IconButton(
                            tooltip: 'Xóa lần ngủ',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: busy
                                ? null
                                : () async {
                                    if (await _confirm(
                                          context,
                                          'Xóa lần ghi giờ ngủ này?',
                                          ref,
                                        ) &&
                                        mounted) {
                                      await act((uid) async {
                                        await ref
                                            .read(wellnessRepositoryProvider)
                                            .deleteSleep(uid, log.id);
                                        if (ref
                                                .read(authSessionProvider)
                                                .value
                                                ?.uid ==
                                            uid) {
                                          ref.invalidate(sleepRangeProvider);
                                        }
                                      });
                                    }
                                  },
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

Future<bool> _confirm(BuildContext context, String text, WidgetRef ref) async {
  final uid = ref.read(authSessionProvider).value?.uid;
  final accepted =
      await showDialog<bool>(
        context: context,
        builder: (c) => AccountBoundDialog(
          child: AlertDialog(
            title: Text(text),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Xác nhận'),
              ),
            ],
          ),
        ),
      ) ??
      false;
  return context.mounted &&
      ref.read(authSessionProvider).value?.uid == uid &&
      accepted;
}

class SleepTimeDialog extends StatefulWidget {
  const SleepTimeDialog({
    required this.start,
    required this.end,
    this.onSave,
    super.key,
  });
  final DateTime start, end;
  final Future<bool> Function((DateTime, DateTime))? onSave;
  @override
  State<SleepTimeDialog> createState() => _SleepTimeDialogState();
}

class _SleepTimeDialogState extends State<SleepTimeDialog>
    with ConfirmedSave<(DateTime, DateTime), SleepTimeDialog> {
  late DateTime start = widget.start.toLocal(), end = widget.end.toLocal();
  String? error;
  Future<void> pick(bool first) async {
    final current = first ? start : end, now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      builder: (_, child) => AccountBoundDialog(child: child!),
      initialDate: current.isAfter(now) ? now : current,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      builder: (_, child) => AccountBoundDialog(child: child!),
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;
    final value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (first) {
        start = value;
      } else {
        end = value;
      }
      error = null;
    });
  }

  @override
  Widget build(BuildContext context) => guardSave(
    AlertDialog(
      title: const Text('Kiểm tra giờ ngủ'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Đi ngủ'),
            subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(start)),
            onTap: () => pick(true),
          ),
          ListTile(
            title: const Text('Thức dậy'),
            subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(end)),
            onTap: () => pick(false),
          ),
          if (error != null) Text(error!),
          saveFeedback(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          key: const ValueKey('save-sleep'),
          onPressed: () {
            final validation = SleepLog.validate(start, end, DateTime.now());
            if (validation != null) {
              setState(() => error = validation);
              return;
            }
            saveDraft((start, end), widget.onSave);
          },
          child: const Text('Lưu'),
        ),
      ],
    ),
  );
}

class StepPanel extends ConsumerStatefulWidget {
  const StepPanel({super.key});
  @override
  ConsumerState<StepPanel> createState() => _StepPanelState();
}

class _StepPanelState extends WellnessPanelState<StepPanel>
    with WidgetsBindingObserver {
  Timer? tick;
  Map<String, dynamic>? snapshot;
  bool reading = false;
  String? owner;
  DateTime? lastSync;
  int? lastSyncedCount;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    tick = Timer.periodic(const Duration(seconds: 3), (_) => refresh());
    WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
  }

  @override
  void dispose() {
    tick?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  Future<void> refresh() async {
    if (reading || !mounted) return;
    final uid = ref.read(authSessionProvider).value?.uid;
    if (uid == null) return;
    reading = true;
    try {
      final local = await ref.read(localWellnessProvider.future);
      if (!local.available || local.uid != uid) {
        if (mounted && ref.read(authSessionProvider).value?.uid == uid) {
          setState(() {
            owner = uid;
            snapshot = {'supported': false};
          });
        }
        return;
      }
      final data = await ref.read(wellnessDeviceProvider).steps(uid);
      if (!mounted || ref.read(authSessionProvider).value?.uid != uid) return;
      if (owner != uid) {
        lastSync = null;
        lastSyncedCount = null;
      }
      setState(() {
        owner = uid;
        snapshot = data;
      });
      final day = localDateKey(DateTime.now());
      final row = (data['days'] as Map?)?[day] as Map?;
      if (row != null &&
          row['steps'] != lastSyncedCount &&
          (lastSync == null ||
              DateTime.now().difference(lastSync!) >
                  const Duration(minutes: 1))) {
        lastSync = DateTime.now();
        try {
          await ref.read(wellnessRepositoryProvider).syncSteps(uid, {
            'day': day,
            ...Map<String, dynamic>.from(row),
          });
          if (mounted && ref.read(authSessionProvider).value?.uid == uid) {
            lastSyncedCount = row['steps'] as int;
          }
        } catch (_) {
          if (mounted && ref.read(authSessionProvider).value?.uid == uid) {
            setState(
              () => message =
                  'Bước chân đang giữ trên máy; chưa đồng bộ máy chủ. Có thể thử lại.',
            );
          }
        }
      }
    } catch (e) {
      if (mounted && ref.read(authSessionProvider).value?.uid == uid) {
        setState(() => message = _failure(e));
      }
    } finally {
      reading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(stepHistoryProvider);
    final currentUid = ref.watch(authSessionProvider).value?.uid;
    final currentSnapshot = owner == currentUid ? snapshot : null;
    final day = localDateKey(DateTime.now());
    final row = (currentSnapshot?['days'] as Map?)?[day] as Map?;
    final supported = currentSnapshot?['supported'] == true;
    final running = currentSnapshot?['running'] == true;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Bộ đếm bước chân'),
        const Text(
          'Dùng cảm biến bước chân, không cần API trả phí hoặc vị trí GPS. Chỉ ghi trong khoảng theo dõi. Calo đi bộ là ước tính riêng và chỉ cộng ngân sách khi bạn xác nhận. Lịch sử giữ bản đo cao nhất mỗi ngày, không cộng chồng số bước từ nhiều điện thoại.',
        ),
        feedback(),
        if (currentSnapshot == null)
          const LinearProgressIndicator()
        else if (!supported)
          const Text(
            'Thiết bị/nền tảng chưa cung cấp cảm biến bước chân. Không tạo số bước giả. Bạn vẫn xem được lịch sử đã đồng bộ.',
          ),
        if (supported) ...[
          Text(
            row == null
                ? 'Hôm nay chưa đo'
                : '${row['steps']} bước đã ghi hôm nay',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(
            running ? 'Đang theo dõi · có thông báo thường trực' : 'Đang tắt',
          ),
          FilledButton(
            key: const ValueKey('toggle-steps'),
            onPressed: busy
                ? null
                : () async {
                    await act((uid) async {
                      final device = ref.read(wellnessDeviceProvider);
                      if (running) {
                        await device.stopSteps(uid);
                      } else {
                        if (!await device.requestMotion() ||
                            !await device.requestNotifications()) {
                          throw const FormatException(
                            'Cần quyền Hoạt động thể chất và thông báo để bật theo dõi.',
                          );
                        }
                        if (ref.read(authSessionProvider).value?.uid != uid) {
                          return;
                        }
                        await device.startSteps(uid);
                      }
                    });
                    await Future<void>.delayed(
                      const Duration(milliseconds: 500),
                    );
                    await refresh();
                  },
            child: Text(running ? 'Dừng đếm bước' : 'Bật đếm bước'),
          ),
          OutlinedButton(
            onPressed: busy
                ? null
                : () => act((uid) async {
                    final data = await ref
                        .read(wellnessDeviceProvider)
                        .steps(uid);
                    for (final entry
                        in ((data['days'] as Map?) ?? {}).entries) {
                      if (ref.read(authSessionProvider).value?.uid != uid) {
                        return;
                      }
                      await ref
                          .read(wellnessRepositoryProvider)
                          .syncSteps(uid, {
                            'day': entry.key,
                            ...Map<String, dynamic>.from(entry.value as Map),
                          });
                    }
                  }),
            child: const Text('Đồng bộ dữ liệu trên máy'),
          ),
          const Text(
            'Sau khi khởi động lại/buộc dừng app, mở lại và bật theo dõi nếu đã dừng. Mẫu đầu của ngày hoặc lần bật mới chỉ làm mốc; có thể thiếu bước ngoài khoảng theo dõi.',
          ),
        ],
        const SizedBox(height: 16),
        const Text('Lịch sử đã đồng bộ · 30 ngày có dữ liệu gần nhất'),
        StepEnergyCard(steps: row?['steps'] as int?),
        history.when(
          skipLoadingOnReload: false,
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => _problem(() => ref.invalidate(stepHistoryProvider)),
          data: (days) => days.isEmpty
              ? const Text('Chưa có dữ liệu bước chân đã đồng bộ.')
              : Column(
                  children: [
                    for (final d in days)
                      ListTile(
                        title: Text(d.day),
                        trailing: Text('${d.steps} bước'),
                        subtitle: Text(
                          'Từ ${DateFormat('HH:mm').format(d.startedAt.toLocal())} · khoảng đã đo',
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class NutrientPanel extends ConsumerStatefulWidget {
  const NutrientPanel({super.key});
  @override
  ConsumerState<NutrientPanel> createState() => _NutrientPanelState();
}

class _NutrientPanelState extends ConsumerState<NutrientPanel> {
  DateTime day = localDateOnly(DateTime.now());
  @override
  Widget build(BuildContext context) {
    final meals = ref.watch(mealLogsProvider(day));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.calendar_today),
          label: Text(DateFormat('dd/MM/yyyy').format(day)),
          onPressed: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: day,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (date != null && mounted) {
              setState(() => day = localDateOnly(date));
            }
          },
        ),
        const Text(
          'Dưỡng chất mở rộng chỉ dùng số liệu có nguồn hoặc bạn nhập từ nhãn. Quét ảnh không xác minh được các giá trị này.',
        ),
        meals.when(
          skipLoadingOnReload: false,
          loading: () => const LinearProgressIndicator(),
          error: (_, _) =>
              _problem(() => ref.invalidate(mealLogsProvider(day))),
          data: (logs) {
            final items = logs.expand((m) => m.items).toList();
            if (items.isEmpty) {
              return const Text('Chưa ghi bữa ăn trong ngày này.');
            }
            return Column(
              children: [
                for (final n in ExtraNutrient.values)
                  Builder(
                    builder: (_) {
                      final known = items
                          .where(
                            (i) =>
                                i.nutrition.extraNutrients.containsKey(n.name),
                          )
                          .toList();
                      final value = known.fold<double>(
                        0,
                        (sum, i) => sum + i.nutrition.extraNutrients[n.name]!,
                      );
                      return Card(
                        child: ListTile(
                          title: Text(n.label),
                          trailing: Text(
                            known.isEmpty
                                ? 'Chưa có dữ liệu'
                                : '${foodNumber(value)} ${n.unit}',
                          ),
                          subtitle: Text(
                            known.length == items.length
                                ? 'Đủ dữ liệu trong các món đã ghi'
                                : 'Mới biết ${known.length}/${items.length} món · chưa phải tổng đầy đủ',
                          ),
                        ),
                      );
                    },
                  ),
                const Text(
                  'Sửa/nhập các giá trị còn thiếu tại Thư viện món → Món của tôi → Dưỡng chất mở rộng, rồi chọn đúng món cho lần ghi mới. Không tự sửa lịch sử cũ.',
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class MealPlannerPanel extends ConsumerStatefulWidget {
  const MealPlannerPanel({super.key});
  @override
  ConsumerState<MealPlannerPanel> createState() => _MealPlannerPanelState();
}

class _MealPlannerPanelState extends WellnessPanelState<MealPlannerPanel> {
  bool suggesting = false;
  DateTime week = localDateOnly(DateTime.now());
  Future<void> edit(
    DateTime date,
    MealType type, {
    PlannedMeal? existing,
  }) async {
    final uid = ref.read(authSessionProvider).value?.uid;
    if (uid == null) return;
    await act((_) async {
      final catalog = await ref.read(foodCatalogProvider.future);
      final profile = await ref
          .read(userProfileProvider.future)
          .timeout(const Duration(seconds: 15));
      if (profile == null) {
        throw const FormatException(
          'Chưa tải được hồ sơ và thực phẩm cần tránh. Hãy thử lại.',
        );
      }
      if (!mounted || ref.read(authSessionProvider).value?.uid != uid) return;
      final draft = await showDialog<MealDraft>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AccountBoundDialog(
          child: PlanMealDialog(
            date: date,
            type: type,
            catalog: catalog,
            initialDiet: FoodDietPreference.fromAnswer(
              profile.personalization?['diet'],
            ),
            avoidance: FoodAvoidance.fromText(
              profile.personalization?['avoidFoods'],
            ),
            items: existing?.items ?? [],
            onSave: (draft) async {
              if (ref.read(authSessionProvider).value?.uid != uid) return false;
              await ref.read(wellnessRepositoryProvider).savePlan(uid, draft);
              return ref.read(authSessionProvider).value?.uid == uid;
            },
          ),
        ),
      );
      if (draft == null) return;
    });
  }

  Future<void> log(PlannedMeal plan) async {
    final now = DateTime.now();
    if (localDateOnly(plan.date).isAfter(localDateOnly(now))) return;
    final uid = ref.read(authSessionProvider).value?.uid;
    if (uid == null) return;
    await act((_) async {
      final repo = ref.read(wellnessRepositoryProvider);
      if (await repo.existingPlanMeal(uid, plan.id)) {
        if (mounted && ref.read(authSessionProvider).value?.uid == uid) {
          setState(() => message = 'Bữa đã có trong Nhật ký.');
        }
        return;
      }
      // Reconciliation may have cleared a legacy marker and changed its version.
      final refreshed = await repo.loadPlan(uid, plan.id);
      if (refreshed == null) {
        throw const FormatException('Kế hoạch đã bị xóa. Hãy tải lại.');
      }
      final catalog = await ref.read(foodCatalogProvider.future);
      final profile = await ref
          .read(userProfileProvider.future)
          .timeout(const Duration(seconds: 15));
      if (profile == null) {
        throw const FormatException(
          'Chưa tải được hồ sơ và thực phẩm cần tránh. Hãy thử lại.',
        );
      }
      if (!mounted || ref.read(authSessionProvider).value?.uid != uid) return;
      String? saveError;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AccountBoundDialog(
          child: MealFormDialog(
            catalog: catalog,
            initialDiet: FoodDietPreference.fromAnswer(
              profile.personalization?['diet'],
            ),
            avoidance: FoodAvoidance.fromText(
              profile.personalization?['avoidFoods'],
            ),
            initialItems: refreshed.items,
            initialType: plan.type,
            initialConsumedAt: plan.date == localDateOnly(now)
                ? now
                : DateTime(plan.date.year, plan.date.month, plan.date.day, 12),
            onSave: (draft) async {
              if (ref.read(authSessionProvider).value?.uid != uid) return false;
              try {
                await repo.recordPlanMeal(uid, refreshed, draft);
                if (ref.read(authSessionProvider).value?.uid != uid) {
                  return false;
                }
                return true;
              } catch (error) {
                saveError = _failure(error);
                return false;
              }
            },
            saveErrorMessage: () => saveError ?? 'Chưa lưu được. Hãy thử lại.',
          ),
        ),
      );
    });
  }

  Future<void> suggest(List<PlannedMeal> existing) async {
    final uid = ref.read(authSessionProvider).value?.uid;
    if (uid == null) return;
    final catalog = await ref.read(foodCatalogProvider.future);
    final profile = await ref
        .read(userProfileProvider.future)
        .timeout(const Duration(seconds: 15));
    if (profile == null) {
      throw const FormatException(
        'Chưa tải được hồ sơ và thực phẩm cần tránh. Hãy thử lại.',
      );
    }
    if (!mounted || ref.read(authSessionProvider).value?.uid != uid) return;
    final diet = FoodDietPreference.fromAnswer(
      profile.personalization?['diet'],
    );
    final avoidance = FoodAvoidance.fromText(
      profile.personalization?['avoidFoods'],
    );
    final targets = await ref.read(weeklyNutritionTargetsProvider(week).future);
    if (!mounted || ref.read(authSessionProvider).value?.uid != uid) return;
    final suggestion = suggestMealPlan(
      start: week,
      catalog: catalog,
      existing: existing,
      targets: targets,
      diet: diet,
      avoidance: avoidance,
    );
    final drafts = suggestion.drafts;
    if (drafts.isEmpty) {
      setState(
        () => message =
            'Các bữa đã có kế hoạch hoặc kcal dự kiến đã đạt mục tiêu; không thêm bữa tự động.',
      );
      return;
    }
    final accept = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Xem trước gợi ý 7 ngày'),
        content: SizedBox(
          width: 440,
          height: 400,
          child: ListView(
            children: [
              if (diet != FoodDietPreference.general)
                Text('Lựa chọn trong hồ sơ: ${diet.label}.'),
              if (avoidance.isActive) ...[
                const SizedBox(height: 8),
                Text('Đang tránh: ${avoidance.label}'),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Chỉ lưu kế hoạch. Xác nhận đã ăn để ghi nhật ký.'),
              ),
              for (final summary in suggestion.summaries)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    key: ValueKey(
                      'suggested-day-${localDateKey(summary.date)}',
                    ),
                    initiallyExpanded: summary.date == week,
                    title: Text(
                      DateFormat('EEEE dd/MM', 'vi').format(summary.date),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 6,
                        children: [
                          Text(
                            '${foodNumber(summary.plannedKcal)} kcal dự kiến'
                            '${summary.targetKcal == null ? ' · Chưa có mục tiêu' : ' / ${foodNumber(summary.targetKcal!)} kcal mục tiêu'}',
                          ),
                          if (summary.outsideTarget)
                            const Text('Lệch trên 5% · Cần kiểm tra khẩu phần'),
                        ],
                      ),
                    ),
                    children: [
                      for (final draft in drafts.where(
                        (d) =>
                            localDateKey(d.consumedAt) ==
                            localDateKey(summary.date),
                      ))
                        Padding(
                          key: ValueKey(
                            'suggested-meal-${localDateKey(draft.consumedAt)}-${draft.type.name}',
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: 6,
                            children: [
                              Text(
                                '${draft.type.label} · ${foodNumber(draft.totals.kcal)} kcal',
                                style: Theme.of(c).textTheme.titleSmall,
                              ),
                              for (final item in draft.items)
                                Text(
                                  '${item.name} · ${foodNumber(item.grams)} g',
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              const HelpDetails(
                title: 'Cách gợi ý và giới hạn',
                children: [
                  Text(
                    'Điều chỉnh gram theo mục tiêu kcal, giữ các bữa đã có kế hoạch. Chưa cân bằng riêng từng chất hay thay thế tư vấn dinh dưỡng.',
                  ),
                  Text(
                    'Ẩn món cần tránh và món chưa rõ thành phần. Kiểm tra món thực tế; bộ lọc không xác minh nhiễm chéo.',
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Thêm bữa còn trống'),
          ),
        ],
      ),
    );
    if (accept != true ||
        !mounted ||
        ref.read(authSessionProvider).value?.uid != uid) {
      return;
    }
    await act((uid) async {
      for (final draft in drafts) {
        if (ref.read(authSessionProvider).value?.uid != uid) return;
        await ref.read(wellnessRepositoryProvider).savePlan(uid, draft);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(plansProvider(week));
    // Keep the auto-disposed catalog alive while opening/editing a plan.
    ref.watch(foodCatalogProvider);
    final now = localDateOnly(DateTime.now());
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Thực đơn 7 ngày', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('Chỉ bữa đã xác nhận ăn mới được tính vào nhật ký.'),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(
              tooltip: '7 ngày trước',
              onPressed: busy || suggesting
                  ? null
                  : () => setState(
                      () =>
                          week = DateTime(week.year, week.month, week.day - 7),
                    ),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                '${DateFormat('dd/MM').format(week)} – ${DateFormat('dd/MM').format(DateTime(week.year, week.month, week.day + 6))}',
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              tooltip: '7 ngày sau',
              onPressed: busy || suggesting
                  ? null
                  : () => setState(
                      () =>
                          week = DateTime(week.year, week.month, week.day + 7),
                    ),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        feedback(),
        plans.when(
          skipLoadingOnReload: false,
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => _problem(() => ref.invalidate(plansProvider(week))),
          data: (values) => Column(
            children: [
              OutlinedButton(
                key: const ValueKey('suggest-week-plan'),
                onPressed: busy || suggesting
                    ? null
                    : () async {
                        setState(() => suggesting = true);
                        try {
                          await suggest(values);
                        } catch (e) {
                          if (mounted) setState(() => message = _failure(e));
                        } finally {
                          if (mounted) setState(() => suggesting = false);
                        }
                      },
                child: const Text('Gợi ý thực đơn'),
              ),
              const SizedBox(height: 16),
              for (var index = 0; index < 7; index++)
                Builder(
                  builder: (_) {
                    final date = DateTime(
                      week.year,
                      week.month,
                      week.day + index,
                    );
                    final daily = values.where((p) => p.date == date).toList();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 12,
                          children: [
                            Text(
                              DateFormat('EEEE dd/MM', 'vi').format(date),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (daily.isEmpty) const Text('Chưa lập bữa nào.'),
                            if (daily.isNotEmpty)
                              Text(
                                '${foodNumber(sumNutritionTotals(daily.map((p) => p.totals)).kcal)} kcal dự kiến',
                              ),
                            for (final type in MealType.values)
                              Builder(
                                builder: (_) {
                                  final plan = daily
                                      .where((p) => p.type == type)
                                      .firstOrNull;
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        title: Text(type.label),
                                        subtitle: Text(
                                          plan == null
                                              ? 'Chưa có kế hoạch'
                                              : plan.items
                                                    .map(
                                                      (i) =>
                                                          '${i.name} · ${snapshotQuantityLabel(i)}',
                                                    )
                                                    .join('\n'),
                                        ),
                                        trailing: IconButton(
                                          tooltip: 'Chỉnh kế hoạch',
                                          icon: const Icon(Icons.edit_outlined),
                                          onPressed:
                                              busy || plan?.loggedMealId != null
                                              ? null
                                              : () => edit(
                                                  date,
                                                  type,
                                                  existing: plan,
                                                ),
                                        ),
                                      ),
                                      if (plan != null)
                                        Wrap(
                                          spacing: 8,
                                          children: [
                                            if (!date.isAfter(now))
                                              TextButton(
                                                onPressed: busy
                                                    ? null
                                                    : () => log(plan),
                                                child: Text(
                                                  plan.loggedMealId != null
                                                      ? 'Đã ghi · Kiểm tra'
                                                      : 'Xác nhận đã ăn',
                                                ),
                                              ),
                                            TextButton(
                                              onPressed: busy
                                                  ? null
                                                  : () async {
                                                      if (await _confirm(
                                                            context,
                                                            'Xóa kế hoạch này? Nhật ký đã ghi được giữ nguyên.',
                                                            ref,
                                                          ) &&
                                                          mounted) {
                                                        await act(
                                                          (uid) => ref
                                                              .read(
                                                                wellnessRepositoryProvider,
                                                              )
                                                              .deletePlan(
                                                                uid,
                                                                plan.id,
                                                              ),
                                                        );
                                                      }
                                                    },
                                              child: const Text('Xóa kế hoạch'),
                                            ),
                                          ],
                                        ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class PlanMealDialog extends StatefulWidget {
  const PlanMealDialog({
    required this.date,
    required this.type,
    required this.catalog,
    required this.items,
    this.onSave,
    this.initialDiet = FoodDietPreference.general,
    this.avoidance = const FoodAvoidance.none(),
    super.key,
  });
  final DateTime date;
  final MealType type;
  final List<FoodCatalogItem> catalog;
  final List<MealItemSnapshot> items;
  final Future<bool> Function(MealDraft)? onSave;
  final FoodDietPreference initialDiet;
  final FoodAvoidance avoidance;
  @override
  State<PlanMealDialog> createState() => _PlanMealDialogState();
}

class _PlanMealDialogState extends State<PlanMealDialog>
    with ConfirmedSave<MealDraft, PlanMealDialog> {
  late final List<MealItemSnapshot> items = [...widget.items];
  String search = '';
  late FoodDietPreference diet = widget.initialDiet;
  @override
  Widget build(BuildContext context) => guardSave(
    Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Kế hoạch ${widget.type.label.toLowerCase()}'),
          actions: [
            TextButton(
              key: const ValueKey('save-meal-plan'),
              onPressed:
                  items.isEmpty ||
                      widget.avoidance
                          .flaggedSnapshots(items, widget.catalog)
                          .isNotEmpty
                  ? null
                  : () => saveDraft(
                      MealDraft(
                        type: widget.type,
                        consumedAt: DateTime(
                          widget.date.year,
                          widget.date.month,
                          widget.date.day,
                          12,
                        ),
                        items: List.unmodifiable(items),
                        source: MealSource.manual,
                      ),
                      widget.onSave,
                    ),
              child: const Text('Lưu kế hoạch'),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            saveFeedback(),
            if (widget.avoidance.isActive)
              Text('Đang tránh: ${widget.avoidance.label}'),
            if (widget.avoidance
                .flaggedSnapshots(items, widget.catalog)
                .isNotEmpty)
              const Text(
                'Có món chứa thực phẩm cần tránh hoặc chưa rõ thành phần. Hãy bỏ hoặc thay món đó trước khi lưu kế hoạch.',
              ),
            FoodDietFilter(
              value: diet,
              onChanged: saving
                  ? null
                  : (value) => setState(() => diet = value),
            ),
            const SizedBox(height: 12),
            for (final entry in items.indexed)
              ListTile(
                title: Text(entry.$2.name),
                subtitle: Text(snapshotQuantityLabel(entry.$2)),
                onTap: () async {
                  final quantity = await askSnapshotQuantity(context, entry.$2);
                  if (quantity != null && mounted) {
                    setState(
                      () => items[entry.$1] = entry.$2.withQuantity(quantity),
                    );
                  }
                },
                trailing: IconButton(
                  tooltip: 'Bỏ món',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => items.removeAt(entry.$1)),
                ),
              ),
            TextField(
              key: const ValueKey('plan-food-search'),
              decoration: const InputDecoration(
                labelText: 'Tìm món Việt / tên không dấu',
              ),
              onChanged: (value) => setState(() => search = value),
            ),
            for (final food in searchFoodCatalog(
              widget.catalog
                  .where(
                    (food) =>
                        diet.allows(food) && widget.avoidance.allows(food),
                  )
                  .toList(),
              search,
            ).where((f) => f.hasNutritionData).take(25))
              ListTile(
                title: Text(food.name),
                subtitle: Text(
                  '${foodNumber(food.nutritionPer100g.kcal)} kcal / 100 g',
                ),
                trailing: const Icon(Icons.add),
                onTap: items.length >= 5
                    ? null
                    : () async {
                        final grams = await askFoodGrams(
                          context,
                          food: food,
                          initial: food.hasValidServing
                              ? food.servingGrams!
                              : food.defaultServingGrams,
                        );
                        if (grams != null && mounted) {
                          setState(
                            () => items.add(
                              MealItemSnapshot.fromCatalog(food, grams),
                            ),
                          );
                        }
                      },
              ),
          ],
        ),
      ),
    ),
  );
}
