USE [DoAnCoSoVer18.0]

-- 1. Homestay Services --
INSERT INTO Services (Category, Name, Price)
VALUES 
(1, N'Phòng Standard', 250000),
(1, N'Phòng Deluxe',   400000),
(1, N'Phòng Suite',    600000);

-- 2. Vet Services --
INSERT INTO Services (Category, Name, Price)
VALUES 
(2, N'Khám tổng quát',          150000),
(2, N'Tiêm phòng vaccine',       200000),
(2, N'Siêu âm/X-quang',          300000),
(2, N'Điều trị bệnh tiêu hóa',   250000),
(2, N'Phẫu thuật nhỏ',           500000),
(2, N'Khám tai-mũi-họng',       180000);

-- 3. Spa Services (chỉ tạo service rỗng giá, giá lưu trong SpaPricing) --
INSERT INTO Services (Category, Name, Price)
VALUES 
(0, N'Spa (Tắm sấy vệ sinh)', 0),
(0, N'Grooming (Spa + Cắt tạo kiểu)', 0),
(0, N'Shave (Spa + Cạo lông)', 0);

-- Bảng giá Spa (liên kết qua ServiceId) --
INSERT INTO SpaPricing (ServiceId, PriceUnder5kg, Price5To12kg, Price12To25kg, PriceOver25kg)
VALUES
( (SELECT ServiceId FROM Services WHERE Name = N'Spa (Tắm sấy vệ sinh)'), 330000, 440000, 610000, 850000),
( (SELECT ServiceId FROM Services WHERE Name = N'Grooming (Spa + Cắt tạo kiểu)'), 500000, 690000, 930000, 1300000),
( (SELECT ServiceId FROM Services WHERE Name = N'Shave (Spa + Cạo lông)'), 420000, 570000, 770000, 1000000);

-- ServiceDetail cho Vet Services --
-- Khám tổng quát--
INSERT INTO ServiceDetail (ServiceId, Name, Price, SalePrice)
VALUES 
( (SELECT ServiceId FROM Services WHERE Name = N'Khám tổng quát'), N'Khám sức khỏe cơ bản', 150000, NULL),
( (SELECT ServiceId FROM Services WHERE Name = N'Khám tổng quát'), N'Khám tổng quát + xét nghiệm máu', 250000, 220000);

-- Tiêm phòng vaccine --
INSERT INTO ServiceDetail (ServiceId, Name, Price, SalePrice)
VALUES
( (SELECT ServiceId FROM Services WHERE Name = N'Tiêm phòng vaccine'), N'Vaccine dại', 200000, NULL),
( (SELECT ServiceId FROM Services WHERE Name = N'Tiêm phòng vaccine'), N'Vaccine hỗn hợp 5 bệnh', 250000, 220000);

-- Siêu âm/X-quang --
INSERT INTO ServiceDetail (ServiceId, Name, Price, SalePrice)
VALUES
( (SELECT ServiceId FROM Services WHERE Name = N'Siêu âm/X-quang'), N'Siêu âm bụng', 300000, 270000),
( (SELECT ServiceId FROM Services WHERE Name = N'Siêu âm/X-quang'), N'X-quang tim phổi', 350000, 320000);

-- Điều trị bệnh tiêu hóa --
INSERT INTO ServiceDetail (ServiceId, Name, Price, SalePrice)
VALUES
( (SELECT ServiceId FROM Services WHERE Name = N'Điều trị bệnh tiêu hóa'), N'Khám + thuốc tiêu hóa', 250000, NULL),
( (SELECT ServiceId FROM Services WHERE Name = N'Điều trị bệnh tiêu hóa'), N'Điều trị bệnh viêm dạ dày', 300000, 280000);

-- Phẫu thuật nhỏ --
INSERT INTO ServiceDetail (ServiceId, Name, Price, SalePrice)
VALUES
( (SELECT ServiceId FROM Services WHERE Name = N'Phẫu thuật nhỏ'), N'Nhổ răng', 500000, 450000),
( (SELECT ServiceId FROM Services WHERE Name = N'Phẫu thuật nhỏ'), N'Tiểu phẫu cắt bỏ u nhỏ', 600000, 550000);

-- Khám tai-mũi-họng --
INSERT INTO ServiceDetail (ServiceId, Name, Price, SalePrice)
VALUES
( (SELECT ServiceId FROM Services WHERE Name = N'Khám tai-mũi-họng'), N'Khám tai', 180000, NULL),
( (SELECT ServiceId FROM Services WHERE Name = N'Khám tai-mũi-họng'), N'Khám mũi + họng', 200000, 180000);

-- Danh mục sản phẩm --
INSERT INTO Categories(Name) VALUES
(N'Pate Mèo'),
(N'Pate Chó'),
(N'Pate Chó & Mèo'),
(N'Hạt cho Mèo'),
(N'Hạt cho Chó');

-- Sản phẩm 1 --
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Pate Mèo Dạng Thạch Nekko Jelly 70g', 20000, 15000, N'Nekko', 
N'Nếu bạn đang tìm kiếm một loại pate mèo chất lượng thì không thể bỏ qua Pate Nekko Jelly. 
Pate Nekko được cung cấp bởi công ty Unicorn Public Co Nhật Bản, có cơ sở sản xuất tại Thái Lan. 
Với công nghệ tiên tiến và công thức đặc biệt tạo ra hương vị ngon miệng tuyệt vời, Pate Nekko dễ dàng chinh phục được khẩu vị các bé mèo. 
Các sản phẩm đều trong một quy trình khép kín, bảo đảm vệ sinh an toàn thực phẩm, đảm bảo sức khỏe cho mèo cưng.', 
N'/images/SanPham/Pate_Meo/SP_01/5.webp', 1, 
N'Cá Ngừ, Cá Ngừ + Cá Bào, Cá Ngừ + Trứng Hấp, Cá Ngừ + Thanh Cua, Cá Ngừ + Phô Mai, Cá Ngừ + Gà, Cá Ngừ + Tôm Sò, Cá Ngừ + Cá Cơm Sữa');

