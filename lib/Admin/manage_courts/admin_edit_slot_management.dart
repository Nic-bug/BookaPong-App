import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class Surcharge {
  String name;
  double amount;
  Surcharge({required this.name, required this.amount});
}

class CourtSlot {
  String id;
  String time;
  String tableName;
  bool isAvailable;
  double price;
  List<Surcharge> surcharges;
  DateTime targetDate;

  CourtSlot({
    required this.id,
    required this.time,
    required this.tableName,
    required this.isAvailable,
    required this.price,
    required this.targetDate,
    this.surcharges = const [],
  });
}

class AdminEditSlotManagementPage extends StatefulWidget {
  final DateTime selectedDate;
  final String tableName;

  const AdminEditSlotManagementPage({
    super.key,
    required this.selectedDate,
    required this.tableName,
  });

  @override
  State<AdminEditSlotManagementPage> createState() =>
      _AdminEditSlotManagementPageState();
}

class _AdminEditSlotManagementPageState
    extends State<AdminEditSlotManagementPage> {
  static const Color brandMaroon = Color(0xFF8B0000);
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  List<CourtSlot> globalInventory = [];
  final Map<String, bool> _dayClosureRegistry = {};

  late DateTime _currentRealTime;
  late DateTime _focusedDate;
  late DateTime _calendarMinBoundary;
  late DateTime _calendarMaxBoundary;

  final Set<DateTime> _selectedDatesSet = {};
  final Map<int, GlobalKey> _gridItemKeys = {};

  bool _isFormOpen = false;
  bool _isSaving = false;
  CourtSlot? _editingSlot;

  String _selectedTimeChoice = "08:00 AM - 09:00 AM";
  final TextEditingController _priceController = TextEditingController(
    text: "25.0",
  );
  List<Surcharge> _selectedSurcharges = [];
  bool _editingSlotAvailable = true;

  StreamSubscription? _closuresSubscription;
  StreamSubscription? _slotsSubscription;

  final List<String> timeSlotsChoices = [
    "07:00 AM - 08:00 AM",
    "08:00 AM - 09:00 AM",
    "09:00 AM - 10:00 AM",
    "10:00 AM - 11:00 AM",
    "11:00 AM - 12:00 PM",
    "12:00 PM - 01:00 PM",
    "01:00 PM - 02:00 PM",
    "02:00 PM - 03:00 PM",
    "03:00 PM - 04:00 PM",
    "04:00 PM - 05:00 PM",
    "05:00 PM - 06:00 PM",
    "06:00 PM - 07:00 PM",
    "07:00 PM - 08:00 PM",
  ];

  final List<Surcharge> availableSurcharges = [
    Surcharge(name: "Peak Hour Rate", amount: 5.00),
    Surcharge(name: "Weekend Surcharge", amount: 10.00),
  ];

  @override
  void initState() {
    super.initState();
    _currentRealTime = DateTime.now();
    _calendarMinBoundary = DateTime(
      _currentRealTime.year,
      _currentRealTime.month,
      _currentRealTime.day,
    );
    _calendarMaxBoundary = DateTime(
      _currentRealTime.year,
      _currentRealTime.month + 12,
      0,
    );
    _focusedDate = widget.selectedDate.isBefore(_calendarMinBoundary)
        ? _calendarMinBoundary
        : widget.selectedDate;
    _normalizeAndSelectDate(_focusedDate);
    _listenToCloudSlots();
  }

  void _listenToCloudSlots() {
    if (_currentUser == null) return;

    _closuresSubscription = FirebaseFirestore.instance
        .collection('admins')
        .doc(_currentUser.uid)
        .collection('courts')
        .doc(widget.tableName)
        .snapshots()
        .listen((doc) {
          if (!mounted) return;
          if (doc.exists && doc.data() != null) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['closures'] != null) {
              setState(() {
                _dayClosureRegistry.clear();
                (data['closures'] as Map<String, dynamic>).forEach((key, val) {
                  _dayClosureRegistry[key] = val as bool;
                });
              });
            }
          }
        });

    _slotsSubscription = FirebaseFirestore.instance
        .collection('admins')
        .doc(_currentUser.uid)
        .collection('courts')
        .doc(widget.tableName)
        .collection('slots')
        .snapshots()
        .listen((snapshot) {
          if (!mounted) return;
          final List<CourtSlot> loadedSlots = [];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final List<dynamic> rawSurcharges = data['surcharges'] ?? [];

            loadedSlots.add(
              CourtSlot(
                id: doc.id,
                time: data['time'] ?? '',
                tableName: widget.tableName,
                isAvailable: data['isAvailable'] ?? true,
                price: (data['price'] as num? ?? 0.0).toDouble(),
                targetDate: data['targetDate'] != null
                    ? (data['targetDate'] as Timestamp).toDate()
                    : DateTime.now(),
                surcharges: rawSurcharges
                    .map(
                      (e) => Surcharge(
                        name: e['name'] ?? '',
                        amount: (e['amount'] as num? ?? 0.0).toDouble(),
                      ),
                    )
                    .toList(),
              ),
            );
          }
          setState(() {
            globalInventory = loadedSlots;
          });
        });
  }

  @override
  void dispose() {
    _closuresSubscription?.cancel();
    _slotsSubscription?.cancel();
    _priceController.dispose();
    super.dispose();
  }

  void _normalizeAndSelectDate(DateTime date) {
    final midnight = DateTime(date.year, date.month, date.day);
    if (!midnight.isBefore(_calendarMinBoundary)) {
      _selectedDatesSet.add(midnight);
    }
  }

  String _getMidnightKey(DateTime date) {
    return "${date.year}-${date.month}-${date.day}";
  }

  List<CourtSlot> get _activeDaySlots {
    final dayKey = _getMidnightKey(_focusedDate);
    final isDayOpen = _dayClosureRegistry[dayKey] ?? true;
    if (!isDayOpen) return [];

    return globalInventory
        .where(
          (slot) =>
              slot.targetDate.year == _focusedDate.year &&
              slot.targetDate.month == _focusedDate.month &&
              slot.targetDate.day == _focusedDate.day,
        )
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
  }

  List<String> get _filteredTimeChoices {
    if (_editingSlot != null || _selectedDatesSet.length > 1) {
      return timeSlotsChoices;
    }
    final existingTimesForDay = _activeDaySlots.map((s) => s.time).toSet();
    return timeSlotsChoices
        .where((time) => !existingTimesForDay.contains(time))
        .toList();
  }

  bool get _isBatchSelectionOpen {
    if (_selectedDatesSet.isEmpty) return false;
    for (var date in _selectedDatesSet) {
      if (!(_dayClosureRegistry[_getMidnightKey(date)] ?? true)) return false;
    }
    return true;
  }

  void _toggleBatchClosureStatus(bool makeOpen) async {
    if (_currentUser == null || _isSaving) return;

    setState(() => _isSaving = true);

    final courtRef = FirebaseFirestore.instance
        .collection('admins')
        .doc(_currentUser.uid)
        .collection('courts')
        .doc(widget.tableName);

    Map<String, dynamic> updates = {};
    for (var date in _selectedDatesSet) {
      updates['closures.${_getMidnightKey(date)}'] = makeOpen;
    }

    await courtRef.update(updates);
    setState(() {
      _isFormOpen = false;
      _isSaving = false;
    });
  }

  List<DateTime> _generateMonthGridDays(DateTime monthFocus) {
    final DateTime firstOfMonth = DateTime(
      monthFocus.year,
      monthFocus.month,
      1,
    );
    int prevMonthDaysOffset = firstOfMonth.weekday - 1;
    final DateTime startDate = firstOfMonth.subtract(
      Duration(days: prevMonthDaysOffset),
    );
    return List.generate(35, (index) => startDate.add(Duration(days: index)));
  }

  void _handleGridDragUpdate(
    DragUpdateDetails details,
    List<DateTime> gridDays,
  ) {
    RenderBox? renderBox;
    for (int i = 0; i < gridDays.length; i++) {
      final key = _gridItemKeys[i];
      if (key?.currentContext != null) {
        renderBox = key!.currentContext!.findRenderObject() as RenderBox;
        final localPos = renderBox.globalToLocal(details.globalPosition);

        if (localPos.dx >= 0 &&
            localPos.dy >= 0 &&
            localPos.dx <= renderBox.size.width &&
            localPos.dy <= renderBox.size.height) {
          final targetMidnight = DateTime(
            gridDays[i].year,
            gridDays[i].month,
            gridDays[i].day,
          );
          if (!targetMidnight.isBefore(_calendarMinBoundary) &&
              !targetMidnight.isAfter(_calendarMaxBoundary)) {
            setState(() {
              _normalizeAndSelectDate(gridDays[i]);
              _focusedDate = gridDays[i];
            });
          }
          break;
        }
      }
    }
  }

  void _openCreateForm() {
    final alternatives = _filteredTimeChoices;
    setState(() {
      _editingSlot = null;
      _selectedTimeChoice = alternatives.isNotEmpty
          ? alternatives.first
          : timeSlotsChoices.first;
      _priceController.text = "25.0";
      _selectedSurcharges = [];
      _isFormOpen = true;
    });
  }

  void _openEditForm(CourtSlot slot) {
    setState(() {
      _editingSlot = slot;
      _selectedTimeChoice = slot.time;
      _priceController.text = slot.price.toString();
      _selectedSurcharges = List.from(slot.surcharges);
      _editingSlotAvailable = slot.isAvailable;
      _isFormOpen = true;
    });
  }

  void _saveFormConfiguration() async {
    if (_currentUser == null || _isSaving) return;

    final double basePrice = double.tryParse(_priceController.text) ?? 25.0;
    setState(() => _isSaving = true);

    final slotsCollection = FirebaseFirestore.instance
        .collection('admins')
        .doc(_currentUser.uid)
        .collection('courts')
        .doc(widget.tableName)
        .collection('slots');

    final List<Map<String, dynamic>> mappedSurcharges = _selectedSurcharges
        .map((e) => {'name': e.name, 'amount': e.amount})
        .toList();

    try {
      if (_editingSlot != null) {
        await slotsCollection.doc(_editingSlot!.id).update({
          'price': basePrice,
          'surcharges': mappedSurcharges,
          'isAvailable': _editingSlotAvailable,
        });
      } else {
        WriteBatch bulkActionBatch = FirebaseFirestore.instance.batch();

        for (var date in _selectedDatesSet) {
          String dateString = DateFormat('yyyy-MM-dd').format(date);
          String documentId =
              "${dateString}_${_selectedTimeChoice.replaceAll(' ', '')}";

          DocumentReference docRef = slotsCollection.doc(documentId);

          bulkActionBatch.set(docRef, {
            'time': _selectedTimeChoice,
            'price': basePrice,
            'isAvailable': true,
            'targetDate': Timestamp.fromDate(date),
            'surcharges': mappedSurcharges,
          });
        }
        await bulkActionBatch.commit();
      }

      setState(() {
        _isFormOpen = false;
        _editingSlot = null;
        _selectedDatesSet.clear();
        _normalizeAndSelectDate(_focusedDate);
      });
    } catch (error) {
      debugPrint("Error committing batch operational metadata: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed allocation update: $error")),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayKey = _getMidnightKey(_focusedDate);
    final bool isCurrentDayOpen = _dayClosureRegistry[dayKey] ?? true;
    final double paddingHorizontal = MediaQuery.of(context).size.width * 0.04;
    final bool isFocusedDayPast = _focusedDate.isBefore(_calendarMinBoundary);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text("${widget.tableName} Slots"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildEmbeddedCalendarHeader()),
                SliverToBoxAdapter(child: _buildMasterClosureToggleRow()),
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: paddingHorizontal,
                    vertical: 16.0,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _selectedDatesSet.length > 1
                                  ? "Selected ${_selectedDatesSet.length} days for Range Action"
                                  : "Slots for ${DateFormat('MMM d, yyyy').format(_focusedDate)}",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!_isFormOpen &&
                              isCurrentDayOpen &&
                              !isFocusedDayPast)
                            ElevatedButton.icon(
                              onPressed: _openCreateForm,
                              icon: const Icon(Icons.add, size: 16),
                              label: Text(
                                _selectedDatesSet.length > 1
                                    ? "Allocate to Range"
                                    : "Add Slot",
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brandMaroon,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_isFormOpen) _buildInlineSlotFormCard(),
                      if (_isFormOpen) const SizedBox(height: 16),
                      isFocusedDayPast
                          ? _buildPastDateNoticeWidget()
                          : (!isCurrentDayOpen
                                ? _buildDayClosedNoticeWidget()
                                : _buildActiveSlotsListView()),
                    ]),
                  ),
                ),
              ],
            ),
            if (_isSaving)
              Positioned.fill(
                child: Container(
                  color: Colors.white24,
                  child: const Center(
                    child: CircularProgressIndicator(color: brandMaroon),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterClosureToggleRow() {
    final bool currentSelectionState = _isBatchSelectionOpen;
    final bool isFocusedDayPast = _focusedDate.isBefore(_calendarMinBoundary);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.door_sliding,
                  size: 18,
                  color: isFocusedDayPast
                      ? Colors.grey
                      : (currentSelectionState ? Colors.green : Colors.red),
                ),
                const SizedBox(width: 8),
                const Text(
                  "Facility Status",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                isFocusedDayPast
                    ? "LOCKED"
                    : (currentSelectionState ? "OPEN" : "CLOSED"),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isFocusedDayPast
                      ? Colors.grey
                      : (currentSelectionState ? Colors.green : Colors.red),
                ),
              ),
              const SizedBox(width: 4),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: isFocusedDayPast ? false : currentSelectionState,
                  activeColor: Colors.green,
                  inactiveThumbColor: isFocusedDayPast
                      ? Colors.grey.shade400
                      : Colors.red,
                  inactiveTrackColor: isFocusedDayPast
                      ? Colors.grey.shade200
                      : Colors.red.withOpacity(0.3),
                  onChanged: isFocusedDayPast || _isSaving
                      ? null
                      : (val) => _toggleBatchClosureStatus(val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmbeddedCalendarHeader() {
    final List<DateTime> gridDays = _generateMonthGridDays(_focusedDate);
    final List<String> weekdaysHeaders = ["M", "T", "W", "T", "F", "S", "S"];
    bool canMoveRight =
        _focusedDate.year < _calendarMaxBoundary.year ||
        _focusedDate.month < _calendarMaxBoundary.month;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() {
                  _focusedDate = DateTime(
                    _focusedDate.year,
                    _focusedDate.month - 1,
                    1,
                  );
                  _selectedDatesSet.clear();
                  _normalizeAndSelectDate(_focusedDate);
                  _isFormOpen = false;
                }),
              ),
              Column(
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(_focusedDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: brandMaroon,
                    ),
                  ),
                  const Text(
                    "Swipe or drag across grids to batch-allocate",
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.chevron_right,
                  color: canMoveRight ? Colors.black : Colors.black26,
                ),
                onPressed: canMoveRight
                    ? () => setState(() {
                        _focusedDate = DateTime(
                          _focusedDate.year,
                          _focusedDate.month + 1,
                          1,
                        );
                        _selectedDatesSet.clear();
                        _normalizeAndSelectDate(_focusedDate);
                        _isFormOpen = false;
                      })
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdaysHeaders
                .map(
                  (day) => Expanded(
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final double gridSpacing = 6.0;
              final double cellWidth =
                  (constraints.maxWidth - (gridSpacing * 6)) / 7;

              return GestureDetector(
                onPanStart: (details) => setState(() {
                  _selectedDatesSet.clear();
                  _isFormOpen = false;
                }),
                onPanUpdate: (details) =>
                    _handleGridDragUpdate(details, gridDays),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: gridSpacing,
                    mainAxisSpacing: gridSpacing,
                    childAspectRatio: cellWidth / (cellWidth + 4),
                  ),
                  itemCount: gridDays.length,
                  itemBuilder: (context, index) {
                    final DateTime currentDay = gridDays[index];
                    final normalizedCurrent = DateTime(
                      currentDay.year,
                      currentDay.month,
                      currentDay.day,
                    );

                    bool isHighlighted = _selectedDatesSet.contains(
                      normalizedCurrent,
                    );
                    bool isPrimaryFocused =
                        currentDay.day == _focusedDate.day &&
                        currentDay.month == _focusedDate.month &&
                        currentDay.year == _focusedDate.year;
                    bool isCurrentMonth =
                        currentDay.month == _focusedDate.month;
                    bool isDateInPast = normalizedCurrent.isBefore(
                      _calendarMinBoundary,
                    );
                    bool isWithinMaxBounds = !normalizedCurrent.isAfter(
                      _calendarMaxBoundary,
                    );
                    bool isDayOpen =
                        _dayClosureRegistry[_getMidnightKey(currentDay)] ??
                        true;

                    bool hasSlotsConfigured = globalInventory.any(
                      (slot) =>
                          slot.targetDate.day == currentDay.day &&
                          slot.targetDate.month == currentDay.month &&
                          slot.targetDate.year == currentDay.year,
                    );
                    _gridItemKeys[index] = _gridItemKeys[index] ?? GlobalKey();

                    return GestureDetector(
                      key: _gridItemKeys[index],
                      onTap: () => setState(() {
                        _selectedDatesSet.clear();
                        _normalizeAndSelectDate(currentDay);
                        _focusedDate = currentDay;
                        _isFormOpen = false;
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDateInPast
                              ? Colors.grey.shade200
                              : (!isWithinMaxBounds
                                    ? Colors.grey.shade100
                                    : (isHighlighted
                                          ? brandMaroon.withOpacity(0.15)
                                          : const Color(0xFFF8F9FA))),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isPrimaryFocused
                                ? brandMaroon
                                : (isHighlighted
                                      ? brandMaroon.withOpacity(0.4)
                                      : Colors.transparent),
                            width: isPrimaryFocused ? 2.0 : 1.0,
                          ),
                        ),
                        child: Opacity(
                          opacity: (isWithinMaxBounds && isCurrentMonth)
                              ? (isDateInPast ? 0.4 : 1.0)
                              : 0.25,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                currentDay.day.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  decoration: (isDateInPast || !isDayOpen)
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  color: !isDayOpen
                                      ? Colors.red
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      hasSlotsConfigured &&
                                          !isDateInPast &&
                                          isDayOpen
                                      ? Colors.teal.shade400
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPastDateNoticeWidget() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          "Historical Records Locked",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildInlineSlotFormCard() {
    final availableChoices = _filteredTimeChoices;
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _editingSlot == null
                  ? "Allocate to Range Configuration"
                  : "Modify Configuration Item",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: brandMaroon,
              ),
            ),
            if (_editingSlot != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Slot Manual Override Status:"),
                  Switch(
                    value: _editingSlotAvailable,
                    activeColor: Colors.green,
                    onChanged: (v) => setState(() => _editingSlotAvailable = v),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            availableChoices.isEmpty && _editingSlot == null
                ? const Text("All slots configured for this day.")
                : DropdownButtonFormField<String>(
                    value: availableChoices.contains(_selectedTimeChoice)
                        ? _selectedTimeChoice
                        : (availableChoices.isNotEmpty
                              ? availableChoices.first
                              : null),
                    items: availableChoices
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedTimeChoice = val!),
                  ),
            const SizedBox(height: 12),
            const Text(
              "Base Unit Price (RM):",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(prefixText: "RM "),
            ),
            const SizedBox(height: 12),
            const Text(
              "Surcharge Modifiers:",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            ...availableSurcharges.map((charge) {
              bool applied = _selectedSurcharges.any(
                (e) => e.name == charge.name,
              );
              return CheckboxListTile(
                title: Text("${charge.name} (+RM${charge.amount})"),
                value: applied,
                onChanged: (checked) => setState(() {
                  if (checked == true) {
                    _selectedSurcharges.add(charge);
                  } else {
                    _selectedSurcharges.removeWhere(
                      (e) => e.name == charge.name,
                    );
                  }
                }),
              );
            }),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() => _isFormOpen = false),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveFormConfiguration,
                  child: Text(
                    _selectedDatesSet.length > 1
                        ? "Allocate to Range"
                        : "Save Slot",
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayClosedNoticeWidget() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Text(
          "This facility date has been marked CLOSED.",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildActiveSlotsListView() {
    final daySlots = _activeDaySlots;
    if (daySlots.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text("No operational slots allocated for this day."),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: daySlots.length,
      itemBuilder: (context, index) {
        final slot = daySlots[index];
        final double grossTotal =
            slot.price + slot.surcharges.fold(0, (v, c) => v + c.amount);

        return Card(
          color: slot.isAvailable ? Colors.white : Colors.grey.shade300,
          elevation: slot.isAvailable ? 2 : 0,
          child: ListTile(
            leading: Icon(
              Icons.access_time_filled,
              color: slot.isAvailable ? brandMaroon : Colors.grey.shade600,
            ),
            title: Text(
              slot.time,
              style: TextStyle(
                color: slot.isAvailable ? Colors.black : Colors.grey.shade700,
                decoration: slot.isAvailable
                    ? TextDecoration.none
                    : TextDecoration.lineThrough,
                fontWeight: slot.isAvailable
                    ? FontWeight.normal
                    : FontWeight.w500,
              ),
            ),
            subtitle: Text(
              slot.isAvailable
                  ? "Base: RM${slot.price}"
                  : "Unavailable / Booked Slot",
              style: TextStyle(
                color: slot.isAvailable ? Colors.black54 : Colors.grey.shade600,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "RM${grossTotal.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: slot.isAvailable
                        ? Colors.black
                        : Colors.grey.shade700,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    size: 16,
                    color: slot.isAvailable
                        ? Colors.black87
                        : Colors.grey.shade600,
                  ),
                  onPressed: () => _openEditForm(slot),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
