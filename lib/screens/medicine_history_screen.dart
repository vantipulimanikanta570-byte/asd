import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../language/app_translations.dart';

class MedicineHistoryScreen extends StatefulWidget {
  const MedicineHistoryScreen({super.key});

  @override
  State<MedicineHistoryScreen> createState() =>
      _MedicineHistoryScreenState();
}

class _MedicineHistoryScreenState
    extends State<MedicineHistoryScreen> {
  static const String historyPrefix =
      'medicine_history_';

  List<Map<String, dynamic>> history = [];

  String selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();

    _loadLanguage();
    loadHistory();
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
  // LOAD HISTORY
  // ============================================================

  Future<void> loadHistory() async {
    final SharedPreferencesAsync prefs =
    SharedPreferencesAsync();

    final Set<String> keys =
    await prefs.getKeys();

    final List<Map<String, dynamic>>
    loadedHistory = [];

    for (final key in keys) {
      if (!key.startsWith(historyPrefix)) {
        continue;
      }

      final String? value =
      await prefs.getString(key);

      if (value == null) {
        continue;
      }

      try {
        final Map<String, dynamic> data =
        jsonDecode(value);

        loadedHistory.add(data);
      } catch (_) {}
    }

    // Sort newest first
    loadedHistory.sort((a, b) {
      final DateTime timeA =
          DateTime.tryParse(
            a['time']?.toString() ?? '',
          ) ??
              DateTime(2000);

      final DateTime timeB =
          DateTime.tryParse(
            b['time']?.toString() ?? '',
          ) ??
              DateTime(2000);

      return timeB.compareTo(timeA);
    });

    if (!mounted) {
      return;
    }

    setState(() {
      history = loadedHistory;
    });
  }

  // ============================================================
  // DATE TITLE
  // ============================================================

  String getDateTitle(String? value) {
    if (value == null) {
      return '';
    }

    try {
      final DateTime date =
      DateTime.parse(value).toLocal();

      final DateTime now =
      DateTime.now();

      final DateTime today =
      DateTime(
        now.year,
        now.month,
        now.day,
      );

      final DateTime dateOnly =
      DateTime(
        date.year,
        date.month,
        date.day,
      );

      final int difference =
          today.difference(dateOnly).inDays;

      if (difference == 0) {
        return t('today');
      }

      if (difference == 1) {
        return t('yesterday');
      }

      final List<String> months = [
        t('january'),
        t('february'),
        t('march'),
        t('april'),
        t('may'),
        t('june'),
        t('july'),
        t('august'),
        t('september'),
        t('october'),
        t('november'),
        t('december'),
      ];

      final List<String> weekdays = [
        t('monday'),
        t('tuesday'),
        t('wednesday'),
        t('thursday'),
        t('friday'),
        t('saturday'),
        t('sunday'),
      ];

      return '${weekdays[date.weekday - 1]}, '
          '${months[date.month - 1]} '
          '${date.day}, ${date.year}';
    } catch (_) {
      return '';
    }
  }

  // ============================================================
  // FORMAT TIME
  // ============================================================

  String formatTime(String? value) {
    if (value == null) {
      return '';
    }

    try {
      final DateTime date =
      DateTime.parse(value).toLocal();

      int hour = date.hour;

      final String minute =
      date.minute
          .toString()
          .padLeft(2, '0');

      final String period =
      hour >= 12 ? 'PM' : 'AM';

      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour -= 12;
      }

      return '$hour:$minute $period';
    } catch (_) {
      return '';
    }
  }

  // ============================================================
  // GET STATUS
  // ============================================================

  String getStatus(Map<String, dynamic> item) {
    final String status =
        item['status']?.toString().toLowerCase() ?? '';

    if (status == 'missed') {
      return 'MISSED';
    }

    return 'TAKEN';
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color getStatusColor(String status) {
    if (status == 'MISSED') {
      return Colors.red;
    }

    return Colors.teal;
  }

  // ============================================================
  // STATUS ICON
  // ============================================================

  IconData getStatusIcon(String status) {
    if (status == 'MISSED') {
      return Icons.cancel;
    }

    return Icons.check_circle;
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

        title: Text(
          t('medicineHistory'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: history.isEmpty
          ? Center(
        child: Text(
          t('noMedicineHistory'),
          style: const TextStyle(
            fontSize: 18,
            color: Colors.grey,
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: loadHistory,

        child: ListView.builder(
          padding:
          const EdgeInsets.all(16),

          itemCount:
          history.length,

          itemBuilder:
              (context, index) {
            final item =
            history[index];

            final String medicineName =
                item['medicineName']
                    ?.toString() ??
                    '';

            final String dosage =
                item['dosage']
                    ?.toString() ??
                    '';

            final String dateTitle =
            getDateTitle(
              item['time']?.toString(),
            );

            final String takenTime =
            formatTime(
              item['time']?.toString(),
            );

            // IMPORTANT:
            // Read the actual saved status.
            final String status =
            getStatus(item);

            final Color statusColor =
            getStatusColor(status);

            final IconData statusIcon =
            getStatusIcon(status);

            bool showDateTitle = true;

            if (index > 0) {
              final String previousDate =
              getDateTitle(
                history[index - 1]
                ['time']
                    ?.toString(),
              );

              if (previousDate ==
                  dateTitle) {
                showDateTitle = false;
              }
            }

            return Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                // ------------------------------------------------
                // DATE
                // ------------------------------------------------

                if (showDateTitle)
                  Padding(
                    padding:
                    const EdgeInsets.only(
                      top: 10,
                      bottom: 10,
                    ),

                    child: Text(
                      dateTitle,

                      style:
                      const TextStyle(
                        fontSize: 20,
                        fontWeight:
                        FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ),

                // ------------------------------------------------
                // MEDICINE CARD
                // ------------------------------------------------

                Card(
                  margin:
                  const EdgeInsets.only(
                    bottom: 12,
                  ),

                  elevation: 3,

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      16,
                    ),
                  ),

                  child: ListTile(
                    contentPadding:
                    const EdgeInsets.all(
                      16,
                    ),

                    // ------------------------------------------------
                    // STATUS ICON
                    // ------------------------------------------------

                    leading:
                    Container(
                      width: 50,
                      height: 50,

                      decoration:
                      BoxDecoration(
                        color:
                        statusColor.withValues(alpha: 0.10),

                        shape:
                        BoxShape.circle,
                      ),

                      child:
                      Icon(
                        statusIcon,

                        color:
                        statusColor,

                        size: 30,
                      ),
                    ),

                    // ------------------------------------------------
                    // MEDICINE NAME
                    // ------------------------------------------------

                    title: Text(
                      medicineName,

                      maxLines: 2,

                      overflow:
                      TextOverflow
                          .ellipsis,

                      style:
                      const TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    // ------------------------------------------------
                    // DOSAGE + TIME
                    // ------------------------------------------------

                    subtitle:
                    Padding(
                      padding:
                      const EdgeInsets
                          .only(
                        top: 5,
                      ),

                      child: Text(
                        '${t('dosageLabel')}: '
                            '$dosage\n'
                            '${t('takenAt')} '
                            '$dateTitle '
                            '${t('at')} '
                            '$takenTime',
                      ),
                    ),

                    // ------------------------------------------------
                    // STATUS
                    // ------------------------------------------------

                    trailing:
                    Text(
                      status,

                      style:
                      TextStyle(
                        color:
                        statusColor,

                        fontWeight:
                        FontWeight.bold,

                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}