INSERT INTO [dbo].[ProductImages] ([ProductId], [Url])
VALUES 

(1, N'/images/SanPham/Pate_Meo/SP_01/4.webp'),
(1, N'/images/SanPham/Pate_Meo/SP_01/3.jpg'),
(1, N'/images/SanPham/Pate_Meo/SP_01/2.jpg'),
(1, N'/images/SanPham/Pate_Meo/SP_01/1.webp');

-- Sản phẩm 2 --
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Pate Tươi The Pet Cho Chó Mèo Biếng Ăn (1kg)', 120000, 95000, N'The Pet', 
N'Pate Tươi Cho Mèo Hỗn Hợp cho Chó Mèo Biếng Ăn được làm từ hỗn hợp cá biển và gan gà tươi nguyên chất thích hợp dùng cho Chó Mèo.', 
N'/images/SanPham/SP_Cho&Meo/SP_01/1.jpg', 3, 
N'Hỗn Hợp Gà, Hỗn Hợp Cá, Cá Ngừ, Cá Nước Ngọt, Cá Trích, Collagen Gà, Collagen Cá Tôm, Gan Gà');

INSERT INTO [dbo].[ProductImages] ([ProductId], [Url])
VALUES 

(2, N'/images/SanPham/SP_Cho&Meo/SP_01/5.webp'),
(2, N'/images/SanPham/SP_Cho&Meo/SP_01/6.webp'),
(2, N'/images/SanPham/SP_Cho&Meo/SP_01/7.webp'),
(2, N'/images/SanPham/SP_Cho&Meo/SP_01/8.jpg');

-- Sản phẩm 3 --
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Pate Mèo Snappy Tom Cá Ngừ Mix Trái Cây 70g', 17000, 14000, N'Snappy Tom', 
N'Pate mèo Snappy Tom là sản phẩm thức ăn hỗn hợp hoàn chỉnh dành cho mèo với Omega 3, bổ sung Vitamin và khoáng chất theo tiêu chuẩn thức ăn của Hoa Kỳ AAFCO. 
Pate Snappy Tom Cá Ngừ Mix Trái Cây là sản phẩm được làm từ cá ngừ tươi nguyên chất kết hợp với các loại trái cây tươi ngon như xoài, kiwi, táo, kỷ tử,... mang đến hương vị thơm ngon, hấp dẫn cho mèo cưng.', 
N'/images/SanPham/Pate_Meo/SP_02/3.jpg', 1, 
N'Cá Ngừ + Trứng cá, Cá Ngừ + Nha Đam, Cá Ngừ + Xoài, Cá Ngừ + Dứa, Cá Ngừ + Táo, Cá Ngừ + Trứng, Cá Ngừ + Kỷ Tử, Cá Ngừ + Kiwi');

INSERT INTO [dbo].[ProductImages] ([ProductId], [Url])
VALUES 

(3, N'/images/SanPham/Pate_Meo/SP_02/8.webp'),
(3, N'/images/SanPham/Pate_Meo/SP_02/9.webp'),
(3, N'/images/SanPham/Pate_Meo/SP_02/10.webp'),
(3, N'/images/SanPham/Pate_Meo/SP_02/11.webp');

-- Sản phẩm 4 --
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Thức Ăn Hạt Mềm cho Chó ANF Soft', 58000, 55000, N'ANF', 
N'Bộ đôi sản phẩm thức ăn hạt mềm ANF SOFT với 2 hương vị Gà và Cá hồi thơm ngon sẽ giúp Sen có thêm lựa chọn nữa để đa dạng bữa ăn cho cún cưng nhà mình. 
ANFSOFT là sự kết hợp giữa thịt chất lượng cao, rau củ, trái cây tươi và các lợi khuẩn, bổ sung các dưỡng chất thiết yếu giúp hỗ trợ tiêu hóa, tăng cường sức khỏe cho cún. 
Thức ăn hạt mềm ANF SOFT là một lựa chọn phù hợp dành cho các chú chó trong mọi giai đoạn phát triển, đặc biệt là chó con, chó già có tình trạng kén ăn hoặc răng yếu.', 
N'/images/SanPham/Hat_Cho/SP_01/6.webp', 5, 
N'Cá Hồi, Gà');

INSERT INTO [dbo].[ProductImages] ([ProductId], [Url])
VALUES 

(4, N'/images/SanPham/Hat_Cho/SP_01/1.webp'),
(4, N'/images/SanPham/Hat_Cho/SP_01/4.webp'),
(4, N'/images/SanPham/Hat_Cho/SP_01/2.webp'),
(4, N'/images/SanPham/Hat_Cho/SP_01/3.webp');

-- Sản phẩm 5 --
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Pate Cho Chó Pate Monge Nhiều Vị 100g', 25000, null, N'Monge', 
N'Một trong những lựa chọn phổ biến nhất khi nghĩ đến đồ ăn chó là Pate hộp. 
Nếu bạn đang tìm kiếm một loại pate cho chó chất lượng thì không thể bỏ qua Pate Monge, một thương hiệu đến từ Ý. 
Với hương vị thơm ngon từ những loại thịt như gà, gà tây và cá ngừ, đây là dòng pate được ưa chuộng tại nhiều nước Châu Âu. 
Pate chó của Monge an toàn và đạt chất lượng cao vì không chứa gluten hay các chất gây dị ứng cho cả động vật và con người. 
Thành phần chính từ thịt thơm ngon, Pate Monge giúp kích thích khả năng ăn uống của chó, nuôi dưỡng lông và da, hạn chế các tác động tiêu cực đến sức khỏe của chúng.', 
N'/images/SanPham/Pate_Cho/SP_01/1.jpg', 2, 
N'Cá Hồi, Cá Hồi + Lê, Heo, Gà, Gà & Rau Củ, Vịt + Cam');

