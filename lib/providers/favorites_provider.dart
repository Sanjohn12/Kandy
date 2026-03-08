import 'package:flutter/material.dart';

class FavoritesProvider extends ChangeNotifier {
  // A set of location IDs that are saved.
  final Set<String> _savedLocationIds = {};

  Set<String> get savedLocationIds => _savedLocationIds;

  bool isSaved(String id) {
    return _savedLocationIds.contains(id);
  }

  void toggleSave(String id) {
    if (_savedLocationIds.contains(id)) {
      _savedLocationIds.remove(id);
    } else {
      _savedLocationIds.add(id);
    }
    notifyListeners();
  }
}
