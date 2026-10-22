import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appLocaleProvider = StateProvider<Locale>(
  (ref) => const Locale('en'),
);
