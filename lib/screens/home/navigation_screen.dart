import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../features/live_walk/screens/live_walk_screen.dart';
  const NavigationScreen({
    super.key,
    required this.time,
    required this.dogName,
    required this.location,
    required this.duration,
    this.bookingId,
  });

  final String time;
  final String dogName;
  final String location;
  final String duration;
  final String? bookingId;

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  bool _arrived = false;
  bool _dogReceived = false;
  bool _updatingBooking = false;

  Future<bool> _updateBookingStatus(String status) async {
    final bookingId = widget.bookingId;

    if (bookingId == null || bookingId.isEmpty) {
      return true;
    }

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Booking update failed. Please try again.',
          ),
        ),
      );

      return false;
    }
  }

  Future<void> _markArrived() async {
    if (_updatingBooking || _arrived) return;

    setState(() {
      _updatingBooking = true;
    });

    final success = await _updateBookingStatus('accepted');

    if (!mounted) return;

    if (success) {
      setState(() {
        _arrived = true;
        _updatingBooking = false;
      });
    } else {
      setState(() {
        _updatingBooking = false;
      });
    }
  }

  Future<void> _markDogReceived() async {
    if (_updatingBooking || !_arrived || _dogReceived) return;

    setState(() {
      _updatingBooking = true;
    });

    final success = await _updateBookingStatus('picked_up');

    if (!mounted) return;

    if (success) {
      setState(() {
        _dogReceived = true;
        _updatingBooking = false;
      });
    } else {
      setState(() {
        _updatingBooking = false;
      });
    }
  }

  Future<void> _startWalk() async {
    if (!_arrived || !_dogReceived || _updatingBooking) {
      return;
    }

    setState(() {
      _updatingBooking = true;
    });

    final success = await _updateBookingStatus('walking');

    if (!mounted) return;

    if (!success) {
      setState(() {
        _updatingBooking = false;
      });
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LiveWalkScreen(
          time: widget.time,
          dogName: widget.dogName,
          location: widget.location,
          duration: widget.duration,
          bookingId: widget.bookingId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool readyToStart = _arrived && _dogReceived;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Navigate to Pickup',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Stack(
        children: [
          // MAP AREA
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFFE9E9E9),
            child: const Center(
              child: Icon(
                Icons.map_outlined,
                size: 100,
                color: Color(0xFFAAAAAA),
              ),
            ),
          ),

          // PICKUP INFO
          Positioned(
            top: 20,
            left: 20,
            right: 20,
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
                  const CircleAvatar(
                    backgroundColor: Color(0xFFFFF1E8),
                    child: Icon(
                      Icons.pets,
                      color: DojoPartnerTheme.primaryOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.dogName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pickup • ${widget.location}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color:
                                DojoPartnerTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.time,
                          style: const TextStyle(
                            color:
                                DojoPartnerTheme.primaryOrange,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // BOTTOM ACTION PANEL
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFEAEAEA),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          readyToStart
                              ? Icons.check_circle
                              : _arrived
                                  ? Icons.pets
                                  : Icons.navigation_outlined,
                          color: readyToStart
                              ? Colors.green
                              : DojoPartnerTheme.primaryOrange,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            !_arrived
                                ? 'Navigate to the pickup location and mark your arrival.'
                                : !_dogReceived
                                    ? 'Pickup location reached. Confirm that you received the dog.'
                                    : '${widget.dogName} received. Slide to start the walk.',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ARRIVED BUTTON
                    if (!_arrived)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _updatingBooking
                              ? null
                              : _markArrived,
                          child: _updatingBooking
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Arrived at Pickup',
                                ),
                        ),
                      )

                    // DOG RECEIVED BUTTON
                    else if (!_dogReceived)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _updatingBooking
                              ? null
                              : _markDogReceived,
                          icon: _updatingBooking
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.pets),
                          label: Text(
                            _updatingBooking
                                ? 'Updating...'
                                : 'Dog Received',
                          ),
                        ),
                      )

                    // SLIDE TO START
                    else
                      _SlideToStart(
                        enabled: !_updatingBooking,
                        onCompleted: _startWalk,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideToStart extends StatefulWidget {
  const _SlideToStart({
    required this.enabled,
    required this.onCompleted,
  });

  final bool enabled;
  final VoidCallback onCompleted;

  @override
  State<_SlideToStart> createState() => _SlideToStartState();
}

class _SlideToStartState extends State<_SlideToStart> {
  double _value = 0;

  bool _completed = false;

  void _updateValue(double value) {
    if (!widget.enabled || _completed) return;

    final safeValue = value.clamp(0.0, 1.0);

    setState(() {
      _value = safeValue;
    });

    if (safeValue >= 0.92) {
      _completed = true;

      setState(() {
        _value = 1.0;
      });

      widget.onCompleted();
    }
  }

  void _resetSlider() {
    if (!widget.enabled || _completed) return;

    setState(() {
      _value = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double height = 60;
        const double thumbSize = 52;

        final double availableWidth =
            constraints.maxWidth - thumbSize;

        final double thumbLeft =
            availableWidth * _value;

        return GestureDetector(
          onHorizontalDragUpdate: widget.enabled
              ? (details) {
                  final double nextValue =
                      _value +
                          details.delta.dx /
                              availableWidth;

                  _updateValue(nextValue);
                }
              : null,
          onHorizontalDragEnd: widget.enabled
              ? (_) {
                  if (_value < 0.92) {
                    _resetSlider();
                  }
                }
              : null,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1E8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFFD8BF),
              ),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // ORANGE PROGRESS
                AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  width: thumbLeft + thumbSize,
                  height: height,
                  decoration: BoxDecoration(
                    color: DojoPartnerTheme.primaryOrange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                // CENTER TEXT
                Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 100),
                    opacity: _value > 0.35 ? 0.0 : 1.0,
                    child: const Text(
                      'Slide to Start Walk',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color:
                            DojoPartnerTheme.primaryOrange,
                      ),
                    ),
                  ),
                ),

                // ARROW TEXT
                Positioned(
                  right: 18,
                  child: AnimatedOpacity(
                    duration:
                        const Duration(milliseconds: 100),
                    opacity: _value > 0.35 ? 0.0 : 1.0,
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color:
                          DojoPartnerTheme.primaryOrange,
                    ),
                  ),
                ),

                // SLIDER THUMB
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 60),
                  left: thumbLeft,
                  top: 4,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            DojoPartnerTheme.primaryOrange,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      _completed
                          ? Icons.check
                          : Icons.arrow_forward_rounded,
                      color:
                          DojoPartnerTheme.primaryOrange,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
