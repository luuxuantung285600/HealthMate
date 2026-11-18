import '../../../core/theme/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/energy_estimate.dart';

class EnergyEstimateDialog extends StatefulWidget {
  const EnergyEstimateDialog({super.key});
  @override
  State<EnergyEstimateDialog> createState() => _EnergyEstimateDialogState();
}

class _EnergyEstimateDialogState extends State<EnergyEstimateDialog> {
  final _age = TextEditingController(), _weight = TextEditingController();
  FormulaSex? _sex;
  HabitualActivity? _activity;
  bool _eligible = false;
  EnergyEstimate? _result;
  String? _error;
  void _changed() => setState(() {
    _result = null;
    _error = null;
  });
  @override
  void dispose() {
    _age.dispose();
    _weight.dispose();
    super.dispose();
  }

  void _calculate() {
    final input = EnergyEstimateInput(
      age: int.tryParse(_age.text.trim()),
      weightKg: double.tryParse(_weight.text.trim().replaceAll(',', '.')),
      sex: _sex,
      activity: _activity,
      eligible: _eligible,
    );
    setState(() {
      _error = input.validate();
      _result = _error == null ? input.calculate() : null;
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final number = NumberFormat('0', 'vi');
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mức duy trì tham khảo'),
          leading: IconButton(
            tooltip: 'Quay về nhập tay',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(AppIcons.x),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Tùy chọn cho người 18–59 tuổi, khỏe mạnh, chỉ muốn tham khảo năng lượng duy trì cân. Công thức theo nhóm dân số có thể sai khác đáng kể ở từng người.',
            ),
            const SizedBox(height: 12),
            const Text(
              'Không dùng hướng dẫn này khi mang thai/cho con bú, có chế độ ăn điều trị, thể trạng đặc biệt hoặc vận động thể thao chuyên nghiệp. Giảm/tăng cân hay trường hợp ngoài phạm vi: quay về nhập tay cùng chuyên gia. Không thay thế tư vấn y tế.',
            ),
            CheckboxListTile(
              key: const ValueKey('estimate-eligible'),
              contentPadding: EdgeInsets.zero,
              title: const Text('Tôi đã đọc và thuộc phạm vi áp dụng trên'),
              value: _eligible,
              onChanged: (v) {
                _eligible = v!;
                _changed();
              },
            ),
            TextField(
              key: const ValueKey('estimate-age'),
              controller: _age,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Tuổi (năm, 18–59)'),
              onChanged: (_) => _changed(),
            ),
            const SizedBox(height: 20),
            TextField(
              key: const ValueKey('estimate-weight'),
              controller: _weight,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Cân nặng hiện tại (kg)',
              ),
              onChanged: (_) => _changed(),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<FormulaSex>(
              key: const ValueKey('estimate-sex'),
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Hệ số sinh lý theo công thức gốc',
              ),
              items: const [
                DropdownMenuItem(
                  value: FormulaSex.male,
                  child: Text('Nam · hệ số theo nghiên cứu'),
                ),
                DropdownMenuItem(
                  value: FormulaSex.female,
                  child: Text('Nữ · hệ số theo nghiên cứu'),
                ),
              ],
              onChanged: (v) {
                _sex = v;
                _changed();
              },
            ),
            const Text(
              'Không suy ra từ tên hay hồ sơ. Nếu không muốn chọn hoặc không phù hợp với hệ số gốc, bạn có thể quay về nhập tay.',
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<HabitualActivity>(
              key: const ValueKey('estimate-activity'),
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Hoạt động thường ngày (tự chọn)',
              ),
              items: [
                for (final a in HabitualActivity.values)
                  DropdownMenuItem(value: a, child: Text(a.label)),
              ],
              onChanged: (v) {
                _activity = v;
                _changed();
              },
            ),
            if (_activity != null)
              Text(
                '${_activity!.description}. Hệ số ví dụ ${_activity!.factor}.',
              ),
            const SizedBox(height: 16),
            const Text(
              'Nguồn: FAO/WHO/UNU, Human Energy Requirements, bảng 5.1 và 5.2 (Schofield). BMR từ cân nặng và nhóm tuổi × hệ số hoạt động ví dụ của FAO. Đây là phép tham khảo, không phải số đo cá nhân; không cộng kcal từ phút vận động đã ghi.',
            ),
            const SelectionArea(child: Text('fao.org/4/y5686e/y5686e07.htm')),
            if (_error != null)
              Text(
                _error!,
                key: const ValueKey('estimate-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            OutlinedButton(
              key: const ValueKey('calculate-estimate'),
              onPressed: _calculate,
              child: const Text('Xem cách tính và kết quả'),
            ),
            if (_result != null) ...[
              Text(
                'BMR tham khảo ${number.format(_result!.basalKcal)} × ${_result!.activityFactor} = ${number.format(_result!.maintenanceKcal)} kcal/ngày.\nLàm tròn: ${number.format(_result!.roundedKcal)} kcal/ngày.',
                key: const ValueKey('estimate-result'),
              ),
              const Text(
                'Chỉ đưa kcal vào form; các mục tiêu chất hiện có được giữ nguyên. Chưa lưu. Bạn có thể chỉnh mọi giá trị và ngày hiệu lực trước khi Lưu mục tiêu. Dữ liệu đầu vào ở đây chỉ giữ trong form, không lưu hồ sơ.',
              ),
              FilledButton(
                key: const ValueKey('accept-estimate'),
                onPressed: () => Navigator.pop(context, _result!.roundedKcal),
                child: const Text('Dùng số này trong form'),
              ),
            ],
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Bỏ qua, quay về nhập tay'),
            ),
          ],
        ),
      ),
    );
  }
}
