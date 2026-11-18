import '../../../core/theme/app_icons.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/feature_page.dart';
import '../../../core/widgets/confirmed_save.dart';
import '../../auth/models/account_action_failure.dart';
import '../../auth/models/auth_failure.dart';
import '../../auth/presentation/account_security_dialogs.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../core/utils/local_date_key.dart';
import '../../../shared/providers/local_clock_provider.dart';
import '../../nutrition_targets/models/nutrition_target.dart';
import '../../nutrition_targets/models/personal_nutrition_plan.dart';
import '../models/personalization_answers.dart';
import '../models/onboarding_journey.dart';
import 'onboarding_widgets.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../nutrition_targets/providers/nutrition_target_providers.dart';
import '../models/body_metric.dart';
import '../models/health_goal.dart';
import '../models/onboarding_draft.dart';
import '../models/onboarding_progress.dart';
import '../../meal_drafts/data/meal_draft_store.dart';
import 'account_information_screen.dart';
import '../models/profile_failure.dart';
import '../models/profile_validation.dart';
import '../models/user_profile.dart';
import '../providers/profile_providers.dart';
import '../providers/onboarding_deferred_provider.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key, this.isEditing = false});
  final bool isEditing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(userProfileProvider);
    final today = localDateOnly(ref.watch(localClockProvider));
    final metricsState = ref.watch(latestBodyMetricProvider(today));
    return Scaffold(
      body: SafeArea(
        child: profileState.when(
          loading: () => const _OnboardingStatus(
            title: 'Đang chuẩn bị hồ sơ',
            message: 'HealthMate đang tải thông tin của bạn.',
          ),
          error: (error, _) => _OnboardingStatus(
            title: 'Chưa thể tải hồ sơ',
            message: _messageFor(error),
            onRetry: () {
              ref.invalidate(profileBootstrapProvider);
              ref.invalidate(userProfileProvider);
            },
          ),
          data: (profile) {
            if (profile == null) {
              return _OnboardingStatus(
                title: 'Chưa thể tạo hồ sơ',
                message: 'Hãy thử lại để tiếp tục thiết lập HealthMate.',
                onRetry: () {
                  ref.invalidate(profileBootstrapProvider);
                  ref.invalidate(userProfileProvider);
                },
              );
            }
            return metricsState.when(
              loading: () => const _OnboardingStatus(
                title: 'Đang tải dữ liệu thể trạng',
                message: 'Quá trình này chỉ mất một chút thời gian.',
              ),
              error: (error, _) => _OnboardingStatus(
                title: 'Chưa thể tải cân nặng',
                message: _messageFor(error),
                onRetry: () => ref.invalidate(latestBodyMetricProvider(today)),
              ),
              data: (metrics) => _OnboardingForm(
                key: ValueKey('onboarding-${profile.uid}'),
                profile: profile,
                isEditing: isEditing,
                latestMetric: metrics.firstOrNull,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingForm extends ConsumerStatefulWidget {
  const _OnboardingForm({
    required this.profile,
    required this.latestMetric,
    required this.isEditing,
    super.key,
  });

  final UserProfile profile;
  final BodyMetric? latestMetric;
  final bool isEditing;

  @override
  ConsumerState<_OnboardingForm> createState() => _OnboardingFormState();
}

class _OnboardingFormState extends ConsumerState<_OnboardingForm> {
  final _questionFormKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late final TextEditingController _targetWeight;
  late DateTime? _birthDate;
  late HealthGoal? _goal;
  OnboardingStep _step = OnboardingStep.name;
  bool _includeDetails = false;
  bool _applyPlan = true;
  PersonalNutritionPlan? _calculatedPlan;
  String? _planError;
  late PersonalizationAnswers _answers;
  String? _birthDateError;
  String? _goalError;
  NutritionTarget? _nutritionDraft;
  bool _completing = false;
  bool _nutritionSaved = false;
  String? _completionError;
  Timer? _draftTimer;
  bool _draftRestored = false;
  bool _draftSaved = false;
  bool _finished = false;
  bool _restoreFailed = false;
  String? _draftError;
  String? _lastDraft;
  late String _initialDraft;
  OnboardingStep? _calculatorReturn;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.displayName);
    _height = TextEditingController(
      text: widget.profile.heightCm?.toStringAsFixed(1) ?? '',
    );
    _weight = TextEditingController(
      text: widget.latestMetric?.weightKg.toStringAsFixed(1) ?? '',
    );
    _targetWeight = TextEditingController(
      text: widget.profile.targetWeightKg?.toStringAsFixed(1) ?? '',
    );
    _birthDate = widget.profile.birthDate;
    _goal = widget.profile.healthGoal;
    _answers = widget.profile.personalization ?? PersonalizationAnswers();
    _initialDraft = jsonEncode(_progress.toJson());
    for (final controller in [_name, _height, _weight, _targetWeight]) {
      controller.addListener(() {
        _nutritionDraft = null;
        _calculatedPlan = null;
        _nutritionSaved = false;
        _scheduleDraft();
        if (mounted && _draftRestored) setState(() {});
      });
    }
    unawaited(_restoreDraft());
  }

  bool get _current =>
      mounted && ref.read(authSessionProvider).value?.uid == widget.profile.uid;

  OnboardingProgress get _progress => OnboardingProgress(
    step: _step.legacySection,
    screen: _step,
    includeDetails: _includeDetails,
    name: _name.text,
    height: _height.text,
    weight: _weight.text,
    targetWeight: _targetWeight.text,
    birthDate: _birthDate,
    goal: _goal,
    answers: _answers,
  );

  Future<void> _restoreDraft() async {
    final store = ref.read(mealDraftStoreProvider);
    if (!store.local.supported) {
      if (mounted) setState(() => _draftRestored = true);
      return;
    }
    try {
      final json = await store.readOnboarding(widget.profile.uid);
      if (!_current) return;
      if (json != null) {
        final draft = OnboardingProgress.fromJson(json);
        _name.text = draft.name;
        _height.text = draft.height;
        _weight.text = draft.weight;
        _targetWeight.text = draft.targetWeight;
        _birthDate = draft.birthDate;
        _goal = draft.goal;
        _answers = draft.answers;
        _includeDetails = draft.includeDetails;
        _step = draft.screen ?? OnboardingStep.fromLegacy(draft.step);
        if (!_journey.contains(_step)) {
          _step = _step == OnboardingStep.targetWeight
              ? OnboardingStep.guidance
              : OnboardingStep.details;
        }
        for (final entry in _requiredErrors.entries) {
          if (entry.value != null &&
              _journey.indexOf(entry.key) < _journey.indexOf(_step)) {
            _step = entry.key;
            break;
          }
        }
        if (_step == OnboardingStep.plan) _preparePlan();
      }
      _initialDraft = jsonEncode(_progress.toJson());
      _lastDraft = jsonEncode(_progress.toJson());
      setState(() {
        _draftRestored = true;
        _draftSaved = json != null;
        _restoreFailed = false;
        _draftError = null;
      });
    } catch (_) {
      if (_current) {
        setState(() {
          _draftRestored = true;
          _restoreFailed = true;
          _draftError =
              'Chưa đọc được nháp riêng tư. Thử lại trước khi nhập tiếp.';
        });
      }
    }
  }

  void _scheduleDraft() {
    if (!_draftRestored ||
        _finished ||
        _draftError != null ||
        !_current ||
        !ref.read(mealDraftStoreProvider).local.supported) {
      return;
    }
    final raw = jsonEncode(_progress.toJson());
    if (raw == _lastDraft) return;
    _lastDraft = raw;
    _draftSaved = false;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 300), () {
      unawaited(_saveDraft());
    });
  }

  Future<bool> _saveDraft() async {
    _draftTimer?.cancel();
    final store = ref.read(mealDraftStoreProvider);
    if (!store.local.supported || !_current || _finished) return false;
    try {
      final progress = _progress.toJson();
      final serialized = jsonEncode(progress);
      await store.writeOnboarding(widget.profile.uid, progress);
      if (_current) {
        setState(() {
          _draftSaved = serialized == jsonEncode(_progress.toJson());
          _draftError = null;
        });
      }
      return true;
    } catch (_) {
      if (_current) {
        setState(
          () => _draftError =
              'Chưa lưu được nháp trên thiết bị. Giữ màn này hoặc thử lại.',
        );
      }
      return false;
    }
  }

  Future<void> _skipPersonalization() => _leave(AppRoutes.journal);

  void _exitTo(String destination) {
    if (!widget.isEditing) {
      ref.read(onboardingDeferredProvider.notifier).defer();
    }
    context.go(destination);
  }

  Future<void> _leave(String destination) async {
    if (!_current) return;
    if (ref.read(mealDraftStoreProvider).local.supported) {
      if (!await _saveDraft() || !_current) return;
    } else if (_initialDraft != jsonEncode(_progress.toJson())) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Thoát và bỏ nháp?'),
          content: const Text(
            'Nền tảng này chưa giữ nháp thiết lập khi đóng màn.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Nhập tiếp'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Thoát và bỏ nháp'),
            ),
          ],
        ),
      );
      if (discard != true || !_current) return;
    }
    if (mounted) {
      _exitTo(destination);
    }
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _name.dispose();
    _height.dispose();
    _weight.dispose();
    _targetWeight.dispose();
    super.dispose();
  }

  List<OnboardingStep> get _journey => onboardingJourney(
    goal: _goal,
    answers: _answers,
    includeDetails: _includeDetails,
  );

  Map<OnboardingStep, String?> get _requiredErrors => {
    OnboardingStep.name: ProfileValidation.displayName(_name.text),
    OnboardingStep.birthDate: ProfileValidation.birthDate(
      _birthDate,
      today: ref.read(currentLocalTimeProvider)(),
    ),
    OnboardingStep.height: ProfileValidation.requiredHeight(_height.text),
    OnboardingStep.weight: ProfileValidation.weight(_weight.text),
    OnboardingStep.goal: _goal == null ? 'Vui lòng chọn một mục tiêu.' : null,
    if (_goal?.needsTargetWeight == true)
      OnboardingStep.targetWeight: ProfileValidation.targetWeight(
        _targetWeight.text,
        _goal,
      ),
  };

  void _goTo(OnboardingStep step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _step = step;
      _completionError = null;
      if (step == OnboardingStep.plan) _preparePlan();
    });
  }

  void _next() {
    final validForm = _questionFormKey.currentState?.validate() ?? true;
    final error = _requiredErrors[_step];
    setState(() {
      _birthDateError = _step == OnboardingStep.birthDate ? error : null;
      _goalError = _step == OnboardingStep.goal ? error : null;
    });
    if (!validForm || error != null) return;
    final journey = _journey;
    final next = _calculatorReturn ?? journey[journey.indexOf(_step) + 1];
    _calculatorReturn = null;
    _goTo(next);
  }

  void _previous() {
    final index = _journey.indexOf(_step);
    if (index > 0) _goTo(_journey[index - 1]);
  }

  void _changeAnswers(PersonalizationAnswers answers) => setState(() {
    _answers = answers.normalized(_goal);
    _nutritionDraft = null;
    _calculatedPlan = null;
    _nutritionSaved = false;
    _completionError = null;
  });

  OnboardingStep? get _missingPlanStep {
    if (_answers['guidance'] != null && !_answers.eligible) return null;
    if (_answers.formulaSex == null) return OnboardingStep.formulaSex;
    if (_answers.activity == null) return OnboardingStep.activity;
    if (_answers['guidance'] == null) return OnboardingStep.guidance;
    if (_goal?.needsTargetWeight == true && _answers['pace'] == null) {
      return OnboardingStep.pace;
    }
    return null;
  }

  PersonalNutritionPlan _calculatePlan() => PersonalNutritionInput(
    age: _birthDate == null
        ? null
        : ageOnDate(_birthDate!, ref.read(currentLocalTimeProvider)()),
    heightCm: ProfileValidation.parseDecimal(_height.text),
    weightKg: ProfileValidation.parseDecimal(_weight.text),
    sex: _answers.formulaSex,
    activity: _answers.activity,
    goal: _goal,
    targetWeightKg: _goal?.needsTargetWeight == true
        ? ProfileValidation.parseDecimal(_targetWeight.text)
        : null,
    pace: _answers.pace,
    macros: _goal == HealthGoal.gainMuscle
        ? PlanMacroSplit.proteinFocus
        : PlanMacroSplit.balanced,
    eligible: _answers.eligible,
  ).calculate();

  void _preparePlan() {
    _nutritionDraft = null;
    _calculatedPlan = null;
    _nutritionSaved = false;
    _applyPlan = true;
    _planError = null;
    if (_missingPlanStep != null) {
      _planError =
          'Bạn có thể bổ sung thông tin để nhận đề xuất, hoặc hoàn tất và thiết lập calo sau.';
      return;
    }
    try {
      _calculatedPlan = _calculatePlan();
      _nutritionDraft = _calculatedPlan!.toTarget(
        localDateKey(ref.read(currentLocalTimeProvider)()),
      );
    } on FormatException catch (error) {
      _planError = '${error.message} Bạn vẫn có thể thiết lập kcal sau.';
    }
  }

  void _personalize() {
    final missing = _missingPlanStep;
    if (missing != null) {
      _calculatorReturn = OnboardingStep.plan;
      _goTo(missing);
    } else {
      setState(_preparePlan);
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year - 120, now.month, now.day);
    final last = DateTime(now.year - 18, now.month, now.day);
    final initial = _birthDate ?? DateTime(now.year - 20);
    final selected = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(last)
          ? last
          : initial.isBefore(first)
          ? first
          : initial,
      firstDate: first,
      lastDate: last,
      helpText: 'Ngày sinh',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (selected != null && mounted) {
      setState(() {
        _birthDate = selected;
        _birthDateError = null;
      });
    }
  }

  Future<void> _complete() async {
    if (_completing) return;
    final bodyError =
        ProfileValidation.displayName(_name.text) ??
        ProfileValidation.birthDate(_birthDate) ??
        ProfileValidation.requiredHeight(_height.text) ??
        ProfileValidation.weight(_weight.text);
    if (bodyError != null) {
      _goTo(
        _requiredErrors.entries.firstWhere((entry) => entry.value != null).key,
      );
      return;
    }
    if (_goal == null) {
      _goTo(OnboardingStep.goal);
      return;
    }
    if (ProfileValidation.targetWeight(_targetWeight.text, _goal) != null) {
      _goTo(OnboardingStep.targetWeight);
      return;
    }
    FocusScope.of(context).unfocus();
    final uid = widget.profile.uid;
    final draftStore = ref.read(mealDraftStoreProvider);
    bool current() =>
        mounted && ref.read(authSessionProvider).value?.uid == uid;
    if (!current()) return;
    setState(() {
      _completing = true;
      _completionError = null;
    });
    try {
      final target = _applyPlan ? _nutritionDraft : null;
      if (target != null) {
        final today = localDateKey(ref.read(currentLocalTimeProvider)());
        if (target.effectiveFromDateKey != today) {
          setState(() {
            _step = OnboardingStep.plan;
            _nutritionDraft = null;
            _completionError =
                'Đã sang ngày mới. Hãy tạo lại đề xuất hoặc chọn thiết lập sau.';
          });
          return;
        }
        final existing = await ref
            .read(nutritionTargetRepositoryProvider)
            .loadForDay(uid, today)
            .timeout(const Duration(seconds: 15));
        if (!current()) return;
        if (!mounted) return;
        final retainedTarget = target.withMarkersFrom(existing);
        if (existing != null &&
            !sameNutritionTarget(existing, retainedTarget)) {
          final replace = await showDialog<bool>(
            context: context,
            builder: (_) => AccountBoundDialog(
              child: AlertDialog(
                title: const Text('Thay mục tiêu từ hôm nay?'),
                content: Text(
                  'Bạn đang có mục tiêu ${existing.kcalTarget} kcal/ngày. Chỉ thay từ hôm nay bằng ${target.kcalTarget} kcal/ngày khi bạn đồng ý; lịch sử được giữ nguyên.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Giữ mục tiêu hiện tại'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Đồng ý thay'),
                  ),
                ],
              ),
            ),
          );
          if (!current()) return;
          if (replace != true) {
            setState(() {
              _applyPlan = false;
              _step = OnboardingStep.plan;
            });
            return;
          }
        }
        if (!sameNutritionTarget(existing, retainedTarget)) {
          final saved = await ref
              .read(nutritionTargetControllerProvider.notifier)
              .save(retainedTarget);
          if (!current()) return;
          if (!saved) {
            setState(
              () => _completionError =
                  'Chưa lưu được mục tiêu dinh dưỡng. Đề xuất được giữ để thử lại; hồ sơ chưa hoàn tất.',
            );
            return;
          }
        }
        _nutritionSaved = true;
      }
      if (!current()) return;
      final saved = await ref
          .read(profileControllerProvider.notifier)
          .completeOnboarding(
            OnboardingDraft(
              displayName: _name.text.trim(),
              birthDate: _birthDate!,
              heightCm: ProfileValidation.parseDecimal(_height.text.trim())!,
              currentWeightKg: ProfileValidation.parseDecimal(
                _weight.text.trim(),
              )!,
              healthGoal: _goal!,
              targetWeightKg: _goal!.needsTargetWeight
                  ? ProfileValidation.parseDecimal(_targetWeight.text.trim())
                  : null,
              personalization: _answers.normalized(_goal),
              isProfileEdit: widget.isEditing,
              recordCurrentWeight:
                  !widget.isEditing ||
                  widget.latestMetric?.weightKg !=
                      ProfileValidation.parseDecimal(_weight.text),
            ),
          );
      if (saved && mounted && current() && widget.isEditing) {
        context.go(AppRoutes.profile);
      }
      if (saved) {
        _finished = true;
        _draftTimer?.cancel();
        if (draftStore.local.supported) {
          await draftStore.writeOnboarding(uid, null);
        }
      }
    } catch (_) {
      if (current()) {
        setState(
          () => _completionError =
              'Chưa tải hoặc lưu được mục tiêu. Hãy kiểm tra kết nối rồi thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  Future<void> _deleteAccount() async {
    ref.read(accountSecurityControllerProvider.notifier).clearError();
    final password = await showDeleteAccountDialog(
      context,
      requirePassword:
          ref.read(authSessionProvider).value?.hasPassword != false,
    );
    if (password == null || !mounted) return;
    await ref
        .read(accountSecurityControllerProvider.notifier)
        .deleteAccount(password);
  }

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(profileControllerProvider);
    final accountAction = ref.watch(accountSecurityControllerProvider);
    final busy = _completing || action.isLoading || accountAction.isLoading;
    if (!_draftRestored) {
      return const _OnboardingStatus(
        title: 'Đang khôi phục thiết lập',
        message: 'Đang đọc nháp riêng tư trên thiết bị.',
      );
    }
    if (_restoreFailed) {
      return FeaturePage(
        title: 'Chưa đọc được nháp',
        subtitle: _draftError!,
        children: [
          FilledButton(
            onPressed: _restoreDraft,
            child: const Text('Đọc lại nháp'),
          ),
          TextButton(
            onPressed: () async {
              final discard = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Bỏ nháp thiết lập cũ?'),
                  content: const Text(
                    'Chỉ bỏ nháp cá nhân hóa trên thiết bị; các bữa ăn và hồ sơ đã lưu được giữ lại.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('Giữ nháp'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Bỏ nháp'),
                    ),
                  ],
                ),
              );
              if (discard != true || !_current) return;
              try {
                await ref
                    .read(mealDraftStoreProvider)
                    .writeOnboarding(widget.profile.uid, null);
                if (_current) await _restoreDraft();
              } catch (_) {
                /* Keep the recovery state and original error. */
              }
            },
            child: const Text('Bỏ nháp thiết lập cũ'),
          ),
        ],
      );
    }
    _scheduleDraft();
    final journey = _journey;
    final index = journey.indexOf(_step);
    final isLast = _step == OnboardingStep.plan;
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || busy) return;
        if (index > 0) {
          _previous();
        } else {
          _leave(widget.isEditing ? AppRoutes.profile : AppRoutes.journal);
        }
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      key: const ValueKey('onboarding-back'),
                      tooltip: 'Quay lại',
                      onPressed: busy
                          ? null
                          : () => index > 0
                                ? _previous()
                                : _leave(
                                    widget.isEditing
                                        ? AppRoutes.profile
                                        : AppRoutes.journal,
                                  ),
                      icon: const Icon(AppIcons.arrowLeft),
                    ),
                    Expanded(
                      child: Text(
                        widget.isEditing
                            ? 'Cập nhật cá nhân hóa'
                            : 'Thiết lập sức khỏe ban đầu',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Tùy chọn tài khoản',
                      enabled: !busy,
                      onSelected: (value) async {
                        switch (value) {
                          case 'privacy':
                            showPrivacyInformation(context);
                          case 'logout':
                            if (ref
                                    .read(mealDraftStoreProvider)
                                    .local
                                    .supported &&
                                !await _saveDraft()) {
                              return;
                            }
                            if (_current) {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .signOut();
                            }
                          case 'delete':
                            await _deleteAccount();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'privacy',
                          child: Text('Quyền riêng tư'),
                        ),
                        PopupMenuItem(
                          value: 'logout',
                          child: Text('Đăng xuất và thiết lập sau'),
                        ),
                        PopupMenuItem(
                          key: ValueKey('onboarding-delete-account'),
                          value: 'delete',
                          child: Text('Xóa tài khoản và dữ liệu'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      key: const ValueKey('onboarding-progress'),
                      value: (index + 1) / journey.length,
                      semanticsLabel:
                          'Bước ${index + 1} trên ${journey.length}',
                      borderRadius: BorderRadius.circular(12),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bước ${index + 1}/${journey.length} · ${_stepTitle(_step)}',
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  key: ValueKey('onboarding-scroll-${_step.name}'),
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Form(
                    key: _questionFormKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _questionContent(busy),
                        if (_draftError != null) ...[
                          Text(
                            _draftError!,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                          TextButton(
                            onPressed: _saveDraft,
                            child: const Text('Thử lưu nháp'),
                          ),
                        ],
                        if (_completionError != null)
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _completionError!,
                              key: const ValueKey('onboarding-nutrition-error'),
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        if (_nutritionSaved && action.hasError)
                          const Text(
                            'Mục tiêu dinh dưỡng đã được lưu. Hồ sơ chưa hoàn tất; thử lại không tạo bản trùng.',
                          ),
                        if (action.error case final Object error)
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              _messageFor(error),
                              key: const ValueKey('onboarding-save-error'),
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        if (accountAction.error case final Object error)
                          Text(switch (error) {
                            AuthFailure failure => failure.message,
                            AccountActionFailure failure => failure.message,
                            _ =>
                              'Chưa thể hoàn tất thao tác. Vui lòng thử lại.',
                          }, style: TextStyle(color: theme.colorScheme.error)),
                        if (_draftSaved) ...[
                          const SizedBox(height: 16),
                          const Text('Đã giữ nháp riêng tư trên thiết bị'),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton(
                      key: ValueKey(
                        isLast ? 'onboarding-complete' : 'onboarding-next',
                      ),
                      onPressed: busy
                          ? null
                          : isLast
                          ? _complete
                          : _step == OnboardingStep.details
                          ? () {
                              setState(() => _includeDetails = false);
                              _goTo(OnboardingStep.review);
                            }
                          : _next,
                      child: busy && isLast
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                isLast
                                    ? (_applyPlan && _nutritionDraft != null
                                          ? 'Hoàn tất và áp dụng kế hoạch'
                                          : 'Hoàn tất hồ sơ')
                                    : _calculatorReturn != null
                                    ? 'Xem lại kế hoạch'
                                    : _step == OnboardingStep.details
                                    ? 'Xem tổng kết của tôi'
                                    : _step == OnboardingStep.review
                                    ? 'Xem kế hoạch calo'
                                    : 'Tiếp tục',
                              ),
                            ),
                    ),
                    if (!widget.isEditing)
                      TextButton(
                        key: const ValueKey('onboarding-skip-all'),
                        onPressed: busy ? null : _skipPersonalization,
                        child: const Text('Cá nhân hóa sau'),
                      )
                    else
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => _leave(AppRoutes.profile),
                        child: const Text('Hủy, giữ thông tin đã lưu'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _questionContent(bool busy) {
    final title = switch (_step) {
      OnboardingStep.name => 'Mình nên gọi bạn là gì?',
      OnboardingStep.formulaSex => 'Chọn hệ số dùng để ước tính năng lượng',
      OnboardingStep.birthDate => 'Bạn sinh ngày nào?',
      OnboardingStep.height => 'Chiều cao của bạn là bao nhiêu?',
      OnboardingStep.weight => 'Cân nặng hiện tại của bạn?',
      OnboardingStep.goal => 'Bạn muốn hướng tới mục tiêu nào?',
      OnboardingStep.targetWeight => 'Bạn muốn hướng tới cân nặng bao nhiêu?',
      OnboardingStep.activity => 'Một ngày bình thường bạn vận động thế nào?',
      OnboardingStep.guidance => 'Bạn có cần hướng dẫn dinh dưỡng riêng không?',
      OnboardingStep.pace => 'Bạn muốn bắt đầu với nhịp nào?',
      OnboardingStep.details => 'Bạn có muốn cá nhân hóa thêm không?',
      OnboardingStep.review => 'Cùng xem lại thông tin của bạn nhé',
      OnboardingStep.plan => 'Kế hoạch dành cho bạn',
      _ => personalizationQuestions.firstWhere((q) => q.id == _step.name).title,
    };
    final description = switch (_step) {
      OnboardingStep.name => 'Tên này sẽ xuất hiện trong hồ sơ của bạn.',
      OnboardingStep.formulaSex =>
        'Đây là hệ số sinh lý của công thức, không phải câu hỏi về bản dạng giới. Có thể để sau nếu bạn không muốn trả lời.',
      OnboardingStep.birthDate =>
        'Dùng để tính tuổi. HealthMate hiện dành cho người từ 18 tuổi.',
      OnboardingStep.height || OnboardingStep.weight =>
        'Nhập số đo bạn biết; có thể cập nhật lại trong hồ sơ.',
      OnboardingStep.goal =>
        'Bạn chủ động chọn mục tiêu và có thể thay đổi sau.',
      OnboardingStep.targetWeight =>
        'Đây là mong muốn của bạn, không phải mức cân nặng app yêu cầu phải đạt.',
      OnboardingStep.activity =>
        'Tính cả sinh hoạt và tập luyện thường lệ. Không cộng calo tập luyện thêm lần nữa.',
      OnboardingStep.guidance =>
        'Phạm vi tự động: 18–65 tuổi, không mang thai/cho con bú, không có chế độ ăn điều trị, rối loạn ăn uống hoặc nhu cầu thể thao chuyên nghiệp. Ngoài phạm vi vẫn dùng app và đặt mục tiêu được tư vấn riêng.',
      OnboardingStep.pace =>
        'Thay đổi lựa chọn để xem mức calo khởi đầu. Đây không phải cam kết tăng/giảm một số kg mỗi tuần.',
      OnboardingStep.details =>
        'Các câu về vận động, ăn uống và giấc ngủ là tùy chọn. Bạn có thể trả lời sau trong Cá nhân.',
      OnboardingStep.avoidFoods =>
        'Ngăn cách bằng dấu ; hoặc dấu phẩy. Bộ lọc từ khóa không kiểm tra được nhiễm chéo; luôn kiểm tra nguyên liệu thực tế.',
      OnboardingStep.review =>
        'Chạm quay lại nếu cần sửa. Chưa có thay đổi nào được lưu vào hồ sơ.',
      OnboardingStep.plan =>
        'Xem mục tiêu, cách tính và dưỡng chất trước khi xác nhận.',
      _ =>
        'Có thể để sau. Câu trả lời giúp mô tả thói quen, không dùng để chẩn đoán hay tự cộng/trừ calo.',
    };
    final children = <Widget>[
      if (_step != OnboardingStep.plan)
        OnboardingPrompt(title: title, message: description),
    ];
    switch (_step) {
      case OnboardingStep.name:
        children.add(
          TextFormField(
            key: const ValueKey('onboarding-name'),
            controller: _name,
            enabled: !busy,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Tên hiển thị',
              prefixIcon: Icon(AppIcons.contactRound),
            ),
            validator: ProfileValidation.displayName,
          ),
        );
      case OnboardingStep.birthDate:
        children.add(
          OutlinedButton(
            key: const ValueKey('onboarding-birth-date'),
            onPressed: busy ? null : _pickBirthDate,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  const Icon(AppIcons.cake),
                  Text(
                    _birthDate == null
                        ? 'Chọn ngày sinh'
                        : DateFormat('dd/MM/yyyy').format(_birthDate!),
                  ),
                ],
              ),
            ),
          ),
        );
        if (_birthDateError != null) {
          children.add(
            Text(
              _birthDateError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }
      case OnboardingStep.height ||
          OnboardingStep.weight ||
          OnboardingStep.targetWeight:
        final height = _step == OnboardingStep.height;
        final target = _step == OnboardingStep.targetWeight;
        children.add(
          OnboardingMeasurement(
            controller: height
                ? _height
                : target
                ? _targetWeight
                : _weight,
            fieldKey: height
                ? 'onboarding-height'
                : target
                ? 'onboarding-target-weight'
                : 'onboarding-weight',
            label: height
                ? 'Chiều cao'
                : target
                ? 'Cân nặng mục tiêu'
                : 'Cân nặng hiện tại',
            unit: height ? 'cm' : 'kg',
            min: height ? 80 : 20,
            max: height ? 250 : 500,
            validator: height
                ? ProfileValidation.requiredHeight
                : ProfileValidation.weight,
            enabled: !busy,
          ),
        );
        if (!height) {
          children.add(
            OnboardingBmi(
              heightCm: ProfileValidation.parseDecimal(_height.text),
              weightKg: ProfileValidation.parseDecimal(
                target ? _targetWeight.text : _weight.text,
              ),
              isTarget: target,
            ),
          );
        }
      case OnboardingStep.goal:
        for (final goal in HealthGoal.values) {
          children.add(
            OnboardingChoice(
              key: ValueKey('onboarding-goal-${goal.value}'),
              label: goal.label,
              description: switch (goal) {
                HealthGoal.loseWeight =>
                  'Giảm năng lượng vừa phải và theo dõi tiến độ.',
                HealthGoal.maintainWeight =>
                  'Bắt đầu ở mức năng lượng duy trì.',
                HealthGoal.gainWeightOrMuscle =>
                  'Tăng năng lượng từng bước theo lựa chọn của bạn.',
                HealthGoal.gainMuscle =>
                  'Bắt đầu ở mức duy trì, ưu tiên đạm và thói quen tập sức mạnh.',
                HealthGoal.healthierHabits =>
                  'Ưu tiên ăn uống, vận động hoặc giấc ngủ; không bắt buộc theo dõi calo.',
              },
              icon: switch (goal) {
                HealthGoal.loseWeight => AppIcons.trendingDown,
                HealthGoal.maintainWeight => AppIcons.moveRight,
                HealthGoal.gainWeightOrMuscle => AppIcons.trendingUp,
                HealthGoal.gainMuscle => AppIcons.workout,
                HealthGoal.healthierHabits => AppIcons.leaf,
              },
              selected: _goal == goal,
              onTap: busy
                  ? null
                  : () => setState(() {
                      _goal = goal;
                      _goalError = null;
                      _answers = _answers.normalized(goal);
                      _nutritionDraft = null;
                      _calculatedPlan = null;
                    }),
            ),
          );
        }
        if (_goalError != null) {
          children.add(
            Text(
              _goalError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );
        }
      case OnboardingStep.details:
        children.add(
          OnboardingChoice(
            key: const ValueKey('onboarding-add-details'),
            label: 'Trả lời thêm về thói quen',
            description:
                'Có thể bỏ qua từng câu; không làm thay đổi calo chỉ từ giấc ngủ.',
            icon: AppIcons.slidersHorizontal,
            selected: _includeDetails,
            onTap: busy
                ? null
                : () {
                    setState(() => _includeDetails = true);
                    _next();
                  },
          ),
        );
      case OnboardingStep.review:
        children.addAll([
          _summaryRow('Tên hiển thị', _name.text.trim()),
          _summaryRow(
            'Ngày sinh',
            DateFormat('dd/MM/yyyy').format(_birthDate!),
          ),
          _summaryRow('Chiều cao', '${_height.text} cm'),
          _summaryRow('Cân nặng hiện tại', '${_weight.text} kg'),
          _summaryRow('Mục tiêu', _goal!.label),
          if (_goal!.needsTargetWeight)
            _summaryRow('Cân nặng mục tiêu', '${_targetWeight.text} kg'),
          _summaryRow('Vận động', _answers.activity?.label ?? 'Chưa trả lời'),
          OnboardingBmi(
            heightCm: ProfileValidation.parseDecimal(_height.text),
            weightKg: ProfileValidation.parseDecimal(_weight.text),
          ),
          if (_answers.segmentLabels.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Đặc điểm đã chọn: ${_answers.segmentLabels.join(' · ')}'),
          ],
          const SizedBox(height: 12),
          Text(_answers.firstAction),
          TextButton(
            key: const ValueKey('onboarding-edit-answers'),
            onPressed: busy ? null : () => _goTo(OnboardingStep.name),
            child: const Text('Chỉnh sửa câu trả lời'),
          ),
        ]);
      case OnboardingStep.plan:
        if (_goal!.needsTargetWeight) {
          children.add(
            _summaryRow(
              'Cân nặng mục tiêu',
              '${ProfileValidation.parseDecimal(_targetWeight.text)!.toStringAsFixed(1)} kg',
            ),
          );
        }
        if (_calculatedPlan != null) {
          children.add(
            OnboardingPlanSummary(
              plan: _calculatedPlan!,
              name: _name.text.trim(),
            ),
          );
          children.add(
            CheckboxListTile(
              key: const ValueKey('onboarding-apply-plan'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Áp dụng mục tiêu calo này từ hôm nay'),
              subtitle: const Text(
                'Bỏ chọn nếu bạn muốn thiết lập calo sau hoặc giữ mục tiêu đang có.',
              ),
              value: _applyPlan,
              onChanged: busy
                  ? null
                  : (value) => setState(() => _applyPlan = value == true),
            ),
          );
        } else {
          children.addAll([
            Text(
              'Mục tiêu của bạn: ${_goal!.label}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              _planError ?? 'Bạn có thể hoàn tất hồ sơ và thiết lập calo sau.',
            ),
          ]);
        }
        children.add(
          TextButton.icon(
            key: const ValueKey('onboarding-personalize-nutrition'),
            onPressed: busy ? null : _personalize,
            icon: const Icon(AppIcons.calculator),
            label: Text(
              _missingPlanStep == null
                  ? 'Tính lại đề xuất'
                  : 'Bổ sung thông tin để tính calo',
            ),
          ),
        );
        children.add(
          const Text(
            'Thông tin chỉ hỗ trợ theo dõi thói quen, không thay thế tư vấn y tế.',
          ),
        );
      default:
        children.add(
          OnboardingSurvey(
            id: _step.name,
            goal: _goal,
            answers: _answers,
            onChanged: _changeAnswers,
            enabled: !busy,
          ),
        );
        if (_step == OnboardingStep.pace && _answers['pace'] != null) {
          try {
            final estimate = _calculatePlan();
            children.add(
              Text(
                'Mức khởi đầu: ${estimate.kcal.toStringAsFixed(0)} kcal/ngày',
                key: const ValueKey('onboarding-pace-preview'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            );
          } on FormatException catch (error) {
            children.add(Text(error.message));
          }
        }
    }
    return Column(
      key: ValueKey(switch (_step) {
        OnboardingStep.name => 'onboarding-name-step',
        OnboardingStep.goal => 'onboarding-goal-step',
        OnboardingStep.targetWeight => 'onboarding-target-step',
        OnboardingStep.review => 'onboarding-review-step',
        OnboardingStep.plan => 'onboarding-nutrition-step',
        _ => 'onboarding-${_step.name}-step',
      }),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _summaryRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        Text(label),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}

class _OnboardingStatus extends StatelessWidget {
  const _OnboardingStatus({
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return FeaturePage(
      title: title,
      subtitle: message,
      children: [
        if (onRetry == null)
          const Center(child: CircularProgressIndicator())
        else
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(AppIcons.refreshCw),
            label: const Text('Thử lại'),
          ),
      ],
    );
  }
}

String _stepTitle(OnboardingStep step) => switch (step) {
  OnboardingStep.name => 'Tên hiển thị',
  OnboardingStep.formulaSex => 'Hệ số sinh lý',
  OnboardingStep.birthDate => 'Ngày sinh',
  OnboardingStep.height => 'Chiều cao',
  OnboardingStep.weight => 'Cân nặng',
  OnboardingStep.goal => 'Mục tiêu',
  OnboardingStep.targetWeight => 'Cân nặng mong muốn',
  OnboardingStep.activity => 'Vận động thường ngày',
  OnboardingStep.guidance => 'Phạm vi đề xuất',
  OnboardingStep.pace => 'Nhịp điều chỉnh',
  OnboardingStep.details => 'Cá nhân hóa thêm',
  OnboardingStep.review => 'Tổng kết',
  OnboardingStep.plan => 'Kế hoạch của bạn',
  _ => 'Thói quen · tùy chọn',
};
String _messageFor(Object error) => switch (error) {
  ProfileFailure failure => failure.message,
  _ => 'Chưa thể tải dữ liệu. Vui lòng thử lại.',
};
