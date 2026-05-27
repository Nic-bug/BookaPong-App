import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'available_slot_page.dart';

class AvailableFacilityPage extends StatefulWidget {
  final bool isModal;
  const AvailableFacilityPage({super.key, this.isModal = false});

  @override
  State<AvailableFacilityPage> createState() => _AvailableFacilityPageState();
}

class _AvailableFacilityPageState extends State<AvailableFacilityPage> {
  final Color darkRed = const Color(0xFF800020);
  final Color beige = const Color(0xFFFDF8F0);
  final Color greyBorder = const Color(0xFFE0E0E0);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = "";

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  ImageProvider _getFacilityImageProvider(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const NetworkImage(
        'https://images.unsplash.com/photo-1534158914592-062992fbe900?q=80&w=600&auto=format&fit=crop',
      );
    }
    if (imageUrl.startsWith('http') || imageUrl.startsWith('https') || kIsWeb) {
      return NetworkImage(imageUrl);
    }
    final localFile = File(imageUrl);
    if (localFile.existsSync()) {
      return FileImage(localFile);
    }
    return const NetworkImage(
      'https://images.unsplash.com/photo-1534158914592-062992fbe900?q=80&w=600&auto=format&fit=crop',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beige,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: darkRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  const Text(
                    "Facilities",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: greyBorder),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: "Search court...",
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: Icon(Icons.search, color: darkRed),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('admins')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return const Center(
                      child: Text("Failed to load facilities."),
                    );
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return Center(
                      child: CircularProgressIndicator(color: darkRed),
                    );

                  final docs = snapshot.data?.docs ?? [];
                  final facilities = docs
                      .map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        List<String> images = [];

                        if (data['coverImage'] != null &&
                            data['coverImage'].toString().isNotEmpty) {
                          images.add(data['coverImage']);
                        }
                        if (data['galleryImages'] != null) {
                          images.addAll(
                            List<String>.from(data['galleryImages']),
                          );
                        }

                        return {
                          "id": doc.id,
                          "name": data['centerName'] ?? 'Unnamed Arena',
                          "loc":
                              data['addressLocation'] ??
                              'Location not provided',
                          "rate": data['rating'] ?? '4.8',
                          "dist": data['distance'] ?? '1.8 km',
                          "images": images,
                        };
                      })
                      .where(
                        (f) => f['name']!.toLowerCase().contains(_searchQuery),
                      )
                      .toList();

                  if (facilities.isEmpty) {
                    return const Center(
                      child: Text(
                        "No partner centers found.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(15, 5, 15, 15),
                    itemCount: facilities.length,
                    itemBuilder: (context, index) =>
                        _buildFacilityCard(facilities[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityCard(Map<String, dynamic> f) {
    final String? thumbnailPath = (f['images'] as List).isNotEmpty
        ? f['images'][0]
        : null;

    return GestureDetector(
      onTap: () {
        _searchFocusNode.unfocus();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AvailableSlotsPage(
              facilityId: f['id'],
              facilityName: f['name'],
              facilityLocation: f['loc'],
              facilityImages: f['images'],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: greyBorder),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FadeInImage(
                placeholder: const NetworkImage(
                  'https://images.unsplash.com/photo-1534158914592-062992fbe900?q=80&w=200&auto=format&fit=crop',
                ),
                image: _getFacilityImageProvider(thumbnailPath),
                height: 65,
                width: 65,
                fit: BoxFit.cover,
                imageErrorBuilder: (context, error, stackTrace) => Container(
                  color: darkRed.withValues(alpha: 0.1),
                  width: 65,
                  height: 65,
                  child: Icon(Icons.sports_tennis, color: darkRed, size: 24),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    f['loc'],
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  f['dist'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      Text(
                        " ${f['rate']}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
