import 'package:flutter/material.dart';
import '../models/medicine.dart';
import 'dart:io';

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const MedicineCard({
    super.key,
    required this.medicine,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final bool imageExists =
        medicine.imagePath.isNotEmpty &&
            File(medicine.imagePath).existsSync();

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            // Medicine image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageExists
                  ? Image.file(
                File(medicine.imagePath),
                height: 70,
                width: 70,
                fit: BoxFit.cover,
              )
                  : Container(
                height: 70,
                width: 70,
                color: Colors.teal.shade50,
                child: const Icon(
                  Icons.medication,
                  size: 40,
                  color: Colors.teal,
                ),
              ),
            ),

            const SizedBox(width: 15),

            // Medicine information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    medicine.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "Dosage: ${medicine.dosage}",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  Text(
                    "Time: ${medicine.time}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Edit and Delete buttons
            Column(
              children: [

                IconButton(
                  icon: const Icon(
                    Icons.edit,
                    color: Colors.blue,
                  ),
                  onPressed: onEdit,
                ),

                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}