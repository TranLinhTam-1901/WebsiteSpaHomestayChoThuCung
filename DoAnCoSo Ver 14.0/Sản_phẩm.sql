USE [DoAnCoSoVer11.0]

--Dịch vụ--
INSERT INTO Services (Discriminator, Name, PriceUnder5kg, Price5To12kg, Price12To25kg, PriceOver25kg)
VALUES 
('SpaService', N'Spa (Tắm sấy vệ sinh)', 330000, 440000, 610000, 850000),
('SpaService', N'Grooming (Spa + Cắt tạo kiểu)', 500000, 690000, 930000, 1300000),
('SpaService', N'Shave (Spa + Cạo lông)', 420000, 570000, 770000, 1000000);

INSERT INTO Services (Discriminator, Name) VALUES
('HomestayService', N'Phòng Standard'),
('HomestayService', N' Phòng Deluxe');

--Danh mục sản phẩm--
INSERT INTO Categories(Name) VALUES
(N'Pate Mèo'),
(N'Pate Chó'),
(N'Pate Chó & Mèo'),
(N'Hạt cho Mèo'),
(N'Hạt cho Chó');

--Sản phẩm 1--
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

--Sản phẩm 2--
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

--Sản phẩm 3--
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

--Sản phẩm 4--
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

--Sản phẩm 5--
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

--Sản phẩm 6--
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

--Sản phẩm 7--
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

--Sản phẩm 8--
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

--Sản phẩm 9--
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

--Sản phẩm 10--
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

--Sản phẩm 11--
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

--Sản phẩm 12--
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

--Sản phẩm 13--
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

--Sản phẩm 14--
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

--Sản phẩm 15--
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

--Sản phẩm 16--
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

--Sản phẩm 17--
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

--Sản phẩm 18--
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

--Sản phẩm 19--
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

--Sản phẩm 20--
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

--Sản phẩm 21--
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Thức Ăn Hạt Cho Chó Ganador Vị Cừu Và Gạo 3kg', 150000, NULL, N'Ganador',
N'Ganador cung cấp protein chất lượng cao từ cừu và gạo, giúp chó phát triển khỏe mạnh, hỗ trợ hệ tiêu hóa tối ưu.',
N'/images/SanPham/Hat_Meo/SP_04/1.webp', 5, N'Cừu, Gạo');

--Sản phẩm 22--
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Thức Ăn Hạt Cho Chó SmartHeart Puppy Vị Bò & Sữa 400g', 33000, NULL, N'SmartHeart',
N'Sản phẩm dành cho chó con, giúp phát triển trí não và miễn dịch với hương vị bò và sữa thơm ngon.',
N'/images/SanPham/Hat_Meo/SP_04/1.webp', 5, N'Bò, Sữa');

--Sản phẩm 23--
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Pate Cho Chó Pedigree Vị Gà 100g', 32000, NULL, N'Pedigree',
N'Pate Pedigree vị gà được chế biến từ thịt gà tươi ngon, giàu dinh dưỡng giúp bổ sung năng lượng và tăng cường sức khỏe cho chó.',
N'/images/SanPham/Hat_Meo/SP_04/1.webp', 2, N'Gà');

--Sản phẩm 24--
INSERT INTO [dbo].[Products] (Name, Price, PriceReduced, Trademark, Description, ImageUrl, CategoryId, Flavors)
VALUES 
(N'Pate Cho Chó Royal Canin 100g', 35000, NULL, N'Royal Canin',
N'Pate Royal Canin với công thức đặc biệt giúp chó dễ hấp thu dinh dưỡng, hỗ trợ hệ tiêu hóa và tăng cường sức đề kháng.',
N'/images/SanPham/Hat_Meo/SP_04/1.webp', 2, N'Gà');

--Sản phẩm 25--
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
-- Customer3 Customer3@gmail.com HUE 0123456787 --

