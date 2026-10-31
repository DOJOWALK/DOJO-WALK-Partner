import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme.dart';
import 'otp_screen.dart';
import 'account_check_screen.dart';

class MobileLoginScreen extends StatefulWidget {
  const MobileLoginScreen({super.key});

  @override
  State<MobileLoginScreen> createState() => _MobileLoginScreenState();
}

class _MobileLoginScreenState extends State<MobileLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _autoVerificationCompleted = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = '+91${_phoneController.text.trim()}';

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),

        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            _autoVerificationCompleted = true;

            if (!mounted) return;

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(
                builder: (_) => AccountCheckScreen(phoneNumber: phone),
              ),
              (route) => false,
            );
          } on FirebaseAuthException catch (e) {
            if (!mounted) return;

            setState(() {
              _isLoading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  e.message ?? 'Automatic verification failed.',
                ),
              ),
            );
          }
        },

        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;

          setState(() {
            _isLoading = false;
          });

          String message = 'Unable to send OTP. Please try again.';

          if (e.code == 'invalid-phone-number') {
            message = 'Enter a valid mobile number.';
          } else if (e.code == 'too-many-requests') {
            message = 'Too many attempts. Please try again later.';
          } else if (e.message != null) {
            message = e.message!;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        },

        codeSent: (String verificationId, int? resendToken) {
          if (!mounted || _autoVerificationCompleted) return;

          setState(() {
            _isLoading = false;
          });

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpScreen(
                phoneNumber: phone,
                verificationId: verificationId,
                resendToken: resendToken,
              ),
            ),
          );
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          // Firebase OTP auto-retrieval timeout.
        },
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Something went wrong.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DojoPartnerTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 380,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Centered DOJO Partner branding.
                          Column(
                            children: [
                              Container(
                                width: 66,
                                height: 66,
                                decoration: BoxDecoration(
                                  color: DojoPartnerTheme.primaryOrange,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.pets_rounded,
                                  color: Colors.white,
                                  size: 35,
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'DOJO',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: DojoPartnerTheme.primaryOrange,
                                  fontSize: 34,
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 4,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 42),

                          const Text(
                            'Welcome to DOJO 👋',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                              color: DojoPartnerTheme.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            'Your dog-walking journey starts here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: DojoPartnerTheme.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 32),

                          const Text(
                            'Mobile number',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: DojoPartnerTheme.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 10),

                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            enabled: !_isLoading,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: 'Enter mobile number',
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 14, right: 10),
                                child: Center(
                                  widthFactor: 1,
                                  child: Text(
                                    '+91',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: DojoPartnerTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 68,
                              ),
                              filled: true,
                              fillColor: DojoPartnerTheme.background,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
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
                              final phone = value?.trim() ?? '';

                              if (phone.isEmpty) {
                                return 'Enter your mobile number';
                              }

                              if (!RegExp(r'^[6-9][0-9]{9}$')
                                  .hasMatch(phone)) {
                                return 'Enter a valid 10-digit mobile number';
                              }

                              return null;
                            },
                            onFieldSubmitted: (_) {
                              if (!_isLoading) _continue();
                            },
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            "We'll send an OTP to verify your number.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: DojoPartnerTheme.textSecondary,
                            ),
                          ),

                          const SizedBox(height: 24),

                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _continue,
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
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 23,
                                      height: 23,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Send OTP',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text(
                                'New to DOJO? ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: DojoPartnerTheme.textSecondary,
                                ),
                              ),
                              Text(
                                'Join as a Partner',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: DojoPartnerTheme.primaryOrange,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 36),

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