INSERT INTO [dbo].[ProductImages] ([ProductId], [Url])
VALUES 

(5, N'/images/SanPham/Pate_Cho/SP_01/4.webp'),
(5, N'/images/SanPham/Pate_Cho/SP_01/5.webp'),
(5, N'/images/SanPham/Pate_Cho/SP_01/6.webp'),
(5, N'/images/SanPham/Pate_Cho/SP_01/7.webp');

-- Sản phẩm 6 --
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Thức Ăn Hạt Cho Mèo Royal Canin Indoor 27 400g', 85000, 81000, N'Royal Canin',
N'Thức ăn hạt Royal Canin Indoor 27 được thiết kế dành riêng cho mèo trưởng thành sống trong nhà từ 1 đến 7 tuổi. 
Với hàm lượng calo vừa phải, sản phẩm giúp duy trì cân nặng lý tưởng, đồng thời hỗ trợ kiểm soát búi lông và giảm mùi phân. 
Thành phần dinh dưỡng cân bằng giúp mèo khỏe mạnh và năng động trong môi trường sống trong nhà.',
N'/images/SanPham/Hat_Meo/SP_01/1.webp', 4, N'Gà, Rau Củ');

INSERT INTO [dbo].[ProductImages] ([ProductId], [Url])
VALUES 
(6, N'/images/SanPham/Hat_Meo/SP_01/1.webp'),
(6, N'/images/SanPham/Hat_Meo/SP_01/2.jpg'),
(6, N'/images/SanPham/Hat_Meo/SP_01/3.webp'),
(6, N'/images/SanPham/Hat_Meo/SP_01/4.webp');

-- Sản phẩm 7 --
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Thức Ăn Hạt Cho Mèo Catsrang 400g', 47000, 43500, N'Catsrang',
N'Thức ăn hạt Catsrang phù hợp cho mọi giai đoạn phát triển của mèo, cung cấp protein chất lượng cao từ thịt gà và cá hồi. 
Sản phẩm hỗ trợ hệ tiêu hóa khỏe mạnh, tăng cường hệ miễn dịch và giúp lông mèo bóng mượt. 
Không chứa chất bảo quản nhân tạo, đảm bảo an toàn cho sức khỏe của mèo.',
N'/images/SanPham/Hat_Meo/SP_02/1.webp', 4, N'Cá Hồi, Gà');

INSERT INTO [dbo].[ProductImages] ([ProductId], [Url])
VALUES 

(7, N'/images/SanPham/Hat_Meo/SP_02/3.webp'),
(7, N'/images/SanPham/Hat_Meo/SP_02/4.webp'),
(7, N'/images/SanPham/Hat_Meo/SP_02/6.webp'),
(7, N'/images/SanPham/Hat_Meo/SP_02/5.webp');

-- Sản phẩm 8 --
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Thức Ăn Hạt Cho Mèo Con Whiskas 450g', 33000, 31500, N'Whiskas',
N'Thức ăn hạt Whiskas dành cho mèo con từ 2 đến 12 tháng tuổi, cung cấp đầy đủ vitamin và khoáng chất cần thiết cho sự phát triển toàn diện. 
Hạt có lớp vỏ giòn bên ngoài và nhân mềm bên trong, kích thích vị giác và giúp mèo con ăn ngon miệng hơn.',
N'/images/SanPham/Hat_Meo/SP_03/1.webp', 4, N'Cá Biển, Cá Hồi');

INSERT INTO [dbo].[ProductImages] ([ProductId], [Url])
VALUES 
(8, N'/images/SanPham/Hat_Meo/SP_03/1.webp'),
(8, N'/images/SanPham/Hat_Meo/SP_03/2.webp'),
(8, N'/images/SanPham/Hat_Meo/SP_03/3.webp'),
(8, N'/images/SanPham/Hat_Meo/SP_03/4.webp');

-- Sản phẩm 9 --
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Pate Cho Mèo Miglior Gatto 400g', 32000, 30000, N'Miglior Gatto',
N'Pate Miglior Gatto được chế biến từ thịt cừu và gan, cung cấp protein chất lượng cao và vitamin E giúp tăng cường hệ miễn dịch. 
Sản phẩm không chứa chất tạo màu hay chất bảo quản nhân tạo, đảm bảo an toàn cho sức khỏe của mèo.',
N'/images/SanPham/Pate_Meo/SP_03/1.webp', 1, N'Cừu, Gan');

INSERT INTO [dbo].[ProductImages] ([ProductId], [Url])
VALUES 

(9, N'/images/SanPham/Pate_Meo/SP_03/3.webp'),
(9, N'/images/SanPham/Pate_Meo/SP_03/4.webp'),
(9, N'/images/SanPham/Pate_Meo/SP_03/5.webp'),
(9, N'/images/SanPham/Pate_Meo/SP_03/6.webp');

-- Sản phẩm 10 --
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Pate Cho Mèo Dạng Hộp Ciao 85g', 15000, NULL, N'Inaba',
N'Pate Ciao từ Inaba được làm từ phi lê cá ngừ và shirasu, bổ sung vitamin E và chiết xuất trà xanh giúp khử mùi hôi. 
Kết cấu mềm mịn dễ ăn, phù hợp cho mèo ở mọi lứa tuổi.',
N'/images/SanPham/Pate_Meo/SP_04/1.webp', 1, N'Cá Ngừ, Shirasu');

INSERT INTO [dbo].[ProductImages] ([ProductId], [Url])
VALUES 

(10, N'/images/SanPham/Pate_Meo/SP_04/4.webp'),
(10, N'/images/SanPham/Pate_Meo/SP_04/5.webp'),
(10, N'/images/SanPham/Pate_Meo/SP_04/6.webp'),
(10, N'/images/SanPham/Pate_Meo/SP_04/7.jpg');

