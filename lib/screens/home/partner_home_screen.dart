import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme.dart';
import 'earnings_screen.dart';
import 'profile_screen.dart';
import 'review_bottom_sheet.dart';
import 'schedule_screen.dart';
import 'walk_details_screen.dart';
import 'working_schedule_screen.dart';

class PartnerHomeScreen extends StatefulWidget {
  const PartnerHomeScreen({super.key});

  @override
  State<PartnerHomeScreen> createState() => _PartnerHomeScreenState();
}

class _PartnerHomeScreenState extends State<PartnerHomeScreen> {
  bool _isLoading = true;
  bool _scheduleSet = false;

  bool _showReviewPrompt = false;
  String? _reviewDogName;
  String? _reviewWalkId;

  String _fullName = 'Partner';
  String _partnerId = 'DOJO-W-00124';

  List<Map<String, dynamic>> _todayBookings = [];

  @override
  void initState() {
    super.initState();
    _loadPartnerData();
  }

  Future<void> _loadPartnerData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final walkerDoc = await FirebaseFirestore.instance
          .collection('walkers')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (walkerDoc.exists) {
        final data = walkerDoc.data() ?? <String, dynamic>{};

        final schedule = data['workingSchedule'];
        final fullName = data['fullName'];
        final walkerId = data['walkerId'];

        setState(() {
          _fullName = fullName is String && fullName.trim().isNotEmpty
              ? fullName.trim()
              : 'Partner';

          _partnerId = walkerId is String && walkerId.trim().isNotEmpty
              ? walkerId.trim()
              : 'DOJO-W-00124';

          _scheduleSet = schedule is Map &&
              schedule['status'] != null &&
              schedule['status'].toString().trim().isNotEmpty;
        });
      }

