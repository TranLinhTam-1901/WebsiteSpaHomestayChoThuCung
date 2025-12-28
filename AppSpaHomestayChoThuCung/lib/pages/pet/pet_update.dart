import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Controller/pet_controller.dart';

const kDarkPink = Color(0xFFFF6185);
const kPrimaryPink = Color(0xFFFFB6C1);
const kBackgroundPink = Color(0xFFFFF0F5);

class PetUpdatePage extends StatefulWidget {
  final Pet pet;
  final int index;

  const PetUpdatePage({Key? key, required this.pet, required this.index}) : super(key: key);

  @override
  State<PetUpdatePage> createState() => _PetUpdatePageState();
}

class _PetUpdatePageState extends State<PetUpdatePage> {
  late TextEditingController nameCtrl;
  late TextEditingController typeCtrl;
  late TextEditingController breedCtrl;
  late TextEditingController dobCtrl;
  late TextEditingController genderCtrl;
  late TextEditingController ageCtrl;
  late TextEditingController colorCtrl;
  late TextEditingController marksCtrl;
  late TextEditingController weightCtrl;
  late TextEditingController heightCtrl;
  late TextEditingController vaccinationCtrl;
  late TextEditingController historyCtrl;
  late TextEditingController allergiesCtrl;
  late TextEditingController dietCtrl;
  late TextEditingController healthNotesCtrl;
  late TextEditingController aiCtrl;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.pet.name);
    typeCtrl = TextEditingController(text: widget.pet.type);
    breedCtrl = TextEditingController(text: widget.pet.breed);
    dobCtrl = TextEditingController(
        text: widget.pet.dateOfBirth != null
            ? "${widget.pet.dateOfBirth!.day}/${widget.pet.dateOfBirth!.month}/${widget.pet.dateOfBirth!.year}"
            : "");
    genderCtrl = TextEditingController(text: widget.pet.gender);
    ageCtrl = TextEditingController(text: widget.pet.age?.toString() ?? "");
    colorCtrl = TextEditingController(text: widget.pet.color);
    marksCtrl = TextEditingController(text: widget.pet.distinguishingMarks);
    weightCtrl = TextEditingController(text: widget.pet.weight?.toString() ?? "");
    heightCtrl = TextEditingController(text: widget.pet.height?.toString() ?? "");
    vaccinationCtrl = TextEditingController(text: widget.pet.vaccinationRecords);
    historyCtrl = TextEditingController(text: widget.pet.medicalHistory);
    allergiesCtrl = TextEditingController(text: widget.pet.allergies);
    dietCtrl = TextEditingController(text: widget.pet.dietPreferences);
    healthNotesCtrl = TextEditingController(text: widget.pet.healthNotes);
    aiCtrl = TextEditingController(text: widget.pet.aiAnalysisResult);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    typeCtrl.dispose();
    breedCtrl.dispose();
    dobCtrl.dispose();
    genderCtrl.dispose();
    ageCtrl.dispose();
    colorCtrl.dispose();
    marksCtrl.dispose();
    weightCtrl.dispose();
    heightCtrl.dispose();
    vaccinationCtrl.dispose();
    historyCtrl.dispose();
    allergiesCtrl.dispose();
    dietCtrl.dispose();
    healthNotesCtrl.dispose();
    aiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundPink,
      appBar: AppBar(
        backgroundColor: kPrimaryPink,
        title: const Text("✏️ Cập nhật thông tin thú cưng", style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: kPrimaryPink.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: widget.pet.imageUrl != null && widget.pet.imageUrl!.isNotEmpty
                    ? CircleAvatar(
                  radius: 75,
                  backgroundImage: NetworkImage(widget.pet.imageUrl!),
                )
                    : const CircleAvatar(
                  radius: 75,
                  child: Icon(Icons.pets, size: 48, color: kDarkPink),
                ),
              ),
              const SizedBox(height: 20),
              _sectionTitle("📋 Thông tin cơ bản"),
              _textField("Tên", nameCtrl),
              _textField("Loại", typeCtrl),
              _textField("Giống", breedCtrl),
              _textField("Ngày sinh", dobCtrl),
              _textField("Giới tính", genderCtrl),
              _textField("Tuổi", ageCtrl, readOnly: true),
              _textField("Màu sắc", colorCtrl),
              _textField("Dấu hiệu nhận dạng", marksCtrl),
              const SizedBox(height: 20),
              _sectionTitle("⚖️ Thông tin thể chất"),
              _textField("Cân nặng (kg)", weightCtrl, keyboardType: TextInputType.number),
              _textField("Chiều cao (cm)", heightCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              _sectionTitle("🩺 Thông tin sức khỏe"),
              _textArea("Hồ sơ tiêm phòng", vaccinationCtrl),
              _textArea("Tiền sử bệnh", historyCtrl),
              _textArea("Dị ứng", allergiesCtrl),
              _textArea("Chế độ ăn", dietCtrl),
              _textArea("Ghi chú sức khỏe", healthNotesCtrl),
              const SizedBox(height: 20),
              _sectionTitle("🤖 Kết quả phân tích AI"),
              _textArea("AI Analysis", aiCtrl, readOnly: true),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("← Quay lại"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: gọi controller update dữ liệu
                      Navigator.pop(context);
                    },
                    child: const Text("💾 Cập nhật"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kDarkPink)),
  );

  Widget _textField(String label, TextEditingController ctrl,
      {bool readOnly = false, TextInputType keyboardType = TextInputType.text}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: TextField(
          controller: ctrl,
          readOnly: readOnly,
          keyboardType: keyboardType,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        ),
      );

  Widget _textArea(String label, TextEditingController ctrl, {bool readOnly = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: TextField(
      controller: ctrl,
      readOnly: readOnly,
      maxLines: 3,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    ),
  );
}
