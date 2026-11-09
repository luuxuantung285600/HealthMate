import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/local_date_key.dart';
import '../data/journal_export_service.dart';
import '../../reports/presentation/report_range_dialog.dart';
import '../../reports/models/period_report.dart';
import '../../../core/data/bounded_range.dart';
import '../../../shared/providers/local_clock_provider.dart';

class JournalExportDialog extends ConsumerStatefulWidget {
  const JournalExportDialog({this.initialRange, super.key});
  final ReportRange? initialRange;
  @override
  ConsumerState<JournalExportDialog> createState() =>
      _JournalExportDialogState();
}

class _JournalExportDialogState extends ConsumerState<JournalExportDialog> {
  late DateTime _end =
      widget.initialRange?.lastDay ??
      localDateOnly(ref.read(currentLocalTimeProvider)());
  late DateTime _start =
      widget.initialRange?.start ??
      DateTime(_end.year, _end.month, _end.day - 6);
  bool _consent = false, _busy = false;
  JournalExportFormat _format = JournalExportFormat.detailed;
  JournalExportStage? _stage;
  String? _message;
  ReportRange? _initialRange() {
    try {
      return ReportRange.inclusive(_start, _end);
    } on RangeReadFailure {
      return null;
    }
  }

  Future<void> _pick(bool start) async {
    final value = await showDatePicker(
      context: context,
      initialDate: start ? _start : _end,
      firstDate: DateTime(1900),
      lastDate: ref.read(currentLocalTimeProvider)(),
    );
    if (value != null && mounted) {
      setState(() {
        if (start) {
          _start = value;
        } else {
          _end = value;
        }
        _message = null;
      });
    }
  }

