
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/requirements_service.dart';

class MyRequirementsScreen extends StatefulWidget {
  const MyRequirementsScreen({super.key});

  @override
  State<MyRequirementsScreen> createState() =>
      _MyRequirementsScreenState();
}

class _MyRequirementsScreenState extends State<MyRequirementsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _requirements = [];
  final Set<String> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    _loadRequirements();
  }

  Future<void> _loadRequirements() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await RequirementsService.myRequirements();

      if (!mounted) return;

      setState(() {
        _requirements = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _value(dynamic value, [String fallback = 'Not specified']) {
    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }
    return value.toString();
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';

    try {
      final date = DateTime.parse(value.toString()).toLocal();
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _toggleStatus(Map<String, dynamic> requirement) async {
    final id = _value(requirement['id'], '');

    if (id.isEmpty) {
      _showMessage('Requirement ID not found.');
      return;
    }

    final currentStatus = _value(requirement['status'], 'open');
    final newStatus = currentStatus == 'open' ? 'closed' : 'open';

    try {
      await RequirementsService.updateRequirement(
        requirementId: id,
        status: newStatus,
      );

      if (!mounted) return;

      _showMessage(
        newStatus == 'closed'
            ? 'Requirement closed successfully.'
            : 'Requirement reopened successfully.',
      );

      await _loadRequirements();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Unable to update requirement: $e');
    }
  }

  Future<void> _deleteRequirement(Map<String, dynamic> requirement) async {
    final id = _value(requirement['id'], '');

    if (id.isEmpty) {
      _showMessage('Requirement ID not found.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete requirement?'),
        content: const Text(
          'Are you sure you want to delete this room requirement? '
          'It will be removed from your list and matching results.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingIds.add(id));

    try {
      await RequirementsService.deleteRequirement(requirementId: id);

      if (!mounted) return;
      _showMessage('Requirement deleted successfully.');
      await _loadRequirements();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Unable to delete requirement: $e');
    } finally {
      if (mounted) {
        setState(() => _deletingIds.remove(id));
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showMatches(Map<String, dynamic> requirement) async {
    final id = _value(requirement['id'], '');

    if (id.isEmpty) {
      _showMessage('Requirement ID not found.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _MatchingPropertiesSheet(requirementId: id);
      },
    );
  }

  Widget _buildInfo(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.forest),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppTheme.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementCard(Map<String, dynamic> requirement) {
    final status = _value(requirement['status'], 'open');
    final isOpen = status == 'open';
    final createdAt = _formatDate(requirement['created_at']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _value(requirement['room_type']),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isOpen
                      ? Colors.green.withValues(alpha: 0.10)
                      : Colors.grey.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOpen ? 'Open' : 'Closed',
                  style: TextStyle(
                    color: isOpen ? Colors.green.shade700 : Colors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _buildInfo(
            Icons.location_on_outlined,
            'Preferred Area',
            _value(requirement['area']),
          ),
          _buildInfo(
            Icons.currency_rupee,
            'Monthly Budget',
            '₹${_value(requirement['monthly_budget'])}',
          ),
          _buildInfo(
            Icons.calendar_month_outlined,
            'Move In',
            _value(requirement['move_in']),
          ),
          _buildInfo(
            Icons.chair_outlined,
            'Furnishing',
            _value(requirement['furnishing']),
          ),

          if (_value(requirement['notes'], '').isNotEmpty)
            _buildInfo(
              Icons.notes,
              'Notes',
              _value(requirement['notes']),
            ),

          if (createdAt.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Posted on $createdAt',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),

          const SizedBox(height: 16),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 8),

          if (isOpen)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showMatches(requirement),
                icon: const Icon(Icons.home_work_outlined),
                label: const Text('View Matching Properties'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.forest,
                  side: const BorderSide(color: AppTheme.forest),
                ),
              ),
            ),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _deletingIds.contains(_value(requirement['id'], ''))
                  ? null
                  : () => _deleteRequirement(requirement),
              icon: _deletingIds.contains(_value(requirement['id'], ''))
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red,
                      ),
                    )
                  : const Icon(Icons.delete_outline),
              label: Text(
                _deletingIds.contains(_value(requirement['id'], ''))
                    ? 'Deleting...'
                    : 'Delete Requirement',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),

          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _toggleStatus(requirement),
              icon: Icon(
                isOpen ? Icons.close : Icons.refresh,
                color: isOpen ? Colors.red : AppTheme.forest,
              ),
              label: Text(
                isOpen ? 'Close Requirement' : 'Reopen Requirement',
                style: TextStyle(
                  color: isOpen ? Colors.red : AppTheme.forest,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.forest),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              const Text(
                'Could not load your requirements',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadRequirements,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_requirements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.home_work_outlined,
                size: 64,
                color: AppTheme.forest.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Requirements Yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your room requirements will appear here '
                'after you post them.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.forest,
      onRefresh: _loadRequirements,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            '${_requirements.length} requirement(s) posted',
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ..._requirements.map(_buildRequirementCard),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'My Requirements',
          style: TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.ink,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadRequirements,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}

class _MatchingPropertiesSheet extends StatefulWidget {
  final String requirementId;

  const _MatchingPropertiesSheet({
    required this.requirementId,
  });

  @override
  State<_MatchingPropertiesSheet> createState() =>
      _MatchingPropertiesSheetState();
}

class _MatchingPropertiesSheetState
    extends State<_MatchingPropertiesSheet> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = RequirementsService.matchingProperties(
      widget.requirementId,
    );
  }

  String _text(dynamic value, [String fallback = 'Not specified']) {
    if (value == null || value.toString().trim().isEmpty) {
      return fallback;
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Matching Properties',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.forest,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Unable to load matching properties:\n${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final properties = snapshot.data ?? [];

                  if (properties.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 55,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No matching properties found yet.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: properties.length,
                    itemBuilder: (context, index) {
                      final property = properties[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _text(
                                property['title'],
                                _text(property['property_type'], 'Property'),
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.ink,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '📍 ${_text(property['location'], _text(property['area']))}',
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '₹${_text(property['rent'], _text(property['monthly_rent']))} / month',
                              style: const TextStyle(
                                color: AppTheme.forest,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (property['furnishing'] != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Furnishing: ${property['furnishing']}',
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
