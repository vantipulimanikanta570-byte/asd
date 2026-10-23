import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/medicine.dart';
import '../services/notification_service.dart';
import '../language/app_translations.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() =>
      _AddMedicineScreenState();
}

class _AddMedicineScreenState
    extends State<AddMedicineScreen> {
  final medicineNameController =
  TextEditingController();

  final dosageController =
  TextEditingController();

  File? medicineImage;

  TimeOfDay? selectedTime;

  String selectedFrequency = "Once";

  String selectedFoodTiming = "Any Time";

  String selectedAlertType =
      "Sound + Vibration";

  String selectedLanguage = "English";

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs =
    await SharedPreferences.getInstance();

    final savedLanguage =
    prefs.getString('selected_language');

    if (!mounted) return;

    setState(() {
      selectedLanguage =
          savedLanguage ?? "English";
    });
  }

  String t(String key) {
    return AppTranslations(selectedLanguage)
        .text(key);
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? image =
    await picker.pickImage(
      source: ImageSource.camera,
    );

    if (image != null) {
      setState(() {
        medicineImage =
            File(image.path);
      });
    }
  }

  Future<void> pickTime() async {
    TimeOfDay? time =
    await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder:
          (BuildContext context,
          Widget? child) {
        return MediaQuery(
          data:
          MediaQuery.of(context)
              .copyWith(
            alwaysUse24HourFormat: false,
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() {
        selectedTime = time;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t('addMedicine'),
        ),
        backgroundColor: Colors.teal,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            // ====================================================
            // MEDICINE PHOTO
            // ====================================================

            GestureDetector(
              onTap: pickImage,

              child: Container(
                height: 180,
                width: double.infinity,

                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius:
                  BorderRadius.circular(25),
                ),

                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,

                  children: [
                    medicineImage != null
                        ? Image.file(
                      medicineImage!,
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                    )
                        : const Icon(
                      Icons.camera_alt,
                      size: 55,
                      color: Colors.teal,
                    ),

                    const SizedBox(height: 10),

                    Text(
                      medicineImage != null
                          ? t(
                          'medicinePhotoAdded')
                          : t(
                          'addMedicinePhoto'),

                      style:
                      const TextStyle(
                        fontSize: 18,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ====================================================
            // MEDICINE NAME
            // ====================================================

            TextField(
              controller:
              medicineNameController,

              decoration: InputDecoration(
                labelText:
                t('medicineName'),

                prefixIcon:
                const Icon(
                  Icons.medication,
                ),

                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                      20),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ====================================================
            // DOSAGE
            // ====================================================

            TextField(
              controller:
              dosageController,

              decoration: InputDecoration(
                labelText:
                t('dosageExample'),

                prefixIcon:
                const Icon(
                  Icons.health_and_safety,
                ),

                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                      20),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ====================================================
            // FOOD TIMING
            // ====================================================

            DropdownButtonFormField<String>(
              value:
              selectedFoodTiming,

              decoration:
              InputDecoration(
                labelText:
                t('whenToTake'),

                prefixIcon:
                const Icon(
                  Icons.restaurant,
                ),

                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                      20),
                ),
              ),

              items: [
                DropdownMenuItem(
                  value: "Before Food",
                  child: Text(
                    t('beforeFood'),
                  ),
                ),

                DropdownMenuItem(
                  value: "After Food",
                  child: Text(
                    t('afterFood'),
                  ),
                ),

                DropdownMenuItem(
                  value: "Any Time",
                  child: Text(
                    t('anyTime'),
                  ),
                ),
              ],

              onChanged:
                  (value) {
                if (value != null) {
                  setState(() {
                    selectedFoodTiming =
                        value;
                  });
                }
              },
            ),

            const SizedBox(height: 20),

            // ====================================================
            // ALERT TYPE
            // ====================================================

            DropdownButtonFormField<String>(
              value:
              selectedAlertType,

              decoration:
              InputDecoration(
                labelText:
                t('alertType'),

                prefixIcon:
                const Icon(
                  Icons.notifications_active,
                ),

                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                      20),
                ),
              ),

              items: [
                DropdownMenuItem(
                  value:
                  "Vibration Only",

                  child: Row(
                    children: [
                      const Icon(
                        Icons.vibration,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(
                        t('vibrationOnly'),
                      ),
                    ],
                  ),
                ),

                DropdownMenuItem(
                  value:
                  "Sound + Vibration",

                  child: Row(
                    children: [
                      const Icon(
                        Icons.volume_up,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(
                        t('soundVibration'),
                      ),
                    ],
                  ),
                ),
              ],

              onChanged:
                  (value) {
                if (value != null) {
                  setState(() {
                    selectedAlertType =
                        value;
                  });
                }
              },
            ),

            const SizedBox(height: 25),

            // ====================================================
            // REMINDER TIME
            // ====================================================

            SizedBox(
              width:
              double.infinity,
              height: 55,

              child:
              ElevatedButton.icon(
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  Colors.teal,

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                        30),
                  ),
                ),

                icon: const Icon(
                  Icons.access_time,
                  color: Colors.white,
                ),

                label: Text(
                  selectedTime == null
                      ? t(
                      'selectReminderTime')
                      : selectedTime!
                      .format(context),

                  style:
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                  ),
                ),

                onPressed:
                pickTime,
              ),
            ),

            const SizedBox(height: 20),

            // ====================================================
            // FREQUENCY
            // ====================================================

            DropdownButtonFormField<String>(
              value:
              selectedFrequency,

              decoration:
              InputDecoration(
                labelText:
                t('reminderFrequency'),

                prefixIcon:
                const Icon(
                  Icons.repeat,
                ),

                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                      20),
                ),
              ),

              items: [
                DropdownMenuItem(
                  value: "Once",
                  child: Text(
                    t('once'),
                  ),
                ),

                DropdownMenuItem(
                  value: "Every Day",
                  child: Text(
                    t('everyDay'),
                  ),
                ),
              ],

              onChanged:
                  (value) {
                if (value != null) {
                  setState(() {
                    selectedFrequency =
                        value;
                  });
                }
              },
            ),

            const SizedBox(height: 35),

            // ====================================================
            // SAVE MEDICINE
            // ====================================================

            SizedBox(
              width:
              double.infinity,
              height: 55,

              child:
              ElevatedButton(
                style:
                ElevatedButton.styleFrom(
                  backgroundColor:
                  Colors.teal,

                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                        30),
                  ),
                ),

                onPressed: () async {
                  print(
                    "SAVE BUTTON CLICKED",
                  );

                  if (medicineNameController
                      .text
                      .trim()
                      .isEmpty) {
                    ScaffoldMessenger.of(
                        context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          t(
                            'pleaseEnterMedicineName',
                          ),
                        ),
                      ),
                    );

                    return;
                  }

                  if (dosageController
                      .text
                      .trim()
                      .isEmpty) {
                    ScaffoldMessenger.of(
                        context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          t(
                            'pleaseEnterDosage',
                          ),
                        ),
                      ),
                    );

                    return;
                  }

                  if (selectedTime ==
                      null) {
                    ScaffoldMessenger.of(
                        context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          t(
                            'pleaseSelectReminderTime',
                          ),
                        ),
                      ),
                    );

                    return;
                  }

                  // ==================================================
                  // CREATE MEDICINE
                  // ==================================================

                  final medicine =
                  Medicine(
                    name:
                    medicineNameController
                        .text
                        .trim(),

                    dosage:
                    dosageController
                        .text
                        .trim(),

                    time:
                    selectedTime!
                        .format(context),

                    imagePath:
                    medicineImage
                        ?.path ??
                        '',

                    frequency:
                    selectedFrequency,

                    foodTiming:
                    selectedFoodTiming,

                    alertType:
                    selectedAlertType,
                  );

                  print(
                    "SCHEDULING NOTIFICATION",
                  );

                  // ==================================================
                  // SCHEDULE NOTIFICATION
                  // ==================================================

                  await NotificationService
                      .scheduleMedicineReminder(
                    medicineName:
                    medicine.name,

                    dosage:
                    medicine.dosage,

                    time: DateTime(
                      DateTime.now()
                          .year,
                      DateTime.now()
                          .month,
                      DateTime.now()
                          .day,
                      selectedTime!
                          .hour,
                      selectedTime!
                          .minute,
                    ),

                    frequency:
                    medicine.frequency,

                    alertType:
                    medicine.alertType,

                    foodTiming:
                    medicine.foodTiming,

                    imagePath:
                    medicine.imagePath,
                  );

                  if (!mounted) {
                    return;
                  }

                  print(
                    "RETURNING MEDICINE",
                  );

                  Navigator.pop(
                    context,
                    medicine,
                  );
                },

                child: Text(
                  t('saveMedicine'),

                  style:
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}