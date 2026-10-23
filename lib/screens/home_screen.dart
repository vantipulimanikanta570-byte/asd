import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../language/app_translations.dart';
import 'add_medicine_screen.dart';
import '../models/medicine.dart';
import 'edit_medicine_screen.dart';
import '../widgets/medicine_card.dart';
import 'medicine_history_screen.dart';
import 'alerts_screen.dart';
import 'memory_notes_screen.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Medicine> medicines = [];

  int selectedIndex = 0;

  static const String medicinesKey =
      'saved_medicines';

  String selectedLanguage = 'English';

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _loadLanguage();
    loadMedicines();
  }

  // ==========================================================
  // LOAD SELECTED LANGUAGE
  // ==========================================================

  Future<void> _loadLanguage() async {
    final SharedPreferences prefs =
    await SharedPreferences.getInstance();

    final String? savedLanguage =
    prefs.getString('selected_language');

    if (!mounted) {
      return;
    }

    setState(() {
      selectedLanguage =
          savedLanguage ?? 'English';
    });
  }

  // ==========================================================
  // TRANSLATION
  // ==========================================================

  String t(String key) {
    return AppTranslations(
      selectedLanguage,
    ).text(key);
  }

  // ==========================================================
  // LOAD SAVED MEDICINES
  // ==========================================================

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

      final List<Medicine>
      loadedMedicines =
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
        'ERROR LOADING MEDICINES: $e',
      );
    }
  }

  // ==========================================================
  // SAVE ALL MEDICINES
  // ==========================================================

  Future<void> saveMedicines() async {
    final SharedPreferencesAsync prefs =
    SharedPreferencesAsync();

    final List<Map<String, dynamic>> data =
    medicines.map((medicine) {
      return medicine.toMap();
    }).toList();

    await prefs.setString(
      medicinesKey,
      jsonEncode(data),
    );

    print('MEDICINES SAVED');
  }

  // ==========================================================
  // ADD MEDICINE
  // ==========================================================

  Future<void> addMedicine() async {
    final medicine = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const AddMedicineScreen(),
      ),
    );

    if (medicine != null) {
      setState(() {
        medicines.add(medicine);
      });

      await saveMedicines();
    }
  }

  // ==========================================================
  // DELETE MEDICINE
  // ==========================================================

  Future<void> deleteMedicine(
      Medicine medicine,
      ) async {
    await cancelMedicineReminders(
      medicineName: medicine.name,
      time: medicine.time,
      frequency: medicine.frequency,
    );

    setState(() {
      medicines.remove(medicine);
    });

    await saveMedicines();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '${medicine.name} deleted',
        ),
        duration:
        const Duration(seconds: 2),
      ),
    );
  }

  // ==========================================================
  // HISTORY
  // ==========================================================

  void openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const MedicineHistoryScreen(),
      ),
    );
  }

  // ==========================================================
  // COMING SOON
  // ==========================================================

  void showComingSoon(
      String feature) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '$feature coming soon',
        ),
        duration:
        const Duration(seconds: 2),
      ),
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xffF5FAFA),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor:
        Colors.teal,
        elevation: 0,

        title: Text(
          t('appName'),
          style: const TextStyle(
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: Padding(
        padding:
        const EdgeInsets.all(20),

        child:
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              // ==================================================
              // GREETING
              // ==================================================

              Text(
                t('goodEvening'),

                style:
                const TextStyle(
                  fontSize: 28,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              // ==================================================
              // SUBTITLE
              // ==================================================

              Text(
                t('healthCompanion'),

                style:
                const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              // ==================================================
              // MEDICINE CARD
              // ==================================================

              Container(
                width: double.infinity,

                padding:
                const EdgeInsets.all(25),

                decoration:
                BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                  BorderRadius.circular(
                    25,
                  ),

                  boxShadow:
                  const [
                    BoxShadow(
                      color:
                      Colors.black12,
                      blurRadius: 15,
                    ),
                  ],
                ),

                child: Column(
                  children: [
                    const Icon(
                      Icons
                          .medication_outlined,
                      size: 60,
                      color:
                      Colors.teal,
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    medicines.isEmpty
                        ? Text(
                      t(
                        'noMedicineAdded',
                      ),

                      style:
                      const TextStyle(
                        fontSize: 20,
                        fontWeight:
                        FontWeight
                            .bold,
                      ),
                    )
                        : Column(
                      children:
                      medicines.map(
                            (medicine) {
                          return MedicineCard(
                            medicine:
                            medicine,

                            // DELETE
                            onDelete:
                                () {
                              deleteMedicine(
                                medicine,
                              );
                            },

                            // EDIT
                            onEdit:
                                () async {
                              final Medicine?
                              updatedMedicine =
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                      EditMedicineScreen(
                                        medicine:
                                        medicine,
                                      ),
                                ),
                              );

                              if (updatedMedicine !=
                                  null) {
                                await cancelMedicineReminders(
                                  medicineName:
                                  medicine.name,
                                  time:
                                  medicine.time,
                                  frequency:
                                  medicine.frequency,
                                );

                                setState(() {
                                  final int
                                  index =
                                  medicines
                                      .indexOf(
                                    medicine,
                                  );

                                  medicines[
                                  index] =
                                      updatedMedicine;
                                });

                                await saveMedicines();
                              }
                            },
                          );
                        },
                      ).toList(),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      t(
                        'addMedicinesReminder',
                      ),

                      style:
                      const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              // ==================================================
              // ADD MEDICINE
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 55,

                child:
                ElevatedButton.icon(
                  style:
                  ElevatedButton
                      .styleFrom(
                    backgroundColor:
                    Colors.teal,

                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        30,
                      ),
                    ),
                  ),

                  icon: const Icon(
                    Icons.add,
                    color:
                    Colors.white,
                  ),

                  label: Text(
                    t('addMedicine'),

                    style:
                    const TextStyle(
                      fontSize: 18,
                      color:
                      Colors.white,
                    ),
                  ),

                  onPressed:
                  addMedicine,
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              // ==================================================
              // MEMORY NOTES
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 55,

                child:
                OutlinedButton.icon(
                  style:
                  OutlinedButton
                      .styleFrom(
                    side:
                    const BorderSide(
                      color:
                      Colors.teal,
                    ),

                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        30,
                      ),
                    ),
                  ),

                  icon: const Icon(
                    Icons.note_alt,
                    color:
                    Colors.teal,
                  ),

                  label: Text(
                    t('memoryNotes'),

                    style:
                    const TextStyle(
                      fontSize: 18,
                      color:
                      Colors.teal,
                    ),
                  ),

                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                        const MemoryNotesScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(
                height: 100,
              ),
            ],
          ),
        ),
      ),

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================

      bottomNavigationBar:
      SafeArea(
        child: Container(
          height: 80,

          decoration:
          const BoxDecoration(
            color: Colors.white,

            boxShadow: [
              BoxShadow(
                color:
                Colors.black12,
                blurRadius: 10,
                offset:
                Offset(0, -3),
              ),
            ],
          ),

          child: Row(
            mainAxisAlignment:
            MainAxisAlignment
                .spaceAround,

            children: [
              // HOME
              _bottomButton(
                icon: Icons.home,
                label: t('appName') ==
                    'కేర్ గార్డియన్'
                    ? 'హోమ్'
                    : t('appName') ==
                    'केयर गार्जियन'
                    ? 'होम'
                    : 'Home',
                index: 0,

                onTap: () {
                  setState(() {
                    selectedIndex =
                    0;
                  });
                },
              ),

              // MEDICINES
              _bottomButton(
                icon:
                Icons.medication,
                label: t('medicines'),
                index: 1,

                onTap: () {
                  setState(() {
                    selectedIndex =
                    1;
                  });

                  showComingSoon(
                    t('medicines'),
                  );
                },
              ),

              // CENTER ADD BUTTON
              GestureDetector(
                onTap:
                addMedicine,

                child: Container(
                  height: 64,
                  width: 64,

                  decoration:
                  const BoxDecoration(
                    color:
                    Colors.teal,
                    shape:
                    BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.add,
                    color:
                    Colors.white,
                    size: 34,
                  ),
                ),
              ),

              // ALERTS
              _bottomButton(
                icon: Icons.notifications,
                label: t('alerts'),
                index: 3,

                onTap: () {
                  setState(() {
                    selectedIndex =
                    3;
                  });

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                      const AlertsScreen(),
                    ),
                  );
                },
              ),

              // HISTORY
              _bottomButton(
                icon: Icons.history,
                label: t('history'),
                index: 4,

                onTap: () {
                  setState(() {
                    selectedIndex =
                    4;
                  });

                  openHistory();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // BOTTOM BUTTON
  // ==========================================================

  Widget _bottomButton({
    required IconData icon,
    required String label,
    required int index,
    required VoidCallback onTap,
  }) {
    final bool isSelected =
        selectedIndex == index;

    return GestureDetector(
      onTap: onTap,

      child: SizedBox(
        width: 65,

        child: Column(
          mainAxisAlignment:
          MainAxisAlignment
              .center,

          children: [
            Icon(
              icon,
              size: 28,

              color: isSelected
                  ? Colors.teal
                  : Colors
                  .grey
                  .shade600,
            ),

            const SizedBox(
              height: 4,
            ),

            Text(
              label,

              style: TextStyle(
                fontSize: 12,

                fontWeight:
                isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,

                color: isSelected
                    ? Colors.teal
                    : Colors
                    .grey
                    .shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}