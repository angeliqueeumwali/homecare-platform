import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile/providers/provider_viewmodel.dart';
import 'package:mobile/services/location_service.dart';
import 'package:mobile/theme/colors.dart';
import 'package:mobile/theme/spacing.dart';
import 'package:mobile/widgets/app_widgets.dart';

class ProviderLocationScreen extends StatefulWidget {
  const ProviderLocationScreen({super.key});

  @override
  State<ProviderLocationScreen> createState() => _ProviderLocationScreenState();
}

class _ProviderLocationScreenState extends State<ProviderLocationScreen> {
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLocating = false;
  bool _showManualCoordinates = false;

  @override
  void dispose() {
    _latitudeController.dispose();
    _longitudeController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
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
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() => _showManualCoordinates = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${e.message} Enter an address instead.'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

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

  Future<void> _save(ProviderViewModel vm) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final result = await vm.saveLocation(
      latitude: double.parse(_latitudeController.text.trim()),
      longitude: double.parse(_longitudeController.text.trim()),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
    );
    if (!mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            vm.errorMessage ?? 'The backend refused to save the location.',
          ),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location saved'),
        backgroundColor: AppColors.successGreen,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProviderViewModel>();
    final hasCoordinates =
        _latitudeController.text.isNotEmpty &&
        _longitudeController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text('Business Location'),
        backgroundColor: AppColors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppCard(
              backgroundColor: AppColors.darkNavyBlue.withValues(alpha: 0.05),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.darkNavyBlue,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Your location helps an administrator match you to '
                      'customer requests near you. We find the coordinates '
                      'for you, so you never have to type them.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.mainText,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Address',
              controller: _addressController,
              prefixIcon: Icons.location_on_outlined,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _locateFromTypedAddress(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _isLocating ? null : _useCurrentLocation,
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
                      _isLocating ? 'Locating...' : 'Use current location',
                      style: const TextStyle(
                        color: AppColors.darkNavyBlue,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _isLocating ? null : _locateFromTypedAddress,
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
            if (!_showManualCoordinates && !hasCoordinates)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () =>
                      setState(() => _showManualCoordinates = true),
                  child: const Text(
                    'Enter coordinates manually',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            if (_showManualCoordinates) ...[
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Latitude',
                      controller: _latitudeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      validator: _validateCoordinate(-90, 90),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Longitude',
                      controller: _longitudeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      validator: _validateCoordinate(-180, 180),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              text: 'Save location',
              isLoading: vm.isLoading,
              onPressed: vm.isLoading ? null : () => _save(vm),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'The backend has no endpoint to read a saved location back, so '
              'this form starts empty each time you open it.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.secondaryText,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? Function(String?) _validateCoordinate(double min, double max) {
    return (value) {
      final text = value?.trim() ?? '';
      if (text.isEmpty) return 'Required';
      final parsed = double.tryParse(text);
      if (parsed == null) return 'Not a number';
      if (parsed < min || parsed > max) {
        return 'Between $min and $max';
      }
      return null;
    };
  }
}
