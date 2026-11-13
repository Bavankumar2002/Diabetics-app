import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../providers/medication_provider.dart';
import '../../models/medication_model.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MedicationProvider>(context, listen: false).fetchMedications();
    });
  }

  void _showAddMedicationModal() {
    final nameCtrl = TextEditingController();
    final dosageCtrl = TextEditingController(text: '500 mg');
    final instructionCtrl = TextEditingController(text: 'Take after meal');
    String frequency = 'Once daily';
    String reminderTime = '08:00 AM';
    bool isInsulin = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Add Diabetes Medication', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Medication Name',
                      hintText: 'e.g. Metformin / Glimepiride',
                      prefixIcon: Icon(Icons.medication_rounded, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: dosageCtrl,
                          decoration: const InputDecoration(labelText: 'Dosage', hintText: 'e.g. 500 mg'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                            if (picked != null) {
                              final h = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
                              final m = picked.minute.toString().padLeft(2, '0');
                              final p = picked.period == DayPeriod.am ? 'AM' : 'PM';
                              setModalState(() => reminderTime = '$h:$m $p');
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Reminder Time'),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(reminderTime, style: const TextStyle(fontWeight: FontWeight.bold)),
                                const Icon(Icons.access_time, size: 18, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Is this an Insulin dose?', style: TextStyle(fontWeight: FontWeight.w600)),
                    value: isInsulin,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setModalState(() => isInsulin = val),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: instructionCtrl,
                    decoration: const InputDecoration(labelText: 'Physician Instructions', hintText: 'e.g. Take immediately after breakfast'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx);
                      final medProvider = Provider.of<MedicationProvider>(context, listen: false);
                      await medProvider.addMedication(
                        name: nameCtrl.text.trim(),
                        dosage: dosageCtrl.text.trim(),
                        frequency: frequency,
                        isInsulin: isInsulin,
                        reminderTime: reminderTime,
                        instructions: instructionCtrl.text.trim(),
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Medication added successfully'), backgroundColor: AppColors.success),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Save Medication', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final med = Provider.of<MedicationProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Management'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Medication', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _showAddMedicationModal,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => med.fetchMedications(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Adherence Header Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.health_and_safety_rounded, color: AppColors.primaryDark, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Adherence to your prescribed medications ensures stable blood glucose and prevents long-term diabetic vascular complications.',
                          style: TextStyle(fontSize: 12, height: 1.4, color: AppColors.primaryDark),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Daily Medication Schedule (${med.medications.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                if (med.medications.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(
                      child: Text(
                        'No medications added yet.\nTap "+ Add Medication" to schedule your daily doses.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textMutedLight),
                      ),
                    ),
                  ),
                ] else ...[
                  ...med.medications.map((m) {
                    final isTaken = m.todayStatus == 'taken';
                    final isSkipped = m.todayStatus == 'skipped';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (m.isInsulin ? AppColors.secondary : AppColors.purple).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    m.isInsulin ? Icons.vaccines_rounded : Icons.medication_rounded,
                                    color: m.isInsulin ? AppColors.secondary : AppColors.purple,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        m.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          decoration: isTaken ? TextDecoration.lineThrough : null,
                                        ),
                                      ),
                                      Text('${m.dosage} • ${m.frequency}', style: const TextStyle(fontSize: 12, color: AppColors.textMutedLight)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                                  onPressed: () => med.deleteMedication(m.id),
                                ),
                              ],
                            ),
                            if (m.instructions.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('Note: ${m.instructions}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondaryLight)),
                            ],
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.alarm, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 4),
                                    Text(m.reminderTime, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                  ],
                                ),
                                Row(
                                  children: [
                                    OutlinedButton(
                                      onPressed: () => med.updateStatus(m.id, 'skipped'),
                                      style: OutlinedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        foregroundColor: isSkipped ? Colors.white : AppColors.textSecondaryLight,
                                        backgroundColor: isSkipped ? AppColors.danger : Colors.transparent,
                                        side: BorderSide(color: isSkipped ? AppColors.danger : AppColors.borderLight),
                                      ),
                                      child: const Text('Skipped'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => med.updateStatus(m.id, 'taken'),
                                      style: ElevatedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        backgroundColor: isTaken ? AppColors.success : AppColors.primary,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text(isTaken ? 'Taken ✓' : 'Take Dose'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
