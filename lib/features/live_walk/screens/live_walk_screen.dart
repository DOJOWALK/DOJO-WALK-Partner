import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as maps;

import '../../theme.dart';
import 'customer_otp_sheet.dart';
import 'walk_summary_screen.dart';

class LiveWalkScreen extends StatefulWidget {
  const LiveWalkScreen({
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
  State<LiveWalkScreen> createState() => _LiveWalkScreenState();
}

class _LiveWalkScreenState extends State<LiveWalkScreen> {
  Timer? _timer;
  StreamSubscription<Position>? _positionSubscription;

  // One stable document ID prevents duplicate walk documents on retry.
  late final String _walkDocumentId =
      FirebaseFirestore.instance.collection('walks').doc().id;

  int _seconds = 0;
  double _distanceMeters = 0;

  int _peeCount = 0;
  int _poopCount = 0;

  Position? _lastPosition;
  Position? _startPosition;
  DateTime? _startedAt;

  final List<Position> _route = [];

  bool _isStarting = true;
  bool _isEnding = false;
  bool _locationTracking = false;
  bool _showReturnPanel = false;
  bool _dogReturned = false;
  bool _returnLocationChecked = false;
  bool _sameReturnLocation = false;
  bool _returnLocationFailed = false;

  double? _customerLatitude;
  double? _customerLongitude;

  bool get _hasCustomerLocation =>
      _customerLatitude != null && _customerLongitude != null;

  @override
  void initState() {
    super.initState();
    _startWalk();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startWalk() async {
    try {
      final permission = await _checkLocationPermission();

      if (!permission) {
        if (!mounted) return;

        setState(() {
          _isStarting = false;
          _locationTracking = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission is required to start the walk.',
            ),
          ),
        );
        return;
      }

      await _loadCustomerLocation();

      if (!mounted) return;

      _startedAt ??= DateTime.now();

      setState(() {
        _isStarting = false;
        _locationTracking = true;
      });

      _startTimer();
      await _startLocationStream();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isStarting = false;
        _locationTracking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not start location tracking. Please try again.',
          ),
        ),
      );
    }
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted || _isEnding) return;

        setState(() {
          _seconds++;
        });
      },
    );
  }

  Future<void> _startLocationStream() async {
    await _positionSubscription?.cancel();

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen(
      _handlePosition,
      onError: (_) {
        if (!mounted) return;

        setState(() {
          _locationTracking = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'GPS updates stopped. Check your location settings.',
            ),
          ),
        );
      },
    );
  }

  void _handlePosition(Position position) {
    if (!mounted || _isEnding) return;

    // Ignore unreliable GPS readings.
    if (!position.latitude.isFinite ||
        !position.longitude.isFinite ||
        position.accuracy > 35 ||
        position.latitude < -90 ||
        position.latitude > 90 ||
        position.longitude < -180 ||
        position.longitude > 180) {
      return;
    }

    final previous = _lastPosition;

    if (previous == null) {
      _startPosition = position;
      _lastPosition = position;
      _route.add(position);

      setState(() {
        _locationTracking = true;
      });
      return;
    }

    final movement = Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      position.latitude,
      position.longitude,
    );

    // Reject large GPS jumps instead of inflating distance.
    if (!movement.isFinite || movement > 100) {
      return;
    }

    // Keep the route from filling with tiny GPS fluctuations.
    if (movement < 3) {
      setState(() {
        _locationTracking = true;
      });
      return;
    }

    _distanceMeters += movement;
    _lastPosition = position;
    _route.add(position);

    setState(() {
      _locationTracking = true;
    });
  }

  Future<void> _loadCustomerLocation() async {
    final bookingId = widget.bookingId;

    if (bookingId == null || bookingId.isEmpty) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();

      final data = snapshot.data();
      if (data == null) return;

      final latitude = _readDouble(data['latitude']);
      final longitude = _readDouble(data['longitude']);

      if (_validCoordinates(latitude, longitude)) {
        _customerLatitude = latitude;
        _customerLongitude = longitude;
        return;
      }

      final geoPoint = data['location'];

      if (geoPoint is GeoPoint &&
          _validCoordinates(
            geoPoint.latitude,
            geoPoint.longitude,
          )) {
        _customerLatitude = geoPoint.latitude;
        _customerLongitude = geoPoint.longitude;
      }
    } catch (_) {
      // Missing customer coordinates are handled during return verification.
    }
  }

  bool _validCoordinates(double? latitude, double? longitude) {
    return latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  double? _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  Future<bool> _checkLocationPermission() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) return false;

      final openSettings = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Location is off'),
            content: const Text(
              'Please turn on location services to start the walk.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Open Settings'),
              ),
            ],
          );
        },
      );

      if (openSettings == true) {
        await Geolocator.openLocationSettings();
      }

      return false;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

  void _increasePee() {
    setState(() => _peeCount++);
  }

  void _increasePoop() {
    setState(() => _poopCount++);
  }

  void _decreasePee() {
    if (_peeCount == 0) return;
    setState(() => _peeCount--);
  }

  void _decreasePoop() {
    if (_poopCount == 0) return;
    setState(() => _poopCount--);
  }

  String get _formattedTime {
    final hours = _seconds ~/ 3600;
    final minutes = (_seconds % 3600) ~/ 60;
    final seconds = _seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  String get _formattedDistance =>
      '${(_distanceMeters / 1000).toStringAsFixed(2)} km';

  Future<void> _openReturnPanel() async {
    if (_isEnding) return;

    setState(() {
      _showReturnPanel = true;
      _returnLocationChecked = false;
      _returnLocationFailed = false;
    });

    await _checkReturnLocation();
  }

  Future<void> _checkReturnLocation() async {
    if (!mounted || _isEnding) return;

    setState(() {
      _returnLocationChecked = false;
      _returnLocationFailed = false;
    });

    Position? currentPosition;

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('Location services are off.');
      }

      currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      // Do not trust a poor-accuracy reading for return verification.
      if (currentPosition.accuracy > 35) {
        throw Exception('GPS accuracy is too low.');
      }

      _lastPosition = currentPosition;
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _returnLocationChecked = true;
        _returnLocationFailed = true;
        _sameReturnLocation = false;
      });
      return;
    }

    if (!mounted) return;

    if (!_hasCustomerLocation) {
      setState(() {
        _returnLocationChecked = true;
        _returnLocationFailed = true;
        _sameReturnLocation = false;
      });
      return;
    }

    final distance = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      _customerLatitude!,
      _customerLongitude!,
    );

    setState(() {
      _returnLocationChecked = true;
      _returnLocationFailed = false;
      _sameReturnLocation = distance <= 75;
    });
  }

  void _markDogReturned() {
    if (_isEnding ||
        !_showReturnPanel ||
        !_returnLocationChecked) {
      return;
    }

    setState(() {
      _dogReturned = true;
    });
  }

  Future<void> _confirmEndWalk() async {
    if (_isEnding || !_dogReturned) return;

    if (!_returnLocationChecked) {
      await _checkReturnLocation();
      if (!mounted || !_returnLocationChecked) return;
    }

    // If the GPS fix or customer coordinates are unavailable, do not
    // pretend the location matches. Require the OTP flow instead.
    if (!_sameReturnLocation) {
      await _showCustomerOtpSheet();
      return;
    }

    await _endWalk();
  }

  Future<void> _showCustomerOtpSheet() async {
    final bookingId = widget.bookingId;

    if (bookingId == null || bookingId.isEmpty) {
      _showMessage(
        'Booking information is unavailable. Contact support to complete this walk.',
      );
      return;
    }

    final verified = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) => CustomerOtpSheet(
        bookingId: bookingId,
        dogName: widget.dogName,
      ),
    );

    if (verified == true && mounted) {
      await _endWalk();
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<GeoPoint> _compactRoute() {
    if (_route.isEmpty) return [];

    const maxPoints = 500;

    if (_route.length <= maxPoints) {
      return _route
          .map((p) => GeoPoint(p.latitude, p.longitude))
          .toList();
    }

    final step = (_route.length - 1) / (maxPoints - 1);

    return List<GeoPoint>.generate(
      maxPoints,
      (index) {
        final routeIndex = (index * step).round();
        final position = _route[routeIndex];

        return GeoPoint(
          position.latitude,
          position.longitude,
        );
      },
    );
  }

  Future<void> _endWalk() async {
    if (_isEnding) return;

    // Check authentication before stopping the timer and GPS stream.
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Unable to identify partner account.');
      return;
    }

    setState(() {
      _isEnding = true;
      _locationTracking = false;
    });

    _timer?.cancel();
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    try {
      final startedAt = _startedAt ?? DateTime.now();
      final endedAt = DateTime.now();

      final walkData = <String, dynamic>{
        'walkerId': user.uid,
        'dogName': widget.dogName,
        'walkType': 'Regular Walk',
        'scheduledTime': widget.time,
        'duration': _seconds,
        'distance': _distanceMeters / 1000,
        'location': widget.location,
        'peeCount': _peeCount,
        'poopCount': _poopCount,
        'startedAt': Timestamp.fromDate(startedAt),
        'endedAt': Timestamp.fromDate(endedAt),
        'status': 'completed',
        'dogReturned': true,
        'returnLocationVerified': _sameReturnLocation,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'route': _compactRoute(),
      };

      if (widget.bookingId != null &&
          widget.bookingId!.isNotEmpty) {
        walkData['bookingId'] = widget.bookingId;
      }

      if (_startPosition != null) {
        walkData['startLocation'] = GeoPoint(
          _startPosition!.latitude,
          _startPosition!.longitude,
        );
      }

      if (_lastPosition != null) {
        walkData['endLocation'] = GeoPoint(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
        );
      }

      // Stable ID makes retries update the same walk document.
      await FirebaseFirestore.instance
          .collection('walks')
          .doc(_walkDocumentId)
          .set(walkData);

      if (widget.bookingId != null &&
          widget.bookingId!.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.bookingId)
            .update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'dogReturned': true,
          'returnLocationVerified': _sameReturnLocation,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WalkSummaryScreen(
            dogName: widget.dogName,
            walkType: 'Regular Walk',
            scheduledTime: widget.time,
            durationSeconds: _seconds,
            distanceKm: _distanceMeters / 1000,
            location: widget.location,
            peeCount: _peeCount,
            poopCount: _poopCount,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isEnding = false;
        _locationTracking = true;
      });

      _startTimer();

      try {
        await _startLocationStream();
      } catch (_) {
        if (mounted) {
          setState(() {
            _locationTracking = false;
          });
        }
      }

      _showMessage(
        'Walk could not be fully saved. Check your connection and try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isStarting) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: DojoPartnerTheme.primaryOrange,
              ),
              SizedBox(height: 18),
              Text(
                'Starting walk...',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'Walk in Progress',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DogHeader(
                  dogName: widget.dogName,
                  duration: widget.duration,
                ),
                const SizedBox(height: 12),
                _LiveMap(
                  route: _route,
                  tracking: _locationTracking,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        value: _formattedTime,
                        label: 'Walk Time',
                        icon: Icons.timer_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetricCard(
                        value: _formattedDistance,
                        label: 'Distance',
                        icon: Icons.route,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _WalkNotesCard(
                  peeCount: _peeCount,
                  poopCount: _poopCount,
                  onPee: _increasePee,
                  onPoop: _increasePoop,
                  onPeeMinus: _decreasePee,
                  onPoopMinus: _decreasePoop,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      _locationTracking
                          ? Icons.gps_fixed
                          : Icons.gps_off,
                      size: 18,
                      color: _locationTracking
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _locationTracking
                          ? 'GPS ACTIVE'
                          : 'GPS unavailable',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _locationTracking
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (!_showReturnPanel)
                  _ReturnToCustomerButton(
                    enabled: !_isEnding,
                    onPressed: _openReturnPanel,
                  )
                else
                  _ReturnCustomerPanel(
                    dogName: widget.dogName,
                    checkingLocation: !_returnLocationChecked,
                    sameLocation: _sameReturnLocation,
                    locationFailed: _returnLocationFailed,
                    dogReturned: _dogReturned,
                    ending: _isEnding,
                    onRefreshLocation: _checkReturnLocation,
                    onDogReturned: _markDogReturned,
                    onComplete: _confirmEndWalk,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DogHeader extends StatelessWidget {
  const _DogHeader({
    required this.dogName,
    required this.duration,
  });

  final String dogName;
  final String duration;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 25,
          backgroundColor: Color(0xFFFFF1E8),
          child: Icon(
            Icons.pets,
            color: DojoPartnerTheme.primaryOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dogName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Regular Walk • $duration',
                style: const TextStyle(
                  fontSize: 13,
                  color: DojoPartnerTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF8EE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _LiveMap extends StatefulWidget {
  const _LiveMap({
    required this.route,
    required this.tracking,
  });

  final List<Position> route;
  final bool tracking;

  @override
  State<_LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends State<_LiveMap> {
  maps.GoogleMapController? _controller;
  String? _lastCameraKey;

  static const maps.LatLng _fallback = maps.LatLng(
    20.5937,
    78.9629,
  );

  maps.LatLng _latLng(Position position) {
    return maps.LatLng(
      position.latitude,
      position.longitude,
    );
  }

  @override
  void didUpdateWidget(covariant _LiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.route.isNotEmpty) {
      _moveCameraToLatest();
    }
  }

  Future<void> _moveCameraToLatest() async {
    if (widget.route.isEmpty || _controller == null) return;

    final latest = widget.route.last;
    final key =
        '${latest.latitude.toStringAsFixed(6)},'
        '${latest.longitude.toStringAsFixed(6)}';

    if (key == _lastCameraKey) return;
    _lastCameraKey = key;

    try {
      await _controller!.animateCamera(
        maps.CameraUpdate.newLatLng(_latLng(latest)),
      );
    } catch (_) {
      // Map can still render if camera animation is interrupted.
    }
  }

  Set<maps.Marker> _markers() {
    if (widget.route.isEmpty) return {};

    final markers = <maps.Marker>{};

    if (widget.route.length > 1) {
      markers.add(
        maps.Marker(
          markerId: const maps.MarkerId('walk-start'),
          position: _latLng(widget.route.first),
          infoWindow: const maps.InfoWindow(
            title: 'Walk started',
          ),
          icon: maps.BitmapDescriptor.defaultMarkerWithHue(
            maps.BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    markers.add(
      maps.Marker(
        markerId: const maps.MarkerId('live-location'),
        position: _latLng(widget.route.last),
        infoWindow: const maps.InfoWindow(
          title: 'Current location',
        ),
        icon: maps.BitmapDescriptor.defaultMarkerWithHue(
          maps.BitmapDescriptor.hueOrange,
        ),
      ),
    );

    return markers;
  }

  Set<maps.Polyline> _polylines() {
    if (widget.route.length < 2) return {};

    return {
      maps.Polyline(
        polylineId: const maps.PolylineId('walk-route'),
        points: widget.route.map(_latLng).toList(),
        color: DojoPartnerTheme.primaryOrange,
        width: 6,
        startCap: maps.Cap.roundCap,
        endCap: maps.Cap.roundCap,
        jointType: maps.JointType.round,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition = widget.route.isNotEmpty
        ? _latLng(widget.route.last)
        : _fallback;

    return Container(
      height: 330,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE3E3E3),
        ),
      ),
      child: Stack(
        children: [
          maps.GoogleMap(
            initialCameraPosition: maps.CameraPosition(
              target: initialPosition,
              zoom: widget.route.isNotEmpty ? 17 : 4.5,
            ),
            onMapCreated: (controller) {
              _controller = controller;
              _moveCameraToLatest();
            },
            mapType: maps.MapType.normal,
            myLocationEnabled: widget.tracking,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            compassEnabled: true,
            mapToolbarEnabled: false,
            buildingsEnabled: true,
            trafficEnabled: false,
            markers: _markers(),
            polylines: _polylines(),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.tracking
                        ? Icons.gps_fixed
                        : Icons.gps_off,
                    size: 15,
                    color: widget.tracking
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.tracking ? 'GPS ACTIVE' : 'GPS OFF',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: widget.tracking
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.route.isEmpty)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Waiting for an accurate GPS location...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFEAEAEA),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: DojoPartnerTheme.primaryOrange,
            size: 21,
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: DojoPartnerTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalkNotesCard extends StatelessWidget {
  const _WalkNotesCard({
    required this.peeCount,
    required this.poopCount,
    required this.onPee,
    required this.onPoop,
    required this.onPeeMinus,
    required this.onPoopMinus,
  });

  final int peeCount;
  final int poopCount;
  final VoidCallback onPee;
  final VoidCallback onPoop;
  final VoidCallback onPeeMinus;
  final VoidCallback onPoopMinus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFEAEAEA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Walk Notes',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _NoteControl(
                  emoji: '💧',
                  label: 'Pee',
                  count: peeCount,
                  onAdd: onPee,
                  onMinus: onPeeMinus,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _NoteControl(
                  emoji: '💩',
                  label: 'Poop',
                  count: poopCount,
                  onAdd: onPoop,
                  onMinus: onPoopMinus,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoteControl extends StatelessWidget {
  const _NoteControl({
    required this.emoji,
    required this.label,
    required this.count,
    required this.onAdd,
    required this.onMinus,
  });

  final String emoji;
  final String label;
  final int count;
  final VoidCallback onAdd;
  final VoidCallback onMinus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: count > 0 ? onMinus : null,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.remove, size: 18),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAdd,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.add, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReturnToCustomerButton extends StatelessWidget {
  const _ReturnToCustomerButton({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: const Icon(Icons.location_on_outlined),
        label: const Text('Complete Walk'),
      ),
    );
  }
}

class _ReturnCustomerPanel extends StatelessWidget {
  const _ReturnCustomerPanel({
    required this.dogName,
    required this.checkingLocation,
    required this.sameLocation,
    required this.locationFailed,
    required this.dogReturned,
    required this.ending,
    required this.onRefreshLocation,
    required this.onDogReturned,
    required this.onComplete,
  });

  final String dogName;
  final bool checkingLocation;
  final bool sameLocation;
  final bool locationFailed;
  final bool dogReturned;
  final bool ending;

  final Future<void> Function() onRefreshLocation;
  final VoidCallback onDogReturned;
  final Future<void> Function() onComplete;

  @override
  Widget build(BuildContext context) {
    final locationMessage = checkingLocation
        ? 'Checking return location...'
        : locationFailed
            ? 'Location could not be verified. Customer OTP is required.'
            : sameLocation
                ? 'You are at the customer return location.'
                : 'Return location differs from the customer location. OTP is required.';

    final locationColor = checkingLocation
        ? Colors.blueGrey
        : sameLocation && !locationFailed
            ? Colors.green
            : DojoPartnerTheme.primaryOrange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFEAEAEA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Complete Walk',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Return $dogName safely to the customer.',
            style: const TextStyle(
              color: DojoPartnerTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                if (checkingLocation)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DojoPartnerTheme.primaryOrange,
                    ),
                  )
                else
                  Icon(
                    sameLocation && !locationFailed
                        ? Icons.check_circle
                        : Icons.location_off,
                    color: locationColor,
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    locationMessage,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: locationColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: ending || checkingLocation
                  ? null
                  : onRefreshLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('Check Location Again'),
            ),
          ),
          const SizedBox(height: 10),
          if (!dogReturned)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: ending || checkingLocation
                    ? null
                    : onDogReturned,
                icon: const Icon(Icons.pets),
                label: const Text('Confirm Dog Returned'),
              ),
            )
          else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8EE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Dog returned confirmation recorded.',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (sameLocation && !locationFailed)
              _SlideToEnd(
                enabled: !ending && !checkingLocation,
                onCompleted: onComplete,
              )
            else
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: ending || checkingLocation
                      ? null
                      : onComplete,
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('Verify Customer OTP'),
                ),
              ),
            if (!sameLocation || locationFailed)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'OTP verification is required before completing the walk.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: DojoPartnerTheme.textSecondary,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SlideToEnd extends StatefulWidget {
  const _SlideToEnd({
    required this.enabled,
    required this.onCompleted,
  });

  final bool enabled;
  final Future<void> Function() onCompleted;

  @override
  State<_SlideToEnd> createState() => _SlideToEndState();
}

class _SlideToEndState extends State<_SlideToEnd> {
  double _value = 0;
  bool _completed = false;

  void _onChanged(double value) {
    if (!widget.enabled || _completed) return;

    final safeValue = value.clamp(0.0, 1.0);

    setState(() {
      _value = safeValue;
    });

    if (safeValue >= 0.92) {
      _completed = true;

      setState(() {
        _value = 1;
      });

      widget.onCompleted();
    }
  }

  void _reset() {
    if (_completed) return;

    setState(() {
      _value = 0;
    });
  }

  @override
  void didUpdateWidget(covariant _SlideToEnd oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!widget.enabled && !_completed && _value != 0) {
      _value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final containerWidth = MediaQuery.of(context).size.width - 32;
    final maxLeft = math.max(0.0, containerWidth - 60);

    return GestureDetector(
      onHorizontalDragUpdate: widget.enabled
          ? (details) {
              if (containerWidth <= 0) return;

              _onChanged(
                _value + details.delta.dx / containerWidth,
              );
            }
          : null,
      onHorizontalDragEnd: widget.enabled
          ? (_) {
              if (_value < 0.92) _reset();
            }
          : null,
      child: Container(
        height: 60,
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
            Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 100),
                opacity: _value > 0.25 ? 0 : 1,
                child: const Text(
                  'Slide to End Walk  →',
                  style: TextStyle(
                    color: DojoPartnerTheme.primaryOrange,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 4 + _value * maxLeft,
              top: 4,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: DojoPartnerTheme.primaryOrange,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: DojoPartnerTheme.primaryOrange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
