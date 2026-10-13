
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme.dart';
import '../home/partner_home_screen.dart';
import '../../features/onboarding/screens/work_location_screen.dart';

class AccountCheckScreen extends StatefulWidget {
  const AccountCheckScreen({
    super.key,
    required this.phoneNumber,
  });

  final String phoneNumber;

  @override
  State<AccountCheckScreen> createState() => _AccountCheckScreenState();
}

class _AccountCheckScreenState extends State<AccountCheckScreen> {
  String _message = 'Checking your DOJO Partner account...';
  bool _isChecking = true;
  bool _hasError = false;

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

      // New Partner: begin with State, City, Area and Zones.
      if (!walkerDoc.exists) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const WorkZoneScreen(),
          ),
        );
        return;
      }

      final data = walkerDoc.data() ?? {};

      final status = data['status']?.toString() ?? 'pending';
      final isActive = data['isActive'] == true;
      final isApproved = data['isApproved'] == true;

      // Only approved and active Partners can enter Home.
      if (status == 'approved' && isActive && isApproved) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const PartnerHomeScreen(),
          ),
          (route) => false,
        );
        return;
      }

      if (!mounted) return;

      switch (status) {
        case 'pending':
        case 'under_review':
          _message = 'Your application is under review.';
          break;
        case 'correction_required':
          _message = 'Some information needs correction.';
          break;
        case 'suspended':
          _message = 'Your DOJO Partner account is suspended.';
          break;
        case 'rejected':
          _message = 'Your Partner application was not approved.';
          break;
        case 'left':
          _message = 'This Partner account is inactive.';
          break;
        default:
          _message = 'Your account is being checked by DOJO.';
      }

      setState(() {
        _isChecking = false;
        _hasError = false;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isChecking = false;
        _hasError = true;
        _message = e.message ?? 'Unable to verify your login session.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: DojoPartnerTheme.primaryOrange,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Icon(
                                Icons.pets_rounded,
                                color: Colors.white,
                                size: 38,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'DOJO',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: DojoPartnerTheme.primaryOrange,
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'PARTNER',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 4,
                                color: DojoPartnerTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 44),
                        Container(
                          padding: const EdgeInsets.all(28),
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
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFF3E8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _hasError
                                        ? Icons.error_outline_rounded
                                        : Icons.hourglass_top_rounded,
                                    size: 30,
                                    color: DojoPartnerTheme.primaryOrange,
                                  ),
                                ),
                              const SizedBox(height: 24),
                              Text(
                                _isChecking
                                    ? 'Verifying your account'
                                    : _hasError
                                        ? 'Unable to check account'
                                        : 'Application status',
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
                                  fontSize: 15,
                                  height: 1.6,
                                  color: DojoPartnerTheme.textSecondary,
                                ),
                              ),
                              if (_isChecking) ...[
                                const SizedBox(height: 12),
                                const Text(
                                  'Please wait a moment.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: DojoPartnerTheme.textSecondary,
                                  ),
                                ),
                              ],
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
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(13),
                                      ),
                                    ),
                                    child: const Text(
                                      'Try Again',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'Your partner journey starts here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: DojoPartnerTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Terms  •  Privacy  •  Help',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: DojoPartnerTheme.textSecondary,
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
