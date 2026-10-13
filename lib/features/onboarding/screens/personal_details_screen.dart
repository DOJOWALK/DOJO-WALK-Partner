import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme.dart';
import 'live_selfie_screen.dart';

class PersonalDetailsScreen extends StatefulWidget {
  const PersonalDetailsScreen({super.key});

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

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExistingDetails();
  }

  Future<void> _loadExistingDetails() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    _phoneController.text = user.phoneNumber ?? '';

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('walkers')
          .doc(user.uid)
          .get();

      if (!mounted || !snapshot.exists) return;

      final data = snapshot.data()!;

      setState(() {
        _nameController.text =
            data['fullName'] as String? ?? '';

        _emailController.text =
            data['email'] as String? ?? '';

        final gender = data['gender'] as String?;

        if (gender != null &&
            ['male', 'female', 'other'].contains(gender)) {
          _gender = gender;
        }

        final dob = data['dateOfBirth'];

        if (dob is Timestamp) {
          _dateOfBirth = dob.toDate();
        }
      });
    } on FirebaseException catch (e) {
      debugPrint('Unable to load Walker details: ${e.code}');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ??
          DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1940),
      lastDate: now,
      helpText: 'Date of Birth',
    );

    if (selected != null && mounted) {
      setState(() => _dateOfBirth = selected);
    }
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your date of birth.'),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login again.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final walkerRef = FirebaseFirestore.instance
          .collection('walkers')
          .doc(user.uid);

      final snapshot = await walkerRef.get();

      final data = <String, dynamic>{
        'userId': user.uid,
        'fullName': _nameController.text.trim(),
        'phone': user.phoneNumber ?? '',
        'dateOfBirth': Timestamp.fromDate(_dateOfBirth!),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final email = _emailController.text.trim();

      if (email.isNotEmpty) {
        data['email'] = email;
      }

      if (_gender != null) {
        data['gender'] = _gender!;
      }

      if (!snapshot.exists) {
        data.addAll({
          'status': 'under_review',
          'isActive': false,
          'isApproved': false,
          'verificationStatus': 'pending',
        });
      }

      await walkerRef.set(
        data,
        SetOptions(merge: true),
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LiveSelfieScreen(),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      final message = e.code == 'permission-denied'
          ? 'Permission denied. Please check Firestore Rules.'
          : e.code == 'unavailable'
              ? 'Network unavailable. Please try again.'
              : e.message ?? 'Unable to save details.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Details'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  32,
                ),
                children: [
                  const SizedBox(height: 8),

                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: DojoPartnerTheme.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 24),

                  TextFormField(
                    controller: _nameController,
                    enabled: !_isSaving,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      final name = value?.trim() ?? '';

                      if (name.length < 3) {
                        return 'Enter your full name';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _phoneController,
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),

                  const SizedBox(height: 20),

                  InkWell(
                    onTap: _isSaving ? null : _selectDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth *',
                        prefixIcon:
                            Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        _dateOfBirth == null
                            ? 'Select date'
                            : '${_dateOfBirth!.day.toString().padLeft(2, '0')}/'
                              '${_dateOfBirth!.month.toString().padLeft(2, '0')}/'
                              '${_dateOfBirth!.year}',
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    value: _gender,
                    decoration: const InputDecoration(
                      labelText: 'Gender (Optional)',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'male',
                        child: Text('Male'),
                      ),
                      DropdownMenuItem(
                        value: 'female',
                        child: Text('Female'),
                      ),
                      DropdownMenuItem(
                        value: 'other',
                        child: Text('Other'),
                      ),
                    ],
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() => _gender = value);
                          },
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _emailController,
                    enabled: !_isSaving,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email (Optional)',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';

                      if (email.isNotEmpty &&
                          !RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(email)) {
                        return 'Enter a valid email address';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _continue,
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text('Save & Continue'),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
