import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:bookapong_app/User/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:bookapong_app/User/Profile/profile_page.dart';
import 'package:bookapong_app/User/Access%20Code/access_code_page.dart';
import 'package:bookapong_app/User/Book/available_facility_page.dart';
import 'package:bookapong_app/User/History/booking_history_page.dart';
import 'package:bookapong_app/User/Book/available_slot_page.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color beige = const Color(0xFFFDF8F0);
  final Color darkRed = const Color(0xFF800020);
  final Color greyBorder = const Color(0xFFE0E0E0);
  Map<String, dynamic>? selectedPlaceData;

  String _displayName = "Nicole";

  // Cache the future so it doesn't re-fetch on every rebuild
  late Future<Map<String, dynamic>?> _soonestBookingFuture;

  @override
  void initState() {
    super.initState();
    _syncUserProfileData();
    _soonestBookingFuture = _fetchSoonestBooking();
  }

  Future<void> _syncUserProfileData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;

          String? imgPath = data['profileImage'];
          UserController().updateImage(imgPath ?? "");

          String? backendName = data['name'] ?? data['displayName'];

          if (mounted && backendName != null && backendName.isNotEmpty) {
            setState(() {
              _displayName = backendName;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error syncing user profile contexts: $e");
    }
  }

  // Call this to manually refresh the booking card (e.g. after returning from booking flow)
  void _refreshBookingCard() {
    setState(() {
      _soonestBookingFuture = _fetchSoonestBooking();
    });
  }

  ImageProvider? _getProfileProvider(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http') || path.startsWith('https') || kIsWeb) {
      return NetworkImage(path);
    }
    final localFile = File(path);
    return localFile.existsSync() ? FileImage(localFile) : null;
  }

  ImageProvider _getVenueImageProvider(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const NetworkImage(
        'https://images.unsplash.com/photo-1534158914592-062992fbe900?q=80&w=600&auto=format&fit=crop',
      );
    }
    if (imageUrl.startsWith('http') || imageUrl.startsWith('https')) {
      return NetworkImage(imageUrl);
    }
    return FileImage(File(imageUrl));
  }

  void _showFacilityModal() {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AvailableFacilityPage(isModal: true),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: animation.drive(
                Tween(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.easeOutQuart)),
              ),
              child: child,
            ),
          );
        },
      ),
    ).then((_) {
      // Refresh booking card when returning from facility/booking flow
      _refreshBookingCard();
    });
  }

  String _getTruncatedName(String fullStringName) {
    List<String> words = fullStringName.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words[0].isEmpty) return "Nicole";
    if (words.length <= 2) return fullStringName;
    return "${words[0]} ${words[1]}";
  }

  Future<Map<String, dynamic>?> _fetchSoonestBooking() async {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    // Level 1: Strict rejection of empty/null IDs
    if (currentUserId.isEmpty) return null;

    final DateTime now = DateTime.now();

    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: currentUserId)
        .get();

    if (snapshot.docs.isEmpty) return null;

    List<Map<String, dynamic>> processedList = [];

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};

      // Level 2: Strict Double-Validation against DB misfires
      if (data['userId'] != currentUserId) continue;

      final String currentStatus = (data['status'] ?? '')
          .toString()
          .toLowerCase()
          .trim();

      if (currentStatus == 'cancelled' || currentStatus == 'rejected') {
        continue;
      }

      final Timestamp? startTimeTimestamp = data['startTime'] as Timestamp?;
      final Timestamp? endTimeTimestamp = data['endTime'] as Timestamp?;

      if (startTimeTimestamp != null && endTimeTimestamp != null) {
        final DateTime sessionStart = startTimeTimestamp.toDate();
        final DateTime sessionEnd = endTimeTimestamp.toDate();

        if (sessionEnd.isAfter(now)) {
          processedList.add({
            'docId': doc.id,
            'startDateTime': sessionStart,
            'endDateTime': sessionEnd,
            'raw': data,
          });
        }
      }
    }

    if (processedList.isEmpty) return null;

    processedList.sort((a, b) {
      final DateTime timeA = a['startDateTime'];
      final DateTime timeB = b['startDateTime'];
      final DateTime dateA = DateTime(timeA.year, timeA.month, timeA.day);
      final DateTime dateB = DateTime(timeB.year, timeB.month, timeB.day);
      int dateComparison = dateA.compareTo(dateB);
      if (dateComparison != 0) return dateComparison;
      return timeA.compareTo(timeB);
    });

    return {
      'totalUpcomingCount': processedList.length,
      'booking': processedList.first,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beige,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 25),
                    _buildSectionTitle("Places", Icons.location_on_outlined),
                    const SizedBox(height: 12),
                    _buildPlacesHorizontalStreamList(),
                    const SizedBox(height: 25),
                    const Text(
                      "Quick Actions",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _actionCard(
                            icon: Icons.calendar_month,
                            title: "Book a Table",
                            color: darkRed,
                            isPrimary: true,
                            onTap: _showFacilityModal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _actionCard(
                            icon: Icons.history,
                            title: "My Bookings",
                            color: Colors.white,
                            isPrimary: false,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const BookingHistoryPage(),
                              ),
                            ).then((_) => _refreshBookingCard()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    if (selectedPlaceData != null) _buildAvailabilitySection(),
                    const SizedBox(height: 25),
                    _buildActiveBookingStreamCard(),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        color: darkRed,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [darkRed, darkRed.withOpacity(0.8)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(30),
              ),
              child: Image.asset(
                'assets/ping_pong_header.png',
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Hi, ${_getTruncatedName(_displayName)}",
                        style: const TextStyle(
                          color: Color(0xFFFFB347),
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      ValueListenableBuilder<String?>(
                        valueListenable: UserController().profileImagePath,
                        builder: (context, path, _) {
                          final provider = _getProfileProvider(path);
                          return GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfilePage(),
                                ),
                              );
                              _syncUserProfileData();
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24),
                                image: provider != null
                                    ? DecorationImage(
                                        image: provider,
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: provider == null
                                  ? const Icon(
                                      Icons.person_outline_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(
                    width: 200,
                    child: Text(
                      "Plan Your Sports Activities to be the Best",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: darkRed),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildPlacesHorizontalStreamList() {
    return SizedBox(
      height: 100,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('admins').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  "Connection Warning: Unable to sync arenas.",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: darkRed));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                "No registered venues active.",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            );
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              String facilityId = doc.id;
              String centerName = data['centerName'] ?? 'Unnamed Arena';
              String location =
                  data['addressLocation'] ?? 'Location setup pending';
              String distance = data['distance'] ?? '1.2 km away';

              String? imagePath =
                  (data['coverImage'] != null &&
                      data['coverImage'].toString().isNotEmpty)
                  ? data['coverImage'].toString()
                  : null;

              List<String> venueImages = [];
              if (imagePath != null) venueImages.add(imagePath);
              if (data['galleryImages'] != null) {
                venueImages.addAll(List<String>.from(data['galleryImages']));
              }

              bool isSelected =
                  selectedPlaceData != null &&
                  selectedPlaceData!['id'] == facilityId;
              final currentVenueItem = {
                "id": facilityId,
                "name": centerName,
                "location": location,
                "distance": distance,
                "images": venueImages,
              };

              return GestureDetector(
                onTap: () =>
                    setState(() => selectedPlaceData = currentVenueItem),
                child: Container(
                  width: 240,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: isSelected ? darkRed : greyBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: FadeInImage(
                          placeholder: const NetworkImage(
                            'https://images.unsplash.com/photo-1534158914592-062992fbe900?q=80&w=200&auto=format&fit=crop',
                          ),
                          image: _getVenueImageProvider(imagePath),
                          height: 80,
                          width: 80,
                          fit: BoxFit.cover,
                          imageErrorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey.shade200,
                                width: 80,
                                height: 80,
                                child: Icon(
                                  Icons.sports_tennis,
                                  color: darkRed,
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              centerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              location,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              distance,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    final DateTime now = DateTime.now();
    final DateTime startOfToday = DateTime(now.year, now.month, now.day);
    final DateTime endOfToday = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
    );

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: greyBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Today's Availability: ${selectedPlaceData!['name']}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AvailableSlotsPage(
                      facilityId: selectedPlaceData!['id'],
                      facilityName: selectedPlaceData!['name'],
                      facilityLocation: selectedPlaceData!['location'],
                      facilityImages: List<String>.from(
                        selectedPlaceData!['images'] ?? [],
                      ),
                    ),
                  ),
                ),
                child: Text(
                  "View All",
                  style: TextStyle(color: darkRed, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collectionGroup('slots')
                .where('isAvailable', isEqualTo: true)
                .where(
                  'targetDate',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday),
                )
                .where(
                  'targetDate',
                  isLessThanOrEqualTo: Timestamp.fromDate(endOfToday),
                )
                .orderBy('targetDate')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    "Slots temporarily unavailable due to sync mismatch.",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              }

              final docsList = snapshot.data?.docs ?? [];

              final filteredSlots = docsList.where((doc) {
                return doc.reference.path.contains(
                  'admins/${selectedPlaceData!['id']}/courts/',
                );
              }).toList();

              if (filteredSlots.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    "No available slots for today.",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              }

              filteredSlots.sort((a, b) {
                final aTime = (a.data() as Map<String, dynamic>)['time'] ?? '';
                final bTime = (b.data() as Map<String, dynamic>)['time'] ?? '';
                return aTime.compareTo(bTime);
              });

              final bool viewAllNeeded = filteredSlots.length > 5;
              final displaySlots = filteredSlots.take(5).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...displaySlots.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final String timeLabel = data['time'] ?? 'N/A';
                    final bool isAvailable = data['isAvailable'] ?? true;
                    final docPathParts = doc.reference.path.split('/');
                    final String tableLabel =
                        docPathParts[docPathParts.length - 3];
                    return _timeSlot(timeLabel, isAvailable, tableLabel);
                  }),
                  if (viewAllNeeded) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        "Click 'View All' to explore all remaining slots",
                        style: TextStyle(
                          color: darkRed.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveBookingStreamCard() {
    return FutureBuilder<Map<String, dynamic>?>(
      future:
          _soonestBookingFuture, // uses cached future — no re-fetch on rebuild
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final int upcomingCount = snapshot.data!['totalUpcomingCount'];
        final Map<String, dynamic> currentBookingNode =
            snapshot.data!['booking'];

        final String docId = currentBookingNode['docId'];
        final DateTime start = currentBookingNode['startDateTime'];
        final DateTime end = currentBookingNode['endDateTime'];
        final Map<String, dynamic> data = currentBookingNode['raw'];

        final String formattedDate = DateFormat('MMM dd, yyyy').format(start);
        final String formattedTime =
            "${DateFormat('hh:mm a').format(start)} - ${DateFormat('hh:mm a').format(end)}";

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: greyBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Active Booking",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (upcomingCount > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: darkRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "1 of $upcomingCount upcoming",
                        style: TextStyle(
                          color: darkRed,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _infoRow(
                "Court",
                "${data['facilityName'] ?? 'Venue'} • ${data['table'] ?? 'Table'}",
              ),
              _infoRow("Date", formattedDate),
              _infoRow("Time", formattedTime),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AccessCodePage(
                        accessCode: data['accessCode'] ?? "0000",
                        court:
                            "${data['facilityName'] ?? 'Venue'} - ${data['table'] ?? 'Table'}",
                        date: formattedDate,
                        time: formattedTime,
                        reference: docId
                            .substring(0, min(8, docId.length))
                            .toUpperCase(),
                        bookingStartTime: start,
                        bookingEndTime: end,
                        bookingDocId: docId,
                      ),
                    ),
                  ).then((_) => _refreshBookingCard()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "View Access Code",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _timeSlot(String time, bool available, String tableName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: beige.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: greyBorder.withOpacity(0.4), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: darkRed.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.access_time_filled, size: 16, color: darkRed),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                tableName,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "Available",
              style: TextStyle(
                color: Colors.green,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required Color color,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          border: isPrimary ? null : Border.all(color: greyBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: isPrimary ? Colors.white : Colors.black87,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: isPrimary ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
