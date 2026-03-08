import 'package:flutter/material.dart';
import '../../services/place_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/zip_import_service.dart';

class SafetyManagementScreen extends StatefulWidget {
  const SafetyManagementScreen({super.key});

  @override
  State<SafetyManagementScreen> createState() => _SafetyManagementScreenState();
}

class _SafetyManagementScreenState extends State<SafetyManagementScreen> {
  final PlaceService _placeService = PlaceService();
  bool _isImporting = false;
  double _importProgress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety & Help Management'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emergency Data Feed',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Manage Hospitals, Police Stations, and Pharmacies. You can add them individually or upload a ZIP file containing safety data.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Stats Row
            Row(
              children: [
                _buildSafetyStat('Hospitals', 'hospital', Colors.red),
                const SizedBox(width: 10),
                _buildSafetyStat('Police', 'police', Colors.blue),
                const SizedBox(width: 10),
                _buildSafetyStat('Pharmacies', 'pharmacy', Colors.orange),
              ],
            ),

            const SizedBox(height: 30),

            // Actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            _buildActionCard(
              title: 'Bulk Upload Safety Data',
              subtitle: 'Upload a ZIP with data.csv and images',
              icon: Icons.unarchive,
              color: Colors.purple,
              onTap: _handleZipImport,
              isLoading: _isImporting,
            ),

            const SizedBox(height: 10),

            if (_isImporting)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: LinearProgressIndicator(value: _importProgress),
              ),

            _buildActionCard(
              title: 'Broadcast Safety Alert',
              subtitle: 'Send a live alert to all app users',
              icon: Icons.campaign,
              color: Colors.deepOrange,
              onTap: _showBroadcastDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyStat(String label, String category, Color color) {
    return Expanded(
      child: StreamBuilder<int>(
        stream: _placeService.getPlacesCountByCategory(category),
        builder: (context, snapshot) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(
                    category == 'hospital'
                        ? Icons.local_hospital
                        : category == 'police'
                            ? Icons.local_police
                            : Icons.local_pharmacy,
                    color: color),
                Text(
                  snapshot.hasData ? snapshot.data.toString() : '...',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(label, style: const TextStyle(fontSize: 10)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else
              const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _handleZipImport() async {
    setState(() {
      _isImporting = true;
      _importProgress = 0;
    });

    try {
      await ZipImportService().importPlacesFromZip((progress) {
        setState(() => _importProgress = progress);
      });
      Fluttertoast.showToast(msg: 'Safety data imported successfully!');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Import failed: $e');
    } finally {
      setState(() {
        _isImporting = false;
        _importProgress = 0;
      });
    }
  }

  void _showBroadcastDialog() {
    final TextEditingController alertController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Broadcast Safety Alert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'This message will appear on the main map for all tourists.'),
            const SizedBox(height: 10),
            TextField(
              controller: alertController,
              decoration: const InputDecoration(
                hintText: 'Enter alert message (e.g., Road closed at KCC)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                foregroundColor: Colors.white),
            onPressed: () {
              if (alertController.text.isNotEmpty) {
                // For now, we'll just show a toast. In a real app, this would update a Firestore collection.
                Fluttertoast.showToast(
                    msg: 'Alert Broadcasted: ${alertController.text}');
                Navigator.pop(context);
              }
            },
            child: const Text('Broadcast Now'),
          ),
        ],
      ),
    );
  }
}
