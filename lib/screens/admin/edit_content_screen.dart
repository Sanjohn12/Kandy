import 'package:flutter/material.dart';
import '../../services/place_service.dart';
import '../../models/place_model.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/zip_import_service.dart';

class EditContentScreen extends StatefulWidget {
  const EditContentScreen({super.key});

  @override
  State<EditContentScreen> createState() => _EditContentScreenState();
}

class _EditContentScreenState extends State<EditContentScreen> {
  final PlaceService _placeService = PlaceService();
  final ImagePicker _picker = ImagePicker();
  final ZipImportService _zipImportService = ZipImportService();
  bool _isUploading = false;
  double _uploadProgress = 0;
  bool _isZipUploading = false;
  double _zipUploadProgress = 0;

  Future<String?> _uploadImage(XFile imageFile) async {
    try {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0;
      });

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final imageData = await imageFile.readAsBytes();

      // Upload to Supabase 'places' bucket
      // Note: Make sure you created a PUBLIC bucket named 'places' in Supabase
      await Supabase.instance.client.storage.from('places').uploadBinary(
            fileName,
            imageData,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      // Get public URL
      final String publicUrl = Supabase.instance.client.storage
          .from('places')
          .getPublicUrl(fileName);

      setState(() {
        _isUploading = false;
        _uploadProgress = 1.0;
      });

      return publicUrl;
    } catch (e) {
      debugPrint('Upload error: $e');
      setState(() {
        _isUploading = false;
      });
      Fluttertoast.showToast(msg: 'Upload failed: $e');
      return null;
    }
  }

  Future<XFile?> _pickImage(ImageSource source) async {
    return await _picker.pickImage(source: source);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Content'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.drive_folder_upload),
            onPressed: _isZipUploading
                ? null
                : () async {
                    setState(() {
                      _isZipUploading = true;
                      _zipUploadProgress = 0.0;
                    });
                    try {
                      await _zipImportService.importPlacesFromZip((progress) {
                        setState(() => _zipUploadProgress = progress);
                      });
                    } catch (e) {
                      // Handled in service
                    } finally {
                      if (mounted) {
                        setState(() => _isZipUploading = false);
                      }
                    }
                  },
            tooltip: 'Bulk Upload ZIP',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showPlaceDialog(context),
            tooltip: 'Add New Place',
          ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<List<Place>>(
            stream: _placeService.getPlaces(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final places = snapshot.data ?? [];

              return ListView.builder(
                itemCount: places.length,
                padding: const EdgeInsets.all(10),
                itemBuilder: (context, index) {
                  final place = places[index];
                  return _PlaceListItem(
                    place: place,
                    onEdit: () => _showPlaceDialog(context, place: place),
                    onDelete: () => _showDeleteDialog(context, place),
                  );
                },
              );
            },
          ),
          if (_isZipUploading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Importing places...',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 20),
                        LinearProgressIndicator(value: _zipUploadProgress),
                        const SizedBox(height: 10),
                        Text(
                            '${(_zipUploadProgress * 100).toStringAsFixed(0)}%'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showPlaceDialog(BuildContext context, {Place? place}) {
    final isEditing = place != null;
    final nameController = TextEditingController(text: place?.name ?? '');
    final locationController =
        TextEditingController(text: place?.location ?? '');
    final ratingController =
        TextEditingController(text: place?.rating.toString() ?? '4.5');
    final descController =
        TextEditingController(text: place?.description ?? '');
    final imageController = TextEditingController(
        text: place?.image ?? 'assets/images/templeoftooth.jpeg');
    final categoryController =
        TextEditingController(text: place?.category ?? 'Temples');
    final latController = TextEditingController(
        text: place?.coordinates.latitude.toString() ?? '7.2906');
    final lngController = TextEditingController(
        text: place?.coordinates.longitude.toString() ?? '80.6337');
    bool isHiddenGem = place?.isHiddenGem ?? false;

    XFile? selectedImage;

    showDialog(
      context: context,
      barrierDismissible: !_isUploading,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Place' : 'Add New Place'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isUploading) ...[
                    LinearProgressIndicator(value: _uploadProgress),
                    const SizedBox(height: 10),
                    Text(
                        'Uploading image... ${(100 * _uploadProgress).toStringAsFixed(0)}%'),
                  ],
                  TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name')),
                  TextField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: 'Location')),
                  TextField(
                    controller: ratingController,
                    decoration:
                        const InputDecoration(labelText: 'Rating (0.0 - 5.0)'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 15),
                  // Image selection area
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Image Source',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _isUploading
                                  ? null
                                  : () async {
                                      final picked =
                                          await _pickImage(ImageSource.gallery);
                                      if (picked != null) {
                                        setDialogState(
                                            () => selectedImage = picked);
                                      }
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[50],
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.photo_library,
                                        color: Colors.teal[700], size: 20),
                                    const SizedBox(height: 4),
                                    const Text('Gallery',
                                        style: TextStyle(fontSize: 10),
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: _isUploading
                                  ? null
                                  : () async {
                                      final picked =
                                          await _pickImage(ImageSource.camera);
                                      if (picked != null) {
                                        setDialogState(
                                            () => selectedImage = picked);
                                      }
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey[50],
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.camera_alt,
                                        color: Colors.teal[700], size: 20),
                                    const SizedBox(height: 4),
                                    const Text('Camera',
                                        style: TextStyle(fontSize: 10),
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (selectedImage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            selectedImage!.name,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.teal[700],
                                fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (!isEditing ||
                          !imageController.text.startsWith('http')) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: imageController,
                          decoration: const InputDecoration(
                            labelText: 'OR Assets/URL Path',
                            hintText: 'e.g. assets/images/temple.jpeg',
                          ),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(
                          labelText: 'Category (Temples, Nature, City, Food)')),
                  TextField(
                    controller: latController,
                    decoration: const InputDecoration(labelText: 'Latitude'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: lngController,
                    decoration: const InputDecoration(labelText: 'Longitude'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text('Is Hidden Gem? 💎',
                        style: TextStyle(fontSize: 14)),
                    value: isHiddenGem,
                    onChanged: (val) => setDialogState(() => isHiddenGem = val),
                    activeColor: Colors.purple,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isUploading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _isUploading
                  ? null
                  : () async {
                      String imageUrl = imageController.text;

                      if (selectedImage != null) {
                        setDialogState(() {
                          _isUploading = true;
                          _uploadProgress = 0;
                        });

                        final uploadedUrl = await _uploadImage(selectedImage!);

                        if (uploadedUrl != null) {
                          imageUrl = uploadedUrl;
                        } else {
                          setDialogState(() => _isUploading = false);
                          return;
                        }
                      }

                      final newPlace = Place(
                        id: isEditing
                            ? place.id
                            : DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text,
                        location: locationController.text,
                        rating: double.tryParse(ratingController.text) ?? 4.5,
                        description: descController.text,
                        coordinates: LatLng(
                          double.tryParse(latController.text) ?? 7.2906,
                          double.tryParse(lngController.text) ?? 80.6337,
                        ),
                        image: imageUrl,
                        category: categoryController.text,
                        isHiddenGem: isHiddenGem,
                      );

                      if (isEditing) {
                        await _placeService.updatePlace(newPlace);
                        Fluttertoast.showToast(msg: 'Place updated!');
                      } else {
                        await _placeService.addPlace(newPlace);
                        Fluttertoast.showToast(msg: 'Place added!');
                      }

                      if (context.mounted) Navigator.pop(context);
                    },
              child: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Place place) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Place'),
        content: Text('Are you sure you want to delete ${place.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _placeService.deletePlace(place.id);
              Fluttertoast.showToast(msg: 'Place deleted!');
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _PlaceListItem extends StatelessWidget {
  final Place place;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PlaceListItem({
    required this.place,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: SizedBox(
          width: 50,
          height: 50,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: place.image.startsWith('assets/')
                ? Image.asset(
                    place.image,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 50),
                  )
                : Image.network(
                    place.image,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 50),
                  ),
          ),
        ),
        title: Row(
          children: [
            Text(place.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (place.isHiddenGem) ...[
              const SizedBox(width: 5),
              const Icon(Icons.diamond, color: Colors.purple, size: 16),
            ],
          ],
        ),
        subtitle:
            Text(place.location, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: onEdit),
            IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
