import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Api/review_api.dart';
import '../controller/review_controller.dart';
import 'package:image_picker/image_picker.dart';

class WriteReviewPage extends StatefulWidget {
  final int productId;
  final String productName;
  final String? productImage;
  final String? optionText;
  const WriteReviewPage({
    super.key,
    required this.productId,
    this.productName = "",
    this.productImage,
    this.optionText,
  });


  @override
  State<WriteReviewPage> createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage> {
  int rating = 0;
  final contentCtrl = TextEditingController();
  final pickedImages = <XFile>[].obs;
  final picker = ImagePicker();


  Future<void> pickImages() async {
    final files = await picker.pickMultiImage();
    if (files != null) {
      pickedImages.addAll(files);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        title: const Text("Viết đánh giá"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🧾 PRODUCT INFO
            // Padding(
            //   padding: const EdgeInsets.all(16),
            //   child: Container(
            //     padding: const EdgeInsets.all(12),
            //     decoration: BoxDecoration(
            //       borderRadius: BorderRadius.circular(12),
            //       border: Border.all(color: Colors.grey.shade200),
            //     ),
            //     child: Row(
            //       children: [
            //         Container(
            //           width: 72,
            //           height: 72,
            //           decoration: BoxDecoration(
            //             borderRadius: BorderRadius.circular(8),
            //             color: Colors.grey.shade200,
            //             image: widget.productImage != null
            //                 ? DecorationImage(
            //               image: NetworkImage(
            //                 "${AuthService.baseUrl}${widget.productImage}",
            //               ),
            //               fit: BoxFit.cover,
            //             )
            //                 : null,
            //           ),
            //           child: widget.productImage == null
            //               ? const Icon(Icons.image, size: 32)
            //               : null,
            //         ),
            //         const SizedBox(width: 12),
            //         Expanded(
            //           child: Column(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: [
            //               const Text(
            //                 "Đang đánh giá",
            //                 style: TextStyle(
            //                   color: Colors.pink,
            //                   fontSize: 12,
            //                   fontWeight: FontWeight.bold,
            //                 ),
            //               ),
            //               const SizedBox(height: 4),
            //               Text(
            //                 widget.productName,
            //                 maxLines: 2,
            //                 overflow: TextOverflow.ellipsis,
            //                 style: const TextStyle(fontWeight: FontWeight.bold),
            //               ),
            //               if (widget.optionText != null)
            //                 Text(
            //                   widget.optionText!,
            //                   style: const TextStyle(color: Colors.grey),
            //                 ),
            //             ],
            //           ),
            //         )
            //       ],
            //     ),
            //   ),
            // ),


            /// ⭐ RATING
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  "Chất lượng sản phẩm?",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    iconSize: 40,
                    onPressed: () {
                      setState(() => rating = i + 1);
                    },
                    icon: Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: Colors.pink,
                    ),
                  );
                }),
              ),
            ),

            if (rating > 0)
              Center(
                child: Text(
                  _ratingText(rating),
                  style: const TextStyle(
                    color: Colors.pink,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const Divider(height: 32),

            /// 📝 CONTENT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: contentCtrl,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText:
                  "Hãy chia sẻ những điều bạn thích về sản phẩm này nhé...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),


            /// 🖼 IMAGE PICKER UI (HIỂN THỊ)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Obx(() {
                return SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      /// ➕ ADD IMAGE
                      GestureDetector(
                        onTap: pickImages,
                        child: Container(
                          width: 80,
                          height: 80,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.pink.withOpacity(0.4),
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, color: Colors.pink),
                              SizedBox(height: 4),
                              Text(
                                "Thêm ảnh",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pink,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),

                      /// 🖼 PREVIEW IMAGES
                      ...pickedImages
                          .map((img) => Stack(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            margin: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: kIsWeb
                                  ? Image.network(img.path, fit: BoxFit.cover)
                                  : Image.file(File(img.path), fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: GestureDetector(
                              onTap: () => pickedImages.remove(img),
                              child: const CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.close, size: 14, color: Colors.red),
                              ),
                            ),
                          )
                        ],
                      ))
                          .toList(),

                    ],
                  ),
                );
              }),
            ),

          ],
        ),
      ),

      /// 🚀 SUBMIT
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: rating == 0
                ? null
                : () async {
              try {
                await ReviewApi.postReview(
                  productId: widget.productId,
                  rating: rating,
                  comment: contentCtrl.text,
                  images: pickedImages.toList(),
                );

                Get.back();
                Get.find<ReviewController>()
                    .load(widget.productId);

                Get.snackbar(
                  "Thành công",
                  "Đánh giá đã được gửi",
                  backgroundColor: Colors.green.shade100,
                );
              } catch (e) {
                Get.snackbar(
                  "Lỗi",
                  e.toString(),
                  backgroundColor: Colors.red.shade100,
                );
              }
            },
            icon: const Icon(Icons.send),
            label: const Text("Gửi đánh giá"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
      ),





    );
  }

  String _ratingText(int r) {
    switch (r) {
      case 1:
        return "Rất tệ";
      case 2:
        return "Không hài lòng";
      case 3:
        return "Bình thường";
      case 4:
        return "Hài lòng";
      case 5:
        return "Rất hài lòng";
      default:
        return "";
    }
  }
}
