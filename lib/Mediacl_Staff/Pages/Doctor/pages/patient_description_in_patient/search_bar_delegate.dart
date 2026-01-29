import 'package:flutter/material.dart';

class SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  SearchBarDelegate({required this.child});

  @override
  double get minExtent => 80;

  @override
  double get maxExtent => 80;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.grey.shade100, child: child);
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