-- Sản phẩm 11 --
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Thức Ăn Hạt Cho Mèo Me-O 1.1kg', 23000, 21500, N'Me-O',
N'Thức ăn hạt Me-O cung cấp dinh dưỡng cân bằng với hàm lượng natri thấp, hỗ trợ hệ tiết niệu khỏe mạnh. 
Sản phẩm giàu vitamin C và taurine, giúp tăng cường hệ miễn dịch và thị lực cho mèo.',
N'/images/SanPham/Hat_Meo/SP_04/1.webp', 4, N'Cá Ngừ, Cá Thu');

INSERT INTO [dbo].[ProductImages] ([ProductId], [Url])
VALUES 
(11, N'/images/SanPham/Hat_Meo/SP_04/1.webp'),
(11, N'/images/SanPham/Hat_Meo/SP_04/2.webp'),
(11, N'/images/SanPham/Hat_Meo/SP_04/3.webp'),
(11, N'/images/SanPham/Hat_Meo/SP_04/4.webp');

-- Sản phẩm 12 --
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Pate Cho Mèo Snappy Tom 85g', 15000, 12000, N'Snappy Tom',
N'Pate Snappy Tom được làm từ thịt bò và gà tươi, không chứa gluten và chất bảo quản nhân tạo. 
Sản phẩm giàu protein, hỗ trợ phát triển cơ bắp và duy trì sức khỏe tổng thể cho mèo.',
N'/images/SanPham/Pate_Meo/SP_05/1.webp', 1, N'Bò, Gà');

INSERT INTO [dbo].[ProductImages] ([ProductId], [Url])
VALUES 

(12, N'/images/SanPham/Pate_Meo/SP_05/5.webp'),
(12, N'/images/SanPham/Pate_Meo/SP_05/6.webp'),
(12, N'/images/SanPham/Pate_Meo/SP_05/7.webp'),
(12, N'/images/SanPham/Pate_Meo/SP_05/8.webp');

-- Sản phẩm 13 --
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Súp Thưởng Cho Mèo Ciao Churu 14g', 10000, NULL, N'Inaba',
N'Súp thưởng Ciao Churu với hương vị cá ngừ và sò điệp, kết cấu mềm mịn dễ ăn, giúp bổ sung nước và dưỡng chất cho mèo. 
Sản phẩm không chứa ngũ cốc, chất tạo màu hay chất bảo quản nhân tạo.',
N'/images/SanPham/Pate_Meo/SP_06/1.webp', 1, N'Cá Ngừ, Sò Điệp');

INSERT INTO [dbo].[ProductImages] ([ProductId], [Url])
VALUES 

(13, N'/images/SanPham/Pate_Meo/SP_06/4.webp'),
(13, N'/images/SanPham/Pate_Meo/SP_06/5.webp'),
(13, N'/images/SanPham/Pate_Meo/SP_06/6.webp'),
(13, N'/images/SanPham/Pate_Meo/SP_06/7.webp');

-- Sản phẩm 14 --
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Thức Ăn Hạt Cho Mèo Royal Canin Sterilised 37 2kg', 93000, 90000, N'Royal Canin',
N'Thức ăn hạt Royal Canin Sterilised 37 dành cho mèo đã triệt sản từ 1 đến 7 tuổi, giúp kiểm soát cân nặng và duy trì cơ bắp săn chắc. 
Sản phẩm hỗ trợ sức khỏe đường tiết niệu và cung cấp dinh dưỡng cân bằng cho mèo.',
N'/images/SanPham/Hat_Meo/SP_05/1.webp', 4, N'Gà');

INSERT INTO [dbo].[ProductImages] ([ProductId], [Url])
VALUES 

(14, N'/images/SanPham/Hat_Meo/SP_05/3.webp'),
(14, N'/images/SanPham/Hat_Meo/SP_05/4.webp'),
(14, N'/images/SanPham/Hat_Meo/SP_05/5.webp'),
(14, N'/images/SanPham/Hat_Meo/SP_05/6.webp');

-- Sản phẩm 15 --
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Thức Ăn Hạt Cho Mèo Iskhan 2.5kg', 367000, 345000, N'Iskhan',
N'Thức ăn hạt Iskhan không chứa ngũ cốc, được làm từ thịt gà và cá hồi tươi, bổ sung Omega-3 và thảo mộc tự nhiên. 
Sản phẩm hỗ trợ sức khỏe da và lông, tăng cường hệ miễn dịch và phù hợp cho mèo ở mọi lứa tuổi.',
N'/images/SanPham/Hat_Meo/SP_06/1.jpg', 4, N'Cá Hồi, Thảo Mộc');

INSERT INTO [dbo].[ProductImages] ([ProductId], [Url])
VALUES 

(15, N'/images/SanPham/Hat_Meo/SP_06/2.jpg'),
(15, N'/images/SanPham/Hat_Meo/SP_06/3.png'),
(15, N'/images/SanPham/Hat_Meo/SP_06/4.png'),
(15, N'/images/SanPham/Hat_Meo/SP_06/5.png');

-- Sản phẩm 16 --
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Pate Cho Chó Ganador Vị Gà 100g', 35000, 32000, N'Ganador',
N'Pate Ganador dành cho chó với hương vị gà thơm ngon, giàu protein và vitamin hỗ trợ phát triển cơ bắp và sức khỏe toàn diện.',
N'/images/SanPham/Pate_Cho/SP_02/1.png', 2, N'Gà, Heo');

INSERT INTO [dbo].[ProductImages] ([ProductId], [Url])
VALUES 
(16, N'/images/SanPham/Pate_Cho/SP_02/1.png'),
(16, N'/images/SanPham/Pate_Cho/SP_02/2.jpg'),
(16, N'/images/SanPham/Pate_Cho/SP_02/3.png'),
(16, N'/images/SanPham/Pate_Cho/SP_02/4.webp');

-- Sản phẩm 17 --
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Pate Cho Chó SmartHeart Pate Vị Bò 100g', 30000, 27500, N'SmartHeart',
N'Pate SmartHeart với thành phần chính là thịt bò tươi ngon, giúp bổ sung năng lượng và dưỡng chất cần thiết cho chó.',
N'/images/SanPham/Pate_Cho/SP_03/1.png', 2, N'Bò Nấu Đông, Gà và Gan, Gà Nấu Đông');

