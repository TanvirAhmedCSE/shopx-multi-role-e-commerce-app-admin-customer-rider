import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

// "Electronics-headphone" : ("Electronics", "headphone")
(String, String?) splitCategoryIcon(String raw) {
  final idx = raw.lastIndexOf('-');
  if (idx <= 0 || idx == raw.length - 1) return (raw, null);
  return (raw.substring(0, idx), raw.substring(idx + 1));
}

// Manual lookup — Iconsax names can't be resolved dynamically from string.
// Add more entries here as admin uses new icon names.
const _iconsaxByName = <String, IconData>{
  'headphone': Iconsax.headphone,
  'crown_1': Iconsax.crown_1,
  'element_4': Iconsax.element_4, // for "All"
  'person_outline': Icons.person_outline, // Men
  'man': Iconsax.man, // Men
  'woman': Iconsax.woman, // Women
  'female': Icons.female, // Women
  'box': Iconsax.box,
  'bag': Iconsax.bag,
  'bag_2': Iconsax.bag_2,
  'watch': Iconsax.watch,
  'gameboy': Iconsax.gameboy,
  'mobile': Iconsax.mobile,
  'monitor': Iconsax.monitor,
  'car': Iconsax.car,
  'home_2': Iconsax.home_2,
  'book': Iconsax.book,
  'star1': Iconsax.star1,
};

IconData iconsaxFromName(String? name) {
  if (name == null) return Iconsax.box;
  return _iconsaxByName[name] ?? Iconsax.box;
}
