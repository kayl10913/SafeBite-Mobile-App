import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'services/user_service.dart';
import 'loginscreen.dart';

// SignUpScreen: Allows the user to create a new account
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _userService = UserService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _acceptPrivacy = false;
  bool _hasReadTerms = false;
  bool _hasReadPrivacy = false;

  late TapGestureRecognizer _termsRecognizer;
  late TapGestureRecognizer _privacyRecognizer;

  // Base URL for the Express backend (use 10.0.2.2 for Android emulator)
  static const String baseUrl = 'http://192.168.100.128:3000/api';
  // Base URL for the Express backend when running on a website or local browser
  static const String websiteBaseUrl = 'http://localhost:3000/api';

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () {
        _showPolicyDialog(
          'Terms and Conditions',
          '''Welcome to SafeBite!

By using this application, you agree to the following terms:

1. You will use the app for lawful purposes only.
2. You are responsible for the accuracy of the information you provide.
3. SafeBite is not liable for any damages resulting from the use of this app.
4. You agree not to misuse or attempt to disrupt the service.
5. These terms may be updated at any time. Continued use of the app means you accept the new terms.

For the full terms, please visit our website or contact support.
''',
          () {
            setState(() {
              _hasReadTerms = true;
            });
          },
        );
      };
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () {
        _showPolicyDialog(
          'Data Privacy Policy',
          '''SafeBite Privacy Policy

We value your privacy. By using this app, you consent to our data practices:

1. We collect your email, username, and contact number for account creation.
2. Your data is stored securely and is not shared with third parties except as required by law.
3. You may request deletion of your account and data at any time.
4. We use your information to provide and improve our services.
5. This policy may change. Continued use of the app means you accept the new policy.

For more details, please visit our website or contact support.
''',
          () {
            setState(() {
              _hasReadPrivacy = true;
            });
          },
        );
      };
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if backend is available
      bool isBackendAvailable = await _userService.isBackendAvailable();
      if (!isBackendAvailable) {
        _showErrorDialog('Connection Error', 'Cannot connect to server. Please make sure the backend is running.');
        return;
      }

      final result = await _userService.registerUser(
  email: _emailController.text.trim(),
  password: _passwordController.text,
  confirmPassword: _confirmPasswordController.text,
  firstName: _firstNameController.text.trim(),
  lastName: _lastNameController.text.trim(),
  username: _usernameController.text.trim(),
  contact_number: _phoneNumberController.text.trim(), 
  acceptTerms: _acceptTerms,
  acceptPrivacy: _acceptPrivacy,
);

      if (result['success']) {
        _showSuccessDialog('Success', result['message']);
        // Clear form after successful registration
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _firstNameController.clear();
        _lastNameController.clear();
        _usernameController.clear();
        _phoneNumberController.clear();
        setState(() {
          _acceptTerms = false;
          _acceptPrivacy = false;
        });
      } else {
        _showErrorDialog('Registration Failed', result['message']);
      }
    } catch (e) {
      _showErrorDialog('Error', 'An unexpected error occurred: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Redirect to login screen after successful registration
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showPolicyDialog(String title, String content, VoidCallback onAgree) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(content)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onAgree();
              },
              child: const Text('Agree'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003366),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App logo
                  const SizedBox(height: 24),
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                      children: [
                        TextSpan(
                          text: 'Safe',
                          style: TextStyle(color: Colors.white),
                        ),
                        TextSpan(
                          text: 'Bite',
                          style: TextStyle(color: Color(0xFF7FA6C9)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  const Text(
                    'Sign Up',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // User Details Card
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'User Details',
                            style: TextStyle(
                              color: Color(0xFF003366),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildIconTextField(
                                  controller: _firstNameController,
                                  hint: 'First Name',
                                  icon: Icons.person,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Enter first name';
                                    }
                                    if (!_userService.isValidName(value)) {
                                      return 'Min 2 letters';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildIconTextField(
                                  controller: _lastNameController,
                                  hint: 'Last Name',
                                  icon: Icons.person,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Enter last name';
                                    }
                                    if (!_userService.isValidName(value)) {
                                      return 'Min 2 letters';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildIconTextField(
                            controller: _usernameController,
                            hint: 'Username',
                            icon: Icons.alternate_email,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter username';
                              }
                              if (!_userService.isValidUsername(value)) {
                                return 'Min 3 chars, letters/numbers/_';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildIconTextField(
                            controller: _emailController,
                            hint: 'Email',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter email';
                              }
                              if (!_userService.isValidEmail(value)) {
                                return 'Invalid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildIconTextField(
                            controller: _phoneNumberController,
                            hint: 'Contact Number',
                            icon: Icons.phone,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter contact number';
                              }
                              if (!_userService.isValidPhoneNumber(value)) {
                                return 'Invalid number';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Password Card
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Update Password',
                            style: TextStyle(
                              color: Color(0xFF003366),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildIconPasswordField(
                            controller: _passwordController,
                            hint: 'New Password',
                            icon: Icons.lock,
                            obscure: _obscurePassword,
                            toggle: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter password';
                              }
                              if (!_userService.isValidPassword(value)) {
                                return 'Min 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildIconPasswordField(
                            controller: _confirmPasswordController,
                            hint: 'Confirm New Password',
                            icon: Icons.lock,
                            obscure: _obscureConfirmPassword,
                            toggle: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Confirm password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Agreements
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Agreements',
                            style: TextStyle(
                              color: Color(0xFF003366),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center, // <-- This centers the checkbox with the text
                              children: [
                                Checkbox(
                                  value: _acceptTerms,
                                  onChanged: _hasReadTerms
                                      ? (bool? value) {
                                          setState(() {
                                            _acceptTerms = value ?? false;
                                          });
                                        }
                                      : null,
                                  activeColor: Color(0xFF7FA6C9),
                                  checkColor: Colors.white,
                                  materialTapTargetSize: MaterialTapTargetSize.padded,
                                  visualDensity: VisualDensity(horizontal: 0, vertical: 0), // optional: default density
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                Expanded(
                                  child: Opacity(
                                    opacity: _hasReadTerms ? 1.0 : 0.5,
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(color: Color(0xFF003366), fontSize: 14),
                                        children: [
                                          TextSpan(text: 'I accept the '),
                                          TextSpan(
                                            text: 'Terms and Conditions',
                                            style: TextStyle(
                                              color: Color(0xFF2196F3),
                                              decoration: TextDecoration.underline,
                                            ),
                                            recognizer: _termsRecognizer,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center, // <-- This centers the checkbox with the text
                              children: [
                                Checkbox(
                                  value: _acceptPrivacy,
                                  onChanged: _hasReadPrivacy
                                      ? (bool? value) {
                                          setState(() {
                                            _acceptPrivacy = value ?? false;
                                          });
                                        }
                                      : null, // disables the checkbox if not read
                                  activeColor: Color(0xFF7FA6C9),
                                  checkColor: Colors.white,
                                  materialTapTargetSize: MaterialTapTargetSize.padded,
                                  visualDensity: VisualDensity(horizontal: 0, vertical: 0), // optional: default density
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                Expanded(
                                  child: Opacity(
                                    opacity: _hasReadPrivacy ? 1.0 : 0.5,
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(color: Color(0xFF003366), fontSize: 14),
                                        children: [
                                          TextSpan(text: 'I accept the '),
                                          TextSpan(
                                            text: 'Data Privacy Policy',
                                            style: TextStyle(
                                              color: Color(0xFF2196F3),
                                              decoration: TextDecoration.underline,
                                            ),
                                            recognizer: _privacyRecognizer,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign Up Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 2,
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _isLoading ? null : _signUp,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Sign Up'),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Color(0xFF003366)),
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Color(0xFF2196F3)),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF2196F3)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildIconPasswordField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscure,
    required VoidCallback toggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Color(0xFF003366)),
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Color(0xFF2196F3)),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility : Icons.visibility_off,
            color: Color(0xFF2196F3),
          ),
          onPressed: toggle,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF2196F3)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
} 