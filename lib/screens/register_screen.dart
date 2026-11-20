
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color forest = Color(0xFF07583C);
  static const Color moss = Color(0xFFEAF4E8);
  static const Color ink = Color(0xFF173329);

  final AuthService _authService = AuthService.instance;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  String _role = 'tenant';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _otpSent = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        role: _role,
      );

      if (!mounted) return;

      setState(() => _otpSent = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent to your email address.'),
          backgroundColor: forest,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().length != 6) {
      _showError('Please enter the 6-digit OTP.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.verifyEmail(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verified! Please login.'),
          backgroundColor: forest,
        ),
      );

      Navigator.pop(context, _emailController.text.trim());
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);

    try {
      await _authService.resendOtp(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      _otpController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A new OTP has been sent.'),
          backgroundColor: forest,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error.toString().replaceFirst('Exception: ', ''),
        ),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: forest),
      filled: true,
      fillColor: moss.withValues(alpha: 0.45),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(_otpSent ? 'Verify Email' : 'Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _otpSent ? _buildOtpForm() : _buildRegisterForm(),
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),

          const Icon(
            Icons.home_rounded,
            color: forest,
            size: 65,
          ),

          const SizedBox(height: 18),

          const Text(
            'Join RentKhojRKL',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: ink,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Create your account and find your perfect place.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),

          const SizedBox(height: 30),

          const Text('Full Name'),
          const SizedBox(height: 8),

          TextFormField(
            controller: _nameController,
            decoration: _decoration(
              'Enter your full name',
              Icons.person_outline,
            ),
            validator: (value) {
              if (value == null || value.trim().length < 2) {
                return 'Enter your name (at least 2 characters)';
              }
              return null;
            },
          ),

          const SizedBox(height: 18),

          const Text('Email Address'),
          const SizedBox(height: 8),

          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _decoration(
              'Enter your email',
              Icons.email_outlined,
            ),
            validator: (value) {
              if (value == null ||
                  !RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                      .hasMatch(value.trim())) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),

          const SizedBox(height: 18),

          const Text('Phone Number'),
          const SizedBox(height: 8),

          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            decoration: _decoration(
              '10-digit mobile number',
              Icons.phone_outlined,
            ),
            validator: (value) {
              if (value == null ||
                  !RegExp(r'^[6-9][0-9]{9}$').hasMatch(value.trim())) {
                return 'Enter a valid 10-digit Indian mobile number';
              }
              return null;
            },
          ),

          const SizedBox(height: 18),

          const Text('Password'),
          const SizedBox(height: 8),

          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: _decoration(
              'Create a password',
              Icons.lock_outline,
            ).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: forest,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.length < 8) {
                return 'Password must contain at least 8 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 22),

          const Text(
            'I want to register as',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _roleCard(
                  title: 'Tenant',
                  subtitle: 'Find a home',
                  icon: Icons.person_search,
                  value: 'tenant',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _roleCard(
                  title: 'Owner',
                  subtitle: 'List properties',
                  icon: Icons.home_work_outlined,
                  value: 'owner',
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: forest,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final selected = _role == value;

    return InkWell(
      onTap: () => setState(() => _role = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? moss : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? forest : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: forest, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            Radio<String>(
              value: value,
              groupValue: _role,
              activeColor: forest,
              onChanged: (v) {
                if (v != null) setState(() => _role = v);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 45),

        const Icon(
          Icons.mark_email_read_outlined,
          color: forest,
          size: 75,
        ),

        const SizedBox(height: 24),

        const Text(
          'Verify your email',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: ink,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'We have sent a 6-digit verification code to ${_emailController.text.trim()}.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),

        const SizedBox(height: 35),

        TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          style: const TextStyle(
            fontSize: 25,
            letterSpacing: 12,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: '------',
            counterText: '',
            filled: true,
            fillColor: moss,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 25),

        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: forest,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Verify Email',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 15),

        TextButton(
          onPressed: _isLoading ? null : _resendOtp,
          child: const Text(
            'Resend OTP',
            style: TextStyle(
              color: forest,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