INSERT INTO [dbo].[ProductImages] ([ProductId], [Url])
VALUES 

(17, N'/images/SanPham/Pate_Cho/SP_03/4.webp'),
(17, N'/images/SanPham/Pate_Cho/SP_03/5.webp'),
(17, N'/images/SanPham/Pate_Cho/SP_03/6.webp'),
(17, N'/images/SanPham/Pate_Cho/SP_03/7.webp');

-- Sản phẩm 18 --
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Pate Cho Chó & Mèo King''s Pet Vị Gà 70g', 15000, 13500, N'King''s Pet',
N'Pate King''s Pet với thành phần chính từ thịt gà, phù hợp cho cả chó và mèo. 
Sản phẩm giàu protein và vitamin, hỗ trợ sức khỏe toàn diện cho thú cưng của bạn.',
N'/images/SanPham/SP_Cho&Meo/SP_02/1.webp', 3, N'Gà');

INSERT INTO [dbo].[ProductImages] ([ProductId], [Url])
VALUES 
(18, N'/images/SanPham/SP_Cho&Meo/SP_02/1.webp'),
(18, N'/images/SanPham/SP_Cho&Meo/SP_02/2.webp'),
(18, N'/images/SanPham/SP_Cho&Meo/SP_02/3.jpg'),
(18, N'/images/SanPham/SP_Cho&Meo/SP_02/4.jpg'),
(18, N'/images/SanPham/SP_Cho&Meo/SP_02/5.jpg');

-- Sản phẩm 19 --
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Thức Ăn Hạt Cho Chó Royal Canin Medium Adult 2kg', 179000, 160000, N'Royal Canin',
N'Sản phẩm cung cấp dinh dưỡng cân bằng cho chó trưởng thành giống trung bình, hỗ trợ hệ tiêu hóa và tăng cường miễn dịch.',
N'/images/SanPham/Hat_Cho/SP_02/1.webp', 5, N'1kg, 4kg');

INSERT INTO [dbo].[ProductImages] ([ProductId], [Url])
VALUES 

(19, N'/images/SanPham/Hat_Cho/SP_02/2.webp'),
(19, N'/images/SanPham/Hat_Cho/SP_02/3.webp'),
(19, N'/images/SanPham/Hat_Cho/SP_02/4.webp'),
(19, N'/images/SanPham/Hat_Cho/SP_02/5.webp');

-- Sản phẩm 20 --
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Thức Ăn Hạt Cho Chó ANF Nature''s Kitchen 2kg', 359000, 320000, N'ANF',
N'ANF Nature''s Kitchen giúp tăng cường hệ miễn dịch với nguyên liệu tự nhiên, không chứa chất bảo quản, phù hợp cho mọi giống chó.',
N'/images/SanPham/Hat_Cho/SP_03/1.webp', 5, N'Xanh, Hồng, Cam');

INSERT INTO [dbo].[ProductImages] ([ProductId], [Url])
VALUES 
(20, N'/images/SanPham/Hat_Cho/SP_03/1.webp'),
(20, N'/images/SanPham/Hat_Cho/SP_03/2.webp'),
(20, N'/images/SanPham/Hat_Cho/SP_03/3.webp'),
(20, N'/images/SanPham/Hat_Cho/SP_03/4.webp');

-- Sản phẩm 21 --
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Thức Ăn Hạt Cho Chó Ganador Vị Cừu Và Gạo 3kg', 150000, NULL, N'Ganador',
N'Ganador cung cấp protein chất lượng cao từ cừu và gạo, giúp chó phát triển khỏe mạnh, hỗ trợ hệ tiêu hóa tối ưu.',
N'/images/SanPham/Hat_Meo/SP_04/1.webp', 5, N'Cừu, Gạo');

-- Sản phẩm 22 --
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Thức Ăn Hạt Cho Chó SmartHeart Puppy Vị Bò & Sữa 400g', 33000, NULL, N'SmartHeart',
N'Sản phẩm dành cho chó con, giúp phát triển trí não và miễn dịch với hương vị bò và sữa thơm ngon.',
N'/images/SanPham/Hat_Meo/SP_04/1.webp', 5, N'Bò, Sữa');

-- Sản phẩm 23 --
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Pate Cho Chó Pedigree Vị Gà 100g', 32000, NULL, N'Pedigree',
N'Pate Pedigree vị gà được chế biến từ thịt gà tươi ngon, giàu dinh dưỡng giúp bổ sung năng lượng và tăng cường sức khỏe cho chó.',
N'/images/SanPham/Hat_Meo/SP_04/1.webp', 2, N'Gà');

-- Sản phẩm 24 --
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Pate Cho Chó Royal Canin 100g', 35000, NULL, N'Royal Canin',
N'Pate Royal Canin với công thức đặc biệt giúp chó dễ hấp thu dinh dưỡng, hỗ trợ hệ tiêu hóa và tăng cường sức đề kháng.',
N'/images/SanPham/Hat_Meo/SP_04/1.webp', 2, N'Gà');

-- Sản phẩm 25 --
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Pate Cho Chó SmartHeart Vị Bò 100g', 30000, NULL, N'SmartHeart',
N'Pate SmartHeart với hương vị bò thơm ngon, cung cấp protein và vitamin giúp chó phát triển khỏe mạnh.',
N'/images/SanPham/Hat_Meo/SP_04/1.webp', 2, N'Bò');

--Đánh giá & Bình luận--
--Lưu ý: Phải tạo tk trước mới chạy đc--
--Sau khi đăng ký tk xong (nhớ refresh database), hãy chạy dòng code này và sửa lại UserId, sau đó mới insert--
SELECT Id, UserName FROM AspNetUsers;

