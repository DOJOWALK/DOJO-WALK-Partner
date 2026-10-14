import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'walker_details_screen.dart';

const Color wmOrange = Color(0xFFFF7900);
const Color wmBackground = Color(0xFFFFFAF5);
const Color wmText = Color(0xFF292524);
const Color wmMuted = Color(0xFF78716C);
const Color wmBorder = Color(0xFFE7E5E4);

class WalkerManagementDashboardScreen extends StatefulWidget {
  const WalkerManagementDashboardScreen({super.key});

  @override
  State<WalkerManagementDashboardScreen> createState() =>
      _WalkerManagementDashboardScreenState();
}

class _WalkerManagementDashboardScreenState
    extends State<WalkerManagementDashboardScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  String _selectedArea = 'All Areas';
  String _selectedTab = 'Available';
  String? _selectedVerificationUid;
  bool _processingVerification = false;

  static const List<String> _tabs = [
    'Available',
    'Running',
    'Verification',
    'All Walkers',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }

  String _value(dynamic value) {
    if (value == null) return '';

    final result = value.toString().trim();

    if (result.isEmpty || result == 'null') return '';

    return result;
  }

  String _firstValue(List<dynamic> values) {
    for (final value in values) {
      final result = _value(value);
      if (result.isNotEmpty) return result;
    }

    return '';
  }

  String _name(Map<String, dynamic> data) {
    return _firstValue([
          data['name'],
          data['fullName'],
          data['displayName'],
        ]).isEmpty
        ? 'Unnamed Walker'
        : _firstValue([
            data['name'],
            data['fullName'],
            data['displayName'],
          ]);
  }

  String _phone(Map<String, dynamic> data) {
    return _firstValue([
      data['phoneNumber'],
      data['phone'],
      data['mobile'],
    ]);
  }

  String _area(Map<String, dynamic> data) {
    final workLocation = _asMap(data['workLocation']);

    return _firstValue([
      data['area'],
      data['workArea'],
      workLocation['area'],
      data['city'],
      workLocation['city'],
    ]);
  }

  String _status(Map<String, dynamic> data) {
    final status = _value(data['status']).toLowerCase();
    final verification =
        _value(data['verificationStatus']).toLowerCase();

    if (status == 'suspended') return 'Suspended';

    if (status == 'rejected' || verification == 'rejected') {
      return 'Rejected';
    }

    if (verification == 'verified' || data['isApproved'] == true) {
      return data['isActive'] == true ? 'Active' : 'Verified';
    }

    if (status == 'under_review' ||
        verification == 'under_review') {
      return 'Under Review';
    }

    if (status == 'pending' || verification == 'pending') {
      return 'Pending';
    }

    if (status == 'approved') return 'Approved';

    return status.isEmpty ? 'Unknown' : status;
  }

  bool _isVerified(Map<String, dynamic> data) {
    return _value(data['verificationStatus']).toLowerCase() ==
            'verified' ||
        data['isApproved'] == true;
  }

  bool _isApplication(Map<String, dynamic> data) {
    final status = _value(data['status']).toLowerCase();
    final verification =
        _value(data['verificationStatus']).toLowerCase();

    // Only submitted applications belong in Verification.
    return data['applicationSubmitted'] == true &&
        !_isVerified(data) &&
        (status == 'under_review' ||
            status == 'pending' ||
            status == 'rejected' ||
            verification == 'pending' ||
            verification == 'under_review' ||
            verification == 'rejected');
  }

  bool _isRunningBooking(Map<String, dynamic> data) {
    final status = _value(data['status']).toLowerCase();

    return {
      'in_progress',
      'active_walk',
      'walking',
      'walk_started',
    }.contains(status);
  }

  bool _isAvailable(
    Map<String, dynamic> data,
    String uid,
    Set<String> runningWalkerIds,
  ) {
    return _isVerified(data) &&
        data['isActive'] == true &&
        _value(data['status']).toLowerCase() != 'suspended' &&
        !runningWalkerIds.contains(uid);
  }

  bool _matchesArea(Map<String, dynamic> data) {
    if (_selectedArea == 'All Areas') return true;

    return _area(data).toLowerCase() ==
        _selectedArea.toLowerCase();
  }

  bool _matchesSearch(
    Map<String, dynamic> data,
    String uid,
  ) {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) return true;

    final searchable = [
      _name(data),
      _phone(data),
      _value(data['email']),
      _value(data['walkerId']),
      uid,
      _area(data),
    ].join(' ').toLowerCase();

    return searchable.contains(query);
  }

  List<String> _getAreas(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> walkers,
  ) {
    final areas = <String>{};

    for (final walker in walkers) {
      final area = _area(walker.data());
      if (area.isNotEmpty) areas.add(area);
    }

    final sorted = areas.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return ['All Areas', ...sorted];
  }

  void _openDetails(
    QueryDocumentSnapshot<Map<String, dynamic>> walker,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WalkerDetailsScreen(
          uid: walker.id,
          walkerData: walker.data(),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _updateVerification({
    required String uid,
    required bool approve,
  }) async {
    if (_processingVerification) return;

    final action = approve ? 'Verify' : 'Reject';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$action Walker?'),
        content: Text(
          approve
              ? 'क्या आप इस Walker के KYC documents verify करना चाहते हैं?'
              : 'क्या आप इस Walker का application reject करना चाहते हैं?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor:
                  approve ? wmOrange : const Color(0xFFB91C1C),
            ),
            onPressed: () =>
                Navigator.of(dialogContext).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _processingVerification = true);

    try {
      final ref = FirebaseFirestore.instance
          .collection('walkers')
          .doc(uid);

      // Re-read the document before changing verification status.
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        _showMessage('Walker application नहीं मिला।');
        return;
      }

      final data = snapshot.data() ?? <String, dynamic>{};

      if (data['applicationSubmitted'] != true) {
        _showMessage('यह application submit नहीं हुआ है।');
        return;
      }

      if (_isVerified(data)) {
        _showMessage('यह Walker पहले से verified है।');
        return;
      }

      final status = _value(data['status']).toLowerCase();

      if (status == 'suspended') {
        _showMessage(
          'Suspended Walker को इस स्क्रीन से verify नहीं किया जा सकता।',
        );
        return;
      }

      await ref.update({
        'verificationStatus': approve ? 'verified' : 'rejected',
        'status': approve ? 'approved' : 'rejected',
        'isApproved': approve,
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _selectedVerificationUid = null;
      });

      _showMessage(
        approve
            ? 'KYC verified. Walker अभी inactive रहेगा।'
            : 'Walker application rejected.',
      );
    } on FirebaseException catch (error) {
      _showMessage(
        'Update नहीं हुआ: ${error.message ?? error.code}',
      );
    } catch (error) {
      _showMessage('Update नहीं हुआ: $error');
    } finally {
      if (mounted) {
        setState(() => _processingVerification = false);
      }
    }
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: wmOrange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.groups_outlined,
            color: wmOrange,
            size: 23,
          ),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Walker Management',
                style: TextStyle(
                  color: wmText,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Manage Walkers & applications',
                style: TextStyle(
                  color: wmMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _areaSelector(List<String> areas) {
    if (!areas.contains(_selectedArea)) {
      _selectedArea = 'All Areas';
    }

    return Container(
      height: 43,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: wmBorder),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 18,
            color: wmOrange,
          ),
          const SizedBox(width: 8),
          const Text(
            'Area',
            style: TextStyle(color: wmMuted, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedArea,
                isExpanded: true,
                iconSize: 19,
                items: areas.map((area) {
                  return DropdownMenuItem(
                    value: area,
                    child: Text(
                      area,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: wmText,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _selectedArea = value;
                    _selectedVerificationUid = null;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBox() {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {
          _selectedVerificationUid = null;
        }),
        style: const TextStyle(fontSize: 13, color: wmText),
        decoration: InputDecoration(
          hintText: 'Search name, phone or Walker ID',
          hintStyle: const TextStyle(
            fontSize: 12,
            color: wmMuted,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: wmOrange,
            size: 20,
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _selectedVerificationUid = null;
                    });
                  },
                  icon: const Icon(Icons.close, size: 18),
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: wmBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(color: wmBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: const BorderSide(
              color: wmOrange,
              width: 1.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statistics({
    required int available,
    required int running,
    required int total,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: wmBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _statItem(
            'Available',
            available,
            Icons.check_circle_outline,
            const Color(0xFF15803D),
          ),
          _statDivider(),
          _statItem(
            'Running',
            running,
            Icons.directions_walk,
            wmOrange,
          ),
          _statDivider(),
          _statItem(
            'All Walkers',
            total,
            Icons.groups_outlined,
            const Color(0xFF1D4ED8),
          ),
        ],
      ),
    );
  }

  Widget _statItem(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: wmMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '$count',
            style: const TextStyle(
              color: wmText,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(width: 1, height: 39, color: wmBorder);
  }

  Widget _tabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _tabs.map((tab) {
          final selected = _selectedTab == tab;

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: () {
                setState(() {
                  _selectedTab = tab;
                  _selectedVerificationUid = null;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 130),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: selected ? wmOrange : Colors.white,
                  border: Border.all(
                    color: selected ? wmOrange : wmBorder,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    color: selected ? Colors.white : wmText,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color foreground;
    Color background;

    switch (status) {
      case 'Active':
        foreground = const Color(0xFF166534);
        background = const Color(0xFFDCFCE7);
        break;
      case 'Running':
        foreground = const Color(0xFF9A3412);
        background = const Color(0xFFFFEDD5);
        break;
      case 'Verified':
      case 'Approved':
        foreground = const Color(0xFF1D4ED8);
        background = const Color(0xFFDBEAFE);
        break;
      case 'Rejected':
      case 'Suspended':
        foreground = const Color(0xFFB91C1C);
        background = const Color(0xFFFEE2E2);
        break;
      default:
        foreground = const Color(0xFF92400E);
        background = const Color(0xFFFEF3C7);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _walkerCard({
    required QueryDocumentSnapshot<Map<String, dynamic>> document,
    required bool running,
  }) {
    final data = document.data();

    final photoUrl = _firstValue([
      data['photoUrl'],
      data['profilePhotoUrl'],
    ]);

    final area = _area(data);
    final status = running ? 'Running' : _status(data);
    final isVerification = _selectedTab == 'Verification';
    final selected = _selectedVerificationUid == document.id;

    return Material(
      color: selected ? const Color(0xFFFFF1E5) : Colors.white,
      child: InkWell(
        onTap: () {
          if (isVerification) {
            setState(() {
              _selectedVerificationUid =
                  selected ? null : document.id;
            });
          } else {
            _openDetails(document);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 11,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: wmOrange.withValues(alpha: 0.12),
                backgroundImage:
                    photoUrl.isEmpty ? null : NetworkImage(photoUrl),
                child: photoUrl.isEmpty
                    ? const Icon(
                        Icons.person_outline,
                        color: wmOrange,
                        size: 24,
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _name(data),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: wmText,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        _statusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (area.isNotEmpty) area,
                        if (_phone(data).isNotEmpty) _phone(data),
                      ].join('  ·  ').isEmpty
                          ? 'Area not provided'
                          : [
                              if (area.isNotEmpty) area,
                              if (_phone(data).isNotEmpty) _phone(data),
                            ].join('  ·  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: wmMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Icon(
                isVerification
                    ? selected
                        ? Icons.expand_less
                        : Icons.expand_more
                    : Icons.chevron_right,
                size: 19,
                color: wmMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              label,
              style: const TextStyle(
                color: wmMuted,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: wmText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentPreview(String title, String storagePath) {
    if (storagePath.trim().isEmpty) {
      return Container(
        width: 145,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          border: Border.all(color: wmBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.image_not_supported_outlined,
              color: wmMuted,
              size: 26,
            ),
            const SizedBox(height: 7),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: wmText,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Document path missing',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: wmMuted,
                fontSize: 9,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 145,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: wmBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 110,
            child: FutureBuilder<String>(
              future: FirebaseStorage.instance
                  .ref()
                  .child(storagePath)
                  .getDownloadURL(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: wmOrange,
                      strokeWidth: 2,
                    ),
                  );
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            color: wmMuted,
                            size: 25,
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Preview unavailable',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: wmMuted,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return InkWell(
                  onTap: () {
                    showDialog<void>(
                      context: context,
                      builder: (dialogContext) => Dialog(
                        child: InteractiveViewer(
                          child: Image.network(
                            snapshot.data!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('Image could not be loaded.'),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Image.network(
                    snapshot.data!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: wmMuted,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: wmText,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _verificationPanel(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final currentAddress = _asMap(data['currentAddress']);
    final kyc = _asMap(data['kyc']);
    final selfie = _asMap(kyc['selfie']);
    final documents = _asMap(kyc['documents']);

    final aadhaarFront = _asMap(documents['aadhaar_front']);
    final aadhaarBack = _asMap(documents['aadhaar_back']);
    final panCard = _asMap(documents['pan_card']);

    final address = [
      _value(currentAddress['houseNumber']),
      _value(currentAddress['street']),
      _value(currentAddress['landmark']),
      _value(currentAddress['city']),
      _value(currentAddress['state']),
      _value(currentAddress['pinCode']),
    ].where((part) => part.isNotEmpty).join(', ');

    final zones = data['zoneNames'] is List
        ? (data['zoneNames'] as List)
            .map(_value)
            .where((value) => value.isNotEmpty)
            .join(', ')
        : _value(data['zoneName']);

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF5),
        border: Border.all(color: wmOrange.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'KYC Application Review',
                  style: TextStyle(
                    color: wmText,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _statusBadge(_status(data)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Personal Details',
            style: TextStyle(
              color: wmText,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          _infoRow('Full name', _name(data)),
          _infoRow('Phone', _phone(data)),
          _infoRow('Email', _value(data['email'])),
          _infoRow('Gender', _value(data['gender'])),
          _infoRow(
            'Date of birth',
            _dateOfBirth(data['dateOfBirth']),
          ),
          _infoRow('Travel mode', _value(data['travelMode'])),
          _infoRow(
            'Work location',
            [
              _value(data['area']),
              _value(data['city']),
              _value(data['state']),
            ].where((part) => part.isNotEmpty).join(', '),
          ),
          _infoRow('Zones', zones),
          _infoRow('Residential address', address),
          const Divider(height: 20, color: wmBorder),
          const Text(
            'KYC Documents',
            style: TextStyle(
              color: wmText,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _documentPreview(
                'Selfie',
                _value(selfie['storagePath']),
              ),
              _documentPreview(
                'Aadhaar Front',
                _value(aadhaarFront['storagePath']),
              ),
              _documentPreview(
                'Aadhaar Back',
                _value(aadhaarBack['storagePath']),
              ),
              _documentPreview(
                'PAN Card',
                _value(panCard['storagePath']),
              ),
            ],
          ),
          const SizedBox(height: 13),
          if (_processingVerification)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(color: wmOrange),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateVerification(
                      uid: document.id,
                      approve: false,
                    ),
                    icon: const Icon(Icons.close, size: 17),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB91C1C),
                      side: const BorderSide(
                        color: Color(0xFFB91C1C),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _updateVerification(
                      uid: document.id,
                      approve: true,
                    ),
                    icon: const Icon(Icons.verified_outlined, size: 17),
                    label: const Text('Verify'),
                    style: FilledButton.styleFrom(
                      backgroundColor: wmOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 5),
          const Text(
            'Verify करने के बाद भी Walker inactive रहेगा। उसे काम पर लगाने के लिए activation अलग से करें।',
            style: TextStyle(
              color: wmMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _dateOfBirth(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }

    return _value(value);
  }

  Widget _emptyState() {
    final message = switch (_selectedTab) {
      'Available' => 'No available Walkers found.',
      'Running' => 'No active walks found.',
      'Verification' => 'No submitted applications awaiting verification.',
      _ => 'No Walkers match your search.',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: wmBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.person_search_outlined,
            size: 34,
            color: wmOrange,
          ),
          const SizedBox(height: 9),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: wmMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(String message) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: wmBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          style: const TextStyle(color: wmText, fontSize: 12),
        ),
      ),
    );
  }

  Widget _walkerList({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> walkers,
    required Set<String> runningWalkerIds,
  }) {
    final filtered = walkers.where((document) {
      final data = document.data();
      final uid = document.id;

      if (!_matchesArea(data)) return false;
      if (!_matchesSearch(data, uid)) return false;

      final running = runningWalkerIds.contains(uid);

      switch (_selectedTab) {
        case 'Available':
          return _isAvailable(data, uid, runningWalkerIds);
        case 'Running':
          return running;
        case 'Verification':
          return _isApplication(data);
        case 'All Walkers':
          return true;
        default:
          return false;
      }
    }).toList();

    if (filtered.isEmpty) {
      _selectedVerificationUid = null;
      return _emptyState();
    }

    final selectedStillVisible = filtered.any(
      (document) => document.id == _selectedVerificationUid,
    );

    if (!selectedStillVisible) {
      _selectedVerificationUid = null;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: wmBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (int index = 0; index < filtered.length; index++) ...[
            _walkerCard(
              document: filtered[index],
              running: runningWalkerIds.contains(filtered[index].id),
            ),
            if (_selectedTab == 'Verification' &&
                _selectedVerificationUid == filtered[index].id)
              _verificationPanel(filtered[index]),
            if (index < filtered.length - 1)
              const Divider(
                height: 1,
                thickness: 0.7,
                color: wmBorder,
              ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: wmBackground,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('walkers')
              .snapshots(),
          builder: (context, walkerSnapshot) {
            if (walkerSnapshot.hasError) {
              return Center(
                child: _errorState(
                  'Walkers load नहीं हो सके। Firestore Rules और admin access जाँचें.\n${walkerSnapshot.error}',
                ),
              );
            }

            if (!walkerSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: wmOrange),
              );
            }

            final walkers = walkerSnapshot.data!.docs;
            final areas = _getAreas(walkers);

            if (!areas.contains(_selectedArea)) {
              _selectedArea = 'All Areas';
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .snapshots(),
              builder: (context, bookingSnapshot) {
                if (bookingSnapshot.hasError) {
                  return Center(
                    child: _errorState(
                      'Booking status load नहीं हो सका। Booking read permissions जाँचें.\n${bookingSnapshot.error}',
                    ),
                  );
                }

                if (!bookingSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: wmOrange),
                  );
                }

                final runningWalkerIds = <String>{};

                for (final booking in bookingSnapshot.data!.docs) {
                  final data = booking.data();

                  if (_isRunningBooking(data)) {
                    final walkerId = _value(data['walkerId']);

                    if (walkerId.isNotEmpty) {
                      runningWalkerIds.add(walkerId);
                    }
                  }
                }

                final areaWalkers = walkers.where((document) {
                  return _matchesArea(document.data());
                }).toList();

                final availableCount = areaWalkers.where((document) {
                  return _isAvailable(
                    document.data(),
                    document.id,
                    runningWalkerIds,
                  );
                }).length;

                final runningCount = areaWalkers.where((document) {
                  return runningWalkerIds.contains(document.id);
                }).length;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 800;

                    return ListView(
                      padding: EdgeInsets.fromLTRB(
                        wide ? 24 : 13,
                        13,
                        wide ? 24 : 13,
                        20,
                      ),
                      children: [
                        _header(),
                        const SizedBox(height: 12),
                        _areaSelector(areas),
                        const SizedBox(height: 8),
                        _searchBox(),
                        const SizedBox(height: 12),
                        _statistics(
                          available: availableCount,
                          running: runningCount,
                          total: areaWalkers.length,
                        ),
                        const SizedBox(height: 15),
                        _tabs(),
                        const SizedBox(height: 11),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedTab,
                                style: const TextStyle(
                                  color: wmText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Text(
                              '${_walkerCountForTab(walkers, runningWalkerIds)} records',
                              style: const TextStyle(
                                color: wmMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        _walkerList(
                          walkers: walkers,
                          runningWalkerIds: runningWalkerIds,
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  int _walkerCountForTab(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> walkers,
    Set<String> runningWalkerIds,
  ) {
    return walkers.where((document) {
      final data = document.data();

      if (!_matchesArea(data)) return false;
      if (!_matchesSearch(data, document.id)) return false;

      switch (_selectedTab) {
        case 'Available':
          return _isAvailable(data, document.id, runningWalkerIds);
        case 'Running':
          return runningWalkerIds.contains(document.id);
        case 'Verification':
          return _isApplication(data);
        case 'All Walkers':
          return true;
        default:
          return false;
      }
    }).length;
  }
}