      await Future.wait([
        _loadTodayBookings(user.uid),
        _loadLatestCompletedWalk(user.uid),
      ]);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTodayBookings(String uid) async {
    try {
      final now = DateTime.now();

      final startOfDay = DateTime(
        now.year,
        now.month,
        now.day,
      );

      final endOfDay = startOfDay.add(
        const Duration(days: 1),
      );

      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('walkerId', isEqualTo: uid)
          .get();

      final bookings = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (!_isTodayBooking(
          data['date'],
          startOfDay,
          endOfDay,
        )) {
          continue;
        }

        if (!_isActiveBookingStatus(data['status'])) {
          continue;
        }

        bookings.add({
          ...data,
          'bookingId': doc.id,
        });
      }

      bookings.sort(
        (a, b) => _bookingMinutes(a).compareTo(
          _bookingMinutes(b),
        ),
      );

      if (!mounted) return;

      setState(() {
        _todayBookings = bookings;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _todayBookings = [];
        _isLoading = false;
      });
    }
  }

  bool _isTodayBooking(
    dynamic value,
    DateTime startOfDay,
    DateTime endOfDay,
  ) {
    if (value is Timestamp) {
      final date = value.toDate();

      return !date.isBefore(startOfDay) &&
          date.isBefore(endOfDay);
    }

    if (value is DateTime) {
      return !value.isBefore(startOfDay) &&
          value.isBefore(endOfDay);
    }

    if (value is String) {
      final parsed = DateTime.tryParse(value);

      if (parsed != null) {
        return !parsed.isBefore(startOfDay) &&
            parsed.isBefore(endOfDay);
      }

      final normalized = value.trim();

      final todayIso =
          '${startOfDay.year.toString().padLeft(4, '0')}-'
          '${startOfDay.month.toString().padLeft(2, '0')}-'
          '${startOfDay.day.toString().padLeft(2, '0')}';

      return normalized == todayIso;
    }

    return false;
  }

  bool _isActiveBookingStatus(dynamic status) {
    if (status is! String) {
      return false;
    }

    return <String>{
      'assigned',
      'accepted',
      'picked_up',
      'walking',
    }.contains(status);
  }

  int _bookingMinutes(Map<String, dynamic> booking) {
    final value = booking['startTime'];

    if (value is Timestamp) {
      final date = value.toDate();
      return date.hour * 60 + date.minute;
    }

    if (value is DateTime) {
      return value.hour * 60 + value.minute;
    }

    if (value is String) {
      final parsed = _parseTime(value);

      if (parsed != null) {
        return parsed.hour * 60 + parsed.minute;
      }
    }

    return 9999;
  }

  DateTime? _parseTime(String value) {
    final cleaned = value.trim();

    final match = RegExp(
      r'^(\d{1,2}):(\d{2})(?:\s*([AaPp][Mm]))?$',
    ).firstMatch(cleaned);

    if (match == null) return null;

    var hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);

    if (hour == null || minute == null) return null;

    final meridiem = match.group(3)?.toUpperCase();

    if (meridiem == 'AM') {
      if (hour == 12) hour = 0;
    } else if (meridiem == 'PM') {
      if (hour != 12) hour += 12;
    }

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    return DateTime(2000, 1, 1, hour, minute);
  }

  String _formatBookingTime(Map<String, dynamic> booking) {
    final value = booking['startTime'];

    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = _parseTime(value);
    }

    if (date == null) return 'Time not set';

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  String _bookingDogName(Map<String, dynamic> booking) {
    final value = booking['dogName'];

    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    final dog = booking['dog'];

    if (dog is Map) {
      final name = dog['name'];

      if (name is String && name.trim().isNotEmpty) {
        return name.trim();
      }
    }

    return 'Dog';
  }

  String _bookingType(Map<String, dynamic> booking) {
    final value = booking['type'];

    if (value is String && value.trim().isNotEmpty) {
      final type = value.trim();

      if (type.toLowerCase() == 'regular') {
        return 'Regular Walk';
      }

      if (type.toLowerCase() == 'one_time' ||
          type.toLowerCase() == 'one-time') {
        return 'One-Time Walk';
      }

      return type;
    }

    return 'Walk';
  }

  String _bookingDuration(Map<String, dynamic> booking) {
    final value = booking['duration'];

    if (value is num) {
      return '${value.toInt()} min';
    }

    if (value is String && value.trim().isNotEmpty) {
      final text = value.trim();

      if (text.toLowerCase().contains('min')) {
        return text;
      }

      return '$text min';
    }

    return 'Duration not set';
  }

  int _durationMinutes(Map<String, dynamic> booking) {
    final value = booking['duration'];

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      final match = RegExp(r'\d+').firstMatch(value);

      if (match != null) {
        return int.tryParse(match.group(0)!) ?? 0;
      }
    }

    return 0;
  }

  String _bookingLocation(Map<String, dynamic> booking) {
    final value = booking['pickupAddress'];

    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }

    final location = booking['location'];

    if (location is String && location.trim().isNotEmpty) {
      return location.trim();
    }

    final zoneName = booking['zoneName'];

    if (zoneName is String && zoneName.trim().isNotEmpty) {
      return zoneName.trim();
    }

    return 'Pickup location not set';
  }

  Future<void> _loadLatestCompletedWalk(String uid) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('walks')
          .where('walkerId', isEqualTo: uid)
          .limit(50)
          .get();

      String? latestDogName;
      String? latestWalkId;
      DateTime? latestCreatedAt;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (data['status'] != 'completed') continue;

        final reviewStatus = data['reviewStatus'];

        if (reviewStatus == 'submitted' || reviewStatus == 'skipped') {
          continue;
        }

        final dogName = data['dogName'];

        if (dogName is! String || dogName.trim().isEmpty) {
          continue;
        }

        DateTime? createdAt;
        final createdValue = data['createdAt'];

        if (createdValue is Timestamp) {
          createdAt = createdValue.toDate();
        } else if (data['endedAt'] is Timestamp) {
          createdAt = (data['endedAt'] as Timestamp).toDate();
        } else if (data['startedAt'] is Timestamp) {
          createdAt = (data['startedAt'] as Timestamp).toDate();
        }

        if (latestCreatedAt == null ||
            (createdAt != null && createdAt.isAfter(latestCreatedAt))) {
          latestCreatedAt = createdAt;
          latestDogName = dogName.trim();
          latestWalkId = doc.id;
        }
      }

      if (!mounted) return;

      if (latestDogName != null && latestWalkId != null) {
        setState(() {
          _reviewDogName = latestDogName;
          _reviewWalkId = latestWalkId;
          _showReviewPrompt = true;
        });
      }
    } catch (_) {
      // Review prompt is optional.
    }
  }

  void _openWalkDetails(
    BuildContext context, {
    required Map<String, dynamic> booking,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WalkDetailsScreen(
          time: _formatBookingTime(booking),
          dogName: _bookingDogName(booking),
          type: _bookingType(booking),
          duration: _bookingDuration(booking),
          location: _bookingLocation(booking),
          bookingId: booking['bookingId']?.toString(),
        ),
      ),
    );
  }

  void _openTab(BuildContext context, int index) {
    switch (index) {
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ScheduleScreen(),
          ),
        );
        break;

      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const EarningsScreen(),
          ),
        );
        break;

      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ProfileScreen(),
          ),
        );
        break;
    }
  }

  Future<void> _openWorkingSchedule() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const WorkingScheduleScreen(),
      ),
    );

    if (!mounted) return;

    await _loadPartnerData();
  }

  Future<void> _showReviewSheet() async {
    final dogName = _reviewDogName;
    final walkId = _reviewWalkId;

    if (dogName == null ||
        dogName.isEmpty ||
        walkId == null ||
        walkId.isEmpty) {
      return;
    }

    final result = await showModalBottomSheet<ReviewResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReviewBottomSheet(dogName: dogName),
    );

    if (!mounted || result == null) return;

    try {
      final reviewData = <String, dynamic>{
        'reviewStatus': result.submitted ? 'submitted' : 'skipped',
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (result.submitted) {
        reviewData['reviewRating'] = result.rating;
        reviewData['reviewNote'] = result.note;
      }

      await FirebaseFirestore.instance
          .collection('walks')
          .doc(walkId)
          .update(reviewData);
    } catch (_) {
      // Keep the prompt hidden locally even if the write fails.
    }

    if (!mounted) return;

    setState(() {
      _showReviewPrompt = false;
    });

    if (result.submitted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanks for your feedback!'),
        ),
      );
    }
  }

  Future<void> _skipReview() async {
    final walkId = _reviewWalkId;

    if (walkId == null || walkId.isEmpty) {
      if (mounted) {
        setState(() {
          _showReviewPrompt = false;
        });
      }
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('walks')
          .doc(walkId)
          .update({
        'reviewStatus': 'skipped',
        'reviewedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Hide locally even if Firestore write fails.
    }

    if (!mounted) return;

    setState(() {
      _showReviewPrompt = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final firstName = _fullName.trim().isEmpty
        ? 'Partner'
        : _fullName.trim().split(' ').first;

    final totalWalks = _todayBookings.length;

    final totalMinutes = _todayBookings.fold<int>(
      0,
      (total, booking) => total + _durationMinutes(booking),
    );

    final totalHours = totalMinutes / 60;

    final hoursText = totalMinutes == 0
        ? '0 hrs'
        : totalMinutes % 60 == 0
            ? '${totalMinutes ~/ 60} hrs'
            : '${totalHours.toStringAsFixed(1)} hrs';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'DOJO Partner',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: DojoPartnerTheme.primaryOrange,
                ),
              )
            : RefreshIndicator(
                color: DojoPartnerTheme.primaryOrange,
                onRefresh: _loadPartnerData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Text(
                      'Good morning, $firstName 👋',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: DojoPartnerTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Here's your work for today.",
                      style: TextStyle(
                        color: DojoPartnerTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 22),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFEAEAEA),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: DojoPartnerTheme.primaryOrange
                                  .withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              firstName.isNotEmpty
                                  ? firstName[0].toUpperCase()
                                  : 'P',
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: DojoPartnerTheme.primaryOrange,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fullName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.verified_rounded,
                                      size: 16,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Verified Partner',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Partner ID  •  $_partnerId',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: DojoPartnerTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_showReviewPrompt && _reviewDogName != null) ...[
                      const SizedBox(height: 16),
                      _ReviewPromptCard(
                        dogName: _reviewDogName!,
                        onRate: _showReviewSheet,
                        onSkip: _skipReview,
                      ),
                    ],

                    if (!_scheduleSet) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'COMPLETE YOUR SETUP',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: DojoPartnerTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SetupCard(
                        icon: Icons.calendar_month_outlined,
                        title: 'Set Working Schedule',
                        description:
                            'Set your working days and regular walk timings.',
                        buttonText: 'Set Schedule',
                        onTap: _openWorkingSchedule,
                      ),
                    ],

                    const SizedBox(height: 24),

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
                          Icon(Icons.circle, size: 11, color: Colors.green),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Working',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            'Today',
                            style: TextStyle(
                              color: DojoPartnerTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      "TODAY'S OVERVIEW",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: DojoPartnerTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _OverviewCard(
                            icon: Icons.directions_walk_outlined,
                            title: 'Walks',
                            value: '$totalWalks',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _OverviewCard(
                            icon: Icons.timer_outlined,
                            title: 'Hours',
                            value: hoursText,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      "TODAY'S WORK",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: DojoPartnerTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_todayBookings.isEmpty)
                      const _EmptyWorkCard()
                    else
                      ..._todayBookings.map(
                        (booking) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _WalkCard(
                            time: _formatBookingTime(booking),
                            dogName: _bookingDogName(booking),
                            type: _bookingType(booking),
                            duration: _bookingDuration(booking),
                            location: _bookingLocation(booking),
                            onTap: () {
                              _openWalkDetails(
                                context,
                                booking: booking,
                              );
                            },
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFEAEAEA),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: DojoPartnerTheme.primaryOrange
                                      .withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.support_agent_outlined,
                                  color: DojoPartnerTheme.primaryOrange,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Need a day off?',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Submit a leave request to DOJO.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: DojoPartnerTheme.textSecondary,
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
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) => _openTab(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Earnings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _EmptyWorkCard extends StatelessWidget {
  const _EmptyWorkCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.pets_outlined,
            size: 34,
            color: DojoPartnerTheme.textSecondary,
          ),
          SizedBox(height: 10),
          Text(
            'No walks assigned for today.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Enjoy your day! 🐾',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: DojoPartnerTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewPromptCard extends StatelessWidget {
  const _ReviewPromptCard({
    required this.dogName,
    required this.onRate,
    required this.onSkip,
  });

  final String dogName;
  final VoidCallback onRate;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE1C7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: DojoPartnerTheme.primaryOrange
                      .withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: DojoPartnerTheme.primaryOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'How was the walk with $dogName?',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: DojoPartnerTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Your feedback helps DOJO improve.',
            style: TextStyle(
              fontSize: 13,
              color: DojoPartnerTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: onRate,
                    icon: const Icon(Icons.star_rounded, size: 18),
                    label: const Text('Rate Walk'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 42,
                child: TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: DojoPartnerTheme.textSecondary,
                  ),
                  child: const Text('Skip'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE1C7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: DojoPartnerTheme.primaryOrange
                  .withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: DojoPartnerTheme.primaryOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: DojoPartnerTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: DojoPartnerTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DojoPartnerTheme.primaryOrange,
                      side: const BorderSide(
                        color: DojoPartnerTheme.primaryOrange,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(buttonText),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Row(
        children: [
          Icon(icon, color: DojoPartnerTheme.primaryOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: DojoPartnerTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WalkCard extends StatelessWidget {
  const _WalkCard({
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEAEAEA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: DojoPartnerTheme.primaryOrange,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    child: Icon(Icons.pets),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dogName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$type • $duration',
                          style: const TextStyle(
                            color: DojoPartnerTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          location,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DojoPartnerTheme.textSecondary,
                            fontSize: 13,
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
            ],
          ),
        ),
      ),
    );
  }
}
