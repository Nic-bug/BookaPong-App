import 'package:bookapong_app/Admin/admin_drawer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 1. Data Model
class AccessLog {
  final DateTime timestamp;
  final String court;
  final String accessCode;

  AccessLog({
    required this.timestamp,
    required this.court,
    required this.accessCode,
  });

  String get formattedDayTime => DateFormat('EEEE, h:mm a').format(timestamp);
  String get formattedDate => DateFormat('MMM dd, yyyy').format(timestamp);
}

class AdminAccessLogsPage extends StatelessWidget {
  const AdminAccessLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color brandMaroon = Color(0xFF8B0000);

    final List<AccessLog> logs = [
      AccessLog(
        timestamp: DateTime(2026, 12, 31, 14, 5),
        court: "Table 1",
        accessCode: "8426",
      ),
      AccessLog(
        timestamp: DateTime(2026, 12, 31, 10, 2),
        court: "Table 2",
        accessCode: "7351",
      ),
      AccessLog(
        timestamp: DateTime(2026, 12, 30, 11, 45),
        court: "Table 1",
        accessCode: "9999",
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          "Access Logs",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          const Center(
            child: Text(
              "Admin\nUser",
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 10),
          const Padding(
            padding: EdgeInsets.only(right: 15),
            child: CircleAvatar(
              backgroundColor: brandMaroon,
              child: Text("A", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),

      // INJECTED DRAWER
      drawer: const AdminDrawer(currentPage: 'Access Logs'),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 15,
                        ),
                        color: const Color(0xFFFDF7E7),
                        child: const Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                "Detailed Timestamp",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Court",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                "Access Code",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.separated(
                          itemCount: logs.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            return _buildLogRow(logs[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogRow(AccessLog log) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  log.formattedDayTime,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  log.formattedDate,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              log.court,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              log.accessCode,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
