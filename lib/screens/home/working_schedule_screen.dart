import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme.dart';

class WorkingScheduleScreen extends StatefulWidget {
  const WorkingScheduleScreen({super.key});

  @override
  State<WorkingScheduleScreen> createState() =>
      _WorkingScheduleScreenState();
}

class _WorkingScheduleScreenState
    extends State<WorkingScheduleScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final Map<String, bool> _enabledDays = {};
  final Map<String, TimeOfDay> _startTimes = {};
  final Map<String, TimeOfDay> _endTimes = {};

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    for (final day in _days) {
      _enabledDays[day] = false;
      _startTimes[day] = const TimeOfDay(
        hour: 7,
        minute: 0,
      );
      _endTimes[day] = const TimeOfDay(
        hour: 19,
        minute: 0,
      );
    }

    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    final user = _auth.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('walkers')
          .doc(user.uid)
          .get();

      final data = snapshot.data();
      final schedule = data?['workingSchedule'];

      if (schedule is Map) {
        final daysData = schedule['days'];

        if (daysData is Map) {
          for (final day in _days) {
            final dayData = daysData[day.toLowerCase()];

            if (dayData is Map) {
              final enabled = dayData['enabled'];

              if (enabled is bool) {
                _enabledDays[day] = enabled;
              }

              final start = _parseTime(dayData['start']);
              final end = _parseTime(dayData['end']);

              if (start != null) {
                _startTimes[day] = start;
              }

              if (end != null) {
                _endTimes[day] = end;
              }
            }
          }
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to load your working schedule.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  TimeOfDay? _parseTime(dynamic value) {
    if (value is! String) {
      return null;
    }

    final parts = value.split(' ');

    if (parts.length != 2) {
      return null;
    }

    final timeParts = parts[0].split(':');

    if (timeParts.length != 2) {
      return null;
    }

    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);

    if (hour == null || minute == null) {
      return null;
    }

    final period = parts[1].toUpperCase();

    if (hour < 1 || hour > 12 || minute < 0 || minute > 59) {
      return null;
    }

    var convertedHour = hour % 12;

    if (period == 'PM') {
      convertedHour += 12;
    } else if (period != 'AM') {
      return null;
    }

    return TimeOfDay(
      hour: convertedHour,
      minute: minute,
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  int _minutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  Future<void> _selectTime(
    String day, {
    required bool isStart,
  }) async {
    final initialTime =
        isStart ? _startTimes[day]! : _endTimes[day]!;

    final selected = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: isStart
          ? 'Select start time'
          : 'Select end time',
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      if (isStart) {
        _startTimes[day] = selected;
      } else {
        _endTimes[day] = selected;
      }
    });
  }

  Future<void> _saveSchedule() async {
    // UI-only guard: shared Firestore Rules do not currently permit this client write.
    // Do not attempt the write or show a false successful-save message.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Schedule changes are temporarily unavailable while the approved save process is being connected.',
        ),
      ),
    );
    return;

    final user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please sign in again to continue.',
          ),
        ),
      );
      return;
    }

    final selectedDays =
        _days.where((day) => _enabledDays[day] == true).toList();

    if (selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select at least one working day.',
          ),
        ),
      );
      return;
    }

    for (final day in selectedDays) {
      final start = _startTimes[day]!;
      final end = _endTimes[day]!;

      if (_minutes(end) <= _minutes(start)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$day: end time must be after start time.',
            ),
          ),
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final Map<String, dynamic> daysData = {};

      for (final day in _days) {
        final enabled = _enabledDays[day] == true;

        daysData[day.toLowerCase()] = {
          'enabled': enabled,
          'start': _formatTime(_startTimes[day]!),
          'end': _formatTime(_endTimes[day]!),
        };
      }

      await _firestore
          .collection('walkers')
          .doc(user.uid)
          .set(
        {
          'workingSchedule': {
            'status': 'active',
            'days': daysData,
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Working schedule saved successfully.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to save your working schedule.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Working Schedule',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: DojoPartnerTheme.primaryOrange,
              ),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  32,
                ),
                children: [
                  const Text(
                    'Set your availability',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: DojoPartnerTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose the days and timings when you are available for regular walks.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: DojoPartnerTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DojoPartnerTheme.primaryOrange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: DojoPartnerTheme.primaryOrange.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: DojoPartnerTheme.primaryOrange,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your selected hours are currently a preview. Changes cannot be saved until the approved availability update process is connected.',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: DojoPartnerTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'WORKING DAYS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: DojoPartnerTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._days.map(
                    (day) => _DayScheduleCard(
                      day: day,
                      enabled: _enabledDays[day] == true,
                      startTime: _formatTime(_startTimes[day]!),
                      endTime: _formatTime(_endTimes[day]!),
                      onChanged: (value) {
                        setState(() {
                          _enabledDays[day] = value;
                        });
                      },
                      onStartTap: () {
                        _selectTime(
                          day,
                          isStart: true,
                        );
                      },
                      onEndTap: () {
                        _selectTime(
                          day,
                          isStart: false,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveSchedule,
                    child: _isSaving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Working Schedule'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _DayScheduleCard extends StatelessWidget {
  const _DayScheduleCard({
    required this.day,
    required this.enabled,
    required this.startTime,
    required this.endTime,
    required this.onChanged,
    required this.onStartTap,
    required this.onEndTap,
  });

  final String day;
  final bool enabled;
  final String startTime;
  final String endTime;
  final ValueChanged<bool> onChanged;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: enabled
              ? const Color(0xFFEAEAEA)
              : const Color(0xFFE5E5E5),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _SelectionIndicator(
                selected: enabled,
                onTap: () {
                  onChanged(!enabled);
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  day,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: enabled
                        ? DojoPartnerTheme.textPrimary
                        : DojoPartnerTheme.textSecondary,
                  ),
                ),
              ),
              Text(
                enabled ? 'WORKING' : 'OFF',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: enabled
                      ? DojoPartnerTheme.primaryOrange
                      : DojoPartnerTheme.textSecondary,
                ),
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _TimeButton(
                    label: 'START',
                    value: startTime,
                    onTap: onStartTap,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeButton(
                    label: 'END',
                    value: endTime,
                    onTap: onEndTap,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected
              ? DojoPartnerTheme.primaryOrange
              : Colors.transparent,
          border: Border.all(
            color: selected
                ? DojoPartnerTheme.primaryOrange
                : const Color(0xFFBDBDBD),
            width: 2,
          ),
        ),
        child: selected
            ? const Icon(
                Icons.check,
                size: 15,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DojoPartnerTheme.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                  color: DojoPartnerTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_outlined,
                    size: 17,
                    color: DojoPartnerTheme.primaryOrange,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: DojoPartnerTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
