import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'language/app_translations.dart';
import 'services/notification_service.dart';

class MedicineAlarmScreen extends StatefulWidget {
  final String medicineName;
  final String dosage;
  final String foodTiming;
  final String imagePath;
  final String alertType;

  // 0 = original alarm
  // 1 = first retry
  // 2 = final retry
  final int retryAttempt;

  const MedicineAlarmScreen({
    super.key,
    required this.medicineName,
    required this.dosage,
    this.foodTiming = 'Any Time',
    this.imagePath = '',
    this.alertType = 'Sound + Vibration',
    this.retryAttempt = 0,
  });

  @override
  State<MedicineAlarmScreen> createState() =>
      _MedicineAlarmScreenState();
}

class _MedicineAlarmScreenState
    extends State<MedicineAlarmScreen> {
  String selectedLanguage = 'English';

  bool isProcessing = false;

  Timer? _missedTimer;

  bool _missedSaved = false;

  @override
  void initState() {
    super.initState();

    _loadLanguage();

    // Only the FINAL retry gets the
    // automatic MISSED timer.
    if (widget.retryAttempt == 2) {
      _startMissedTimer();
    }
  }

  // ============================================================
  // START MISSED TIMER
  // ============================================================

  void _startMissedTimer() {
    print(
      'FINAL RETRY DETECTED - '
          '60 SECOND MISSED TIMER STARTED',
    );

    _missedTimer = Timer(
      const Duration(seconds: 60),
          () async {
        // Prevent duplicate MISSED records.
        if (_missedSaved) {
          return;
        }

        _missedSaved = true;

        print(
          '60 SECONDS FINISHED - '
              'SAVING MEDICINE AS MISSED',
        );

        try {
          // IMPORTANT:
          // Save MISSED FIRST.
          // Do NOT check mounted before this.
          await saveMissedMedicineHistory(
            medicineName: widget.medicineName,
            dosage: widget.dosage,
          );

          print(
            'MEDICINE AUTOMATICALLY MARKED MISSED: '
                '${widget.medicineName}',
          );

          // Only UI operations require mounted.
          if (!mounted) {
            return;
          }

          if (!isProcessing) {
            setState(() {
              isProcessing = true;
            });
          }

          Navigator.of(context).pop('MISSED');
        } catch (e) {
          print(
            'ERROR SAVING MISSED MEDICINE: $e',
          );

          // Allow another attempt if saving failed.
          _missedSaved = false;

          if (!mounted) {
            return;
          }

          setState(() {
            isProcessing = false;
          });
        }
      },
    );
  }

  // ============================================================
  // CANCEL MISSED TIMER
  // ============================================================

  void _cancelMissedTimer() {
    if (_missedTimer != null) {
      _missedTimer!.cancel();
      _missedTimer = null;

      print(
        'MISSED TIMER CANCELLED',
      );
    }
  }

  @override
  void dispose() {
    _cancelMissedTimer();
    super.dispose();
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
  // FOOD TIMING TRANSLATION
  // ============================================================

  String translatedFoodTiming() {
    switch (widget.foodTiming) {
      case 'Before Food':
        return t('beforeFood');

      case 'After Food':
        return t('afterFood');

      case 'Any Time':
        return t('anyTime');

      default:
        return widget.foodTiming;
    }
  }

  // ============================================================
  // TAKEN
  // ============================================================

  Future<void> _markAsTaken() async {
    if (isProcessing) {
      return;
    }

    // Patient responded.
    // Cancel automatic MISSED timer.
    _cancelMissedTimer();

    setState(() {
      isProcessing = true;
    });

    try {
      await saveMedicineHistory(
        medicineName:
        widget.medicineName,
        dosage:
        widget.dosage,
      );

      print(
        'FULL SCREEN MEDICINE MARKED TAKEN: '
            '${widget.medicineName}',
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop('TAKEN');
    } catch (e) {
      print(
        'ERROR SAVING MEDICINE HISTORY: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isProcessing = false;
      });
    }
  }

  // ============================================================
  // SNOOZE
  // ============================================================

  Future<void> _snoozeMedicine() async {
    if (isProcessing) {
      return;
    }

    // Patient responded.
    // Cancel automatic MISSED timer.
    _cancelMissedTimer();

    setState(() {
      isProcessing = true;
    });

    try {
      await scheduleSnoozeNotification(
        medicineName:
        widget.medicineName,
        dosage:
        widget.dosage,
        alertType:
        widget.alertType,
      );

      print(
        'FULL SCREEN SNOOZE SCHEDULED: '
            '${widget.medicineName}',
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop('SNOOZE');
    } catch (e) {
      print(
        'ERROR SCHEDULING SNOOZE: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isProcessing = false;
      });
    }
  }

  // ============================================================
  // BUILD SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF5FAF9),
      body: SafeArea(
        child: Padding(
          padding:
          const EdgeInsets.fromLTRB(
            24,
            24,
            24,
            30,
          ),
          child: Column(
            children: [
              const Spacer(),

              const Icon(
                Icons.alarm_rounded,
                size: 54,
                color: Color(0xFF009688),
              ),

              const SizedBox(height: 18),

              Text(
                t('timeToTakeMedicine'),
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  fontSize: 18,
                  fontWeight:
                  FontWeight.w700,
                  letterSpacing: 1.2,
                  color:
                  Color(0xFF00796B),
                ),
              ),

              const SizedBox(height: 24),

              _buildMedicineImage(),

              const SizedBox(height: 24),

              Text(
                widget.medicineName,
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                '${t('dosageLabel')}: ${widget.dosage}',
                textAlign:
                TextAlign.center,
                style:
                const TextStyle(
                  fontSize: 21,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration:
                BoxDecoration(
                  color:
                  const Color(0xFFE0F2F1),
                  borderRadius:
                  BorderRadius.circular(30),
                ),
                child: Text(
                  translatedFoodTiming(),
                  style:
                  const TextStyle(
                    fontSize: 17,
                    fontWeight:
                    FontWeight.w600,
                    color:
                    Color(0xFF00796B),
                  ),
                ),
              ),

              const Spacer(),

              // ==================================================
              // TAKEN BUTTON
              // ==================================================

              SizedBox(
                width:
                double.infinity,
                height: 58,
                child:
                ElevatedButton.icon(
                  onPressed:
                  isProcessing
                      ? null
                      : _markAsTaken,
                  icon:
                  const Icon(
                    Icons.check_rounded,
                    size: 27,
                  ),
                  label: Text(
                    t('taken'),
                    style:
                    const TextStyle(
                      fontSize: 19,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF009688),
                    foregroundColor:
                    Colors.white,
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        18,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ==================================================
              // SNOOZE BUTTON
              // ==================================================

              SizedBox(
                width:
                double.infinity,
                height: 58,
                child:
                OutlinedButton.icon(
                  onPressed:
                  isProcessing
                      ? null
                      : _snoozeMedicine,
                  icon:
                  const Icon(
                    Icons.snooze_rounded,
                    size: 27,
                  ),
                  label: Text(
                    t('snooze10Min'),
                    style:
                    const TextStyle(
                      fontSize: 19,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  style:
                  OutlinedButton.styleFrom(
                    foregroundColor:
                    const Color(0xFF00796B),
                    side:
                    const BorderSide(
                      color:
                      Color(0xFF009688),
                      width: 2,
                    ),
                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MEDICINE IMAGE
  // ============================================================

  Widget _buildMedicineImage() {
    if (widget.imagePath.isEmpty) {
      return Container(
        width: 190,
        height: 190,
        decoration:
        BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              blurRadius: 16,
              offset:
              Offset(0, 7),
              color:
              Color(0x22000000),
            ),
          ],
        ),
        child:
        const Icon(
          Icons.medication_rounded,
          size: 90,
          color:
          Color(0xFF009688),
        ),
      );
    }

    final file =
    File(widget.imagePath);

    if (!file.existsSync()) {
      return Container(
        width: 190,
        height: 190,
        decoration:
        BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(28),
        ),
        child:
        const Icon(
          Icons.medication_rounded,
          size: 90,
          color:
          Color(0xFF009688),
        ),
      );
    }

    return ClipRRect(
      borderRadius:
      BorderRadius.circular(28),
      child:
      Image.file(
        file,
        width: 190,
        height: 190,
        fit: BoxFit.cover,
      ),
    );
  }
}