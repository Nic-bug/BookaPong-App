import 'dart:io';
import 'package:bookapong_app/User/Book/booking_summary_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AvailableSlotsPage extends StatefulWidget {
  final String facilityId;
  final String facilityName;
  final String facilityLocation;
  final List<String> facilityImages;

  const AvailableSlotsPage({
    super.key,
    required this.facilityId,
    required this.facilityName,
    required this.facilityLocation,
    required this.facilityImages,
  });

  @override
  State<AvailableSlotsPage> createState() => _AvailableSlotsPageState();
}

class _AvailableSlotsPageState extends State<AvailableSlotsPage> {
  final Color darkRed = const Color(0xFF800020);
  final Color beige = const Color(0xFFFDF8F0);
  final Color greyBorder = const Color(0xFFE0E0E0);

  int selectedDateIndex = 0;
  int? selectedSlotIndex;
  int currentImageSliderIndex = 0;

  late List<Map<String, String>> dates;
  late String currentMonthYear;

  List<DocumentSnapshot> loadedStreamSlots = [];
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _generateRealTimeCalendar();
  }

  void _generateRealTimeCalendar() {
    final now = DateTime.now();
    currentMonthYear = DateFormat('MMMM yyyy').format(now);
    dates = List.generate(7, (index) {
      final date = now.add(Duration(days: index));
      return {
        "day": DateFormat('E').format(date),
        "date": DateFormat('d').format(date),
        "full": DateFormat('yyyy-MM-dd').format(date),
      };
    });
  }

  bool _isSlotTimeValid(String dateStr, String timeSlotStr) {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    if (dateStr != todayStr) return true;

    try {
      final String startTimeStr = timeSlotStr.split('-').first.trim();
      final DateFormat inputFormat = DateFormat('hh:mm a');
      final DateTime parsedStartTime = inputFormat.parse(startTimeStr);

      final DateTime comparisonTime = DateTime(
        now.year,
        now.month,
        now.day,
        parsedStartTime.hour,
        parsedStartTime.minute,
      );

      return now.isBefore(comparisonTime);
    } catch (e) {
      debugPrint("Error parsing time window boundary: $e");
      return false;
    }
  }

  ImageProvider _getGalleryProvider(String path) {
    if (path.isEmpty ||
        path.startsWith('http') ||
        path.startsWith('https') ||
        kIsWeb) {
      return NetworkImage(
        path.isEmpty
            ? 'https://images.unsplash.com/photo-1534158914592-062992fbe900?q=80&w=1000'
            : path,
      );
    }
    final file = File(path);
    return file.existsSync()
        ? FileImage(file)
        : const NetworkImage(
            'https://images.unsplash.com/photo-1534158914592-062992fbe900?q=80&w=1000',
          );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> centerImages = widget.facilityImages.isEmpty
        ? [
            'https://images.unsplash.com/photo-1534158914592-062992fbe900?q=80&w=1000',
          ]
        : widget.facilityImages;

    String selectedTargetDateStr = dates[selectedDateIndex]["full"]!;

    return Scaffold(
      backgroundColor: beige,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Hero image + back button ──────────────────────────
                    Stack(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 280,
                          child: PageView.builder(
                            itemCount: centerImages.length,
                            onPageChanged: (index) =>
                                setState(() => currentImageSliderIndex = index),
                            itemBuilder: (context, index) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  image: DecorationImage(
                                    image: _getGalleryProvider(
                                      centerImages[index],
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 10,
                          left: 20,
                          child: GestureDetector(
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
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Facility name + location ──────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.facilityName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: darkRed, size: 18),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.facilityLocation,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ── Month label ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        currentMonthYear,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // ── Date strip ────────────────────────────────────────
                    SizedBox(
                      height: 85,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: dates.length,
                        itemBuilder: (context, index) {
                          final item = dates[index];
                          final isSelected = selectedDateIndex == index;
                          return GestureDetector(
                            onTap: () => setState(() {
                              selectedDateIndex = index;
                              selectedSlotIndex = null;
                            }),
                            child: Container(
                              width: 65,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? darkRed : Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: isSelected ? darkRed : greyBorder,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item["day"]!,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white70
                                          : Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item["date"]!,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 25),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Select Time Slot",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),

              // ── Slot list via targeted collection query ─────────────────
              //
              // FIX: Instead of collectionGroup('slots') — which pulls slots
              // from ALL facilities — we now query the specific facility's
              // courts subcollection.  This means a booking at Facility A
              // can never bleed into Facility B's slot list.
              //
              // We also pass `isAvailable` straight from the Firestore stream
              // snapshot so the card reflects the live database state.  When
              // BookingSummaryPage commits its batch (set booking + update
              // isAvailable=false), this StreamBuilder rebuilds automatically
              // and marks the slot as Booked.
              StreamBuilder<QuerySnapshot>(
                // ✅ FIXED: scoped to this facility only, not collectionGroup
                stream: FirebaseFirestore.instance
                    .collectionGroup('slots')
                    .where(
                      'targetDate',
                      isGreaterThanOrEqualTo: Timestamp.fromDate(
                        DateTime.parse(selectedTargetDateStr),
                      ),
                    )
                    .where(
                      'targetDate',
                      isLessThan: Timestamp.fromDate(
                        DateTime.parse(
                          selectedTargetDateStr,
                        ).add(const Duration(days: 1)),
                      ),
                    )
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Text(
                          "Error fetching records: ${snapshot.error}",
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData ||
                      snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  // ✅ FIXED: filter by facilityId path AND targetDate
                  final List<QueryDocumentSnapshot> filteredSlots = snapshot
                      .data!
                      .docs
                      .where((doc) {
                        final data = doc.data() as Map<String, dynamic>?;
                        if (data == null || data['targetDate'] == null)
                          return false;

                        // Ensure this slot belongs to the correct facility
                        final docPath = doc.reference.path;
                        return docPath.contains(
                          'admins/${widget.facilityId}/courts/',
                        );
                      })
                      .toList();

                  filteredSlots.sort((a, b) {
                    final aTime =
                        (a.data() as Map<String, dynamic>?)?['time'] ?? '';
                    final bTime =
                        (b.data() as Map<String, dynamic>?)?['time'] ?? '';
                    return aTime.compareTo(bTime);
                  });

                  // Keep an up-to-date reference for the "Next" button
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      loadedStreamSlots = filteredSlots;
                    }
                  });

                  if (filteredSlots.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 40,
                          horizontal: 20,
                        ),
                        child: Center(
                          child: Text(
                            "No slots available for $selectedTargetDateStr",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index >= filteredSlots.length) return null;

                        final doc = filteredSlots[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final docPathParts = doc.reference.path.split('/');
                        // Path: admins/{fId}/courts/{courtName}/slots/{slotId}
                        // Index:   0      1     2       3         4      5
                        final String courtName = docPathParts.length >= 4
                            ? docPathParts[3]
                            : 'Unknown';

                        final double price = (data['price'] as num? ?? 0.0)
                            .toDouble();
                        final List<dynamic> surcharges =
                            data['surcharges'] ?? [];
                        final double totalGross =
                            price +
                            surcharges.fold(
                              0.0,
                              (v, c) =>
                                  v + (c['amount'] as num? ?? 0.0).toDouble(),
                            );

                        final String timeSlotStr = data['time'] ?? 'N/A';

                        // ✅ FIXED: isAvailable comes directly from the
                        // live Firestore snapshot — no extra fetch needed.
                        // When BookingSummaryPage runs its batch write and
                        // sets isAvailable=false, this StreamBuilder fires
                        // and rebuilds the card as "Booked" automatically.
                        final bool backendAvailable =
                            data['isAvailable'] ?? true;
                        final bool timeFenceValid = _isSlotTimeValid(
                          selectedTargetDateStr,
                          timeSlotStr,
                        );

                        final bool finalAvailable =
                            backendAvailable && timeFenceValid;

                        // Deselect if the slot just became unavailable
                        if (selectedSlotIndex == index && !finalAvailable) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() => selectedSlotIndex = null);
                            }
                          });
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SlotCard(
                            time: timeSlotStr,
                            table: courtName,
                            available: finalAvailable,
                            isSelected: selectedSlotIndex == index,
                            themeColor: darkRed,
                            price: totalGross,
                            onTap: () {
                              if (finalAvailable) {
                                setState(() => selectedSlotIndex = index);
                              }
                            },
                          ),
                        );
                      }, childCount: filteredSlots.length),
                    ),
                  );
                },
              ),
            ],
          ),

          // ── "Next Step" floating button ─────────────────────────────────
          if (selectedSlotIndex != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: FadeInUp(
                child: SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: _isNavigating
                        ? null
                        : () async {
                            if (selectedSlotIndex != null &&
                                selectedSlotIndex! < loadedStreamSlots.length) {
                              setState(() => _isNavigating = true);

                              final targetSlotDoc =
                                  loadedStreamSlots[selectedSlotIndex!];

                              try {
                                // ── Last-mile server check ──────────────
                                // Even though the stream already reflects
                                // isAvailable=false for booked slots, we do
                                // one final server-read here to guard against
                                // the narrow race window between a user
                                // selecting a slot and tapping "Next Step".
                                final freshSnapshot = await targetSlotDoc
                                    .reference
                                    .get(
                                      const GetOptions(source: Source.server),
                                    );

                                if (!mounted) return;

                                final freshData =
                                    freshSnapshot.data()
                                        as Map<String, dynamic>? ??
                                    {};
                                final bool isStillAvailable =
                                    freshData['isAvailable'] ?? true;

                                if (!isStillAvailable) {
                                  setState(() {
                                    selectedSlotIndex = null;
                                    _isNavigating = false;
                                  });
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "This slot was just booked by another user!",
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                  return;
                                }

                                final docPathParts = targetSlotDoc
                                    .reference
                                    .path
                                    .split('/');
                                final String extractedCourtName =
                                    docPathParts.length >= 4
                                    ? docPathParts[3]
                                    : 'Unknown';

                                if (!mounted) return;

                                if (context.mounted) {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BookingSummaryPage(
                                        facilityId: widget.facilityId,
                                        facilityName: widget.facilityName,
                                        date: dates[selectedDateIndex],
                                        time: freshData["time"] ?? 'N/A',
                                        table: extractedCourtName,
                                        slotId: targetSlotDoc.id,
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Connection error: $e"),
                                    ),
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _isNavigating = false);
                                }
                              }
                            }
                          },
                    child: _isNavigating
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Next Step",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SlotCard
// ─────────────────────────────────────────────────────────────────────────────
class SlotCard extends StatelessWidget {
  final String time;
  final String table;
  final bool available;
  final bool isSelected;
  final Color themeColor;
  final double price;
  final VoidCallback onTap;

  const SlotCard({
    super.key,
    required this.time,
    required this.table,
    required this.available,
    required this.isSelected,
    required this.themeColor,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: available ? 1.0 : 0.4,
      child: Container(
        decoration: BoxDecoration(
          color: available ? Colors.white : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected && available
                ? themeColor
                : const Color(0xFFE0E0E0),
            width: isSelected && available ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: available ? onTap : null,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: !available
                        ? Colors.grey.shade400
                        : (isSelected
                              ? themeColor
                              : themeColor.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    available ? Icons.access_time_filled : Icons.block,
                    color: isSelected && available ? Colors.white : themeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        decoration: available
                            ? TextDecoration.none
                            : TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      table,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "RM ${price.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      available ? "Available" : "Booked",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: available ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FadeInUp
// ─────────────────────────────────────────────────────────────────────────────
class FadeInUp extends StatelessWidget {
  final Widget child;
  const FadeInUp({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      builder: (context, double value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