SET DATEFORMAT DMY
INSERT INTO [dbo].[ProductReviews] ([ProductId], [UserId], [Rating], [CommentText], [CreatedDate])
VALUES 
-- Customer1
(1, 'c5aa193f-69ad-4b50-8964-9071dbe3960e', 4, N'Thức ăn thơm ngon, cún nhà mình rất thích!', '2025-05-12 12:00:00'),
(2, 'c5aa193f-69ad-4b50-8964-9071dbe3960e', 5, N'Mèo nhà mình ăn hết sạch, sẽ mua lại!', '2025-05-10 1:00:00'),
(4, 'c5aa193f-69ad-4b50-8964-9071dbe3960e', 5, N'Hạt mềm, không gây rối loạn tiêu hoá như loại cũ.', '2025-05-11 13:00:00'),
(6, 'c5aa193f-69ad-4b50-8964-9071dbe3960e', 4, N'Chất lượng ổn định, thú cưng thích thú.', '2025-05-13 9:00:00'),
(9, 'c5aa193f-69ad-4b50-8964-9071dbe3960e', 5, N'Không có mùi hôi, rất vừa miệng chó nhà mình.', '2025-05-15 17:00:00'),
(12, 'c5aa193f-69ad-4b50-8964-9071dbe3960e', 4, N'Phù hợp cho mèo nhỏ tuổi.', '2025-05-16 14:30:00'),
(15, 'c5aa193f-69ad-4b50-8964-9071dbe3960e', 5, N'Rất tốt cho hệ tiêu hóa của cún.', '2025-05-18 11:15:00'),

-- Customer2
(3, '2cdf5bb5-9349-48e4-8c93-397da567be78', 4, N'Sản phẩm đóng gói kỹ, giao hàng nhanh.', '2025-05-10 12:45:00'),
(5, '2cdf5bb5-9349-48e4-8c93-397da567be78', 5, N'Cún ăn rất hợp, lông mượt hơn rõ rệt!', '2025-05-12 7:30:00'),
(8, '2cdf5bb5-9349-48e4-8c93-397da567be78', 5, N'Giá tốt, dinh dưỡng cao.', '2025-05-14 10:00:00'),
(10, '2cdf5bb5-9349-48e4-8c93-397da567be78', 3, N'Ổn nhưng hơi khô so với loại khác.', '2025-05-15 11:00:00'),
(13, '2cdf5bb5-9349-48e4-8c93-397da567be78', 4, N'Mèo rất thích nhai loại này.', '2025-05-17 8:00:00'),
(16, '2cdf5bb5-9349-48e4-8c93-397da567be78', 5, N'Rất đáng tiền, chất lượng vượt mong đợi.', '2025-05-18 16:00:00'),

-- Customer3
(7, '37e8f224-c255-4162-9fb8-9cad0e231811', 4, N'Mèo ăn không chừa miếng nào, rất đáng mua.', '2025-05-14 13:20:00'),
(11, '37e8f224-c255-4162-9fb8-9cad0e231811', 5, N'Sản phẩm tuyệt vời, thú cưng năng động hơn.', '2025-05-15 9:30:00'),
(14, '37e8f224-c255-4162-9fb8-9cad0e231811', 4, N'Cún thích ăn nhưng hơi đắt.', '2025-05-17 15:45:00'),
(17, '37e8f224-c255-4162-9fb8-9cad0e231811', 5, N'Bao bì đẹp, thành phần rõ ràng.', '2025-05-19 12:10:00'),
(18, '37e8f224-c255-4162-9fb8-9cad0e231811', 4, N'Mèo ăn được nhưng không quá mê.', '2025-05-20 10:10:00'),
(19, '37e8f224-c255-4162-9fb8-9cad0e231811', 5, N'Cún ăn vào khỏe hơn rõ rệt.', '2025-05-21 8:30:00'),
(20, '37e8f224-c255-4162-9fb8-9cad0e231811', 5, N'Rất hài lòng, sẽ giới thiệu bạn bè!', '2025-05-21 16:45:00');

--Thú cưng--
--Lưu ý: Copy UserId ở trên xuống--
INSERT INTO [dbo].[Pets] ([UserId], [Name], [Type], [Age])
VALUES
--Customer1--
('c5aa193f-69ad-4b50-8964-9071dbe3960e', N'Yuki', N'Mèo Anh lông ngắn', 2),
('c5aa193f-69ad-4b50-8964-9071dbe3960e', N'Milo', N'Chó Poodle', 3),
--Customer2--
('2cdf5bb5-9349-48e4-8c93-397da567be78', N'Susu', N'Chó Shiba', 1),
('2cdf5bb5-9349-48e4-8c93-397da567be78', N'Bum', N'Chó Corgi', 4),
--Customer3--
('37e8f224-c255-4162-9fb8-9cad0e231811', N'Luna', N'Mèo Munchkin', 2),
('37e8f224-c255-4162-9fb8-9cad0e231811', N'Mina', N'Mèo Ba Tư', 3);

