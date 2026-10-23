class Medicine {
  String name;
  String dosage;
  String time;
  String imagePath;
  String frequency;
  String foodTiming;
  String alertType;

  Medicine({
    required this.name,
    required this.dosage,
    required this.time,
    required this.imagePath,
    this.frequency = "Once",
    this.foodTiming = "Any Time",
    this.alertType = "Sound + Vibration",
  });

  // Convert Medicine into a Map for saving
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'time': time,
      'imagePath': imagePath,
      'frequency': frequency,
      'foodTiming': foodTiming,
      'alertType': alertType,
    };
  }

  // Convert saved Map back into Medicine
  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      time: map['time'] ?? '',
      imagePath: map['imagePath'] ?? '',
      frequency: map['frequency'] ?? 'Once',
      foodTiming: map['foodTiming'] ?? 'Any Time',
      alertType: map['alertType'] ?? 'Sound + Vibration',
    );
  }
}