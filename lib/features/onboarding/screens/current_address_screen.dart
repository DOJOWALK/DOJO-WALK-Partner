import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme.dart';
import 'review_submit_screen.dart';

class CurrentAddressScreen extends StatefulWidget {
  const CurrentAddressScreen({super.key});

  @override
  State<CurrentAddressScreen> createState() =>
      _CurrentAddressScreenState();
}

class _CurrentAddressScreenState
    extends State<CurrentAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  final _houseController = TextEditingController();
  final _streetController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  @override
  void dispose() {
    _houseController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _loadAddress() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('walkers')
          .doc(user.uid)
          .get();

      final data = snapshot.data() ?? {};

      // Read the existing address map without overwriting
      // unrelated walker profile fields.
      final address = data['currentAddress'];

      if (address is Map) {
        _houseController.text =
            address['houseNumber']?.toString() ?? '';
        _streetController.text =
            address['street']?.toString() ?? '';
        _landmarkController.text =
            address['landmark']?.toString() ?? '';
        _cityController.text =
            address['city']?.toString() ?? '';
        _stateController.text =
            address['state']?.toString() ?? '';
        _pinController.text =
            address['pinCode']?.toString() ?? '';
      }

      if (mounted) setState(() => _loading = false);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage(
        e.code == 'permission-denied'
            ? 'Address access denied. Please check Firestore rules.'
            : 'Unable to load address. Please try again.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('Unable to load address. Please try again.');
    }
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  Future<void> _saveAndContinue() async {
    if (_saving) return;

    if (!_formKey.currentState!.validate()) return;

    if (!_confirmed) {
      _showMessage('Please confirm your current address.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('Your session expired. Please log in again.');
      return;
    }

    setState(() => _saving = true);

    try {
      final walkerRef = FirebaseFirestore.instance
          .collection('walkers')
          .doc(user.uid);

      final existing = await walkerRef.get();

      if (!existing.exists) {
        _showMessage(
          'Please complete your Partner profile before saving your address.',
        );
        return;
      }

      await walkerRef.set({
        'currentAddress': {
          'houseNumber': _houseController.text.trim(),
          'street': _streetController.text.trim(),
          'landmark': _landmarkController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'pinCode': _pinController.text.trim(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ReviewSubmitScreen(),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;

      _showMessage(
        e.code == 'permission-denied'
            ? 'Address save denied. Please check Firestore rules.'
            : 'Unable to save address. Please try again.',
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLength = 100,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
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
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator,
            maxLength: maxLength,
            decoration: InputDecoration(
              hintText: hint,
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFE5E5E5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFE5E5E5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: DojoPartnerTheme.primaryOrange,
                  width: 1.5,
                ),
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
        title: const Text('Current Address'),
        centerTitle: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: DojoPartnerTheme.primaryOrange,
                ),
              )
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          const Text(
                            'Where do you currently live?',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: DojoPartnerTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Enter your residential address accurately.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: DojoPartnerTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _field(
                            label: 'House / Flat Number *',
                            hint: 'Enter house or flat number',
                            controller: _houseController,
                            validator: (v) =>
                                _required(v, 'House / Flat Number'),
                          ),
                          _field(
                            label: 'Street / Locality *',
                            hint: 'Enter street or locality',
                            controller: _streetController,
                            validator: (v) =>
                                _required(v, 'Street / Locality'),
                          ),
                          _field(
                            label: 'Landmark',
                            hint: 'Nearby landmark (optional)',
                            controller: _landmarkController,
                          ),
                          _field(
                            label: 'City *',
                            hint: 'Enter city',
                            controller: _cityController,
                            validator: (v) => _required(v, 'City'),
                          ),
                          _field(
                            label: 'State *',
                            hint: 'Enter state',
                            controller: _stateController,
                            validator: (v) => _required(v, 'State'),
                          ),
                          _field(
                            label: 'PIN Code *',
                            hint: 'Enter 6-digit PIN code',
                            controller: _pinController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            validator: (v) {
                              if (v == null ||
                                  !RegExp(r'^\d{6}$')
                                      .hasMatch(v.trim())) {
                                return 'Enter a valid 6-digit PIN code';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 4),
                          CheckboxListTile(
                            value: _confirmed,
                            onChanged: _saving
                                ? null
                                : (value) => setState(
                                      () => _confirmed = value ?? false,
                                    ),
                            activeColor:
                                DojoPartnerTheme.primaryOrange,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity:
                                ListTileControlAffinity.leading,
                            title: const Text(
                              'I confirm that this is my current residential address.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(18),
                      color: Colors.white,
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed:
                              _saving ? null : _saveAndContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                DojoPartnerTheme.primaryOrange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save & Continue',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