--Lịch sử đặt lịch--
--Lưu ý: Copy UserId ở trên xuống--
INSERT INTO [dbo].[Appointments] (
    [UserId], [PetId], [ServiceId], [AppointmentDate], [AppointmentTime], 
    [StartDate], [EndDate], [Status], [CreatedDate], [OwnerPhoneNumber], [ApplicationUserId]
)
VALUES
-- Customer1 --
('c5aa193f-69ad-4b50-8964-9071dbe3960e', 1, 1, '2025-05-16', '09:00:00', '2025-05-16', '2025-05-16', 'Pending', '2025-05-12', '0123456789', NULL),
('c5aa193f-69ad-4b50-8964-9071dbe3960e', 1, 4, '2025-05-17', '10:30:00', '2025-05-17', '2025-05-19', 'Confirmed', '2025-05-13', '0123456789', NULL),
('c5aa193f-69ad-4b50-8964-9071dbe3960e', 2, 1, '2025-05-18', '14:00:00', '2025-05-18', '2025-05-18', 'Pending', '2025-05-14', '0123456789', NULL),
('c5aa193f-69ad-4b50-8964-9071dbe3960e', 2, 4, '2025-05-16', '15:30:00', '2025-05-16', '2025-05-19', 'Confirmed', '2025-05-11', '0123456789', NULL),

-- Customer2 --
('2cdf5bb5-9349-48e4-8c93-397da567be78', 3, 3, '2025-05-19', '08:15:00', '2025-05-19', '2025-05-19', 'Pending', '2025-05-15', '0123456788', NULL),
('2cdf5bb5-9349-48e4-8c93-397da567be78', 3, 5, '2025-05-20', '11:00:00', '2025-05-18', '2025-05-20', 'Confirmed', '2025-05-14', '0123456788', NULL),
('2cdf5bb5-9349-48e4-8c93-397da567be78', 4, 2, '2025-05-16', '13:45:00', '2025-05-16', '2025-05-16', 'Pending', '2025-05-12', '0123456788', NULL),
('2cdf5bb5-9349-48e4-8c93-397da567be78', 4, 5, '2025-05-18', '16:00:00', '2025-05-18', '2025-05-20', 'Pending', '2025-05-13', '0123456788', NULL),

-- Customer3 --
('37e8f224-c255-4162-9fb8-9cad0e231811', 5, 2, '2025-05-17', '09:30:00', '2025-05-17', '2025-05-17', 'Confirmed', '2025-05-13', '0123456787', NULL),
('37e8f224-c255-4162-9fb8-9cad0e231811', 5, 4, '2025-05-17', '13:00:00', '2025-05-17', '2025-05-21', 'Confirmed', '2025-05-12', '0123456787', NULL),
('37e8f224-c255-4162-9fb8-9cad0e231811', 6, 1, '2025-05-18', '10:45:00', '2025-05-18', '2025-05-18', 'Confirmed', '2025-05-14', '0123456787', NULL),
('37e8f224-c255-4162-9fb8-9cad0e231811', 6, 4, '2025-05-19', '15:00:00', '2025-05-19', '2025-05-19', 'Pending', '2025-05-13', '0123456787', NULL);

--Kiểm tra thú cưng và lịch sử đặt lịch--
SELECT * FROM Pets;
SELECT * FROM Appointments;

--Xóa, reset sản phẩm--
DELETE FROM Products;
DBCC CHECKIDENT ('Products', RESEED, 0);
DELETE FROM ProductImages;
DBCC CHECKIDENT ('ProductImages', RESEED, 0);

--Xóa, reset đánh giá & bình luận--
DELETE FROM ProductReviews;
DBCC CHECKIDENT ('ProductReviews', RESEED, 0);

--Xóa, reset thú cưng & lịch sử đặt lịch--
DELETE FROM Pets;
DBCC CHECKIDENT ('Pets', RESEED, 0);
DELETE FROM Appointments;
DBCC CHECKIDENT ('Appointments', RESEED, 0);