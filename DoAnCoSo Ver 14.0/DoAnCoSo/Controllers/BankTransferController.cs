using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Newtonsoft.Json;
using System.Net.Http.Headers;
using System.Text;
using DoAnCoSo.Models;
using DoAnCoSo.ViewModels;

namespace DoAnCoSo.Controllers
{
    public class BankTransferController : Controller
    {
        private readonly ApplicationDbContext _context;
        private readonly HttpClient _httpClient;

        public BankTransferController(ApplicationDbContext context)
        {
            _context = context;
            _httpClient = new HttpClient();
        }

        public async Task<IActionResult> Payment(int orderId)
        {
            var order = await _context.Orders
                .Include(o => o.OrderDetails)
                .ThenInclude(d => d.Product)
                .FirstOrDefaultAsync(o => o.Id == orderId);

            if (order == null) return NotFound("Không tìm thấy đơn hàng");

            // 🔥 CẬP NHẬT THÔNG TIN NGÂN HÀNG TẠI ĐÂY
            string bankAccount = "1470572492";
            string owner = "TRAN LINH TAM";  // IN HOA, KHÔNG DẤU
            int acqId = 970418; // BIDV (Mã ngân hàng)

            long amount = (long)order.TotalPrice;
            string content = $"ORDER{order.Id}";

            var requestData = new
            {
                accountNo = bankAccount,
                accountName = owner,
                acqId = acqId,
                amount = amount,
                addInfo = content,
                format = "text",
                template = "compact"
            };

            var json = JsonConvert.SerializeObject(requestData);

            var response = await _httpClient.PostAsync(
                "https://api.vietqr.io/v2/generate",
                new StringContent(json, Encoding.UTF8, "application/json")
            );

            var responseJson = await response.Content.ReadAsStringAsync();
            dynamic result = JsonConvert.DeserializeObject(responseJson);

            if (result?.data == null)
            {
                // ✅ Log lỗi ra console nếu cần debug
                Console.WriteLine("Lỗi QR API: " + responseJson);
                return BadRequest("Lỗi tạo QR từ VietQR API");
            }

            string qrImage = result.data.qrDataURL;

            var viewModel = new CheckoutBankTransferViewModel
            {
                OrderId = order.Id,
                Amount = amount,
                BankAccount = bankAccount,
                OwnerName = owner,
                Content = content,
                QRImageUrl = qrImage
            };

            return View("~/Views/ShoppingCart/BankTransferPayment.cshtml", viewModel);
        }

        public async Task<IActionResult> Confirm(int orderId)
        {
            var order = await _context.Orders.FindAsync(orderId);
            if (order == null) return NotFound();

            order.Status = OrderStatusEnum.ChoXacNhan;
            await _context.SaveChangesAsync();

            return RedirectToAction("OrderCompleted", "ShoppingCart", new { orderId = order.Id });
        }
    }
}
