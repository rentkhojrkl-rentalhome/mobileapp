
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/requirements_service.dart';

class NeedRoomScreen extends StatefulWidget {
  const NeedRoomScreen({super.key});

  @override
  State<NeedRoomScreen> createState() => _NeedRoomScreenState();
}

class _NeedRoomScreenState extends State<NeedRoomScreen> {
  final _formKey = GlobalKey<FormState>();

  final _areaController = TextEditingController();
  final _budgetController = TextEditingController();
  final _notesController = TextEditingController();

  String _roomType = 'Single Room';
  String _moveIn = 'Immediately';
  String _furnishing = 'Any';

  bool _isSubmitting = false;

  final List<String> _roomTypes = [
    'Single Room',
    'Shared Room',
    'Room',
    'Flat',
    'PG',
    '1 BHK',
  ];

  final List<String> _moveInOptions = [
    'Immediately',
    'Within 15 days',
    'Within a month',
    'Flexible',
  ];

  final List<String> _furnishingOptions = [
    'Any',
    'Furnished',
    'Semi-furnished',
    'Unfurnished',
  ];

  @override
  void dispose() {
    _areaController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitRequirement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await RequirementsService.createRequirement(
        roomType: _roomType,
        area: _areaController.text.trim(),
        monthlyBudget: int.parse(_budgetController.text.trim()),
        moveIn: _moveIn,
        furnishing: _furnishing,
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Room requirement posted successfully!'),
          backgroundColor: AppTheme.forest,
        ),
      );

      _areaController.clear();
      _budgetController.clear();
      _notesController.clear();

      setState(() {
        _roomType = 'Single Room';
        _moveIn = 'Immediately';
        _furnishing = 'Any';
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to post requirement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.forest),
      filled: true,
      fillColor: AppTheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppTheme.forest,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: _inputDecoration(label, icon),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) =>
          value == null ? 'Please select $label' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'I Need a Room',
          style: TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.ink,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.moss,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.home_work_outlined,
                        color: AppTheme.forest,
                        size: 34,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Tell us what you need',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.ink,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Share your room preferences and find '
                        'properties that match your budget.',
                        style: TextStyle(
                          color: AppTheme.ink,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Room Preferences',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 14),

                _buildDropdown(
                  label: 'Room Type',
                  icon: Icons.bed_outlined,
                  value: _roomType,
                  items: _roomTypes,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _roomType = value);
                    }
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _areaController,
                  decoration: _inputDecoration(
                    'Preferred Area (e.g. Sector 3)',
                    Icons.location_on_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 2) {
                      return 'Please enter your preferred area';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    'Monthly Budget (₹)',
                    Icons.currency_rupee,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your monthly budget';
                    }

                    final budget = int.tryParse(value.trim());

                    if (budget == null || budget <= 0) {
                      return 'Enter a valid budget';
                    }

                    if (budget > 1000000) {
                      return 'Maximum budget is ₹10,00,000';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                _buildDropdown(
                  label: 'When do you need it?',
                  icon: Icons.calendar_month_outlined,
                  value: _moveIn,
                  items: _moveInOptions,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _moveIn = value);
                    }
                  },
                ),

                const SizedBox(height: 16),

                _buildDropdown(
                  label: 'Furnishing Preference',
                  icon: Icons.chair_outlined,
                  value: _furnishing,
                  items: _furnishingOptions,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _furnishing = value);
                    }
                  },
                ),

                const SizedBox(height: 24),

                const Text(
                  'Additional Information',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: _inputDecoration(
                    'Additional Notes (Optional)',
                    Icons.notes_outlined,
                  ).copyWith(
                    alignLabelWithHint: true,
                    hintText: 'Anything else you want to mention?',
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed:
                        _isSubmitting ? null : _submitRequirement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.forest,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppTheme.forest
                          .withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Submit Requirement',
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
        ),
      ),
    );
  }
}
