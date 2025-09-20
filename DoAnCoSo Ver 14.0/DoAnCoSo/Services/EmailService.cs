using DoAnCoSo.Models;
using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using MimeKit;

namespace DoAnCoSo.Services
{
    public class EmailService
    {
        private readonly EmailSettings _emailSettings;
        private readonly ILogger<EmailService> _logger;

        public EmailService(IOptions<EmailSettings> settings, ILogger<EmailService> logger)
        {
            _emailSettings = settings.Value;
            _logger = logger;
        }

        public async Task SendEmailAsync(string toEmail, string subject, string body)
        {
            var email = new MimeMessage();
            email.From.Add(new MailboxAddress(_emailSettings.SenderName, _emailSettings.SenderEmail));
            email.To.Add(MailboxAddress.Parse(toEmail));
            email.Subject = subject;

            var builder = new BodyBuilder
            {
                HtmlBody = body,
                TextBody = "Email này cần hỗ trợ hiển thị HTML."
            };
            email.Body = builder.ToMessageBody();

            try
            {
                using (var smtp = new SmtpClient())
                {
                    await smtp.ConnectAsync(
                        _emailSettings.SmtpServer,
                        _emailSettings.Port,
                        SecureSocketOptions.StartTls
                    );

                    await smtp.AuthenticateAsync(_emailSettings.Username, _emailSettings.Password);

                    await smtp.SendAsync(email);
                    await smtp.DisconnectAsync(true);

                    _logger.LogInformation("✅ Email đã gửi thành công đến {ToEmail}", toEmail);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ Lỗi khi gửi email đến {ToEmail}", toEmail);
                throw; // vẫn throw để controller biết có lỗi
            }
        }
    }
}
