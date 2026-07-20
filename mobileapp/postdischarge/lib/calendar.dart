import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {

  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  // ---------------- FETCH EVENTS ----------------
  Future<void> fetchEvents() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    String baseUrl = sh.getString('url') ?? "http://10.0.2.2:8000";

    final response =
    await http.get(Uri.parse("$baseUrl/get_calendar_events/"));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] == "ok") {
        Map<DateTime, List<Map<String, dynamic>>> loadedEvents = {};

        for (var event in data['events']) {
          DateTime date = DateTime.parse(event['event_date']);
          DateTime normalized =
          DateTime(date.year, date.month, date.day);

          loadedEvents.putIfAbsent(normalized, () => []);
          loadedEvents[normalized]!.add(event);
        }

        setState(() {
          _events = loadedEvents;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  bool _hasEvent(DateTime day) {
    return _getEventsForDay(day).isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F7),

      appBar: AppBar(
        title: const Text("Event Calendar"),
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 2,
      ),

      body: Column(
        children: [

          const SizedBox(height: 10),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            elevation: 5,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2035, 12, 31),
                focusedDay: _focusedDay,
                rowHeight: 65,

                selectedDayPredicate: (day) =>
                    isSameDay(_selectedDay, day),

                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                calendarBuilders: CalendarBuilders(

                  defaultBuilder: (context, day, focusedDay) {
                    bool hasEvent = _hasEvent(day);

                    return _buildDayTile(
                      day: day,
                      isSelected: false,
                      isToday: false,
                      hasEvent: hasEvent,
                    );
                  },

                  todayBuilder: (context, day, focusedDay) {
                    return _buildDayTile(
                      day: day,
                      isSelected: false,
                      isToday: true,
                      hasEvent: _hasEvent(day),
                    );
                  },

                  selectedBuilder: (context, day, focusedDay) {
                    return _buildDayTile(
                      day: day,
                      isSelected: true,
                      isToday: false,
                      hasEvent: _hasEvent(day),
                    );
                  },
                ),

                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });

                  final events =
                  _getEventsForDay(selectedDay);

                  if (events.isNotEmpty) {
                    _showEventDialog(events);
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 15),

          const Text(
            "Tap highlighted dates to view events",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- CUSTOM DAY TILE ----------------
  Widget _buildDayTile({
    required DateTime day,
    required bool isSelected,
    required bool isToday,
    required bool hasEvent,
  }) {

    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,

        // Selected gradient ring
        gradient: isSelected
            ? const LinearGradient(
          colors: [
            Color(0xFF3949AB),
            Color(0xFF5C6BC0),
          ],
        )
            : null,

        border: hasEvent && !isSelected
            ? Border.all(
          color: const Color(0xFF1B5E20),
          width: 2,
        )
            : null,

        boxShadow: isToday
            ? [
          BoxShadow(
            color:
            const Color(0xFF43A047).withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ]
            : null,
      ),

      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? null
              : isToday
              ? const Color(0xFFE8F5E9)
              : Colors.transparent,
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : hasEvent
                ? const Color(0xFF1B5E20)
                : Colors.black87,
          ),
        ),
      ),
    );
  }

  // ---------------- EVENT BOTTOM SHEET ----------------
  void _showEventDialog(List<Map<String, dynamic>> events) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const Text(
                "Events",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              ...events.map((event) => Card(
                shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(15)),
                elevation: 3,
                child: ListTile(
                  leading: const Icon(
                    Icons.event,
                    color: Color(0xFF1B5E20),
                  ),
                  title: Text(
                    event['title'],
                    style: const TextStyle(
                        fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text(event['description']),
                      const SizedBox(height: 5),
                      Text(
                        "By: ${event['organization']}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              )),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
