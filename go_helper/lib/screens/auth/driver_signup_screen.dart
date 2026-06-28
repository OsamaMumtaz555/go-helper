import 'package:flutter/material.dart';
import 'package:go_helper/screens/auth/driver_pending_screen.dart';
import 'package:go_helper/services/auth_service.dart';
import 'package:go_helper/utils/constants/colors.dart';

// This screen is specifically for Partners (Drivers/Mechanics) who want to work with the app
class DriverSignupScreen extends StatefulWidget {
  const DriverSignupScreen({super.key});

  @override
  State<DriverSignupScreen> createState() => _DriverSignupScreenState();
}

class _DriverSignupScreenState extends State<DriverSignupScreen> {
  bool _agreeToPolicies = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  String _selectedServiceType = 'mechanic';
  final List<String> _serviceTypes = ['mechanic', 'courier'];

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  static List<BoxShadow> get _dropShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 4),
      spreadRadius: 1,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final borderRadius = screenWidth * 0.05;
    final fieldSpacing = screenHeight * 0.02;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Join as Partner'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.07,
            vertical: 10,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Become a GoHelper Partner',
                  style: TextStyle(
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeight.bold,
                    color: HColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Earn money by helping others',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),

                _buildTextField(
                  controller: _fullNameController,
                  labelText: 'Full Name',
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  borderRadius: borderRadius,
                  validator: (value) => (value?.isEmpty ?? true) ? 'Required' : null,
                ),
                SizedBox(height: fieldSpacing),

                _buildTextField(
                  controller: _emailController,
                  labelText: 'Email Address',
                  keyboardType: TextInputType.emailAddress,
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  borderRadius: borderRadius,
                  validator: (value) => (value?.isEmpty ?? true) ? 'Required' : null,
                ),
                SizedBox(height: fieldSpacing),

                _buildTextField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  borderRadius: borderRadius,
                  validator: (value) => (value?.isEmpty ?? true) ? 'Required' : null,
                ),
                SizedBox(height: fieldSpacing),

                // Service Type Dropdown
                _buildDropdown(screenWidth, borderRadius),
                SizedBox(height: fieldSpacing),

                _buildTextField(
                  controller: _vehicleModelController,
                  labelText: 'Vehicle Model (e.g. Toyota Corolla)',
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  borderRadius: borderRadius,
                  validator: (value) => (value?.isEmpty ?? true) ? 'Required' : null,
                ),
                SizedBox(height: fieldSpacing),

                _buildTextField(
                  controller: _licensePlateController,
                  labelText: 'License Plate (e.g. ABC-123)',
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  borderRadius: borderRadius,
                  validator: (value) => (value?.isEmpty ?? true) ? 'Required' : null,
                ),
                SizedBox(height: fieldSpacing),

                _buildPasswordField(
                  controller: _passwordController,
                  labelText: 'Password',
                  obscureText: _obscurePassword,
                  onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                  borderRadius: borderRadius,
                  validator: (value) => (value?.length ?? 0) < 6 ? 'Min 6 chars' : null,
                ),
                SizedBox(height: screenHeight * 0.03),

                Row(
                  children: [
                    Checkbox(
                      value: _agreeToPolicies,
                      onChanged: (value) => setState(() => _agreeToPolicies = value!),
                      activeColor: HColors.primary,
                    ),
                    const Expanded(
                      child: Text('I agree to the Terms & Partner Policies'),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.04),

                SizedBox(
                  width: screenWidth * 0.7,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUpAsDriver,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                      ),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Register as Partner', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    required double screenWidth,
    required double screenHeight,
    required double borderRadius,
    FormFieldValidator<String>? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: _dropShadow,
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(borderRadius), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String labelText,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required double screenWidth,
    required double screenHeight,
    required double borderRadius,
    FormFieldValidator<String>? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: _dropShadow,
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: labelText,
          suffixIcon: IconButton(
            icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility),
            onPressed: onToggleVisibility,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(borderRadius), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdown(double screenWidth, double borderRadius) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: _dropShadow,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          initialValue: _selectedServiceType,
          items: _serviceTypes.map((type) => DropdownMenuItem(
            value: type,
            child: Text(type.toUpperCase()),
          )).toList(),
          onChanged: (value) => setState(() => _selectedServiceType = value!),
          decoration: const InputDecoration(
            labelText: 'Specialization',
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  // This logic registers the partner and saves their vehicle info in the database
  Future<void> _signUpAsDriver() async {
    // 1. Verify all fields are correct
    if (!_formKey.currentState!.validate()) return;
    
    // 2. Check if the user agreed to the rules
    if (!_agreeToPolicies) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please agree to policies')));
      return;
    }

    // 3. Start the loading animation
    setState(() => _isLoading = true);

    try {
      // 4. Create the partner account with vehicle and service info
      final user = await AuthService().signUpDriver(
        email: _emailController.text,
        password: _passwordController.text,
        fullName: _fullNameController.text,
        phone: _phoneController.text,
        vehicleModel: _vehicleModelController.text,
        licensePlate: _licensePlateController.text,
        serviceType: _selectedServiceType,
      );

      if (user != null && mounted) {
        // 5. Sign out the driver — they cannot use the app until approved
        await AuthService().signOut();

        // 6. Navigate to the pending approval screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const DriverPendingScreen(status: 'pending'),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      // 7. Report any errors (like invalid email)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      // 8. Done!
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
