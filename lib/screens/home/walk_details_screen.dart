import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../theme.dart';
import 'navigation_screen.dart';

class WalkDetailsScreen extends StatefulWidget {
  const WalkDetailsScreen({
    super.key,
    required this.time,
    required this.dogName,
    required this.type,
    required this.duration,
    required this.location,
    this.bookingId,
  });

  final String time;
  final String dogName;
  final String type;
  final String duration;
  final String location;
  final String? bookingId;

  @override
  State<WalkDetailsScreen> createState() =>
      _WalkDetailsScreenState();
}

class _WalkDetailsScreenState
    extends State<WalkDetailsScreen> {
  bool _isLoading = false;

  String _customerName = 'Customer';
  String _dogBreed = 'Dog';
  String _dogSize = '';
  String _pickupAddress = '';

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    final bookingId = widget.bookingId;

    if (bookingId == null || bookingId.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final data =
            doc.data() ?? <String, dynamic>{};

        final customer = data['customer'];
        final dog = data['dog'];

        String customerName = 'Customer';
        String dogBreed = 'Dog';
        String dogSize = '';

        if (customer is Map) {
          final name = customer['name'];

          if (name is String &&
              name.trim().isNotEmpty) {
            customerName = name.trim();
          }
        }

        if (dog is Map) {
          final breed = dog['breed'];
          final size = dog['size'];

          if (breed is String &&
              breed.trim().isNotEmpty) {
            dogBreed = breed.trim();
          }

          if (size is String &&
              size.trim().isNotEmpty) {
            dogSize = size.trim();
          }
        }

        final directCustomerName =
            data['customerName'];

        final directDogBreed =
            data['dogBreed'];

        final directDogSize =
            data['dogSize'];

        final pickupAddress =
            data['pickupAddress'];

        if (directCustomerName is String &&
            directCustomerName
                .trim()
                .isNotEmpty) {
          customerName =
              directCustomerName.trim();
        }

        if (directDogBreed is String &&
            directDogBreed.trim().isNotEmpty) {
          dogBreed = directDogBreed.trim();
        }

        if (directDogSize is String &&
            directDogSize.trim().isNotEmpty) {
          dogSize = directDogSize.trim();
        }

        setState(() {
          _customerName = customerName;
          _dogBreed = dogBreed;
          _dogSize = dogSize;

          if (pickupAddress is String &&
              pickupAddress.trim().isNotEmpty) {
            _pickupAddress =
                pickupAddress.trim();
          }
        });
      }
    } catch (_) {
      // Keep the screen usable with the data
      // already passed from Home/Schedule.
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToPickup() async {
    final bookingId = widget.bookingId;

    if (bookingId != null &&
        bookingId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .update({
          'status': 'accepted',
          'updatedAt':
              FieldValue.serverTimestamp(),
        });
      } catch (_) {
        // Navigation should still work.
      }
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NavigationScreen(
          time: widget.time,
          dogName: widget.dogName,
          location: _pickupAddress.isNotEmpty
              ? _pickupAddress
              : widget.location,
          duration: widget.duration,
          bookingId: widget.bookingId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Walk Details',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            24,
          ),
          children: [
            // DOG HEADER
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(18),
                border: Border.all(
                  color: DojoPartnerTheme.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: DojoPartnerTheme
                          .primaryOrange
                          .withValues(
                        alpha: 0.10,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pets,
                      color: DojoPartnerTheme
                          .primaryOrange,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.dogName,
                          style:
                              const TextStyle(
                            fontSize: 21,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          widget.type,
                          style:
                              const TextStyle(
                            color:
                                DojoPartnerTheme
                                    .textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'WALK INFORMATION',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color:
                    DojoPartnerTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            _InfoCard(
              icon: Icons.access_time_rounded,
              title: 'Scheduled Time',
              value: widget.time,
            ),
            const SizedBox(height: 10),
            _InfoCard(
              icon: Icons.timer_outlined,
              title: 'Duration',
              value: widget.duration,
            ),
            const SizedBox(height: 10),
            _InfoCard(
              icon: Icons.location_on_outlined,
              title: 'Pickup Location',
              value: _pickupAddress.isNotEmpty
                  ? _pickupAddress
                  : widget.location,
            ),

            const SizedBox(height: 24),

            const Text(
              'CUSTOMER & DOG',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color:
                    DojoPartnerTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(16),
                border: Border.all(
                  color: DojoPartnerTheme.border,
                ),
              ),
              child: Column(
                children: [
                  _DetailRow(
                    icon:
                        Icons.person_outline_rounded,
                    label: 'Customer',
                    value: _customerName,
                  ),
                  const Divider(height: 24),
                  _DetailRow(
                    icon: Icons.pets_outlined,
                    label: 'Breed',
                    value: _dogBreed,
                  ),
                  if (_dogSize.isNotEmpty) ...[
                    const Divider(height: 24),
                    _DetailRow(
                      icon:
                          Icons.straighten_outlined,
                      label: 'Size',
                      value: _dogSize,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: DojoPartnerTheme.primaryOrange
                    .withValues(alpha: 0.06),
                borderRadius:
                    BorderRadius.circular(14),
                border: Border.all(
                  color: DojoPartnerTheme.border,
                ),
              ),
              child: const Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color:
                        DojoPartnerTheme
                            .primaryOrange,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Please arrive at the pickup location on time and confirm the dog is safely received before starting the walk.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color:
                            DojoPartnerTheme
                                .textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            ElevatedButton.icon(
              onPressed:
                  _isLoading ? null : _navigateToPickup,
              icon: const Icon(
                Icons.navigation_rounded,
              ),
              label: const Text(
                'Navigate to Pickup',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: DojoPartnerTheme.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color:
                DojoPartnerTheme.primaryOrange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        DojoPartnerTheme
                            .textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w700,
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 21,
          color:
              DojoPartnerTheme.primaryOrange,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style:
                const TextStyle(
              fontSize: 13,
              color:
                  DojoPartnerTheme
                      .textSecondary,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style:
                const TextStyle(
              fontSize: 14,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

