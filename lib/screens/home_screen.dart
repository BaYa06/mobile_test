import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/apiServices.dart';
import '../services/supabase_service.dart';
import '../models/schedule.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentPage = 0;
  String _selectedGroup = "Choose Group";
  String? _selectedDay;
  List<Schedule> _schedule = [];
  bool _isLoading = false;
  List<String> _groups = [];
  bool _isGroupsLoading = false;
  late Timer _timer;

  final SupabaseService _supabaseService = SupabaseService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadGroups();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isGroupsLoading = true;
    });
    try {
      final groups = await _supabaseService.getGroups();
      setState(() {
        _groups = groups;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('groups', jsonEncode(groups));
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('groups');
      if (cached != null) {
        setState(() {
          _groups = List<String>.from(jsonDecode(cached));
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading groups: $e')),
        );
      }
    } finally {
      setState(() {
        _isGroupsLoading = false;
      });
    }
  }

  Future<void> _loadSchedule(String groupName, [String? day]) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final schedule = await _apiService.getSchedule(groupName, day);
      setState(() {
        _schedule = schedule;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'schedule_$groupName${day ?? ''}',
        jsonEncode(schedule.map((s) => s.toJson()).toList()),
      );
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('schedule_$groupName${day ?? ''}');
      if (cached != null) {
        List<dynamic> data = jsonDecode(cached);
        setState(() {
          _schedule = data.map((json) => Schedule.fromJson(json)).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading schedule: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showModal() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          height: 300,
          child: _isGroupsLoading
              ? const Center(child: CircularProgressIndicator())
              : _groups.isEmpty
                  ? const Center(child: Text('No groups available'))
                  : ListView.builder(
                      itemCount: _groups.length,
                      itemBuilder: (context, index) {
                        final group = _groups[index];
                        return ListTile(
                          title: Text(
                            group,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color.fromRGBO(106, 30, 203, 1.0),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
                          onTap: () {
                            setState(() {
                              _selectedGroup = group;
                              _selectedDay = null;
                            });
                            _loadSchedule(group);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
        );
      },
    );
  }

  String getLessonStatus(String timeSlot) {
    try {
      final times = timeSlot.split('-');
      final startTimeStr = times[0].trim();
      final endTimeStr = times[1].trim();

      final now = DateTime.now();
      final formatter = DateFormat('HH:mm');
      final startTime = formatter.parse(startTimeStr);
      final endTime = formatter.parse(endTimeStr);

      final today = DateTime(now.year, now.month, now.day);
      final lessonStart = DateTime(today.year, today.month, today.day, startTime.hour, startTime.minute);
      final lessonEnd = DateTime(today.year, today.month, today.day, endTime.hour, endTime.minute);


      if (now.isBefore(lessonStart)) {

        final duration = lessonStart.difference(now);
        final seconds = duration.inSeconds;
        final hours = seconds ~/ 3600;
        final minutes = (seconds % 3600) ~/ 60;
        final remainingSeconds = seconds % 60;
        return hours > 0
            ? 'Starts in ${hours}h ${minutes}m ${remainingSeconds}s'
            : 'Starts in ${minutes}m ${remainingSeconds}s';
      } else if (now.isBefore(lessonEnd)) {

        final duration = lessonEnd.difference(now);
        final seconds = duration.inSeconds;
        final hours = seconds ~/ 3600;
        final minutes = (seconds % 3600) ~/ 60;
        final remainingSeconds = seconds % 60;
        return hours > 0
            ? 'Ends in ${hours}h ${minutes}m ${remainingSeconds}s'
            : 'Ends in ${minutes}m ${remainingSeconds}s';
      } else {
        return 'Finished';
      }
    } catch (e) {
      return 'Invalid time format';
    }
  }

  double getLessonProgress(String timeSlot) {
    try {
      final times = timeSlot.split('-');
      final startTimeStr = times[0].trim();
      final endTimeStr = times[1].trim();

      final now = DateTime.now();
      final formatter = DateFormat('HH:mm');
      final startTime = formatter.parse(startTimeStr);
      final endTime = formatter.parse(endTimeStr);

      final today = DateTime(now.year, now.month, now.day);
      final lessonStart = DateTime(today.year, today.month, today.day, startTime.hour, startTime.minute);
      final lessonEnd = DateTime(today.year, today.month, today.day, endTime.hour, endTime.minute);

      if (now.isBefore(lessonStart)) {
        return 0.0; // Урок не начался
      } else if (now.isBefore(lessonEnd)) {
        final totalDuration = lessonEnd.difference(lessonStart).inSeconds;
        final elapsedDuration = now.difference(lessonStart).inSeconds;
        return elapsedDuration / totalDuration; // Процент от 0.0 до 1.0
      } else {
        return 1.0; // Урок закончился
      }
    } catch (e) {
      return 0.0; // В случае ошибки
    }
  }

  @override
  Widget build(BuildContext context) {
    // Форматируем текущую дату и день недели
    final now = DateTime.now();
    final formattedDate = DateFormat('dd.MM.yyyy').format(now);
    final weekdayName = DateFormat('EEEE').format(now);
    final currentDay = DateFormat('EEEE').format(DateTime.now());
    final filteredSchedule = _schedule.where((item) => item.day == currentDay).toList();

    Widget content;
    if (currentPage == 0) {
      final filteredSchedule = _schedule.where((item) => item.day == weekdayName).toList();
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            child: Text(
              '$formattedDate | $weekdayName',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color.fromRGBO(106, 30, 203, 1.0),
              ),
            ),
          ),
          const SizedBox(height: 16.0), // Отступ перед расписанием
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _schedule.isEmpty
                    ? const Center(child: Text('No schedule available'))
                    : ListView.builder(
                        itemCount: filteredSchedule.length,
                        itemBuilder: (context, index) {
                          final item = filteredSchedule[index];
                          final progress = getLessonProgress(item.timeSlot);
                          final progressPercentage = (progress * 100).round();
                          final isFinished = progress == 1.0; // Урок закончился
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              title: Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  item.subject,
                                  style: TextStyle(
                                    color: isFinished ? Colors.grey : const Color.fromRGBO(106, 30, 203, 1.0),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '⏰ Time: ${item.timeSlot}',
                                    style: TextStyle(fontSize: 16, color: isFinished ? Colors.grey : Colors.black),
                                  ),
                                  Text(
                                    '📍 Room: ${item.room}',
                                    style: TextStyle(fontSize: 16, color: isFinished ? Colors.grey : Colors.black),
                                  ),
                                  Text(
                                    '👨‍🏫 Teacher: ${item.teacher}',
                                    style: TextStyle(fontSize: 16, color: isFinished ? Colors.grey : Colors.black),
                                  ),
                                  Text(
                                    '⏳ Status: ${getLessonStatus(item.timeSlot)} ($progressPercentage%)',
                                    style: TextStyle(fontSize: 16, color: isFinished ? Colors.grey : Colors.black),
                                  ),
                                  if (progress > 0.0 && progress < 1.0) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: Colors.grey[300],
                                        valueColor: const AlwaysStoppedAnimation<Color>(
                                          Color.fromRGBO(106, 30, 203, 1.0),
                                        ),
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      );
    } else if (currentPage == 1) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Container(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedDay = 'Monday';
                      });
                      if (_selectedGroup != 'Choose Group') {
                        _loadSchedule(_selectedGroup, _selectedDay);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedDay == 'Monday'
                        ? const Color.fromRGBO(150, 80, 255, 1.0) // Цвет активной кнопки
                        : const Color.fromRGBO(106, 30, 203, 1.0), // Цвет неактивной кнопки
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: const Text(
                      'Mon',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedDay = 'Tuesday';
                      });
                      if (_selectedGroup != 'Choose Group') {
                        _loadSchedule(_selectedGroup, _selectedDay);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedDay == 'Tuesday'
                        ? const Color.fromRGBO(150, 80, 255, 1.0) // Цвет активной кнопки
                        : const Color.fromRGBO(106, 30, 203, 1.0), // Цвет неактивной кнопки
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: const Text(
                      'Tue',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedDay = 'Wednesday';
                      });
                      if (_selectedGroup != 'Choose Group') {
                        _loadSchedule(_selectedGroup, _selectedDay);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedDay == 'Wednesday'
                        ? const Color.fromRGBO(150, 80, 255, 1.0) // Цвет активной кнопки
                        : const Color.fromRGBO(106, 30, 203, 1.0), // Цвет неактивной кнопки
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: const Text(
                      'Wed',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedDay = 'Thursday';
                      });
                      if (_selectedGroup != 'Choose Group') {
                        _loadSchedule(_selectedGroup, _selectedDay);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedDay == 'Thursday'
                        ? const Color.fromRGBO(150, 80, 255, 1.0) // Цвет активной кнопки
                        : const Color.fromRGBO(106, 30, 203, 1.0), // Цвет неактивной кнопки
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: const Text(
                      'Thu',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedDay = 'Friday';
                      });
                      if (_selectedGroup != 'Choose Group') {
                        _loadSchedule(_selectedGroup, _selectedDay);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedDay == 'Friday'
                        ? const Color.fromRGBO(150, 80, 255, 1.0) // Цвет активной кнопки
                        : const Color.fromRGBO(106, 30, 203, 1.0), // Цвет неактивной кнопки
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    child: const Text(
                      'Fri',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  // Добавь кнопки для Wed, Thu, Fri
                ],
              ),
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _schedule.isEmpty
                  ? const Center(child: Text('No schedule available'))
                  : Expanded(
                      child: ListView.builder(
                        itemCount: _schedule.length,
                        itemBuilder: (context, index) {
                          final item = _schedule[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Margin для каждого элемента
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              title: Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  item.subject,
                                  style: TextStyle(
                                    color: Color.fromRGBO(106, 30, 203, 1.0),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              subtitle: Text('⏰ Time: ${item.timeSlot} \n 📍 Room: ${item.room} \n 👨‍🏫 Teacher: ${item.teacher}'),
                              // contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          );
                        },
                      ),
                    ),
        ],
      );
    } else {
      content = const Center(child: Text('Calendar Page'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Container(
          margin: const EdgeInsets.only(bottom: 0),
          child: Text(
            _selectedGroup,
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: _showModal,
          ),
        ],
      ),
      body: content,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentPage,
        onTap: (index) {
          setState(() {
            currentPage = index;
            if (index == 1) {
              _selectedDay = 'Monday'; // Устанавливаем Monday для Week
              if (_selectedGroup != 'Choose Group') {
                _loadSchedule(_selectedGroup, _selectedDay);
              }
            } 
            else if (index == 0) {
              _selectedDay = '$weekdayName'; // Сбрасываем день для Today
              if (_selectedGroup != 'Choose Group') {
                _loadSchedule(_selectedGroup); // Загружаем расписание без фильтра по дню
              }
            }
          });
        },
        selectedItemColor: const Color.fromRGBO(106, 30, 203, 1.0),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_view_week), label: 'Week'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Calendar'),
        ],
      ),
    );
  }
}