-- Customer1 Customer1@gmail.com TPHCM 0123456789 --
-- Customer2 Customer2@gmail.com HANOI 0123456788 --
-- Customer3 Customer3@gmail.com HAIPHONG 0123456787 --
-- Customer4 Customer4@gmail.com LONGAN 0123456786 --
-- Customer5 Customer5@gmail.com HUE 0123456785 --

SET DATEFORMAT DMY
INSERT INTO [dbo].[ProductReviews] ([ProductId], [UserId], [Rating], [CommentText], [CreatedDate])
VALUES 
-- Customer1 --
(1, '32b2c97c-6e22-47e5-94a4-365d93b3687d', 4, N'Thức ăn thơm ngon, cún nhà mình rất thích!', '2025-05-12 12:00:00'),
(2, '32b2c97c-6e22-47e5-94a4-365d93b3687d', 5, N'Mèo nhà mình ăn hết sạch, sẽ mua lại!', '2025-05-10 1:00:00'),
(4, '32b2c97c-6e22-47e5-94a4-365d93b3687d', 5, N'Hạt mềm, không gây rối loạn tiêu hoá như loại cũ.', '2025-05-11 13:00:00'),
(6, '32b2c97c-6e22-47e5-94a4-365d93b3687d', 4, N'Chất lượng ổn định, thú cưng thích thú.', '2025-05-13 9:00:00'),
(9, '32b2c97c-6e22-47e5-94a4-365d93b3687d', 5, N'Không có mùi hôi, rất vừa miệng chó nhà mình.', '2025-05-15 17:00:00'),
(12, '32b2c97c-6e22-47e5-94a4-365d93b3687d', 4, N'Phù hợp cho mèo nhỏ tuổi.', '2025-05-16 14:30:00'),
(15, '32b2c97c-6e22-47e5-94a4-365d93b3687d', 5, N'Rất tốt cho hệ tiêu hóa của cún.', '2025-05-18 11:15:00'),

-- Customer2 --
(3, 'a0d4683f-00ef-495d-9d87-94181e223db0', 4, N'Sản phẩm đóng gói kỹ, giao hàng nhanh.', '2025-05-10 12:45:00'),
(5, 'a0d4683f-00ef-495d-9d87-94181e223db0', 5, N'Cún ăn rất hợp, lông mượt hơn rõ rệt!', '2025-05-12 7:30:00'),
(8, 'a0d4683f-00ef-495d-9d87-94181e223db0', 5, N'Giá tốt, dinh dưỡng cao.', '2025-05-14 10:00:00'),
(10, 'a0d4683f-00ef-495d-9d87-94181e223db0', 3, N'Ổn nhưng hơi khô so với loại khác.', '2025-05-15 11:00:00'),
(13, 'a0d4683f-00ef-495d-9d87-94181e223db0', 4, N'Mèo rất thích nhai loại này.', '2025-05-17 8:00:00'),
(16, 'a0d4683f-00ef-495d-9d87-94181e223db0', 5, N'Rất đáng tiền, chất lượng vượt mong đợi.', '2025-05-18 16:00:00'),

-- Customer3 --
(7, '93bca64d-c4e5-4797-a4ee-dafdf7cb2b94', 4, N'Mèo ăn không chừa miếng nào, rất đáng mua.', '2025-05-14 13:20:00'),
(11, '93bca64d-c4e5-4797-a4ee-dafdf7cb2b94', 5, N'Sản phẩm tuyệt vời, thú cưng năng động hơn.', '2025-05-15 9:30:00'),
(14, '93bca64d-c4e5-4797-a4ee-dafdf7cb2b94', 4, N'Cún thích ăn nhưng hơi đắt.', '2025-05-17 15:45:00'),
(17, '93bca64d-c4e5-4797-a4ee-dafdf7cb2b94', 5, N'Bao bì đẹp, thành phần rõ ràng.', '2025-05-19 12:10:00'),
(18, '93bca64d-c4e5-4797-a4ee-dafdf7cb2b94', 4, N'Mèo ăn được nhưng không quá mê.', '2025-05-20 10:10:00'),
(19, '93bca64d-c4e5-4797-a4ee-dafdf7cb2b94', 5, N'Cún ăn vào khỏe hơn rõ rệt.', '2025-05-21 8:30:00'),
(20, '93bca64d-c4e5-4797-a4ee-dafdf7cb2b94', 5, N'Rất hài lòng, sẽ giới thiệu bạn bè!', '2025-05-21 16:45:00'),

-- Customer4 --
(7, '861b016f-6846-4508-9d8f-65f5b4a19d18', 5, N'Sản phẩm dinh dưỡng, chó mình rất thích.', '2025-05-22 09:00:00'),
(11, '861b016f-6846-4508-9d8f-65f5b4a19d18', 4, N'Mèo ăn được nhưng hơi kén một chút.', '2025-05-23 14:00:00'),
(15, '861b016f-6846-4508-9d8f-65f5b4a19d18', 5, N'Rất phù hợp cho Poodle nhà mình.', '2025-05-24 18:30:00'),
(20, '861b016f-6846-4508-9d8f-65f5b4a19d18', 4, N'Gói snack khá thơm, thú cưng rất thích.', '2025-05-28 09:20:00'),
(22, '861b016f-6846-4508-9d8f-65f5b4a19d18', 5, N'Sữa tắm mùi dễ chịu, lông mềm mượt.', '2025-05-29 17:10:00'),
(24, '861b016f-6846-4508-9d8f-65f5b4a19d18', 3, N'Hàng dùng ổn nhưng giao hơi chậm.', '2025-05-30 13:40:00'),

