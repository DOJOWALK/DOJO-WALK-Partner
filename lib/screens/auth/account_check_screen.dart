import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../features/onboarding/screens/work_location_screen.dart';
import '../../features/onboarding/screens/application_submitted_screen.dart';
import '../home/partner_home_screen.dart';

class AccountCheckScreen extends StatefulWidget {
  const AccountCheckScreen({
    super.key,
    required this.phoneNumber,
  });

  final String phoneNumber;

  @override
  State<AccountCheckScreen> createState() =>
      _AccountCheckScreenState();
}

class _AccountCheckScreenState extends State<AccountCheckScreen> {
  bool _isChecking = true;
  bool _hasError = false;

  String _message = 'Checking your DOJO Partner account...';

  @override
  void initState() {
    super.initState();
    _checkAccount();
  }

  Future<void> _checkAccount() async {
    if (!mounted) return;

    setState(() {
      _isChecking = true;
      _hasError = false;
      _message = 'Checking your DOJO Partner account...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'not-signed-in',
          message: 'Your login session has expired. Please log in again.',
        );
      }

      final walkerRef = FirebaseFirestore.instance
          .collection('walkers')
          .doc(user.uid);

      final walkerDoc = await walkerRef.get();

      if (!mounted) return;

      // New Partner: no application document exists yet.
      if (!walkerDoc.exists) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => const WorkLocationScreen(),
          ),
          (route) => false,
        );
        return;
      }

      final data = walkerDoc.data() ?? <String, dynamic>{};

      final status = (data['status'] ?? 'pending')
          .toString()
          .trim()
          .toLowerCase();

      final isApproved = data['isApproved'] == true;
      final isActive = data['isActive'] == true;

      // Only approved and active Partners can enter Partner Home.
      if (isApproved && isActive && status == 'approved') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => const PartnerHomeScreen(),
          ),
          (route) => false,
        );
        return;
      }

      // All known non-active application states remain outside Home.
      const applicationStatuses = <String>{
        'pending',
        'under_review',
        'correction_required',
        'approved',
        'rejected',
        'suspended',
        'left',
      };

      if (applicationStatuses.contains(status)) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => const ApplicationSubmittedScreen(),
          ),
          (route) => false,
        );
        return;
      }

      // Unknown status: block entry and show a support message.
      setState(() {
        _isChecking = false;
        _hasError = false;
        _message =
            'Your account status needs to be checked by DOJO Support.';
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isChecking = false;
        _hasError = true;
        _message =
            e.message ?? 'Unable to verify your login session.';
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        _isChecking = false;
        _hasError = true;
        _message = e.code == 'permission-denied'
            ? 'Access denied. Please check your Firestore security rules.'
            : 'Unable to connect to DOJO. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isChecking = false;
        _hasError = true;
        _message = 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to log out. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Account Check',
          style: TextStyle(
            color: DojoPartnerTheme.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 380,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: DojoPartnerTheme.primaryOrange,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(
                            Icons.pets_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'DOJO PARTNER',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: DojoPartnerTheme.primaryOrange,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.all(26),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: const Color(0xFFEEEEEE),
                            ),
                          ),
                          child: Column(
                            children: [
                              if (_isChecking)
                                const SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: CircularProgressIndicator(
                                    color: DojoPartnerTheme.primaryOrange,
                                    strokeWidth: 3,
                                  ),
                                )
                              else
                                Icon(
                                  _hasError
                                      ? Icons.error_outline_rounded
                                      : Icons.info_outline_rounded,
                                  color: DojoPartnerTheme.primaryOrange,
                                  size: 46,
                                ),
                              const SizedBox(height: 22),
                              Text(
                                _isChecking
                                    ? 'Verifying your account'
                                    : _hasError
                                        ? 'Unable to check account'
                                        : 'Account status',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: DojoPartnerTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.6,
                                  color: DojoPartnerTheme.textSecondary,
                                ),
                              ),
                              if (_hasError) ...[
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _checkAccount,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          DojoPartnerTheme.primaryOrange,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Try Again',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
