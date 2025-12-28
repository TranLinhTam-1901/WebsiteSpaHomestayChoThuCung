import 'package:get/get.dart';

class Pet {
  final int id;
  final String name;
  final String type;
  final String breed;
  final double? weight;
  final double? height;
  final String gender;
  final DateTime? dateOfBirth;
  final String? imageUrl;
  final int? age;
  final String? color;
  final String? distinguishingMarks;
  final String? vaccinationRecords;
  final String? medicalHistory;
  final String? allergies;
  final String? dietPreferences;
  final String? healthNotes;
  final String? aiAnalysisResult;

  Pet({
    required this.id,
    required this.name,
    required this.type,
    required this.breed,
    this.weight,
    this.height,
    required this.gender,
    this.dateOfBirth,
    this.imageUrl,
    this.age,
    this.color,
    this.distinguishingMarks,
    this.vaccinationRecords,
    this.medicalHistory,
    this.allergies,
    this.dietPreferences,
    this.healthNotes,
    this.aiAnalysisResult,
  });
}

class PetController extends GetxController {
  RxList<Pet> pets = <Pet>[].obs;

  void deletePetByIndex(int index) {
    pets.removeAt(index);
  }

  @override
  void onInit() {
    super.onInit();
    loadMockData();
  }

  void loadMockData() {
    pets.value = [
      Pet(
        id: 1,
        name: "Milo",
        type: "Chó",
        breed: "Poodle",
        weight: 4.5,
        gender: "male",
        dateOfBirth: DateTime(2021, 5, 10),
      ),
      Pet(
        id: 2,
        name: "Luna",
        type: "Mèo",
        breed: "Anh lông ngắn",
        weight: 3.2,
        gender: "female",
        dateOfBirth: DateTime(2022, 1, 20),
      ),
    ];
  }
}
