import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../theme.dart';
import 'personal_details_screen.dart';

class WorkLocationScreen extends StatefulWidget {
  const WorkLocationScreen({super.key});

  @override
  State<WorkLocationScreen> createState() =>
      _WorkLocationScreenState();
}

class _WorkLocationScreenState extends State<WorkLocationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedCity;
  String? _selectedArea;
  String? _travelMode;

  bool _isSaving = false;

  Stream<QuerySnapshot<Map<String, dynamic>>> _locationsStream() {
    return _firestore
        .collection('zones')
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  String _field(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String key,
  ) {
    return doc.data()[key]?.toString().trim() ?? '';
  }

  List<String> _uniqueValues(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String field, {
    String? city,
  }) {
    final values = <String>{};

    for (final doc in docs) {
      final data = doc.data();
      final value = data[field]?.toString().trim() ?? '';

      if (value.isEmpty) continue;

      if (city != null &&
          (data['city']?.toString().trim() ?? '') != city) {
        continue;
      }

      values.add(value);
    }

    return values.toList()..sort();
  }

  Future<void> _continue(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    if (_isSaving) return;

    if (_selectedCity == null || _selectedArea == null) {
      _showMessage('Please select your city and work area.');
      return;
    }

    if (_travelMode == null) {
      _showMessage(
        'Please select how you will travel to bookings.',
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Your login session expired. Please log in again.',
      );
      return;
    }

    final matchingDocs = docs.where((doc) {
      return _field(doc, 'city') == _selectedCity &&
          _field(doc, 'area') == _selectedArea;
    }).toList();

    if (matchingDocs.isEmpty) {
      _showMessage(
        'This area is no longer available. Please select again.',
      );
      return;
    }

    // State and zone names are taken from active zone documents.
    // No arbitrary state or zone is invented.
    final states = matchingDocs
        .map((doc) => _field(doc, 'state'))
        .where((value) => value.isNotEmpty)
        .toSet();

    if (states.length != 1) {
      _showMessage(
        'This location needs a valid state in DOJO zone settings. '
        'Please contact support.',
      );
      return;
    }

    final state = states.first;

    final zoneNames = matchingDocs
        .map((doc) {
          final data = doc.data();

          return (data['zoneName'] ??
                  data['name'] ??
                  data['title'])
              ?.toString()
              .trim() ??
              '';
        })
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    // Do not silently use the area as a zone name. Zone metadata
    // must be configured correctly in Firestore.
    if (zoneNames.isEmpty) {
      _showMessage(
        'No zone name is configured for this area. '
        'Please contact DOJO support.',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final walkerRef =
          _firestore.collection('walkers').doc(user.uid);

      final existing = await walkerRef.get();
      final existingData = existing.data();

      // A submitted application must not be restarted through
      // the initial onboarding flow.
      if (existingData?['applicationSubmitted'] == true) {
        _showMessage(
          'Your application has already been submitted.',
        );
        return;
      }

      // Do not create an incomplete walker document here.
      // PersonalDetailsScreen will create it after collecting
      // all required fields.
      //
      // If a draft already exists, update only fields permitted
      // by the ordinary owner-update rule.
      if (existing.exists) {
        final status = existingData?['status']?.toString();

        if (status != 'in_progress') {
          _showMessage(
            'Your application cannot be edited from this step.',
          );
          return;
        }

        await walkerRef.update({
          'city': _selectedCity,
          'state': state,
          'area': _selectedArea,
          'zoneName': zoneNames.first,
          'zoneNames': zoneNames,
          'zones': matchingDocs.map((doc) => doc.id).toList(),
          'travelMode': _travelMode,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => PersonalDetailsScreen(
            initialCity: _selectedCity,
            initialState: state,
            initialArea: _selectedArea,
            initialZoneNames: zoneNames,
            initialZoneIds:
                matchingDocs.map((doc) => doc.id).toList(),
            initialTravelMode: _travelMode,
          ),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      _showMessage(
        e.code == 'permission-denied'
            ? 'Firebase access denied. Please check Firestore Rules.'
            : e.message ?? 'Unable to continue. Please try again.',
      );
    } catch (e) {
      debugPrint('Work location error: $e');

      if (mounted) {
        _showMessage('Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: DojoPartnerTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: DojoPartnerTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool enabled = true,
  }) {
    final safeValue =
        value != null && items.contains(value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: DojoPartnerTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: safeValue,
          isExpanded: true,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: Color(0xFFE5E5E5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: Color(0xFFE5E5E5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(
                color: DojoPartnerTheme.primaryOrange,
                width: 1.5,
              ),
            ),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: enabled && !_isSaving ? onChanged : null,
        ),
      ],
    );
  }

  Widget _travelModeCard({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _travelMode == value;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: _isSaving
          ? null
          : () {
              setState(() => _travelMode = value);
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFF5EC)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? DojoPartnerTheme.primaryOrange
                : const Color(0xFFE5E5E5),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: selected
                  ? DojoPartnerTheme.primaryOrange
                  : DojoPartnerTheme.textSecondary,
            ),
            const SizedBox(width: 14),
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
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: DojoPartnerTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected
                  ? DojoPartnerTheme.primaryOrange
                  : const Color(0xFFBDBDBD),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Work Location'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _locationsStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Unable to load cities and areas. '
                    'Please check your connection.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: DojoPartnerTheme.primaryOrange,
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No active locations are available yet. '
                    'Please contact DOJO support.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final cities = _uniqueValues(docs, 'city');

            final areas = _uniqueValues(
              docs,
              'area',
              city: _selectedCity,
            );

            if (_selectedCity != null &&
                !cities.contains(_selectedCity)) {
              _selectedCity = null;
              _selectedArea = null;
            } else if (_selectedArea != null &&
                !areas.contains(_selectedArea)) {
              _selectedArea = null;
            }

            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: 480),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          24,
                          18,
                          24,
                          24,
                        ),
                        children: [
                          Center(
                            child: Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color:
                                    DojoPartnerTheme.primaryOrange,
                                borderRadius:
                                    BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.pets_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'DOJO PARTNER',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3,
                              color:
                                  DojoPartnerTheme.primaryOrange,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _sectionTitle(
                            'Where would you like to work?',
                            'Choose one city, one area and your '
                                'preferred travel mode.',
                          ),
                          const SizedBox(height: 24),
                          _dropdown(
                            label: 'Select City',
                            hint: 'Choose your city',
                            value: _selectedCity,
                            items: cities,
                            onChanged: (value) {
                              setState(() {
                                _selectedCity = value;
                                _selectedArea = null;
                              });
                            },
                          ),
                          const SizedBox(height: 20),
                          _dropdown(
                            label: 'Select One Area',
                            hint: _selectedCity == null
                                ? 'Select a city first'
                                : 'Choose your work area',
                            value: _selectedArea,
                            items: areas,
                            enabled: _selectedCity != null,
                            onChanged: (value) {
                              setState(
                                () => _selectedArea = value,
                              );
                            },
                          ),
                          const SizedBox(height: 28),
                          _sectionTitle(
                            'How will you travel?',
                            'Choose your main way to reach '
                                'customer bookings.',
                          ),
                          const SizedBox(height: 14),
                          _travelModeCard(
                            value: 'walking',
                            title: 'Walking',
                            subtitle: 'I will travel on foot.',
                            icon: Icons.directions_walk_rounded,
                          ),
                          _travelModeCard(
                            value: 'bicycle',
                            title: 'Bicycle',
                            subtitle:
                                'I will travel by bicycle.',
                            icon: Icons.pedal_bike_rounded,
                          ),
                          _travelModeCard(
                            value: 'scooter',
                            title: 'Scooter',
                            subtitle:
                                'I will travel by scooter.',
                            icon: Icons.two_wheeler_rounded,
                          ),
                          _travelModeCard(
                            value: 'motorcycle',
                            title: 'Motorcycle / Bike',
                            subtitle:
                                'I will travel by motorcycle.',
                            icon: Icons.motorcycle_rounded,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF5EC),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Note: Travel mode describes how you '
                              'reach the customer. The dog walk '
                              'itself is conducted on foot.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color:
                                    DojoPartnerTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    14,
                    24,
                    20,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: Color(0xFFEEEEEE),
                      ),
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: 480),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () => _continue(docs),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                DojoPartnerTheme.primaryOrange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save Location & Continue',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
