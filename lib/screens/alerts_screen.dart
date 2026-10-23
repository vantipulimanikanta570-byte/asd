import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/medicine.dart';
import '../language/app_translations.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() =>
      _AlertsScreenState();
}

class _AlertsScreenState
    extends State<AlertsScreen> {
  static const String medicinesKey =
      'saved_medicines';

  List<Medicine> medicines = [];

  String selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();

    _loadLanguage();
    loadMedicines();
  }

  // ============================================================
  // LOAD LANGUAGE
  // ============================================================

  Future<void> _loadLanguage() async {
    final prefs =
    await SharedPreferences.getInstance();

    final savedLanguage =
    prefs.getString('selected_language');

    if (!mounted) {
      return;
    }

    setState(() {
      selectedLanguage =
          savedLanguage ?? 'English';
    });
  }

  String t(String key) {
    return AppTranslations(selectedLanguage)
        .text(key);
  }

  // ============================================================
  // LOAD MEDICINES
  // ============================================================

  Future<void> loadMedicines() async {
    final SharedPreferencesAsync prefs =
    SharedPreferencesAsync();

    final String? savedData =
    await prefs.getString(medicinesKey);

    if (savedData == null ||
        savedData.isEmpty) {
      return;
    }

    try {
      final List<dynamic> data =
      jsonDecode(savedData);

      final List<Medicine> loadedMedicines =
      data.map((item) {
        return Medicine.fromMap(
          Map<String, dynamic>.from(item),
        );
      }).toList();

      if (!mounted) {
        return;
      }

      setState(() {
        medicines = loadedMedicines;
      });
    } catch (e) {
      print(
        'ERROR LOADING ALERTS: $e',
      );
    }
  }

  // ============================================================
  // CONVERT MEDICINE TIME TO TODAY'S DATETIME
  // ============================================================

  DateTime? getReminderDateTime(
      String time) {
    try {
      final RegExp regex = RegExp(
        r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
        caseSensitive: false,
      );

      final Match? match =
      regex.firstMatch(
        time.trim(),
      );

      if (match == null) {
        return null;
      }

      int hour =
      int.parse(match.group(1)!);

      final int minute =
      int.parse(match.group(2)!);

      final String period =
      match.group(3)!.toUpperCase();

      if (period == 'AM' &&
          hour == 12) {
        hour = 0;
      }

      if (period == 'PM' &&
          hour != 12) {
        hour += 12;
      }

      final DateTime now =
      DateTime.now();

      return DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // TIME REMAINING
  // ============================================================

  String getTimeRemaining(
      Medicine medicine) {
    final DateTime? reminder =
    getReminderDateTime(
      medicine.time,
    );

    if (reminder == null) {
      return '${t('medicineTime')}: '
          '${medicine.time}';
    }

    final DateTime now =
    DateTime.now();

    DateTime nextReminder =
        reminder;

    if (nextReminder.isBefore(now)) {
      nextReminder =
          nextReminder.add(
            const Duration(days: 1),
          );
    }

    final Duration difference =
    nextReminder.difference(now);

    final int totalMinutes =
        difference.inMinutes;

    if (totalMinutes <= 0) {
      return t('medicineTimeNow');
    }

    final int hours =
        totalMinutes ~/ 60;

    final int minutes =
        totalMinutes % 60;

    if (hours > 0 &&
        minutes > 0) {
      return '${t('reminderIn')} '
          '$hours ${t('hr')} '
          '$minutes ${t('min')}';
    }

    if (hours > 0) {
      return '${t('reminderIn')} '
          '$hours ${t('hr')}';
    }

    return '${t('reminderIn')} '
        '$minutes ${t('min')}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xffF5FAFA),

      appBar: AppBar(
        backgroundColor:
        Colors.teal,

        elevation: 0,

        title: Text(
          t('alerts'),
          style: const TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),

      body: medicines.isEmpty
          ? Center(
        child: Text(
          t('noUpcomingReminders'),
          style:
          const TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh:
        loadMedicines,

        child:
        ListView.builder(
          padding:
          const EdgeInsets.all(
            16,
          ),

          itemCount:
          medicines.length,

          itemBuilder:
              (context, index) {
            final Medicine medicine =
            medicines[index];

            final String remaining =
            getTimeRemaining(
              medicine,
            );

            return Card(
              margin:
              const EdgeInsets.only(
                bottom: 16,
              ),

              elevation: 4,

              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                  20,
                ),
              ),

              child: Padding(
                padding:
                const EdgeInsets.all(
                  18,
                ),

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

                  children: [
                    // ==================================================
                    // NEXT REMINDER
                    // ==================================================

                    Container(
                      width:
                      double.infinity,

                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),

                      decoration:
                      BoxDecoration(
                        color: Colors
                            .teal
                            .shade50,

                        borderRadius:
                        BorderRadius
                            .circular(
                          12,
                        ),
                      ),

                      child: Row(
                        children: [
                          const Icon(
                            Icons
                                .notifications_active,
                            color:
                            Colors.teal,
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          Expanded(
                            child: Text(
                              remaining,

                              style:
                              const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                FontWeight
                                    .bold,
                                color:
                                Colors.teal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // ==================================================
                    // MEDICINE INFORMATION
                    // ==================================================

                    Row(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                      children: [
                        Container(
                          width: 58,
                          height: 58,

                          decoration:
                          BoxDecoration(
                            color: Colors
                                .teal
                                .shade50,

                            shape:
                            BoxShape
                                .circle,
                          ),

                          child:
                          const Icon(
                            Icons.medication,
                            color:
                            Colors.teal,
                            size: 32,
                          ),
                        ),

                        const SizedBox(
                          width: 14,
                        ),

                        Expanded(
                          child:
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                            children: [
                              Text(
                                medicine.name,

                                maxLines: 2,

                                overflow:
                                TextOverflow
                                    .ellipsis,

                                style:
                                const TextStyle(
                                  fontSize:
                                  20,
                                  fontWeight:
                                  FontWeight
                                      .bold,
                                ),
                              ),

                              const SizedBox(
                                height: 6,
                              ),

                              Text(
                                '${t('dosageLabel')}: '
                                    '${medicine.dosage}',

                                style:
                                const TextStyle(
                                  fontSize:
                                  15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    // ==================================================
                    // TIME
                    // ==================================================

                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color:
                          Colors.teal,
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        Text(
                          '${t('medicineTime')}:',

                          style:
                          const TextStyle(
                            fontSize: 15,
                            color:
                            Colors.grey,
                          ),
                        ),

                        const SizedBox(
                          width: 6,
                        ),

                        Text(
                          medicine.time,

                          style:
                          const TextStyle(
                            fontSize: 17,
                            fontWeight:
                            FontWeight
                                .bold,
                            color:
                            Colors.teal,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    // ==================================================
                    // FREQUENCY
                    // ==================================================

                    Row(
                      children: [
                        const Icon(
                          Icons.repeat,
                          color:
                          Colors.teal,
                          size: 22,
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        Text(
                          medicine.frequency ==
                              'Every Day'
                              ? t(
                            'everyDay',
                          )
                              : t(
                            'once',
                          ),

                          style:
                          TextStyle(
                            fontSize: 15,
                            color: Colors
                                .grey
                                .shade700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    // ==================================================
                    // 30 MINUTE INFORMATION
                    // ==================================================

                    const Divider(),

                    const SizedBox(
                      height: 8,
                    ),

                    Row(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                      children: [
                        const Icon(
                          Icons.alarm,
                          color:
                          Colors.orange,
                        ),

                        const SizedBox(
                          width: 8,
                        ),

                        Expanded(
                          child: Text(
                            t(
                              'alert30Minutes',
                            ),

                            style:
                            TextStyle(
                              fontSize: 14,
                              color: Colors
                                  .grey
                                  .shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}