import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geo;

class MapLocationPickerPage extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const MapLocationPickerPage({
    super.key,
    this.initialLat = 1.5533, // Defaulting to Kuching, Sarawak
    this.initialLng = 110.3592,
  });

  @override
  State<MapLocationPickerPage> createState() => _MapLocationPickerPageState();
}

class _MapLocationPickerPageState extends State<MapLocationPickerPage> {
  LatLng? _selectedLocation;
  String _currentAddress = "Loading address...";
  bool _isLoadingAddress = false;
  final Color brandMaroon = const Color(0xFF8B0000);

  @override
  void initState() {
    super.initState();
    _selectedLocation = LatLng(widget.initialLat, widget.initialLng);
    _getAddressFromLatLng(_selectedLocation!);
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() => _isLoadingAddress = true);
    try {
      final List<geo.Placemark> placemarks = await geo.Geocoding()
          .placemarkFromCoordinates(position.latitude, position.longitude);

      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final geo.Placemark place = placemarks.first;

        final addressParts = <String>[
          if (place.street != null && place.street!.trim().isNotEmpty)
            place.street!,
          if (place.subLocality != null && place.subLocality!.trim().isNotEmpty)
            place.subLocality!,
          if (place.locality != null && place.locality!.trim().isNotEmpty)
            place.locality!,
          if (place.postalCode != null && place.postalCode!.trim().isNotEmpty)
            place.postalCode!,
          if (place.country != null && place.country!.trim().isNotEmpty)
            place.country!,
        ];

        setState(() {
          _currentAddress = addressParts.isNotEmpty
              ? addressParts.join(', ')
              : "Location selected (no detailed street name).";
        });
      } else {
        setState(() {
          _currentAddress = "No address found for this location.";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentAddress = "Could not fetch address for this location.";
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingAddress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Pin Center Location",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: brandMaroon),
        actions: [
          TextButton(
            onPressed: _selectedLocation == null
                ? null
                : () {
                    Navigator.pop(context, {
                      'latitude': _selectedLocation!.latitude,
                      'longitude': _selectedLocation!.longitude,
                      'address': _currentAddress,
                    });
                  },
            child: Text(
              "CONFIRM",
              style: TextStyle(
                color: _selectedLocation == null ? Colors.grey : brandMaroon,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.initialLat, widget.initialLng),
              zoom: 14,
            ),
            onTap: (LatLng location) {
              setState(() {
                _selectedLocation = location;
              });
              _getAddressFromLatLng(location);
            },
            markers: _selectedLocation != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected-location'),
                      position: _selectedLocation!,
                    ),
                  }
                : {},
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Selected Address:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _isLoadingAddress
                      ? const LinearProgressIndicator()
                      : Text(
                          _currentAddress,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
