import 'dart:convert';
import 'dart:math';

import 'package:date_picker_timeline/date_picker_widget.dart';
import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:notely/Models/Homework.dart';
import 'package:notely/helpers/HomeworkDatabase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/Event.dart';
import '../Globals.dart' as Globals;

class TimetablePage extends StatefulWidget {
  const TimetablePage({Key? key}) : super(key: key);

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  int timeShift = 0;
  DateTime today = DateTime.now();
  List<Event> _eventList = List.empty(growable: true);
  List<double> itemPositions = [];

// Define start and end of the day as DateTime objects
  final startOfDay = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day, 0, 0);
  final endOfDay = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59);

  // Define variables to calculate the position of the line
  final now = DateTime.now();
  late double currentTime;

  @override
  initState() {
    super.initState();
    getData();
    final totalDuration = endOfDay.difference(startOfDay).inMinutes;
    currentTime = now.difference(startOfDay).inMinutes / totalDuration;
  }

  double calculateItemHeight(DateTime startTime, DateTime endTime,
      DateTime minStartTime, DateTime maxEndTime, double minHeight) {
    final itemDuration = endTime.difference(startTime).inMinutes;
    final dayDuration = maxEndTime.difference(minStartTime).inMinutes;
    final itemHeight = itemDuration / dayDuration;
    return max(itemHeight * minHeight, minHeight);
  }

  void getData() async {
    final prefs = await SharedPreferences.getInstance();
    String school = await prefs.getString("school") ?? "";
    String dateFormatted = DateFormat('yyyy-MM-dd').format(today);
    String url = Globals.apiBase +
        school.toLowerCase() +
        "/rest/v1" +
        "/me/events?min_date=$dateFormatted&max_date=$dateFormatted";
    print(url);
    try {
      await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer ' + Globals.accessToken,
      }).then((response) {
        if (mounted) {
          setState(() {
            _eventList = (json.decode(response.body) as List)
                .map((i) => Event.fromJson(i))
                .toList();
            _eventList.forEach((element) {
              print(element.id);
            });
          });
        }
      });
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Plan",
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.start,
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  DateFormat('dd.MM.yyyy').format(today).toString(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
        DatePicker(
          DateTime.now(),
          height: 90,
          initialSelectedDate: today,
          selectionColor: Globals.isDark
              ? Color.fromARGB(255, 46, 46, 46)
              : Colors.grey.withOpacity(0.2),
          selectedTextColor: Globals.isDark ? Colors.white : Colors.black,
          dayTextStyle: TextStyle(color: Colors.grey),
          monthTextStyle: TextStyle(color: Colors.grey),
          dateTextStyle: TextStyle(color: Colors.grey),
          locale: "de",
          onDateChange: (date) {
            setState(() {
              today = date;
            });
            getData();
          },
        ),
        Expanded(
          child: (_eventList.isNotEmpty)
              ? ListView.builder(
                  shrinkWrap: true,
                  itemCount: _eventList.length,
                  itemBuilder: (BuildContext ctxt, int index) {
                    Event event = _eventList[index];
                    return LayoutBuilder(builder:
                        (BuildContext context, BoxConstraints constraints) {
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(
                            top: 5, bottom: 5, left: 10.0, right: 10.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                            onTap: () {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    // Get data of TextFields
                                    TextEditingController titleController =
                                        TextEditingController();
                                    TextEditingController
                                        descriptionController =
                                        TextEditingController();
                                    return AlertDialog(
                                      title: Text("Event bearbeiten"),
                                      content: Container(
                                        height: 150,
                                        width: 300,
                                        child: Column(
                                          children: [
                                            TextField(
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyText1!
                                                    .color,
                                              ),
                                              decoration: const InputDecoration(
                                                border: UnderlineInputBorder(),
                                                labelStyle: TextStyle(
                                                  color: Colors.white,
                                                ),
                                                labelText: 'Titel',
                                              ),
                                              controller: titleController,
                                            ),
                                            TextField(
                                              decoration: InputDecoration(
                                                labelStyle: TextStyle(
                                                  color: Theme.of(context)
                                                      .textTheme
                                                      .bodyText1!
                                                      .color,
                                                ),
                                                border: UnderlineInputBorder(),
                                                labelText: 'Details (optional)',
                                              ),
                                              controller: descriptionController,
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          child: Text("Abbrechen"),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: Text("Speichern"),
                                          onPressed: () async {
                                            // Get text of TextFields
                                            String title = titleController.text;
                                            String description =
                                                descriptionController.text;
                                            DateTime startDate = DateTime.parse(
                                                event.startDate!);
                                            Homework homework = Homework(
                                              id: event.id!,
                                              lessonName: event.courseName!,
                                              title: title,
                                              description: description,
                                              dueDate: startDate,
                                              isDone: false,
                                            );

                                            await HomeworkDatabase.instance
                                                .create(homework);

                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  });
                            },
                            child: Container(
                              padding: EdgeInsets.all(12),
                              child: IntrinsicHeight(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            event.startDate!.substring(
                                                event.startDate!.length - 5),
                                            style: TextStyle(
                                                fontSize: 18.0,
                                                fontWeight: FontWeight.w600),
                                            textAlign: TextAlign.center,
                                          ),
                                          Opacity(
                                            opacity: 0.75,
                                            child: Text(
                                              event.endDate!
                                                  .substring(
                                                      event.endDate!.length - 5)
                                                  .toString(),
                                              style: TextStyle(
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 9.0,
                                    ),
                                    Container(
                                      width: 2,
                                      height: double.infinity,
                                      color: (DateTime.now().isAfter(
                                                  DateTime.parse(
                                                      event.startDate!)) &&
                                              DateTime.now().isBefore(
                                                  DateTime.parse(
                                                      event.endDate!)))
                                          ? Colors.blue
                                          : Colors.white,
                                    ),
                                    SizedBox(
                                      width: 9.0,
                                    ),
                                    Expanded(
                                      flex: 12,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            event.courseName.toString(),
                                            textAlign: TextAlign.start,
                                            style: const TextStyle(
                                                fontSize: 21,
                                                height: 1.1,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          Text(
                                            event.teachers!.first.toString(),
                                            textAlign: TextAlign.start,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              height: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      event.roomToken.toString(),
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                      );
                    });
                  })
              : Center(
                  child: Text(
                    "Keine Lektionen eingetragen",
                    style: TextStyle(fontSize: 20.0),
                  ),
                ),
        ),
      ],
    );
  }
}
