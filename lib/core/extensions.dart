import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Custom extensions for responsive design and UI utilities
extension SizeExtension on num {
  /// Get responsive font size using Sizer
  double get fSize => this.sp;

  /// Get adaptive size for icons and small elements
  double get adaptSize => this.sp;
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : word)
        .join(' ');
  }
}

extension DateTimeExtension on DateTime {
  String toFormattedString() {
    return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
  }

  String toTimeString() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String toDateTimeString() {
    return '${toFormattedString()} ${toTimeString()}';
  }
}

extension ListExtension<T> on List<T> {
  List<T> takeSafe(int count) {
    if (count >= length) return this;
    return take(count).toList();
  }

  T? get firstOrNull => isNotEmpty ? first : null;

  T? get lastOrNull => isNotEmpty ? last : null;
}

extension MapExtension<K, V> on Map<K, V> {
  V? getValue(K key) => this[key];

  bool hasKey(K key) => containsKey(key);

  Map<K, V> merge(Map<K, V> other) {
    return {...this, ...other};
  }
}