-- Customer5 --
(8, 'bfc19698-9d8c-4c94-9796-29caabb1fef2', 5, N'Cún Golden rất thích, lông óng mượt hơn.', '2025-05-25 10:15:00'),
(12, 'bfc19698-9d8c-4c94-9796-29caabb1fef2', 4, N'Mèo ăn nhanh, giá cả hợp lý.', '2025-05-26 11:45:00'),
(18, 'bfc19698-9d8c-4c94-9796-29caabb1fef2', 5, N'Chất lượng tốt, đáng để mua lại.', '2025-05-27 16:10:00'),
(21, 'bfc19698-9d8c-4c94-9796-29caabb1fef2', 5, N'Bổ sung vitamin rất tốt, mèo khỏe hơn.', '2025-05-28 15:00:00'),
(23, 'bfc19698-9d8c-4c94-9796-29caabb1fef2', 4, N'Khẩu phần phù hợp cho Golden, ăn hết ngay.', '2025-05-29 19:20:00'),
(25, 'bfc19698-9d8c-4c94-9796-29caabb1fef2', 5, N'Rất hài lòng, sẽ mua lại lần nữa.', '2025-05-31 08:10:00');

-- Thú cưng --
-- Lưu ý: Copy UserId ở trên xuống --
INSERT INTO [dbo].[Pets] ([UserId], [Name], [Type], [Age])
VALUES
-- Customer1 --

('32b2c97c-6e22-47e5-94a4-365d93b3687d', N'Yuki', N'Mèo Anh lông ngắn', 2),
('32b2c97c-6e22-47e5-94a4-365d93b3687d', N'Milo', N'Chó Poodle', 3),
-- Customer2 --

('a0d4683f-00ef-495d-9d87-94181e223db0', N'Susu', N'Chó Shiba', 1),
('a0d4683f-00ef-495d-9d87-94181e223db0', N'Bum', N'Chó Corgi', 4),
-- Customer3 --

('93bca64d-c4e5-4797-a4ee-dafdf7cb2b94', N'Luna', N'Mèo Munchkin', 2),
('93bca64d-c4e5-4797-a4ee-dafdf7cb2b94', N'Mina', N'Mèo Ba Tư', 3),
-- Customer4 --

('861b016f-6846-4508-9d8f-65f5b4a19d18', N'Milo', N'Chó Poodle', 2),
('861b016f-6846-4508-9d8f-65f5b4a19d18', N'Bông', N'Mèo Ba Tư', 3),

-- Customer5 --
('bfc19698-9d8c-4c94-9796-29caabb1fef2', N'Lucky', N'Chó Golden Retriever', 4),
('bfc19698-9d8c-4c94-9796-29caabb1fef2', N'Mít', N'Mèo Maine Coon', 2);

--Lịch sử đặt lịch--
--Lưu ý: Copy UserId ở trên xuống--
INSERT INTO [dbo].[Appointments] (
    [UserId], [PetId], [ServiceId], [AppointmentDate], [AppointmentTime], 
    [StartDate], [EndDate], [Status], [CreatedDate], [OwnerPhoneNumber], [ApplicationUserId]
)
VALUES
-- Customer1 --
('32b2c97c-6e22-47e5-94a4-365d93b3687d', 1, 1, '2025-05-16', '09:00:00', '2025-05-16', '2025-05-18', 'Pending',   '2025-05-12', '0123456789', NULL), -- Homestay
('32b2c97c-6e22-47e5-94a4-365d93b3687d', 1, 4, '2025-05-17', '10:30:00', '2025-05-17', '2025-05-17', 'Confirmed', '2025-05-13', '0123456789', NULL), -- Vet
('32b2c97c-6e22-47e5-94a4-365d93b3687d', 2, 2, '2025-05-18', '14:00:00', '2025-05-18', '2025-05-20', 'Pending',   '2025-05-14', '0123456789', NULL), -- Homestay
('32b2c97c-6e22-47e5-94a4-365d93b3687d', 2, 5, '2025-05-16', '15:30:00', '2025-05-16', '2025-05-16', 'Confirmed', '2025-05-11', '0123456789', NULL), -- Vet

-- Customer2 --
('a0d4683f-00ef-495d-9d87-94181e223db0', 3, 3, '2025-05-19', '08:15:00', '2025-05-19', '2025-05-19', 'Pending',   '2025-05-15', '0123456788', NULL), -- Vet
('a0d4683f-00ef-495d-9d87-94181e223db0', 3, 5, '2025-05-20', '11:00:00', '2025-05-20', '2025-05-20', 'Confirmed', '2025-05-14', '0123456788', NULL), -- Vet
('a0d4683f-00ef-495d-9d87-94181e223db0', 4, 2, '2025-05-16', '13:45:00', '2025-05-16', '2025-05-18', 'Pending',   '2025-05-12', '0123456788', NULL), -- Homestay
('a0d4683f-00ef-495d-9d87-94181e223db0', 4, 1, '2025-05-18', '16:00:00', '2025-05-18', '2025-05-20', 'Pending',   '2025-05-13', '0123456788', NULL), -- Homestay

-- Customer3 --
('93bca64d-c4e5-4797-a4ee-dafdf7cb2b94', 5, 2, '2025-05-17', '09:30:00', '2025-05-17', '2025-05-19', 'Confirmed', '2025-05-13', '0123456787', NULL), -- Homestay
('93bca64d-c4e5-4797-a4ee-dafdf7cb2b94', 5, 4, '2025-05-17', '13:00:00', '2025-05-17', '2025-05-17', 'Confirmed', '2025-05-12', '0123456787', NULL), -- Vet
('93bca64d-c4e5-4797-a4ee-dafdf7cb2b94', 6, 1, '2025-05-18', '10:45:00', '2025-05-18', '2025-05-20', 'Confirmed', '2025-05-14', '0123456787', NULL), -- Homestay
('93bca64d-c4e5-4797-a4ee-dafdf7cb2b94', 6, 7, '2025-05-19', '15:00:00', '2025-05-19', '2025-05-19', 'Pending',   '2025-05-13', '0123456787', NULL), -- Spa

