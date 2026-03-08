import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import '../models/place_model.dart';
import 'place_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ZipImportService {
  final PlaceService _placeService = PlaceService();
  final SupabaseStorageClient _storage = Supabase.instance.client.storage;

  Future<void> importPlacesFromZip(Function(double) onProgress) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        withData: true,
      );

      if (result == null) return;

      onProgress(0.1);

      List<int>? bytes;
      if (kIsWeb) {
        bytes = result.files.single.bytes;
      } else {
        final path = result.files.single.path;
        if (path != null) {
          bytes = await File(path).readAsBytes();
        } else {
          bytes = result.files.single.bytes;
        }
      }

      if (bytes == null) {
        throw Exception('Could not read zip file bytes.');
      }

      onProgress(0.2);

      final archive = ZipDecoder().decodeBytes(bytes);

      ArchiveFile? csvFile;
      Map<String, List<int>> imageContents = {};

      void processArchive(Archive arc) {
        for (final file in arc) {
          if (file.isFile) {
            final filename = file.name.split('/').last;
            if (filename.isEmpty ||
                filename.startsWith('.') ||
                file.name.contains('__MACOSX')) continue;

            if (filename.toLowerCase() == 'data.csv') {
              csvFile ??= file;
            } else if (filename.toLowerCase().endsWith('.zip')) {
              try {
                final innerArchive =
                    ZipDecoder().decodeBytes(file.content as List<int>);
                processArchive(innerArchive);
              } catch (e) {
                debugPrint('Failed to decode inner zip ${file.name}: $e');
              }
            } else {
              // Assume it's an image if it has a common extension
              final ext = filename.split('.').last.toLowerCase();
              if (['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) {
                imageContents[filename.toLowerCase()] =
                    file.content as List<int>;
              }
            }
          }
        }
      }

      processArchive(archive);

      if (csvFile == null) {
        throw Exception(
            'data.csv not found in the zip file. Ensure it is exactly named data.csv');
      }

      onProgress(0.3);

      final contentBytes = csvFile!.content as List<int>;
      final csvData = utf8.decode(contentBytes).replaceAll('\r\n', '\n');
      final List<List<dynamic>> rows =
          const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
              .convert(csvData);

      if (rows.isEmpty || rows.length < 2) {
        throw Exception('data.csv is empty or missing data rows.');
      }

      final headers =
          rows.first.map((e) => e.toString().trim().toLowerCase()).toList();
      final dataRows = rows.sublist(1);

      Map<String, String> uploadedImagesMap = {};

      int totalImages = imageContents.length;
      int currentImage = 0;

      for (final entry in imageContents.entries) {
        final filename = entry.key;
        final extension = filename.split('.').last;
        final contentType = extension == 'png' ? 'image/png' : 'image/jpeg';
        final uniqueFileName =
            '${DateTime.now().millisecondsSinceEpoch}_$filename';

        await _storage.from('places').uploadBinary(
              uniqueFileName,
              Uint8List.fromList(entry.value),
              fileOptions: FileOptions(contentType: contentType),
            );

        final String publicUrl =
            _storage.from('places').getPublicUrl(uniqueFileName);
        uploadedImagesMap[filename] = publicUrl;

        currentImage++;
        if (totalImages > 0) {
          onProgress(0.3 + (0.4 * (currentImage / totalImages)));
        }
      }

      int totalPlaces = dataRows.length;
      int currentPlace = 0;

      for (final row in dataRows) {
        if (row.isEmpty) continue;

        Map<String, dynamic> rowData = {};
        for (int i = 0; i < headers.length; i++) {
          if (i < row.length) {
            rowData[headers[i]] = row[i]?.toString().trim() ?? '';
          } else {
            rowData[headers[i]] = '';
          }
        }

        String imageName = rowData['image'] ?? '';
        String imageUrl =
            uploadedImagesMap[imageName.toLowerCase()] ?? imageName;

        String historyImageName = rowData['history_image'] ?? '';
        String historyImageUrl =
            uploadedImagesMap[historyImageName.toLowerCase()] ??
                historyImageName;

        if (imageUrl.isEmpty) {
          imageUrl = 'assets/images/templeoftooth.jpeg';
        }

        await Future.delayed(const Duration(milliseconds: 10));

        String latitudeStr = rowData['lat']?.toString().isNotEmpty == true
            ? rowData['lat']
            : rowData['latitude'] ?? '7.2906';
        String longitudeStr = rowData['lng']?.toString().isNotEmpty == true
            ? rowData['lng']
            : rowData['longitude'] ?? '80.6337';

        final newPlace = Place(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: rowData['name']?.toString().isNotEmpty == true
              ? rowData['name']
              : 'Unknown Place',
          location: rowData['location']?.toString().isNotEmpty == true
              ? rowData['location']
              : 'Unknown Location',
          rating: double.tryParse(rowData['rating'].toString()) ?? 4.5,
          description: rowData['description'] ?? '',
          coordinates: LatLng(
            double.tryParse(latitudeStr.toString()) ?? 7.2906,
            double.tryParse(longitudeStr.toString()) ?? 80.6337,
          ),
          image: imageUrl,
          category: rowData['category']?.toString().isNotEmpty == true
              ? rowData['category']
              : 'Category',
          history: rowData['history'] ?? '',
          historyImage: historyImageUrl.isNotEmpty ? historyImageUrl : null,
          isHiddenGem:
              rowData['is_hidden_gem']?.toString().toLowerCase() == 'true',
        );

        await _placeService.addPlace(newPlace);

        currentPlace++;
        if (totalPlaces > 0) {
          onProgress(0.7 + (0.3 * (currentPlace / totalPlaces)));
        }
      }

      Fluttertoast.showToast(
          msg: 'Successfully imported $currentPlace places!');
    } catch (e) {
      debugPrint('Zip import error: $e');
      Fluttertoast.showToast(msg: 'Import failed: $e');
      rethrow;
    }
  }
}
