import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../theme.dart';
import 'live_selfie_screen.dart';

class PersonalDetailsScreen extends StatefulWidget {
  final String? initialCity;
  final String? initialState;
  final String? initialArea;
  final List<String> initialZoneNames;
  final List<String> initialZoneIds;
  final String? initialTravelMode;

  const PersonalDetailsScreen({
    super.key,
    this.initialCity,
    this.initialState,
    this.initialArea,
    this.initialZoneNames = const [],
    this.initialZoneIds = const [],
    this.initialTravelMode,
  });

  @override
  State<PersonalDetailsScreen> createState() =>
      _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState
    extends State<PersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  DateTime? _dateOfBirth;
  String? _gender;

  bool _isLoading = true;
  bool _isSaving = false;

  static const int _minimumAge = 18;

  @override
  void initState() {
    super.initState();
    _loadExistingDetails();
  }

  Future<void> _loadExistingDetails() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      _showMessage('Please login again to continue.');
      return;
    }

    _phoneController.text = user.phoneNumber ?? '';

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('walkers')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (snapshot.exists) {
        final data = snapshot.data() ?? <String, dynamic>{};

        _nameController.text =
            data['fullName'] as String? ?? '';

        _emailController.text =
            data['email'] as String? ?? '';

        _phoneController.text = user.phoneNumber ??
            (data['phone'] as String? ?? '');

        final gender = data['gender'] as String?;

        if (gender != null &&
            ['male', 'female', 'other'].contains(gender)) {
          _gender = gender;
        }

        final dob = data['dateOfBirth'];

        if (dob is Timestamp) {
          _dateOfBirth = dob.toDate();
        } else if (dob is String) {
          _dateOfBirth = DateTime.tryParse(dob);
        }
      }
    } on FirebaseException catch (e) {
      debugPrint('Load personal details error: ${e.code}');

      if (mounted) {
        _showMessage(
          e.code == 'permission-denied'
              ? 'Unable to access your profile. Check Firestore Rules.'
              : 'Could not load saved details. Please try again.',
        );
      }
    } catch (e) {
      debugPrint('Personal details loading error: $e');

      if (mounted) {
        _showMessage('Unable to load your saved details.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime dob) {
    final now = DateTime.now();

    var age = now.year - dob.year;

    final birthdayNotReached = now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day);

    if (birthdayNotReached) {
      age--;
    }

    return age;
  }

  Future<void> _selectDate() async {
    if (_isSaving) return;

    final now = DateTime.now();

    final lastAllowedDate = DateTime(
      now.year - _minimumAge,
      now.month,
      now.day,
    );

    var initialDate = _dateOfBirth ?? lastAllowedDate;

    if (initialDate.isAfter(lastAllowedDate)) {
      initialDate = lastAllowedDate;
    }

    if (initialDate.isBefore(DateTime(1940))) {
      initialDate = DateTime(1940);
    }

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: lastAllowedDate,
      helpText: 'Select Date of Birth',
      cancelText: 'Cancel',
      confirmText: 'Confirm',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: DojoPartnerTheme.primaryOrange,
                ),
          ),
          child: child!,
        );
      },
    );

    if (selected != null && mounted) {
      setState(() => _dateOfBirth = selected);
    }
  }

  Future<void> _continue() async {
    if (_isLoading || _isSaving) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final dob = _dateOfBirth;

    if (dob == null) {
      _showMessage('Please select your date of birth.');
      return;
    }

    if (_calculateAge(dob) < _minimumAge) {
      _showMessage('You must be at least 18 years old.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Your session expired. Please login again.');
      return;
    }

    final phone = user.phoneNumber ??
        _phoneController.text.trim();

    if (phone.trim().isEmpty) {
      _showMessage(
        'A verified mobile number is required. Please login again.',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final walkerRef = FirebaseFirestore.instance
          .collection('walkers')
          .doc(user.uid);

      final snapshot = await walkerRef.get();
      final existing = snapshot.data();

      if (existing?['applicationSubmitted'] == true) {
        _showMessage(
          'Your application has already been submitted.',
        );
        return;
      }

      if (snapshot.exists &&
          existing?['status'] != 'in_progress') {
        _showMessage(
          'Your application cannot be edited from this step.',
        );
        return;
      }

      final email = _emailController.text.trim();

      // These fields are allowed in an ordinary owner update.
      final data = <String, dynamic>{
        'userId': user.uid,
        'fullName': _nameController.text.trim(),
        'phone': phone.trim(),
        'dateOfBirth': Timestamp.fromDate(dob),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (email.isNotEmpty) {
        data['email'] = email;
      } else {
        data['email'] = FieldValue.delete();
      }

      if (_gender != null) {
        data['gender'] = _gender!;
      } else {
        data['gender'] = FieldValue.delete();
      }

      if (!snapshot.exists) {
        final city = widget.initialCity?.trim() ?? '';
        final state = widget.initialState?.trim() ?? '';
        final area = widget.initialArea?.trim() ?? '';

        final zoneNames = widget.initialZoneNames
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();

        final zoneIds = widget.initialZoneIds
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();

        if (city.isEmpty ||
            state.isEmpty ||
            area.isEmpty ||
            zoneNames.isEmpty ||
            widget.initialTravelMode == null) {
          _showMessage(
            'Please complete Work Location before continuing.',
          );
          return;
        }

        // All mandatory create-rule fields are supplied here.
        data.addAll({
          'status': 'in_progress',
          'isActive': false,
          'isApproved': false,
          'verificationStatus': 'pending',
          'applicationSubmitted': false,
          'createdAt': FieldValue.serverTimestamp(),
          'city': city,
          'state': state,
          'area': area,
          'zoneName': zoneNames.first,
          'zoneNames': zoneNames,
          'zones': zoneIds,
          'travelMode': widget.initialTravelMode,
        });
      } else {
        // An existing draft keeps its location. If location was
        // supplied again, only permitted ordinary fields change.
        final city = widget.initialCity?.trim() ?? '';
        final state = widget.initialState?.trim() ?? '';
        final area = widget.initialArea?.trim() ?? '';

        if (city.isNotEmpty) data['city'] = city;
        if (state.isNotEmpty) data['state'] = state;
        if (area.isNotEmpty) data['area'] = area;

        final zoneNames = widget.initialZoneNames
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();

        final zoneIds = widget.initialZoneIds
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList();

        if (zoneNames.isNotEmpty) {
          data['zoneName'] = zoneNames.first;
          data['zoneNames'] = zoneNames;
        }

        if (zoneIds.isNotEmpty) {
          data['zones'] = zoneIds;
        }

        if (widget.initialTravelMode != null) {
          data['travelMode'] = widget.initialTravelMode;
        }
      }

      // For a new document, this creates the complete draft.
      // For an existing document, only permitted fields update.
      await walkerRef.set(
        data,
        SetOptions(merge: true),
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const LiveSelfieScreen(),
        ),
      );
    } on FirebaseException catch (e) {
      debugPrint('Personal details save error: ${e.code}');

      if (!mounted) return;

      final message = switch (e.code) {
        'permission-denied' =>
          'Permission denied. Please check Firestore Rules.',
        'unavailable' =>
          'Network unavailable. Please try again.',
        'unauthenticated' =>
          'Your session expired. Please login again.',
        _ => e.message ?? 'Unable to save personal details.',
      };

      _showMessage(message);
    } catch (e) {
      debugPrint('Unexpected save error: $e');

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

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE5E5E5),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFFE5E5E5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: DojoPartnerTheme.primaryOrange,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: DojoPartnerTheme.primaryOrange
                .withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            size: 36,
            color: DojoPartnerTheme.primaryOrange,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'DOJO PARTNER',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
            color: DojoPartnerTheme.primaryOrange,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Personal Details',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: DojoPartnerTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your details to continue your partner registration.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: DojoPartnerTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDateOfBirthField() {
    final dob = _dateOfBirth;

    final dateText = dob == null
        ? 'Select your date of birth'
        : '${dob.day.toString().padLeft(2, '0')}/'
            '${dob.month.toString().padLeft(2, '0')}/'
            '${dob.year}';

    return InkWell(
      onTap: _isSaving ? null : _selectDate,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: _inputDecoration(
          label: 'Date of Birth *',
          icon: Icons.calendar_month_outlined,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                dateText,
                style: TextStyle(
                  fontSize: 14,
                  color: dob == null
                      ? DojoPartnerTheme.textSecondary
                      : DojoPartnerTheme.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: DojoPartnerTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderField() {
    return DropdownButtonFormField<String>(
      initialValue: _gender,
      isExpanded: true,
      decoration: _inputDecoration(
        label: 'Gender (Optional)',
        icon: Icons.wc_outlined,
      ),
      items: const [
        DropdownMenuItem(value: 'male', child: Text('Male')),
        DropdownMenuItem(value: 'female', child: Text('Female')),
        DropdownMenuItem(value: 'other', child: Text('Other')),
      ],
      onChanged: _isSaving
          ? null
          : (value) => setState(() => _gender = value),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            enabled: !_isSaving,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            decoration: _inputDecoration(
              label: 'Full Name *',
              icon: Icons.person_outline,
              hint: 'Enter your full name',
            ),
            validator: (value) {
              final name = value?.trim() ?? '';

              if (name.isEmpty) {
                return 'Full name is required.';
              }

              if (name.length < 3) {
                return 'Enter at least 3 characters.';
              }

              if (name.length > 80) {
                return 'Name cannot exceed 80 characters.';
              }

              return null;
            },
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _phoneController,
            enabled: false,
            decoration: _inputDecoration(
              label: 'Verified Mobile Number',
              icon: Icons.phone_outlined,
            ),
          ),
          const SizedBox(height: 18),
          _buildDateOfBirthField(),
          const SizedBox(height: 18),
          _buildGenderField(),
          const SizedBox(height: 18),
          TextFormField(
            controller: _emailController,
            enabled: !_isSaving,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            decoration: _inputDecoration(
              label: 'Email (Optional)',
              icon: Icons.email_outlined,
              hint: 'example@email.com',
            ),
            validator: (value) {
              final email = value?.trim() ?? '';

              if (email.isEmpty) return null;

              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                  .hasMatch(email)) {
                return 'Enter a valid email address.';
              }

              return null;
            },
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5EB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: DojoPartnerTheme.primaryOrange
                    .withValues(alpha: 0.25),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: DojoPartnerTheme.primaryOrange,
                  size: 21,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Use your correct personal information. '
                    'Your details will be reviewed during partner verification.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: DojoPartnerTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isSaving || _isLoading
                  ? null
                  : _continue,
              style: ElevatedButton.styleFrom(
                backgroundColor: DojoPartnerTheme.primaryOrange,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    DojoPartnerTheme.primaryOrange
                        .withValues(alpha: 0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 23,
                      height: 23,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Save & Continue',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 9),
                        Icon(Icons.arrow_forward_rounded),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Personal Details'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: DojoPartnerTheme.primaryOrange,
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      24,
                      24,
                      24,
                      32,
                    ),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 30),
                      _buildForm(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
