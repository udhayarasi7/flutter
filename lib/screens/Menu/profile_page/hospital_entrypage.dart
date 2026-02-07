import 'package:flutter/material.dart';
import 'package:firstapp/service/register_hospital_statues_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';

class HospitalEntryPage extends StatefulWidget {
  const HospitalEntryPage({Key? key}) : super(key: key);

  @override
  State<HospitalEntryPage> createState() => _HospitalEntryPageState();
}

class _HospitalEntryPageState extends State<HospitalEntryPage>
    with TickerProviderStateMixin {
  final _hospitalNameController = TextEditingController();
  final _hospitalAddressController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final RegisterHospitalService _hospitalService = RegisterHospitalService();

  bool _isChecked = false;
  bool _isSubmitting = false;
  File? _licenseFile;
  File? _certificateFile;
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;

  // Animation controllers for blobs
  late AnimationController _topRightController;
  late AnimationController _topRightSmallController;
  late AnimationController _bottomLeftController;
  late AnimationController _bottomLeftSmallController;
  late AnimationController _bottomRightController;

  late Animation<Offset> _topRightAnimation;
  late Animation<Offset> _topRightSmallAnimation;
  late Animation<Offset> _bottomLeftAnimation;
  late Animation<Offset> _bottomLeftSmallAnimation;
  late Animation<Offset> _bottomRightAnimation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();

    // Top right large blob
    _topRightController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _topRightAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(-15, 10),
    ).animate(CurvedAnimation(
        parent: _topRightController, curve: Curves.easeInOut));

    // Top right small blob
    _topRightSmallController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _topRightSmallAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(10, -15),
    ).animate(CurvedAnimation(
        parent: _topRightSmallController, curve: Curves.easeInOut));

    // Bottom left large blob
    _bottomLeftController = AnimationController(
      duration: const Duration(seconds: 3, milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    _bottomLeftAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(12, -18),
    ).animate(CurvedAnimation(
        parent: _bottomLeftController, curve: Curves.easeInOut));

    // Bottom left small blob
    _bottomLeftSmallController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _bottomLeftSmallAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(-8, 12),
    ).animate(CurvedAnimation(
        parent: _bottomLeftSmallController, curve: Curves.easeInOut));

    // Bottom right blob
    _bottomRightController = AnimationController(
      duration: const Duration(seconds: 3, milliseconds: 200),
      vsync: this,
    )..repeat(reverse: true);
    _bottomRightAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(-12, -15),
    ).animate(CurvedAnimation(
        parent: _bottomRightController, curve: Curves.easeInOut));
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Animated top right large blob
          AnimatedBuilder(
            animation: _topRightAnimation,
            builder: (context, child) {
              return Positioned(
                top: -30 + _topRightAnimation.value.dy,
                right: -20 + _topRightAnimation.value.dx,
                child: _buildBlob(120, Colors.cyan.shade300),
              );
            },
          ),

          // Animated top right small blob
          AnimatedBuilder(
            animation: _topRightSmallAnimation,
            builder: (context, child) {
              return Positioned(
                top: 80 + _topRightSmallAnimation.value.dy,
                right: 80 + _topRightSmallAnimation.value.dx,
                child: _buildBlob(80, Colors.blue.shade400),
              );
            },
          ),

          // Animated bottom left large blob
          AnimatedBuilder(
            animation: _bottomLeftAnimation,
            builder: (context, child) {
              return Positioned(
                bottom: -40 + _bottomLeftAnimation.value.dy,
                left: -60 + _bottomLeftAnimation.value.dx,
                child: _buildBlob(180, Colors.cyan.shade200),
              );
            },
          ),

          // Animated bottom left small blob
          AnimatedBuilder(
            animation: _bottomLeftSmallAnimation,
            builder: (context, child) {
              return Positioned(
                bottom: 80 + _bottomLeftSmallAnimation.value.dy,
                left: 80 + _bottomLeftSmallAnimation.value.dx,
                child: _buildBlob(100, Colors.blue.shade300),
              );
            },
          ),

          // Animated bottom right blob
          AnimatedBuilder(
            animation: _bottomRightAnimation,
            builder: (context, child) {
              return Positioned(
                bottom: 150 + _bottomRightAnimation.value.dy,
                right: -30 + _bottomRightAnimation.value.dx,
                child: _buildBlob(140, Colors.blue.shade400),
              );
            },
          ),

          // Main content
          Column(
            children: [
              // Blue header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Register Hospital',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Access admin features',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Verification info card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.verified_outlined,
                                color: Colors.blue.shade700,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hospital Verification',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Submit your hospital documents for verification. Once approved, you\'ll get access to admin dashboard for managing emergencies.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.blue.shade800,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Hospital Details Section
                        const Text(
                          'Hospital Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Hospital Name field
                        const Text(
                          'Hospital Name *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _hospitalNameController,
                          decoration: InputDecoration(
                            hintText: 'City General Hospital',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Hospital Address field
                        const Text(
                          'Hospital Address *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _hospitalAddressController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: '123 Medical Center Drive, New York, NY 10001',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Contact Number field
                        const Text(
                          'Contact Number *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Text(
                                '+ 91',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _contactNumberController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: '9876543210',
                                  hintStyle: TextStyle(color: Colors.grey.shade400),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Location Section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _latitude != null ? Colors.green.shade50 : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _latitude != null ? Colors.green.shade200 : Colors.orange.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _latitude != null ? Icons.location_on : Icons.location_off,
                                color: _latitude != null ? Colors.green.shade700 : Colors.orange.shade700,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _latitude != null ? 'Location Captured' : 'Capturing Location...',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: _latitude != null ? Colors.green.shade900 : Colors.orange.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _latitude != null
                                          ? 'Lat: ${_latitude!.toStringAsFixed(4)}, Lng: ${_longitude!.toStringAsFixed(4)}'
                                          : 'Required for emergency notifications',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _latitude != null ? Colors.green.shade800 : Colors.orange.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isLoadingLocation)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              else if (_latitude == null)
                                IconButton(
                                  onPressed: _getCurrentLocation,
                                  icon: const Icon(Icons.refresh),
                                  color: Colors.orange.shade700,
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Required Documents Section
                        const Text(
                          'Required Documents',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Hospital License Proof
                        const Text(
                          'Hospital License Proof *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildUploadBox('Hospital License Proof', _licenseFile, (file) {
                          setState(() => _licenseFile = file);
                        }),

                        const SizedBox(height: 20),

                        // Registration Certificate
                        const Text(
                          'Registration Certificate *',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildUploadBox('Registration Certificate', _certificateFile, (file) {
                          setState(() => _certificateFile = file);
                        }),

                        const SizedBox(height: 24),

                        // Confirmation checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _isChecked,
                              onChanged: (value) {
                                setState(() {
                                  _isChecked = value ?? false;
                                });
                              },
                              activeColor: Colors.blue.shade700,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text(
                                  'I confirm that all the information provided is accurate and I have the authority to register this hospital on LifeLine Local platform.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_isChecked && !_isSubmitting)
                                ? _submitHospitalRegistration
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              disabledBackgroundColor: Colors.grey.shade300,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Submit for Verification',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Verification time info
                        Center(
                          child: Text(
                            'Verification typically takes 24-48 hours. You\'ll be notified once approved.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
    );
  }

  Future<void> _submitHospitalRegistration() async {
    if (_hospitalNameController.text.trim().isEmpty ||
        _hospitalAddressController.text.trim().isEmpty ||
        _contactNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (_latitude == null || _longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please wait for location to be captured'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final success = await _hospitalService.submitHospitalRegistration(
        hospitalName: _hospitalNameController.text.trim(),
        hospitalAddress: _hospitalAddressController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hospital registered successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit registration. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildUploadBox(String label, File? file, Function(File?) onFilePicked) {
    return GestureDetector(
      onTap: () async {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        );
        if (result != null) {
          onFilePicked(File(result.files.single.path!));
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        decoration: BoxDecoration(
          color: file != null ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: file != null ? Colors.green.shade300 : Colors.grey.shade300,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              file != null ? Icons.check_circle_outline : Icons.cloud_upload_outlined,
              color: file != null ? Colors.green.shade600 : Colors.grey.shade400,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              file != null ? 'File selected' : 'Click to upload',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: file != null ? Colors.green.shade700 : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              file != null ? file.path.split('/').last : 'PDF, JPG or PNG (max 5MB)',
              style: TextStyle(
                fontSize: 12,
                color: file != null ? Colors.green.shade600 : Colors.grey.shade600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hospitalNameController.dispose();
    _hospitalAddressController.dispose();
    _contactNumberController.dispose();
    _topRightController.dispose();
    _topRightSmallController.dispose();
    _bottomLeftController.dispose();
    _bottomLeftSmallController.dispose();
    _bottomRightController.dispose();
    super.dispose();
  }
}