import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../models/exercise_library_entry.dart';
import '../providers/exercise_library_providers.dart';
import 'exercise_gif_preview.dart';
import 'workout_ui.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({this.onOpenWorkouts, super.key});
  final VoidCallback? onOpenWorkouts;

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  final _search = TextEditingController();
  String? _region, _equipment;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clear() => setState(() {
    _search.clear();
    _region = null;
    _equipment = null;
  });

  Future<void> _showFilters() async {
    var region = _region, equipment = _equipment;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .82,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 16, 12),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    children: [
                      Text(
                        'Lọc động tác',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () => update(() {
                          region = null;
                          equipment = null;
                        }),
                        child: const Text('Đặt lại'),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vùng cơ thể',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final item in {
                              '': 'Tất cả',
                              ...exerciseRegions,
                            }.entries)
                              ChoiceChip(
                                label: Text(item.value),
                                selected: (region ?? '') == item.key,
                                onSelected: (_) => update(
                                  () => region = item.key.isEmpty
                                      ? null
                                      : item.key,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Dụng cụ',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final item in {
                              '': 'Tất cả dụng cụ',
                              ...exerciseEquipments,
                            }.entries)
                              ChoiceChip(
                                key: ValueKey('equipment-${item.key}'),
                                label: Text(item.value),
                                selected: (equipment ?? '') == item.key,
                                onSelected: (_) => update(
                                  () => equipment = item.key.isEmpty
                                      ? null
                                      : item.key,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: FilledButton(
                    key: const ValueKey('apply-exercise-filters'),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Áp dụng bộ lọc'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (applied == true && mounted) {
      setState(() {
        _region = region;
        _equipment = equipment;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), scheme = theme.colorScheme;
    final library = ref.watch(exerciseLibraryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.onOpenWorkouts == null ? 'Thư viện động tác' : 'Tập luyện',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Nguồn GIF và tập luyện an toàn',
            onPressed: () => showExerciseMediaInfo(context),
            icon: const Icon(AppIcons.info),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: library.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(AppIcons.cloudAlert, size: 40),
                    const SizedBox(height: 16),
                    const Text(
                      'Chưa tải được thư viện động tác. Kiểm tra kết nối và thử lại.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => ref.invalidate(exerciseLibraryProvider),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
            data: (entries) {
              final filtered = filterExerciseLibrary(
                entries,
                query: _search.text,
                region: _region,
                equipment: _equipment,
              );
              final hasFilters =
                  _search.text.isNotEmpty ||
                  _region != null ||
                  _equipment != null;
              return CustomScrollView(
                key: const ValueKey('exercise-library-scroll'),
                scrollCacheExtent: const ScrollCacheExtent.pixels(0),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.onOpenWorkouts != null) ...[
                            WorkoutSectionTabs(
                              sessionsSelected: false,
                              onLibrary: () {},
                              onSessions: widget.onOpenWorkouts!,
                            ),
                            const SizedBox(height: 24),
                          ] else
                            const SizedBox(height: 12),
                          const WorkoutHeading(
                            eyebrow: 'Khám phá / Kỹ thuật',
                            title: 'Tập có hướng dẫn.',
                            description:
                                'Chọn nhóm cơ, xem động tác và tập theo nhịp của bạn.',
                          ),
                          const SizedBox(height: 20),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextField(
                                  key: const ValueKey('exercise-search'),
                                  controller: _search,
                                  textInputAction: TextInputAction.search,
                                  decoration: InputDecoration(
                                    hintText: 'Tìm động tác, nhóm cơ…',
                                    labelText: 'Tìm động tác',
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.never,
                                    prefixIcon: const Icon(
                                      AppIcons.search,
                                      size: 21,
                                    ),
                                    suffixIcon: _search.text.isEmpty
                                        ? null
                                        : IconButton(
                                            key: const ValueKey(
                                              'clear-exercise-search',
                                            ),
                                            tooltip: 'Xóa từ khóa',
                                            onPressed: () =>
                                                setState(_search.clear),
                                            icon: const Icon(
                                              AppIcons.x,
                                              size: 18,
                                            ),
                                          ),
                                    filled: true,
                                    fillColor: scheme.surfaceContainerLowest,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: scheme.outlineVariant,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: scheme.outlineVariant,
                                      ),
                                    ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Badge(
                                isLabelVisible: _equipment != null,
                                backgroundColor: workoutAccent(context),
                                child: IconButton.outlined(
                                  key: const ValueKey('exercise-filters'),
                                  tooltip: 'Lọc động tác',
                                  onPressed: _showFilters,
                                  style: IconButton.styleFrom(
                                    minimumSize: const Size(54, 54),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(AppIcons.slidersHorizontal),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          for (final item in {
                            '': 'Tất cả',
                            ...exerciseRegions,
                          }.entries)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                key: ValueKey('region-${item.key}'),
                                label: Text(item.value),
                                selected: (_region ?? '') == item.key,
                                showCheckmark: false,
                                selectedColor: workoutAccent(
                                  context,
                                ).withValues(alpha: .16),
                                side: BorderSide(
                                  color: (_region ?? '') == item.key
                                      ? workoutAccent(context)
                                      : scheme.outlineVariant,
                                ),
                                labelStyle: TextStyle(
                                  color: (_region ?? '') == item.key
                                      ? workoutAccent(context)
                                      : scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                                onSelected: (_) => setState(
                                  () => _region = item.key.isEmpty
                                      ? null
                                      : item.key,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              Text(
                                '${filtered.length} động tác',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (hasFilters)
                                TextButton(
                                  key: const ValueKey('clear-exercise-filters'),
                                  onPressed: _clear,
                                  child: const Text('Xóa bộ lọc'),
                                )
                              else
                                Text(
                                  'GIF minh họa',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                          if (_equipment != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: WorkoutTag(
                                  exerciseEquipments[_equipment]!,
                                  icon: AppIcons.dumbbell,
                                ),
                              ),
                            ),
                          if (entries.isEmpty || filtered.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 36),
                              child: Column(
                                children: [
                                  Icon(
                                    entries.isEmpty
                                        ? AppIcons.dumbbell
                                        : AppIcons.searchX,
                                    size: 36,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    entries.isEmpty
                                        ? 'Thư viện chưa có động tác đang hiển thị. Vui lòng quay lại sau.'
                                        : 'Không tìm thấy động tác phù hợp. Hãy đổi từ khóa hoặc bộ lọc.',
                                    textAlign: TextAlign.center,
                                  ),
                                  if (hasFilters)
                                    TextButton(
                                      onPressed: _clear,
                                      child: const Text('Xem tất cả động tác'),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.crossAxisExtent;
                        final scale = MediaQuery.textScalerOf(context).scale(1);
                        final columns = scale > 1.2 || width < 320
                            ? 1
                            : width >= 680
                            ? 3
                            : 2;
                        Widget card(int index) => _ExerciseCard(
                          key: ValueKey(
                            'exercise-card-${filtered[index].id}-${filtered[index].sourceId}',
                          ),
                          entry: filtered[index],
                          portrait: columns > 1,
                        );
                        if (columns == 1) {
                          return SliverList.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: card(index),
                            ),
                          );
                        }
                        return SliverGrid.builder(
                          itemCount: filtered.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisExtent:
                                    320 + (scale - 1).clamp(0, .2) * 150,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 20,
                              ),
                          itemBuilder: (context, index) => card(index),
                        );
                      },
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Khởi động trước khi tập. Dừng nếu đau, chóng mặt hoặc khó chịu. Hướng dẫn không thay thế tư vấn y tế.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.entry, this.portrait = false, super.key});
  final ExerciseLibraryEntry entry;
  final bool portrait;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), scheme = theme.colorScheme;
    final media = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: ExerciseGifPreview(
        key: ValueKey('exercise-inline-${entry.id}-${entry.sourceId}'),
        entry: entry,
        autoLoad: true,
        compact: true,
        thumbnail: true,
        height: portrait ? 170 : 150,
      ),
    );
    final content = Padding(
      padding: EdgeInsets.fromLTRB(portrait ? 0 : 16, 14, 0, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            (exerciseRegions[entry.region] ?? entry.region).toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            entry.name,
            maxLines: portrait ? 3 : null,
            overflow: portrait ? TextOverflow.ellipsis : null,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.25,
              letterSpacing: -.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  exerciseEquipments[entry.equipment] ?? entry.equipment,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(AppIcons.arrowUpRight, size: 17),
            ],
          ),
        ],
      ),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('exercise-${entry.id}'),
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ExerciseLibraryDetailScreen(exerciseId: entry.id),
          ),
        ),
        child: portrait
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [media, content],
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  if (MediaQuery.textScalerOf(context).scale(1) > 1.4) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [media, content, const Divider(height: 24)],
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(width: 112, child: media),
                        Expanded(child: content),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class ExerciseLibraryDetailScreen extends ConsumerWidget {
  const ExerciseLibraryDetailScreen({required this.exerciseId, super.key});
  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context), scheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hướng dẫn động tác'),
        actions: [
          IconButton(
            tooltip: 'Nguồn GIF và tập luyện an toàn',
            onPressed: () => showExerciseMediaInfo(context),
            icon: const Icon(AppIcons.info),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ref
              .watch(exerciseLibraryProvider)
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: FilledButton(
                    onPressed: () => ref.invalidate(exerciseLibraryProvider),
                    child: const Text('Tải lại hướng dẫn'),
                  ),
                ),
                data: (entries) {
                  final entry = entries
                      .where((entry) => entry.id == exerciseId)
                      .firstOrNull;
                  if (entry == null) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Động tác này hiện không còn trong thư viện. Quay lại để chọn động tác khác.',
                        ),
                      ),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      WorkoutHeading(
                        eyebrow: exerciseRegions[entry.region] ?? entry.region,
                        title: entry.name,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          WorkoutTag(
                            exerciseEquipments[entry.equipment] ??
                                entry.equipment,
                            icon: AppIcons.dumbbell,
                          ),
                          WorkoutTag(
                            'Nhóm cơ: ${entry.target}',
                            icon: AppIcons.activity,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ExerciseGifPreview(
                        autoLoad: true,
                        stage: true,
                        height: 280,
                        key: ValueKey('${entry.id}-${entry.sourceId}'),
                        entry: entry,
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Cách thực hiện',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '${entry.steps.length} bước',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      for (
                        var index = 0;
                        index < entry.steps.length;
                        index++
                      ) ...[
                        WorkoutStep(
                          number: index + 1,
                          text: entry.steps[index],
                        ),
                        if (index < entry.steps.length - 1)
                          const Divider(height: 1),
                      ],
                      const SizedBox(height: 8),
                      Container(
                        decoration: workoutPanel(context),
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  AppIcons.lightbulb,
                                  color: workoutAccent(context),
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Cách tập nhẹ hơn',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(entry.easier),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Khởi động trước khi tập, thực hiện chậm và trong tầm thoải mái. Dừng nếu đau, chóng mặt hoặc khó chịu. Thông tin chỉ hỗ trợ thói quen vận động, không thay thế tư vấn y tế.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                },
              ),
        ),
      ),
    );
  }
}