-- Customer4 --
('861b016f-6846-4508-9d8f-65f5b4a19d18', 7, 1, '2025-06-02', '09:00:00', '2025-06-02', '2025-06-04', 'Confirmed', '2025-05-28', '0123456786', NULL), -- Homestay
('861b016f-6846-4508-9d8f-65f5b4a19d18', 8, 6, '2025-06-05', '14:30:00', '2025-06-05', '2025-06-05', 'Pending',   '2025-05-30', '0123456786', NULL), -- Spa
('861b016f-6846-4508-9d8f-65f5b4a19d18', 7, 3, '2025-06-08', '09:30:00', '2025-06-08', '2025-06-08', 'Confirmed', '2025-06-01', '0987654321', NULL), -- Vet
('861b016f-6846-4508-9d8f-65f5b4a19d18', 8, 4, '2025-06-12', '15:00:00', '2025-06-12', '2025-06-12', 'Pending',   '2025-06-02', '0987654321', NULL), -- Vet
('861b016f-6846-4508-9d8f-65f5b4a19d18', 7, 7, '2025-06-15', '10:00:00', '2025-06-15', '2025-06-17', 'Confirmed', '2025-06-04', '0987654321', NULL), -- Homestay

-- Customer5 --
('bfc19698-9d8c-4c94-9796-29caabb1fef2', 9, 2, '2025-06-03', '10:00:00', '2025-06-03', '2025-06-05', 'Pending',   '2025-05-29', '0123456785', NULL), -- Homestay
('bfc19698-9d8c-4c94-9796-29caabb1fef2', 10, 5, '2025-06-06', '11:15:00', '2025-06-06', '2025-06-06', 'Confirmed', '2025-05-31', '0123456785', NULL), -- Vet
('bfc19698-9d8c-4c94-9796-29caabb1fef2', 9, 1, '2025-06-09', '14:00:00', '2025-06-09', '2025-06-11', 'Pending',   '2025-06-01', '0977554321', NULL), -- Homestay
('bfc19698-9d8c-4c94-9796-29caabb1fef2', 10, 2, '2025-06-11', '16:30:00', '2025-06-11', '2025-06-13', 'Confirmed', '2025-06-03', '0977554321', NULL), -- Homestay
('bfc19698-9d8c-4c94-9796-29caabb1fef2', 9, 8, '2025-06-18', '08:30:00', '2025-06-18', '2025-06-18', 'Confirmed', '2025-06-05', '0977554321', NULL); -- Spa

-- Dịch vụ khuyến mãi --
INSERT INTO Promotions (Title, ShortDescription, Description, Image, Discount, StartDate, EndDate)
VALUES
(N'Giảm 20% Gói Spa Toàn Diện', 
 N'Thư giãn tuyệt đối cho thú cưng với gói spa toàn diện.', 
 N'Dịch vụ bao gồm tắm, sấy, chải lông, cắt móng và massage cho thú cưng. Đặt ngay hôm nay để nhận ưu đãi giảm 20%.', 
 N'sale_1.jpg', 
 20, '2025-09-20', '2025-10-20'),

(N'Ở 3 Ngày Tặng 1 Ngày Homestay', 
 N'Đặt phòng homestay cho thú cưng 3 ngày sẽ được tặng thêm 1 ngày miễn phí.', 
 N'Dịch vụ homestay cao cấp với không gian rộng rãi, sạch sẽ, an toàn và đầy đủ tiện nghi. Ưu đãi có hạn, nhanh tay đặt ngay.', 
 N'sale_2.jpg', 
 25, '2025-09-22', '2025-10-10'),

(N'Combo Spa + Homestay Giảm 15%', 
 N'Tiết kiệm khi đặt combo spa và homestay cùng lúc.', 
 N'Kết hợp chăm sóc spa và nghỉ dưỡng homestay cho thú cưng, mang lại trải nghiệm trọn vẹn và tiết kiệm 15% chi phí.', 
 N'sale_3.jpg', 
 15, '2025-09-25', '2025-10-25'),

(N'Tặng Quà Cho Khách Hàng Mới', 
 N'Đăng ký lần đầu sẽ nhận ngay quà tặng hấp dẫn.', 
 N'Khách hàng lần đầu đặt dịch vụ tại spa & homestay thú cưng sẽ được tặng 1 suất spa mini miễn phí hoặc đồ chơi thú cưng.', 
 N'sale_4.jpg', 
 10, '2025-09-22', '2025-12-31'),

(N'Giảm 30% Cho Nhóm 2 Thú Cưng', 
 N'Đưa 2 bé cưng đi spa cùng lúc sẽ nhận ngay ưu đãi giảm 30%.', 
 N'Dành cho khách hàng có từ 2 thú cưng trở lên khi đặt dịch vụ spa, giúp tiết kiệm chi phí mà thú cưng vẫn được chăm sóc tận tình.', 
 N'sale_5.jpg', 
 30, '2025-09-22', '2025-10-15');
 
 -- Kiểm tra mọi thứ --
SELECT * FROM Services;
SELECT * FROM Products;
SELECT * FROM ProductImages;
SELECT * FROM ProductReviews;
SELECT * FROM Pets;
SELECT * FROM Appointments;
SELECT * FROM Promotions;

 -- Xóa, reset dịch vụ --
DELETE FROM Services;
DBCC CHECKIDENT ('Services', RESEED, 0);

-- Xóa, reset sản phẩm --
DELETE FROM Products;
DBCC CHECKIDENT ('Products', RESEED, 0);
DELETE FROM ProductImages;
DBCC CHECKIDENT ('ProductImages', RESEED, 0);

-- Xóa, reset đánh giá & bình luận --
DELETE FROM ProductReviews;
DBCC CHECKIDENT ('ProductReviews', RESEED, 0);

-- Xóa, reset thú cưng & lịch sử đặt lịch --
DELETE FROM Pets;
DBCC CHECKIDENT ('Pets', RESEED, 0);
DELETE FROM Appointments;
DBCC CHECKIDENT ('Appointments', RESEED, 0);

 -- Xóa, reset promotion --
DELETE FROM Promotions;
DBCC CHECKIDENT ('Promotions', RESEED, 0);