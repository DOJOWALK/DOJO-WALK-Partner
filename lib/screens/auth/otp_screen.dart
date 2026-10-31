import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme.dart';
import 'account_check_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
  });

  final String phoneNumber;
  final String verificationId;
  final int? resendToken;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  bool _isVerifying = false;
  bool _isResending = false;
  bool _autoVerificationCompleted = false;
  late String _verificationId;
  int? _resendToken;
  int _resendSeconds = 30;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _resendToken = widget.resendToken;
    _startResendCooldown();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _resendOtp() async {
    if (_isVerifying || _isResending || _resendSeconds > 0) return;
    setState(() => _isResending = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            _autoVerificationCompleted = true;
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(
                builder: (_) =>
                    AccountCheckScreen(phoneNumber: widget.phoneNumber),
              ),
              (route) => false,
            );
          } on FirebaseAuthException catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.message ?? 'Automatic verification failed.'),
              ),
            );
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          final message = e.code == 'too-many-requests'
              ? 'Too many attempts. Please try again later.'
              : e.message ?? 'Unable to resend OTP. Please try again.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted || _autoVerificationCompleted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _otpController.clear();
          });
          _startResendCooldown();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A new OTP has been sent.')),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (!mounted || _autoVerificationCompleted) return;
          setState(() => _verificationId = verificationId);
        },
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = e.code == 'too-many-requests'
          ? 'Too many attempts. Please try again later.'
          : e.message ?? 'Unable to resend OTP. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;

    if (_verificationId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verification session expired. Please request OTP again.',
          ),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isVerifying = true;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AccountCheckScreen(
            phoneNumber: widget.phoneNumber,
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String message = 'OTP verification failed. Please try again.';

      if (e.code == 'invalid-verification-code') {
        message = 'Incorrect OTP. Please check and try again.';
      } else if (e.code == 'session-expired') {
        message = 'OTP expired. Please request a new OTP.';
      } else if (e.code == 'invalid-verification-id') {
        message = 'Verification session is invalid. Please go back.';
      } else if (e.code == 'too-many-requests') {
        message = 'Too many attempts. Please try again later.';
      } else if (e.message != null) {
        message = e.message!;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DojoPartnerTheme.background,
      appBar: AppBar(
        backgroundColor: DojoPartnerTheme.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Go back',
          onPressed: _isVerifying
              ? null
              : () => Navigator.maybePop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: DojoPartnerTheme.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Centered DOJO PARTNER branding.
                          Column(
                            children: [
                              Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  color: DojoPartnerTheme.primaryOrange,
                                  borderRadius: BorderRadius.circular(19),
                                ),
                                child: const Icon(
                                  Icons.pets_rounded,
                                  color: Colors.white,
                                  size: 33,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'DOJO',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: DojoPartnerTheme.primaryOrange,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'PARTNER',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: DojoPartnerTheme.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 4,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 38),

                          const Icon(
                            Icons.mark_email_read_outlined,
                            size: 46,
                            color: DojoPartnerTheme.primaryOrange,
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            'Verify your number',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              color: DojoPartnerTheme.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            'Enter the 6-digit verification code sent to',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: DojoPartnerTheme.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            widget.phoneNumber,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: DojoPartnerTheme.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 30),

                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            enabled: !_isVerifying,
                            autofocus: true,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 12,
                              color: DojoPartnerTheme.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: '• • • • • •',
                              hintStyle: const TextStyle(
                                fontSize: 21,
                                letterSpacing: 5,
                                color: Color(0xFFBDBDBD),
                              ),
                              filled: true,
                              fillColor: DojoPartnerTheme.background,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: DojoPartnerTheme.border,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: DojoPartnerTheme.border,
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
                                borderSide: const BorderSide(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                            validator: (value) {
                              final otp = value?.trim() ?? '';

                              if (otp.isEmpty) {
                                return 'Enter the OTP';
                              }

                              if (!RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
                                return 'Enter all 6 digits';
                              }

                              return null;
                            },
                            onFieldSubmitted: (_) {
                              if (!_isVerifying) _verify();
                            },
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            'Please do not share your OTP with anyone.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: DojoPartnerTheme.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Center(
                            child: TextButton(
                              onPressed: _isVerifying ||
                                      _isResending ||
                                      _resendSeconds > 0
                                  ? null
                                  : _resendOtp,
                              child: _isResending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _resendSeconds > 0
                                          ? 'Resend OTP in ${_resendSeconds}s'
                                          : 'Resend OTP',
                                      style: const TextStyle(
                                        color:
                                            DojoPartnerTheme.primaryOrange,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          const SizedBox(height: 24),

                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isVerifying ? null : _verify,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    DojoPartnerTheme.primaryOrange,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    DojoPartnerTheme.primaryOrange
                                        .withValues(alpha: 0.6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isVerifying
                                  ? const SizedBox(
                                      width: 23,
                                      height: 23,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Verify & Continue',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          Center(
                            child: TextButton(
                              onPressed: _isVerifying
                                  ? null
                                  : () => Navigator.maybePop(context),
                              child: const Text(
                                'Go back to change number',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: DojoPartnerTheme.primaryOrange,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

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
              ),
            );
          },
        ),
      ),
    );
  }
}