  Future<void> _export() async {
    if (_busy || !_consent) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final bytes = await ref
          .read(journalExportServiceProvider)
          .export(
            _start,
            DateTime(_end.year, _end.month, _end.day + 1),
            stillOpen: () => mounted,
            format: _format,
            onStage: (stage) {
              if (mounted) setState(() => _stage = stage);
            },
          );
      if (mounted) {
        setState(
          () => _message = bytes == null
              ? 'Đã hủy chọn nơi lưu; chưa xuất dữ liệu.'
              : 'Đã lưu và đọc lại kiểm tra tệp CSV ($bytes byte), từ ${DateFormat('dd/MM/yyyy').format(_start)} đến hết ${DateFormat('dd/MM/yyyy').format(_end)}.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _message = e is FormatException
              ? e.message
              : e is RangeReadFailure
              ? e.message
              : e is UnsupportedError
              ? e.message
              : 'Chưa xác nhận xuất thành công. Kiểm tra mạng, tài khoản, khoảng 1–366 ngày và quyền nơi lưu rồi thử lại. Nếu có tệp chưa hoàn chỉnh, hãy xóa tệp đó.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _stage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Xuất nhật ký CSV'),
          leading: IconButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Xuất bữa ăn, nước, vận động và cân nặng trong khoảng bạn chọn, từ nhật ký đã lưu.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Ô trống là chưa có dữ liệu; số 0 đã ghi được giữ nguyên.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<JournalExportFormat>(
              key: const ValueKey('export-format'),
              initialValue: _format,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Nội dung tệp CSV'),
              items: const [
                DropdownMenuItem(
                  value: JournalExportFormat.detailed,
                  child: Text(
                    'Nhật ký chi tiết',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: JournalExportFormat.dailySummary,
                  child: Text(
                    'Tổng hợp theo ngày',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              onChanged: _busy
                  ? null
                  : (format) {
                      if (format != null) {
                        setState(() {
                          _format = format;
                          _message = null;
                        });
                      }
                    },
            ),
            const SizedBox(height: 12),
            Text(
              _format == JournalExportFormat.dailySummary
                  ? 'Mỗi ngày một dòng: bữa ăn, kcal và dưỡng chất đã ghi, nước, vận động, lần cân cuối trong ngày. Dưỡng chất thiếu được ghi rõ; không coi nhật ký là đầy đủ cả ngày.'
                  : 'Từng món ăn và từng bản ghi, giữ nguồn, nhãn ước tính, UTC và múi giờ. Khoảng không có nhật ký chỉ có dòng tiêu đề.',
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const ValueKey('export-custom-range'),
              onPressed: _busy
                  ? null
                  : () async {
                      final range = await chooseReportRange(
                        context,
                        today: ref.read(currentLocalTimeProvider)(),
                        initial: _initialRange(),
                      );
                      if (mounted && range != null) {
                        setState(() {
                          _start = range.start;
                          _end = range.lastDay;
                          _message = null;
                        });
                      }
                    },
              icon: const Icon(Icons.date_range),
              label: const Text('Chọn khoảng hoặc số ngày'),
            ),
            OutlinedButton.icon(
              key: const ValueKey('export-this-year'),
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      final range = ReportRange.year(
                        ref.read(currentLocalTimeProvider)().year,
                        ref.read(currentLocalTimeProvider)(),
                      );
                      _start = range.start;
                      _end = range.lastDay;
                      _message = null;
                    }),
              icon: const Icon(Icons.calendar_month),
              label: const Text('Chọn năm nay'),
            ),
            OutlinedButton(
              key: const ValueKey('export-start'),
              onPressed: _busy ? null : () => _pick(true),
              child: Text('Từ ${DateFormat.yMd('vi').format(_start)}'),
            ),
            OutlinedButton(
              key: const ValueKey('export-end'),
              onPressed: _busy ? null : () => _pick(false),
              child: Text('Đến hết ${DateFormat.yMd('vi').format(_end)}'),
            ),
            const ExpansionTile(
              title: Text('Nội dung và giới hạn tệp'),
              childrenPadding: EdgeInsets.only(bottom: 16),
              children: [
                Text(
                  'Mỗi lần 1–366 ngày, tối đa 10.000 bản ghi mỗi nguồn và 5 MB. Mỗi phần tải tối đa 90 ngày/2.000 bản ghi; quá giới hạn cần chọn khoảng nhỏ hơn, không tự cắt bớt.',
                ),
                SizedBox(height: 8),
                Text(
                  'CSV UTF-8 giữ tiếng Việt và đơn vị. Không có nhật ký không có nghĩa là không ăn hoặc không vận động. Cân nặng và bản ghi cũ dùng múi giờ thiết bị lúc xuất. Không bao gồm giấc ngủ, hồ sơ, hội thoại, mục tiêu hoặc nháp.',
                ),
              ],
            ),
            const Text(
              'Tệp chứa dữ liệu sức khỏe cá nhân. Bạn chủ động chọn nơi lưu và chịu trách nhiệm khi chia sẻ.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Chọn bộ nhớ trên thiết bị để giữ cục bộ. Chọn nhà cung cấp đám mây sẽ lưu lên nơi đó. Tệp đã xuất không tự bị xóa khi xóa tài khoản HealthMate.',
            ),
            CheckboxListTile(
              key: const ValueKey('export-consent'),
              value: _consent,
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _consent = v ?? false),
              title: const Text('Tôi đồng ý xuất tệp riêng tư này.'),
            ),
            if (_busy) ...[
              const LinearProgressIndicator(),
              Text(switch (_stage) {
                JournalExportStage.choosingDestination =>
                  'Đang chờ bạn chọn nơi lưu…',
                JournalExportStage.writing =>
                  'Đang ghi và đọc lại kiểm tra tệp…',
                _ => 'Đang tải đủ dữ liệu trong khoảng đã chọn…',
              }, key: const ValueKey('export-stage')),
            ],
            if (_message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(_message!, key: const ValueKey('export-result')),
              ),
            FilledButton.icon(
              key: const ValueKey('export-csv'),
              onPressed: _busy || !_consent ? null : _export,
              icon: const Icon(Icons.save_alt),
              label: Text(_busy ? 'Đang xuất…' : 'Chọn nơi lưu CSV'),
            ),
          ],
        ),
      ),
    ),
  );
}
