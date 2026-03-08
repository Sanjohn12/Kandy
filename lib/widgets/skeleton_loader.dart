import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDarkMode ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  // Preset for Location Card
  static Widget locationCard() {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(width: 280, height: 180, borderRadius: 25),
          const SizedBox(height: 12),
          const SkeletonLoader(width: 150, height: 20),
          const SizedBox(height: 8),
          const SkeletonLoader(width: 100, height: 15),
        ],
      ),
    );
  }

  // Preset for Category Item
  static Widget categoryItem() {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: const SkeletonLoader(width: 100, height: 45, borderRadius: 25),
    );
  }

  // Preset for List Item (Saved Places)
  static Widget listItem() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          const SkeletonLoader(width: 100, height: 100, borderRadius: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonLoader(width: 150, height: 20),
                const SizedBox(height: 10),
                const SkeletonLoader(width: double.infinity, height: 15),
                const SizedBox(height: 5),
                const SkeletonLoader(width: 100, height: 15),
              ],
            ),
          )
        ],
      ),
    );
  }
}
