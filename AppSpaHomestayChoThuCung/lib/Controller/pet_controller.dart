import 'package:get/get.dart';

class Pet {
  final int id;
  final String name;
  final String type;
  final String breed;
  final double weight;
  final String gender; // male / female / unknown
  final DateTime? dateOfBirth;

  Pet({
    required this.id,
    required this.name,
    required this.type,
    required this.breed,
    required this.weight,
    required this.gender,
    this.dateOfBirth,
  });
}

class PetController extends GetxController {
  final pets = <Pet>[].obs;

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
