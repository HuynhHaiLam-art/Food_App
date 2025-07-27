using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using WebFoodAPI.Models;

namespace WebFoodAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class PaymentController : ControllerBase
    {
        [HttpPost("vnpay")]
        public IActionResult CreateVnPayPayment([FromBody] PaymentRequest request)
        {
            // TODO: Tạo paymentUrl từ VNPay (tham khảo tài liệu hoặc mẫu ở trên)
            string paymentUrl = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html?...";
            return Ok(new PaymentUrlResponse { PaymentUrl = paymentUrl });
        }

        [HttpPost("momo")]
        public IActionResult CreateMomoPayment([FromBody] PaymentRequest request)
        {
            // TODO: Tạo paymentUrl từ Momo (tham khảo tài liệu hoặc mẫu ở trên)
            string paymentUrl = "https://test-payment.momo.vn/v2/gateway/api/create?...";
            return Ok(new PaymentUrlResponse { PaymentUrl = paymentUrl });
        }
    }
}