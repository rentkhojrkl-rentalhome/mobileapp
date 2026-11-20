
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/property_service.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _rent = TextEditingController();
  final _deposit = TextEditingController();
  final _area = TextEditingController();
  final _address = TextEditingController();
  final _bedrooms = TextEditingController(text: '1');
  final _bathrooms = TextEditingController(text: '1');

  String propertyType = 'Room';
  String furnishing = 'Unfurnished';
  String tenantPreference = 'Anyone';

  List<File> selectedImages = [];
  bool uploading = false;

  static const forest = AppTheme.forest;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _rent.dispose();
    _deposit.dispose();
    _area.dispose();
    _address.dispose();
    _bedrooms.dispose();
    _bathrooms.dispose();
    super.dispose();
  }

  InputDecoration decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF6F9F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5ECE5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5ECE5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: forest, width: 1.5),
      ),
    );
  }

  Widget textField(
    TextEditingController controller,
    String label, {
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: decoration(label, hint: hint),
      validator: validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter $label';
            }
            return null;
          },
    );
  }

  Widget dropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: decoration(label),
      items: options
          .map(
            (option) => DropdownMenuItem(
              value: option,
              child: Text(option),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Future<void> pickImages() async {
    try {
      final remaining = 10 - selectedImages.length;

      if (remaining <= 0) {
        showMessage('Maximum 10 photos allowed.');
        return;
      }

      final images = await _picker.pickMultiImage(
        imageQuality: 85,
        limit: remaining,
      );

      if (!mounted || images.isEmpty) return;

      final newImages = images.take(remaining).map((image) {
        return File(image.path);
      }).toList();

      setState(() {
        selectedImages.addAll(newImages);
      });
    } catch (e) {
      showMessage('Unable to select photos: $e');
    }
  }

  void removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> submitProperty() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedImages.isEmpty) {
      showMessage('Please select at least one property photo.');
      return;
    }

    final rent = int.tryParse(_rent.text.trim());
    final deposit = int.tryParse(_deposit.text.trim());
    final bedrooms = int.tryParse(_bedrooms.text.trim());
    final bathrooms = int.tryParse(_bathrooms.text.trim());

    if (rent == null || rent <= 0 || rent > 10000000) {
      showMessage('Enter a valid monthly rent.');
      return;
    }

    if (deposit == null || deposit < 0 || deposit > 100000000) {
      showMessage('Enter a valid deposit amount.');
      return;
    }

    if (bedrooms == null || bedrooms < 0 || bedrooms > 50 ||
        bathrooms == null || bathrooms < 0 || bathrooms > 50) {
      showMessage('Enter valid bedroom and bathroom counts.');
      return;
    }

    setState(() => uploading = true);

    try {
      // First upload photos to Cloudinary.
      final imageUrls = await RentKhojApi.uploadPropertyImages(
        selectedImages,
      );

      // Then save property details in MongoDB.
      await RentKhojApi.createProperty({
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'property_type': propertyType,
        'rent': rent,
        'deposit': deposit,
        'area': _area.text.trim(),
        'address': _address.text.trim(),
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'furnishing': furnishing,
        'tenant_preference': tenantPreference,
        'image_urls': imageUrls,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Property submitted successfully!'),
          backgroundColor: forest,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      showMessage('Failed to submit property: $e');
    } finally {
      if (mounted) {
        setState(() => uploading = false);
      }
    }
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: forest,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Add Property'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            sectionTitle('Basic Information'),

            textField(
              _title,
              'Property Title',
              hint: 'Example: Spacious room in Sector 3',
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.length < 5 || text.length > 120) {
                  return 'Title must be 5–120 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            textField(
              _description,
              'Description',
              hint: 'Describe your property and its facilities...',
              maxLines: 5,
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.length < 20 || text.length > 3000) {
                  return 'Description must be 20–3000 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            dropdown(
              'Property Type',
              propertyType,
              ['Room', 'Flat', 'House', 'PG'],
              (value) => setState(() => propertyType = value!),
            ),

            const SizedBox(height: 24),
            sectionTitle('Rent & Location'),

            textField(
              _rent,
              'Monthly Rent (₹)',
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 14),

            textField(
              _deposit,
              'Security Deposit (₹)',
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 14),

            textField(
              _area,
              'Area / Locality',
              hint: 'Example: Sector 3, Rourkela',
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.length < 2 || text.length > 100) {
                  return 'Area must be 2–100 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 14),

            textField(
              _address,
              'Full Address',
              maxLines: 2,
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.length < 5 || text.length > 300) {
                  return 'Address must be 5–300 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),
            sectionTitle('Property Details'),

            Row(
              children: [
                Expanded(
                  child: textField(
                    _bedrooms,
                    'Bedrooms',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: textField(
                    _bathrooms,
                    'Bathrooms',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            dropdown(
              'Furnishing',
              furnishing,
              ['Furnished', 'Semi-furnished', 'Unfurnished'],
              (value) => setState(() => furnishing = value!),
            ),

            const SizedBox(height: 14),

            dropdown(
              'Tenant Preference',
              tenantPreference,
              ['Students', 'Bachelors', 'Family', 'Anyone'],
              (value) => setState(() => tenantPreference = value!),
            ),

            const SizedBox(height: 24),
            sectionTitle('Property Photos'),

            const Text(
              'Add clear photos of your property. Maximum 10 photos, 8 MB each.',
              style: TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 14),

            OutlinedButton.icon(
              onPressed: uploading ? null : pickImages,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: Text('Add Photos (${selectedImages.length}/10)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: forest,
                padding: const EdgeInsets.all(16),
                side: const BorderSide(color: forest),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            if (selectedImages.isNotEmpty) ...[
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: selectedImages.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          selectedImages[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: uploading ? null : () => removeImage(index),
                          child: const CircleAvatar(
                            radius: 13,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],

            const SizedBox(height: 30),

            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: uploading ? null : submitProperty,
                style: ElevatedButton.styleFrom(
                  backgroundColor: forest,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: uploading
                    ? const SizedBox(
                        height: 23,
                        width: 23,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit Property',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
