import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'add_pet_screen.dart';
import 'image_viewer_screen.dart';

class PetDetailsScreen extends StatefulWidget {
  final Map pet;

  const PetDetailsScreen({super.key, required this.pet});

  @override
  State<PetDetailsScreen> createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> {
  bool isLoading = true;
  bool isMarkingMeal = false;
  bool isMarkingVaccine = false;
  bool isMarkingAllMeals = false;
  Map pet = {};
  List logs = [];

  @override
  void initState() {
    super.initState();
    pet = Map<String, dynamic>.from(widget.pet);
    fetchDetails();
  }

  Future<void> fetchDetails() async {
    final data = await ApiService.getPetDetails(widget.pet['_id']);
    if (!mounted) return;

    setState(() {
      pet = data?['pet'] ?? widget.pet;
      logs = (data?['logs'] as List?) ?? [];
      isLoading = false;
    });
  }

  Future<void> markMealDone(String label) async {
    if (isMarkingMeal) return;
    setState(() => isMarkingMeal = true);

    final success = await ApiService.markPetMealDone(widget.pet['_id'], label);
    if (!mounted) return;

    setState(() => isMarkingMeal = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save meal log')),
      );
      return;
    }

    await fetchDetails();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label marked as done')),
    );
  }

  Future<void> markVaccineDone() async {
    if (isMarkingVaccine) return;
    final nextDate = await _pickNextVaccineDate();
    if (!mounted || nextDate == null) return;

    setState(() => isMarkingVaccine = true);

    final success = await ApiService.markPetVaccineDone(
      widget.pet['_id'],
      pet['vaccineReminderDate']?.toString() ?? '',
      nextVaccineDate: nextDate,
    );
    if (!mounted) return;

    setState(() => isMarkingVaccine = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save vaccine log')),
      );
      return;
    }

    await fetchDetails();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          nextDate.isEmpty
              ? 'Vaccine marked as done'
              : 'Vaccine marked as done, next date saved',
        ),
      ),
    );
  }

  Future<void> markAllMealsDone(List<String> mealTimes) async {
    if (isMarkingAllMeals || mealTimes.isEmpty) return;

    final pendingMeals = mealTimes.where((time) => !_mealDoneToday(time)).toList();
    if (pendingMeals.isEmpty) return;

    setState(() => isMarkingAllMeals = true);

    var successCount = 0;
    for (final meal in pendingMeals) {
      final success = await ApiService.markPetMealDone(widget.pet['_id'], meal);
      if (success) successCount++;
    }

    if (!mounted) return;
    setState(() => isMarkingAllMeals = false);

    await fetchDetails();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          successCount == pendingMeals.length
              ? 'All meals marked as done'
              : 'Some meals were not saved',
        ),
      ),
    );
  }

  Future<void> editPet() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPetScreen(pet: pet),
      ),
    );

    if (!mounted) return;
    await fetchDetails();
  }

  Future<void> deletePet() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Pet'),
        content: Text('Delete ${pet['name']} from your pets?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await ApiService.deletePet(widget.pet['_id']);
    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete pet')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pet deleted')),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final mealTimes = _extractFoodTimes(pet);
    final vaccineDate = pet['vaccineReminderDate']?.toString() ?? '';
    final image = pet['image']?.toString();
    final hasImage = image != null && image.isNotEmpty;
    final nextMealSummary = _buildNextMealSummary(mealTimes);
    final nextVaccineSummary = _buildNextVaccineSummary(vaccineDate);
    final completedMealsToday = _completedMealsCountToday(mealTimes);
    final mealProgress = mealTimes.isEmpty
        ? 0.0
        : (completedMealsToday / mealTimes.length).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xff24394a)),
        title: Text(
          pet['name']?.toString().isNotEmpty == true
              ? pet['name'].toString()
              : 'Pet Details',
          style: const TextStyle(
            color: Color(0xff24394a),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                await editPet();
                return;
              }

              if (value == 'delete') {
                await deletePet();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Text('Edit'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text('Delete'),
              ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchDetails,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: GestureDetector(
                            onTap: hasImage
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ImageViewerScreen(
                                          images: [image],
                                          initialIndex: 0,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            child: hasImage
                                ? Image.network(
                                    '${ApiService.baseUrl}/uploads/$image',
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 96,
                                    height: 96,
                                    color: const Color(0xffe9edf3),
                                    child: const Icon(
                                      Icons.pets,
                                      size: 38,
                                      color: Color(0xff24394a),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pet['name']?.toString() ?? 'Pet',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff24394a),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_titleCase(pet['type'])}${_breedSuffix(pet['breed'])}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (nextMealSummary.isNotEmpty)
                                    _pill(
                                      Icons.schedule,
                                      nextMealSummary,
                                    ),
                                  if (nextVaccineSummary.isNotEmpty)
                                    _pill(
                                      Icons.event_available_outlined,
                                      nextVaccineSummary,
                                    ),
                                  if ((pet['gender'] ?? '').toString().isNotEmpty)
                                    _pill(
                                      Icons.pets_outlined,
                                      _titleCase(pet['gender']),
                                    ),
                                  if ((pet['age'] ?? '').toString().isNotEmpty)
                                    _pill(
                                      Icons.cake_outlined,
                                      '${pet['age']} years',
                                    ),
                                  if ((pet['weight'] ?? '').toString().isNotEmpty)
                                    _pill(
                                      Icons.monitor_weight_outlined,
                                      '${pet['weight']} kg',
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (mealTimes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: _cardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Meals today',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xff24394a),
                                ),
                              ),
                              Text(
                                '$completedMealsToday/${mealTimes.length} done',
                                style: const TextStyle(
                                  color: Color(0xff24394a),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: mealProgress,
                              minHeight: 8,
                              backgroundColor: const Color(0xffe6ebf2),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xff24394a),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _sectionTitle('Feeding Schedule'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: mealTimes.isEmpty
                        ? const Text(
                            'No meal reminders yet',
                            style: TextStyle(color: Colors.grey),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (completedMealsToday < mealTimes.length) ...[
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: isMarkingAllMeals
                                        ? null
                                        : () => markAllMealsDone(mealTimes),
                                    icon: const Icon(Icons.done_all),
                                    label: Text(
                                      isMarkingAllMeals
                                          ? 'Saving...'
                                          : 'Mark all meals done',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],
                              ...mealTimes.map((time) => _mealTile(time)),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  _sectionTitle('Vaccine Reminder'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: vaccineDate.isEmpty
                        ? const Text(
                            'No vaccine date set',
                            style: TextStyle(color: Colors.grey),
                          )
                        : _vaccineTile(vaccineDate),
                  ),
                  if ((pet['notes'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _sectionTitle('Notes'),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: _cardDecoration(),
                      child: Text(
                        pet['notes'].toString(),
                        style: const TextStyle(
                          color: Color(0xff24394a),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _sectionTitle('Recent Care Activity'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: logs.isEmpty
                        ? const Text(
                            'No care activity yet',
                            style: TextStyle(color: Colors.grey),
                          )
                        : Column(
                            children: logs
                                .map((log) => _logTile(Map<String, dynamic>.from(log)))
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _mealTile(String time) {
    final done = _mealDoneToday(time);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xfff7f9fc),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xff24394a).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.restaurant_outlined,
                color: Color(0xff24394a),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    time,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xff24394a),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    done ? 'Done today' : 'Waiting for this meal',
                    style: TextStyle(
                      color: done ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: done
                    ? const Color(0xffdcefe3)
                    : const Color(0xff24394a),
                foregroundColor: done
                    ? const Color(0xff1f7a3d)
                    : Colors.white,
                elevation: 0,
              ),
              onPressed: done || isMarkingMeal ? null : () => markMealDone(time),
              child: Text(done ? 'Done' : 'Mark as done'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vaccineTile(String vaccineDate) {
    final done = _vaccineDoneForDate(vaccineDate);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfff7f9fc),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.vaccines_outlined,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vaccineDate,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xff24394a),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  done ? 'Logged as completed' : 'Upcoming vaccine reminder',
                  style: TextStyle(
                    color: done ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: done
                  ? const Color(0xffdcefe3)
                  : const Color(0xff24394a),
              foregroundColor: done
                  ? const Color(0xff1f7a3d)
                  : Colors.white,
              elevation: 0,
            ),
            onPressed: done || isMarkingVaccine ? null : markVaccineDone,
            child: Text(done ? 'Done' : 'Mark as done'),
          ),
        ],
      ),
    );
  }

  Widget _logTile(Map<String, dynamic> log) {
    final kind = log['kind']?.toString() ?? '';
    final doneAt = _formatLogDate(log['doneAt']?.toString() ?? '');
    final label = log['label']?.toString() ?? '';
    final isMeal = kind == 'meal';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: isMeal
                ? const Color(0xff24394a).withOpacity(0.08)
                : Colors.green.withOpacity(0.10),
            child: Icon(
              isMeal ? Icons.restaurant_outlined : Icons.vaccines_outlined,
              size: 18,
              color: isMeal ? const Color(0xff24394a) : Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMeal ? 'Meal completed' : 'Vaccine completed',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xff24394a),
                  ),
                ),
                if (label.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  doneAt,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _mealDoneToday(String label) {
    final today = DateTime.now();
    for (final item in logs) {
      final log = Map<String, dynamic>.from(item);
      if (log['kind']?.toString() != 'meal') continue;
      if ((log['label']?.toString() ?? '') != label) continue;
      final doneAt = DateTime.tryParse(log['doneAt']?.toString() ?? '');
      if (doneAt == null) continue;
      if (doneAt.year == today.year &&
          doneAt.month == today.month &&
          doneAt.day == today.day) {
        return true;
      }
    }
    return false;
  }

  int _completedMealsCountToday(List<String> mealTimes) {
    var count = 0;
    for (final time in mealTimes) {
      if (_mealDoneToday(time)) {
        count++;
      }
    }
    return count;
  }

  bool _vaccineDoneForDate(String label) {
    for (final item in logs) {
      final log = Map<String, dynamic>.from(item);
      if (log['kind']?.toString() != 'vaccine') continue;
      if ((log['label']?.toString() ?? '') == label) return true;
    }
    return false;
  }

  Future<String?> _pickNextVaccineDate() async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Next Vaccine'),
        content: const Text(
          'Pick the next vaccine date, or skip if there is no date yet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, ''),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff24394a),
            ),
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: dialogContext,
                initialDate: now.add(const Duration(days: 30)),
                firstDate: now,
                lastDate: now.add(const Duration(days: 3650)),
              );

              if (!dialogContext.mounted || picked == null) return;

              final month = picked.month.toString().padLeft(2, '0');
              final day = picked.day.toString().padLeft(2, '0');
              Navigator.pop(
                dialogContext,
                '${picked.year}-$month-$day',
              );
            },
            child: const Text(
              'Pick Date',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    return result;
  }

  List<String> _extractFoodTimes(Map pet) {
    final raw = pet['foodReminderTimes'];
    if (raw is List) {
      return raw.map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
    }
    return [];
  }

  String _buildNextMealSummary(List<String> mealTimes) {
    if (mealTimes.isEmpty) return '';

    final now = DateTime.now();
    DateTime? nextMeal;
    String? nextLabel;

    for (final time in mealTimes) {
      final parsed = _parseTime(time);
      if (parsed == null) continue;

      var candidate = DateTime(
        now.year,
        now.month,
        now.day,
        parsed.hour,
        parsed.minute,
      );

      if (candidate.isBefore(now)) {
        candidate = candidate.add(const Duration(days: 1));
      }

      if (nextMeal == null || candidate.isBefore(nextMeal)) {
        nextMeal = candidate;
        nextLabel = time;
      }
    }

    if (nextMeal == null || nextLabel == null) return '';

    final isTomorrow = nextMeal.day != now.day ||
        nextMeal.month != now.month ||
        nextMeal.year != now.year;

    return isTomorrow ? 'Next meal tomorrow at $nextLabel' : 'Next meal $nextLabel';
  }

  String _buildNextVaccineSummary(String vaccineDate) {
    if (vaccineDate.isEmpty) return '';

    final parsed = DateTime.tryParse(vaccineDate);
    if (parsed == null) return 'Next vaccine $vaccineDate';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(parsed.year, parsed.month, parsed.day);
    final difference = target.difference(today).inDays;

    if (difference < 0) {
      return 'Vaccine overdue';
    }
    if (difference == 0) {
      return 'Vaccine today';
    }
    if (difference == 1) {
      return 'Vaccine tomorrow';
    }
    return 'Vaccine in $difference days';
  }

  TimeOfDay? _parseTime(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;

    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*([AP]M)$', caseSensitive: false)
        .firstMatch(text);

    if (match != null) {
      var hour = int.tryParse(match.group(1)!);
      final minute = int.tryParse(match.group(2)!);
      final suffix = match.group(3)!.toUpperCase();

      if (hour == null || minute == null) return null;
      if (suffix == 'PM' && hour != 12) hour += 12;
      if (suffix == 'AM' && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    }

    final parts = text.split(':');
    if (parts.length != 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatLogDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return value;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.year}-$month-$day $hour:$minute $suffix';
  }

  String _titleCase(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return 'Pet';
    return text[0].toUpperCase() + text.substring(1);
  }

  String _breedSuffix(dynamic value) {
    final breed = value?.toString() ?? '';
    return breed.isEmpty ? '' : ' - $breed';
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xffeef2f7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xff24394a)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xff24394a),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: Color(0xff24394a),
      ),
    );
  }
}
