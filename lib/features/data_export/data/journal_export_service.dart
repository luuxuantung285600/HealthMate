import 'dart:convert';
import 'dart:async';
import 'dart:async' as async show AsyncError;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/private_local_data.dart';
import '../../auth/providers/auth_providers.dart';
import '../../meal_drafts/data/meal_draft_store.dart';
import '../../nutrition/data/nutrition_repository.dart';
import '../../nutrition/providers/nutrition_providers.dart';
import '../../water/data/water_repository.dart';
import '../../water/providers/water_providers.dart';
import '../../activity/data/activity_repository.dart';
import '../../activity/providers/activity_providers.dart';
import '../../profile/data/health_profile_repository.dart';
import '../../profile/providers/profile_providers.dart';
import '../models/journal_csv.dart';
import '../../reports/models/period_report.dart';
import '../../reports/data/report_range_loader.dart';

final journalExportServiceProvider = Provider<JournalExportService>((ref) {
  var session = 0;
  ref.listen(authSessionProvider.select((s) => s.value?.uid), (before, after) {
    if (before != after) session++;
  });
  ref.listen(accountDeletionJobProvider, (before, after) {
    if (after.isLoading || after.hasError || after.value != null) session++;
  });
  return JournalExportService(
    local: ref.watch(privateLocalDataProvider),
    nutrition: ref.watch(nutritionRepositoryProvider),
    water: ref.watch(waterRepositoryProvider),
    activity: ref.watch(activityRepositoryProvider),
    profile: ref.watch(healthProfileRepositoryProvider),
    currentUid: () {
      if (!ref.mounted) return null;
      final deletion = ref.read(accountDeletionJobProvider);
      if (deletion.isLoading || deletion.hasError || deletion.value != null) {
        return null;
      }
      return ref.read(authRepositoryProvider).currentUid;
    },
    sessionVersion: () => session,
  );
});

enum JournalExportFormat { detailed, dailySummary }

enum JournalExportStage { loading, choosingDestination, writing }

class JournalExportService {
  JournalExportService({
    required this.local,
    required this.nutrition,
    required this.water,
    required this.activity,
    required this.profile,
    required this.currentUid,
    this.sessionVersion,
  });
  final PrivateLocalData local;
  final NutritionRepository nutrition;
  final WaterRepository water;
  final ActivityRepository activity;
  final HealthProfileRepository profile;
  final String? Function() currentUid;
  final int Function()? sessionVersion;
  bool _busy = false;

  /// null = user cancelled; success is returned only after native byte readback.
  Future<int?> export(
    DateTime start,
    DateTime end, {
    bool Function()? stillOpen,
    JournalExportFormat format = JournalExportFormat.detailed,
    void Function(JournalExportStage)? onStage,
  }) async {
    if (_busy) throw StateError('Đang xuất dữ liệu.');
    if (!local.supported) {
      throw UnsupportedError('Xuất tệp hiện hỗ trợ Android.');
    }
    final uid = currentUid();
    final session = sessionVersion?.call();
    if (uid == null) throw StateError('Hãy đăng nhập trước khi xuất.');
    void check() {
      if (currentUid() != uid ||
          sessionVersion?.call() != session ||
          stillOpen?.call() == false) {
        throw StateError(
          'Phiên xuất đã thay đổi. Không ghi dữ liệu tài khoản cũ.',
        );
      }
    }

    // Validate range before starting any network reads.
    buildJournalCsv(start: start, endExclusive: end);
    final range = ReportRange.inclusive(
      start,
      DateTime(end.year, end.month, end.day - 1),
    );
    _busy = true;
    String? ticket;
    try {
      onStage?.call(JournalExportStage.loading);
      final (meals, waterLogs, activities, weights) = await (
        loadReportRange(
          range,
          (c) => nutrition.loadRange(uid, c.start, c.end),
          keyOf: (m) => m.id,
          isCurrent: () {
            check();
            return true;
          },
        ),
        loadReportRange(
          range,
          (c) => water.loadRange(uid, c.start, c.end),
          keyOf: (w) => w.id,
          isCurrent: () {
            check();
            return true;
          },
        ),
        loadReportRange(
          range,
          (c) => activity.loadRange(uid, c.start, c.end),
          keyOf: (a) => a.id,
          isCurrent: () {
            check();
            return true;
          },
        ),
        loadReportRange(
          range,
          (c) => profile.loadBodyMetricsRange(uid, c.start, c.end),
          keyOf: (m) => m.id,
          isCurrent: () {
            check();
            return true;
          },
        ),
      ).wait;
      check();
      final build = format == JournalExportFormat.dailySummary
          ? buildDailySummaryCsv
          : buildJournalCsv;
      final csv = build(
        start: start,
        endExclusive: end,
        meals: meals,
        water: waterLogs,
        activities: activities,
        weights: weights,
      );
      String date(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      onStage?.call(JournalExportStage.choosingDestination);
      check();
      ticket = await local.chooseCsv(
        'HealthMate-${format == JournalExportFormat.dailySummary ? 'tong-hop-ngay-' : ''}${date(start)}-${date(DateTime(end.year, end.month, end.day - 1))}.csv',
      );
      if (ticket == null) return null;
      check(); // The OS picker may have remained open through sign-out or account switch.
      final bytes = utf8.encode(csv);
      onStage?.call(JournalExportStage.writing);
      check();
      final verified = await local.writeCsv(ticket, bytes);
      ticket = null;
      if (verified != bytes.length) {
        throw StateError('Chưa kiểm chứng được tệp đã lưu.');
      }
      check();
      return verified;
    } on ParallelWaitError catch (error) {
      // Never interpret a partially successful parallel read as a full export.
      check();
      final errors =
          error.errors
              as (
                async.AsyncError?,
                async.AsyncError?,
                async.AsyncError?,
                async.AsyncError?,
              );
      for (final failure in [errors.$1, errors.$2, errors.$3, errors.$4]) {
        if (failure != null) {
          Error.throwWithStackTrace(failure.error, failure.stackTrace);
        }
      }
      rethrow;
    } finally {
      if (ticket != null) {
        try {
          await local.cancelCsv(ticket);
        } catch (_) {
          /* Empty document may need manual removal. */
        }
      }
      _busy = false;
    }
  }
}
