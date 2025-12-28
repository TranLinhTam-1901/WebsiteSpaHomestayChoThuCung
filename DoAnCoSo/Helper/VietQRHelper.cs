using System;
using System.Text;
using System.Linq;

namespace DoAnCoSo.Helpers
{
    public static class VietQRHelper
    {
        // Tạo chuỗi VietQR theo chuẩn ISO 20022
        public static string GenerateVietQRString(string bankCode, string accountNumber, string ownerName, decimal amount, string content)
        {
            var sb = new StringBuilder();

            // 00: Payload Format Indicator
            sb.Append("00");
            sb.Append("02");
            sb.Append("01");

            // 01: Point of Initiation Method
            sb.Append("01");
            sb.Append("01");
            sb.Append("12"); // tạm set static

            // 38: Merchant Account Information (Bank VietQR)
            string merchantInfo = $"A000000727{bankCode}{accountNumber}";
            sb.Append("38");
            sb.Append(merchantInfo.Length.ToString("D2"));
            sb.Append(merchantInfo);

            // 52: Merchant Category Code (tạm set 0000)
            sb.Append("52");
            sb.Append("04");
            sb.Append("0000");

            // 53: Currency (VND = 704)
            sb.Append("53");
            sb.Append("03");
            sb.Append("704");

            // 54: Amount
            string amountStr = amount.ToString("0.##"); // giữ tối đa 2 số thập phân
            sb.Append("54");
            sb.Append(amountStr.Length.ToString("D2"));
            sb.Append(amountStr);

            // 58: Country Code
            sb.Append("58");
            sb.Append("02");
            sb.Append("VN");

            // 59: Merchant Name (tên người nhận)
            sb.Append("59");
            sb.Append(ownerName.Length.ToString("D2"));
            sb.Append(ownerName);

            // 60: Merchant City (tạm bỏ trống)
            sb.Append("60");
            sb.Append("02");
            sb.Append("HN");

            // 62: Additional Data Field (nội dung chuyển tiền)
            sb.Append("62");
            sb.Append((content.Length + 4).ToString("D2")); // +4 vì 2 ký tự ID + 2 ký tự độ dài
            sb.Append("08"); // ID 08 = Reference
            sb.Append(content.Length.ToString("D2"));
            sb.Append(content);

            // 63: CRC16 placeholder
            sb.Append("63");
            sb.Append("04");
            sb.Append("0000");

            // Tính CRC16
            string crc = CalculateCRC16(sb.ToString());
            sb.Replace("0000", crc);

            return sb.ToString();
        }

        private static string CalculateCRC16(string input)
        {
            ushort polynomial = 0x1021;
            ushort crc = 0xFFFF;

            foreach (byte b in Encoding.ASCII.GetBytes(input))
            {
                crc ^= (ushort)(b << 8);
                for (int i = 0; i < 8; i++)
                {
                    if ((crc & 0x8000) != 0)
                        crc = (ushort)((crc << 1) ^ polynomial);
                    else
                        crc <<= 1;
                }
            }

            return crc.ToString("X4");
        }
    }
}
