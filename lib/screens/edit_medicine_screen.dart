import 'package:flutter/material.dart';
import '../models/medicine.dart';

class EditMedicineScreen extends StatefulWidget {

  final Medicine medicine;

  const EditMedicineScreen({
    super.key,
    required this.medicine,
  });

  @override
  State<EditMedicineScreen> createState() =>
      _EditMedicineScreenState();
}


class _EditMedicineScreenState extends State<EditMedicineScreen> {

  late TextEditingController nameController;
  late TextEditingController dosageController;


  @override
  void initState() {
    super.initState();

    nameController =
        TextEditingController(text: widget.medicine.name);

    dosageController =
        TextEditingController(text: widget.medicine.dosage);
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Edit Medicine"),
        backgroundColor: Colors.teal,
      ),


      body: Padding(

        padding: const EdgeInsets.all(20),

        child: Column(

          children: [

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Medicine Name",
              ),
            ),


            const SizedBox(height:20),


            TextField(
              controller: dosageController,
              decoration: const InputDecoration(
                labelText: "Dosage",
              ),
            ),


            const SizedBox(height:30),


            ElevatedButton(

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
              ),

              onPressed: () {

                final updatedMedicine = Medicine(
                  name: nameController.text,
                  dosage: dosageController.text,
                  time: widget.medicine.time,
                  imagePath: widget.medicine.imagePath,
                );

                Navigator.pop(context, updatedMedicine);

              },


              child: const Text(
                "Save Changes",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),

            )

          ],

        ),

      ),

    );

  }
}