import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ItemImageResolver {
  static const String _basePath = "assets/images/pantry/";
  static const String _fallback = "temp_pantry.png";
  static Set<String>? _assetPaths;

  /// Call this once at app start
  static Future<void> init() async {
    if (_assetPaths != null) return;

    try {
      final manifest = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifest);
      _assetPaths = manifestMap.keys
          .where((path) => path.startsWith(_basePath))
          .toSet();
      debugPrint('✅ Loaded ${_assetPaths?.length} pantry assets');
    } catch (e) {
      debugPrint('❌ Error loading asset manifest: $e');
      _assetPaths = {};
    }
  }

  static String _normalize(String name) {
    if (name.isEmpty) return '';
    return name
        .toLowerCase()
        .trim()
        .replaceAll("&", "and")
        .replaceAll(RegExp(r"[^\w\s]"), "")
        .replaceAll(RegExp(r"\s+"), "_");
  }

  static String getImage(String itemName) {
  if (itemName.isEmpty) {
    debugPrint('❌ Empty item name, using fallback');
    return _getFallbackPath();
  }

  final normalized = _normalize(itemName);
  // First try with temp_ prefix (matching your actual files)
  final tempCandidate = "$_basePath" "temp_$normalized.png";
  debugPrint('🔍 Looking for asset: $tempCandidate');

  if (_assetPaths?.contains(tempCandidate) ?? false) {
    debugPrint('✅ Found asset: $tempCandidate');
    return tempCandidate;
  }

  // If not found, try without the temp_ prefix (for any future images)
  final candidate = "$_basePath$normalized.png";
  debugPrint('🔍 Looking for asset: $candidate');

  if (_assetPaths?.contains(candidate) ?? false) {
    debugPrint('✅ Found asset: $candidate');
    return candidate;
  }

  debugPrint('⚠️  Asset not found, using fallback');
  return _getFallbackPath();
}

  static String _getFallbackPath() {
    final path = "$_basePath$_fallback";
    debugPrint('🔄 Using fallback image: $path');
    return path;
  }
}