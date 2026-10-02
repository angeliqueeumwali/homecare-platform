import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:mobile/models/service_request_model.dart';
import 'package:mobile/providers/service_provider.dart';
import 'package:mobile/services/location_service.dart';
import 'package:mobile/screens/customer/request_review_screen.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/widgets/app_widgets.dart';
import 'package:mobile/widgets/service_category_widgets.dart';

class ServiceRequestScreen extends StatefulWidget {
  const ServiceRequestScreen({super.key, this.preselectedCategory});

  /// Service chosen on a details screen, so the first item is pre-filled.
  final ServiceCategoryModel? preselectedCategory;

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _preferredDate;
  bool _isLocating = false;
  bool _showManualCoordinates = false;
  final List<ServiceItemEntry> _itemEntries = [];

  @override
  void initState() {
    super.initState();
    final preselected = widget.preselectedCategory;
    if (preselected != null) {
      _itemEntries.add(
        ServiceItemEntry(key: UniqueKey(), category: preselected),
      );
    } else {
      _addItemEntry();
    }
    final categoryViewModel = context.read<ServiceCategoryViewModel>();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => categoryViewModel.fetchCategories(),
    );
    // Offer the location straight away so most customers never touch the
    // coordinate fields at all.
    WidgetsBinding.instance.addPostFrameCallback((_) => _useCurrentLocation());
  }

  void _addItemEntry() {
    setState(() {
      _itemEntries.add(ServiceItemEntry(key: UniqueKey()));
    });
  }

  void _removeItemEntry(int index) {
    setState(() {
      _itemEntries.removeAt(index);
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final timePicked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (timePicked != null) {
        setState(() {
          _preferredDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            timePicked.hour,
            timePicked.minute,
          );
        });
      }
    }
  }

  /// Fills lat/lng (and the address when reverse geocoding succeeds) from the
  /// device GPS. Manual entry stays available if this fails.
  Future<void> _useCurrentLocation({bool showFeedback = true}) async {
    setState(() => _isLocating = true);
    try {
      final location = await LocationService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _latitudeController.text = location.latitude.toStringAsFixed(6);
        _longitudeController.text = location.longitude.toStringAsFixed(6);
        if (location.address != null && location.address!.isNotEmpty) {
          _addressController.text = location.address!;
        }
      });
      if (showFeedback) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current location applied'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } on LocationException catch (e) {
      if (!mounted) return;
      // Failing to auto-detect is normal on emulators, so point the customer
      // at the next best option rather than leaving an error state.
      setState(() => _showManualCoordinates = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${e.message} Type an address and we will fill it in.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  /// Turns the address the customer typed into coordinates, so they never have
  /// to know what latitude or longitude mean.
  Future<void> _locateFromTypedAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    setState(() => _isLocating = true);
    try {
      final location = await LocationService.geocodeAddress(address);
      if (!mounted) return;
      setState(() {
        _latitudeController.text = location.latitude.toStringAsFixed(6);
        _longitudeController.text = location.longitude.toStringAsFixed(6);
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.errorRed),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  /// Builds the review draft from the form, or null when validation fails.
  RequestDraft? _buildDraft() {
    if (!(_formKey.currentState?.validate() ?? false)) return null;

    final items = <RequestDraftItem>[];
    for (final entry in _itemEntries) {
      final category = entry.category;
      if (category == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please choose a service for every item'),
          ),
        );
        return null;
      }
      items.add(RequestDraftItem(category: category, notes: entry.notes));
    }

    final address = _addressController.text.trim();
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());

    if (address.isEmpty || latitude == null || longitude == null) return null;

    return RequestDraft(
      address: address,
      latitude: latitude,
      longitude: longitude,
      preferredDate: _preferredDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      items: items,
    );
  }

  /// Opens the review step. The request is only created after the customer
  /// confirms on the next screen.
  void _submitRequest() {
    final draft = _buildDraft();
    if (draft == null) return;

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => RequestReviewScreen(draft: draft),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<ServiceRequestViewModel>().isLoading;
    final categories = context.watch<ServiceCategoryViewModel>().categories;
    final dateFormat = DateFormat('MMM d, y · h:mm a');

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Request a Service'),
        backgroundColor: AppColors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'Service Address',
                    controller: _addressController,
                    prefixIcon: Icons.location_on_outlined,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _locateFromTypedAddress(),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Please enter an address';
                      if (value.length < 2) return 'Address is too short';
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _isLocating
                              ? null
                              : () => _useCurrentLocation(),
                          icon: _isLocating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.darkNavyBlue,
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location,
                                  color: AppColors.darkNavyBlue,
                                  size: 18,
                                ),
                          label: Text(
                            _isLocating
                                ? 'Locating...'
                                : 'Use my current location',
                            style: const TextStyle(
                              color: AppColors.darkNavyBlue,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _isLocating
                              ? null
                              : _locateFromTypedAddress,
                          icon: const Icon(
                            Icons.search,
                            color: AppColors.darkNavyBlue,
                            size: 18,
                          ),
                          label: const Text(
                            'Find this address',
                            style: TextStyle(
                              color: AppColors.darkNavyBlue,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!_showManualCoordinates)
                    _ResolvedLocationHint(
                      latitude: _latitudeController.text,
                      longitude: _longitudeController.text,
                      onShowDetails: () =>
                          setState(() => _showManualCoordinates = true),
                    ),
                  if (_showManualCoordinates) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Latitude',
                            controller: _latitudeController,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Required';
                              final val = double.tryParse(value);
                              if (val == null) return 'Invalid number';
                              if (val < -90 || val > 90)
                                return 'Must be between -90 and 90';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            label: 'Longitude',
                            controller: _longitudeController,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Required';
                              final val = double.tryParse(value);
                              if (val == null) return 'Invalid number';
                              if (val < -180 || val > 180)
                                return 'Must be between -180 and 180';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    label: 'Notes (optional)',
                    controller: _notesController,
                    maxLines: 3,
                    validator: (_) => null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _selectDate,
                          icon: const Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.darkNavyBlue,
                          ),
                          label: Text(
                            _preferredDate != null
                                ? dateFormat.format(_preferredDate!)
                                : 'Set preferred date & time',
                            style: const TextStyle(
                              color: AppColors.darkNavyBlue,
                            ),
                          ),
                        ),
                      ),
                      if (_preferredDate != null)
                        TextButton(
                          onPressed: () =>
                              setState(() => _preferredDate = null),
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: AppColors.secondaryText),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    'Service Items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepNavyBlue,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _itemEntries.length,
                    itemBuilder: (context, index) {
                      return ServiceItemForm(
                        key: _itemEntries[index].key,
                        entry: _itemEntries[index],
                        categories: categories,
                        showDelete: _itemEntries.length > 1,
                        onDelete: () => _removeItemEntry(index),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton.icon(
                    onPressed: _addItemEntry,
                    icon: const Icon(Icons.add, color: AppColors.darkNavyBlue),
                    label: const Text(
                      'Add Another Item',
                      style: TextStyle(color: AppColors.darkNavyBlue),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    text: 'Review Request',
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _submitRequest,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}

class ServiceItemEntry {
  final Key key;
  ServiceCategoryModel? category;
  String? notes;

  ServiceItemEntry({required this.key, this.category});
}

class ServiceItemForm extends StatefulWidget {
  final ServiceItemEntry entry;
  final List<ServiceCategoryModel> categories;
  final bool showDelete;
  final VoidCallback? onDelete;

  const ServiceItemForm({
    super.key,
    required this.entry,
    required this.categories,
    this.showDelete = true,
    this.onDelete,
  });

  @override
  State<ServiceItemForm> createState() => _ServiceItemFormState();
}

class _ServiceItemFormState extends State<ServiceItemForm> {
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notesController.text = widget.entry.notes ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ServiceCategoryDropdown(
            categories: widget.categories,
            selected: widget.entry.category,
            onChanged: (value) => widget.entry.category = value,
          ),
          if (widget.entry.category != null &&
              widget.entry.category!.description != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ServiceCategoryImage(
                  category: widget.entry.category,
                  size: 36,
                  borderRadius: 8,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.entry.category!.description!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondaryText,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              isDense: true,
            ),
            maxLines: 2,
            onChanged: (val) =>
                widget.entry.notes = val.isNotEmpty ? val : null,
          ),
          if (widget.showDelete)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: widget.onDelete,
                icon: const Icon(
                  Icons.delete,
                  color: AppColors.errorRed,
                  size: 16,
                ),
                label: const Text(
                  'Remove',
                  style: TextStyle(color: AppColors.errorRed, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}

/// Confirms the location the app resolved, so the customer sees the request
/// will be pinned to a real spot. Coordinates stay collapsed unless the
/// customer asks for them.
class _ResolvedLocationHint extends StatelessWidget {
  final String latitude;
  final String longitude;
  final VoidCallback onShowDetails;

  const _ResolvedLocationHint({
    required this.latitude,
    required this.longitude,
    required this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = latitude.isNotEmpty && longitude.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            resolved ? Icons.check_circle_outline : Icons.info_outline,
            size: 16,
            color: resolved ? AppColors.successGreen : AppColors.secondaryText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              resolved
                  ? 'Location set for this address'
                  : 'We will pin this address on the map for the provider',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
              ),
            ),
          ),
          if (!resolved)
            TextButton(
              onPressed: onShowDetails,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Enter manually'),
            ),
        ],
      ),
    );
  }
}
