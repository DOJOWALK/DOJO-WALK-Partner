import 'package:flutter/material.dart';

import '../../theme.dart';
import 'walk_details_screen.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  void _openWalkDetails(
    BuildContext context, {
    required String time,
    required String dogName,
    required String type,
    required String duration,
    required String location,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WalkDetailsScreen(
          time: time,
          dogName: dogName,
          type: type,
          duration: duration,
          location: location,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Schedule',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const Text(
              'Today',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: DojoPartnerTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Thursday, 8 October',
              style: TextStyle(
                fontSize: 14,
                color: DojoPartnerTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4EC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: DojoPartnerTheme.primaryOrange.withValues(
                    alpha: 0.25,
                  ),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: DojoPartnerTheme.primaryOrange,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sample schedule — these are preview walks, not live assignments.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: DojoPartnerTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFEAEAEA),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    color: DojoPartnerTheme.primaryOrange,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '2 walks scheduled today',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            const Text(
              'TODAY\'S WALKS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: DojoPartnerTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 12),

            _ScheduleWalkCard(
              time: '07:00 AM',
              dogName: 'Bruno',
              type: 'Regular',
              duration: '60 min',
              location: 'Civil Lines',
              onTap: () {
                _openWalkDetails(
                  context,
                  time: '07:00 AM',
                  dogName: 'Bruno',
                  type: 'Regular Walk',
                  duration: '60 min',
                  location: 'Civil Lines',
                );
              },
            ),

            const SizedBox(height: 12),

            _ScheduleWalkCard(
              time: '06:00 PM',
              dogName: 'Bruno',
              type: 'Regular',
              duration: '60 min',
              location: 'Civil Lines',
              onTap: () {
                _openWalkDetails(
                  context,
                  time: '06:00 PM',
                  dogName: 'Bruno',
                  type: 'Regular Walk',
                  duration: '60 min',
                  location: 'Civil Lines',
                );
              },
            ),

            const SizedBox(height: 26),

            const Text(
              'WEEK',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: DojoPartnerTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 12),

            _DayCard(
              day: 'MON',
              date: '5',
              status: '2 walks',
            ),
            _DayCard(
              day: 'TUE',
              date: '6',
              status: '2 walks',
            ),
            _DayCard(
              day: 'WED',
              date: '7',
              status: 'OFF',
            ),
            _DayCard(
              day: 'THU',
              date: '8',
              status: '2 walks',
              selected: true,
            ),
            _DayCard(
              day: 'FRI',
              date: '9',
              status: '2 walks',
            ),
            _DayCard(
              day: 'SAT',
              date: '10',
              status: '2 walks',
            ),
            _DayCard(
              day: 'SUN',
              date: '11',
              status: 'OFF',
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleWalkCard extends StatelessWidget {
  const _ScheduleWalkCard({
    required this.time,
    required this.dogName,
    required this.type,
    required this.duration,
    required this.location,
    required this.onTap,
  });

  final String time;
  final String dogName;
  final String type;
  final String duration;
  final String location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isRegular = type == 'Regular';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFEAEAEA),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 76,
                child: Text(
                  time,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: DojoPartnerTheme.primaryOrange,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const CircleAvatar(
                radius: 23,
                child: Icon(Icons.pets),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      dogName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isRegular
                                ? const Color(0xFFFFF1E8)
                                : const Color(0xFFEFF6FF),
                            borderRadius:
                                BorderRadius.circular(7),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isRegular
                                  ? DojoPartnerTheme
                                      .primaryOrange
                                  : Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          duration,
                          style: const TextStyle(
                            fontSize: 12,
                            color:
                                DojoPartnerTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      location,
                      style: const TextStyle(
                        fontSize: 12,
                        color:
                            DojoPartnerTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: DojoPartnerTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.date,
    required this.status,
    this.selected = false,
  });

  final String day;
  final String date;
  final String status;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final bool isOff = status == 'OFF';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xFFFFF4EC)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? DojoPartnerTheme.primaryOrange
              : const Color(0xFFEAEAEA),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              day,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: DojoPartnerTheme.textSecondary,
              ),
            ),
          ),
          Text(
            date,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Text(
            status,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isOff
                  ? DojoPartnerTheme.textSecondary
                  : DojoPartnerTheme.primaryOrange,
            ),
          ),
        ],
      ),
    );
  }
}
