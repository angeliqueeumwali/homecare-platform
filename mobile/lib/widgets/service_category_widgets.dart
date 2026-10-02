import 'package:flutter/material.dart';

import 'package:mobile/models/service_request_model.dart';
import 'package:mobile/theme/colors.dart';

/// Category image loaded from the backend. Falls back to a navy tile with a
/// generic icon when the category has no image or the image fails to load, so
/// the UI never shows a broken box.
class ServiceCategoryImage extends StatelessWidget {
  final ServiceCategoryModel? category;
  final double size;
  final double borderRadius;
  final IconData fallbackIcon;

  /// When true the image expands to fill its parent instead of using [size].
  /// Give the parent a bounded box, e.g. an AspectRatio.
  final bool fill;

  const ServiceCategoryImage({
    super.key,
    required this.category,
    this.size = 44,
    this.borderRadius = 10,
    this.fallbackIcon = Icons.home_repair_service_outlined,
    this.fill = false,
  });

  @override
  Widget build(BuildContext context) {
    final url = category?.displayImageUrl ?? '';
    final placeholder = _Placeholder(
      size: size,
      borderRadius: borderRadius,
      icon: fallbackIcon,
      fill: fill,
    );

    if (url.isEmpty) return placeholder;

    final image = Image.network(
      url,
      width: fill ? null : size,
      height: fill ? null : size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return placeholder;
      },
    );

    if (fill) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox.expand(child: image),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: image,
    );
  }
}

class _Placeholder extends StatelessWidget {
  final double size;
  final double borderRadius;
  final IconData icon;
  final bool fill;

  const _Placeholder({
    required this.size,
    required this.borderRadius,
    required this.icon,
    this.fill = false,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: fill ? null : size,
      height: fill ? null : size,
      decoration: BoxDecoration(
        color: AppColors.secondaryNavyBlue,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(icon, color: AppColors.white, size: fill ? 40 : size * 0.5),
    );

    return fill
        ? ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: SizedBox.expand(child: box),
          )
        : box;
  }
}

/// Dropdown for choosing a service category, so the user never has to type a
/// raw category UUID. Reuses [ServiceCategoryImage] so the selected service
/// is recognisable at a glance.
class ServiceCategoryDropdown extends StatelessWidget {
  final List<ServiceCategoryModel> categories;
  final ServiceCategoryModel? selected;
  final ValueChanged<ServiceCategoryModel?>? onChanged;
  final String? Function(ServiceCategoryModel?)? validator;

  const ServiceCategoryDropdown({
    super.key,
    required this.categories,
    this.selected,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Service Category',
          isDense: true,
        ),
        child: const Text(
          'No services available',
          style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
        ),
      );
    }

    // Duplicate ids from the backend would break DropdownButton's
    // "exactly one item with this value" assertion.
    final seen = <String>{};
    final items = categories
        .where((category) => seen.add(category.id))
        .map(
          (category) => DropdownMenuItem<ServiceCategoryModel>(
            value: category,
            child: Row(
              children: [
                ServiceCategoryImage(
                  category: category,
                  size: 26,
                  borderRadius: 6,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.mainText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();

    return DropdownButtonFormField<ServiceCategoryModel>(
      initialValue: items.any((item) => item.value == selected)
          ? selected
          : null,
      isExpanded: true,
      validator:
          validator ??
          (value) => value == null ? 'Please select a service' : null,
      decoration: const InputDecoration(
        labelText: 'Service Category',
        isDense: true,
        prefixIcon: Icon(Icons.category_outlined, size: 20),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}
