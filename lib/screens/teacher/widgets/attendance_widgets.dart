import 'package:flutter/material.dart';

class StatBox extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const StatBox({
    super.key,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 13, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class StudentListItem extends StatelessWidget {
  final int idx;
  final String name;
  final bool isPresent;

  const StudentListItem({
    super.key,
    required this.idx,
    required this.name,
    required this.isPresent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isPresent ? const Color(0xFFF2FCF5) : const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPresent ? const Color(0xFFB2F2C9) : const Color(0xFFFFC1C1),
          width: 1.0,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isPresent ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
          child: Text(
            '${idx + 1}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          isPresent ? 'Present' : 'Absent',
          style: TextStyle(
            color:
                isPresent ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          isPresent ? Icons.check_circle : Icons.cancel,
          color: isPresent ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
        ),
      ),
    );
  }
}

class TodayAttendanceCard extends StatelessWidget {
  final List todayRecords;
  final int present;
  final int absent;
  final double percent;

  const TodayAttendanceCard({
    super.key,
    required this.todayRecords,
    required this.present,
    required this.absent,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFF7F9FB),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: const Icon(Icons.calendar_today,
                      color: Color(0xFF2196F3), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Today's Attendance",
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(
                        DateTime.now().toString().split(' ')[0],
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF7B8BB2)),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    '${percent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Color(0xFF2196F3),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                StatBox(value: present, label: 'Present', color: const Color(0xFF4CAF50)),
                const SizedBox(width: 12),
                StatBox(value: absent, label: 'Absent', color: const Color(0xFFF44336)),
                const SizedBox(width: 12),
                StatBox(value: todayRecords.length, label: 'Total', color: const Color(0xFF2196F3)),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('Student List',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: todayRecords.length,
              itemBuilder: (context, idx) {
                final record = todayRecords[idx];
                final studentName =
                    '${record['Student']['fname']} ${record['Student']['lname']}';
                final status = record['status'];
                final isPresent = status == 'present';
                return StudentListItem(
                    idx: idx, name: studentName, isPresent: isPresent);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TakeAttendanceCard extends StatelessWidget {
  final VoidCallback onTap;

  const TakeAttendanceCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFF7F9FB),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(10),
                child: const Icon(Icons.calendar_today,
                    color: Color(0xFF2196F3), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Today's Attendance",
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                    SizedBox(height: 2),
                    Text('Tap to take attendance',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF7B8BB2))),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_forward_ios,
                    color: Color(0xFF2196F3), size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PastAttendanceCard extends StatelessWidget {
  final String date;
  final int present;
  final int absent;
  final double percent;
  final VoidCallback onTap;

  const PastAttendanceCard({
    super.key,
    required this.date,
    required this.present,
    required this.absent,
    required this.percent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFFF7F9FB),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(10),
                child: const Icon(Icons.access_time,
                    color: Color(0xFF2196F3), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(date,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text('Present: $present',
                            style: const TextStyle(
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        const SizedBox(width: 12),
                        Text('Absent: $absent',
                            style: const TextStyle(
                                color: Color(0xFFF44336),
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${percent.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Color(0xFF2196F3),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
