using System.Net.Http.Headers;
using Newtonsoft.Json;

namespace DoAnCoSo.Services
{
    public class GeminiVisionService
    {
        private readonly string _apiKey;

        public GeminiVisionService(IConfiguration config)
        {
            _apiKey = config["GoogleGemini:ApiKey"];
        }

        public async Task<string> AnalyzeImageAsync(IFormFile image)
        {
            using var http = new HttpClient();

            // Convert IFormFile → Base64
            using var ms = new MemoryStream();
            await image.CopyToAsync(ms);
            string base64 = Convert.ToBase64String(ms.ToArray());

            // Body yêu cầu: bắt AI trả về JSON
            var requestBody = new
            {
                contents = new[]
                {
                    new {
                        parts = new object[]
                        {
                            new { text =
                                "Analyze this pet image and RETURN JSON ONLY with keys: type, breed, color, marks."
                            },
                            new {
                                inline_data = new {
                                    mime_type = image.ContentType,
                                    data = base64
                                }
                            }
                        }
                    }
                },

                // ÉP Google trả về JSON chuẩn
                generationConfig = new
                {
                    response_mime_type = "application/json"
                }
            };

            var json = JsonConvert.SerializeObject(requestBody);

            var content = new StringContent(json);
            content.Headers.ContentType = new MediaTypeHeaderValue("application/json");

            // Gọi Gemini API — dùng model đúng + v1beta
            var response = await http.PostAsync(
                $"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={_apiKey}",
                content
            );

            // Trả về raw JSON Google phản hồi
            return await response.Content.ReadAsStringAsync();
        }
        public async Task<string> TranslateAsync(string text)
        {
            using var http = new HttpClient();

            var requestBody = new
            {
                contents = new[]
                {
            new
            {
                parts = new object[]
                {
                    new { text = $"Dịch câu sau sang TIẾNG VIỆT và chỉ trả lại bản dịch thuần túy, không giải thích: {text}" }
                }
            }
        },
                generationConfig = new
                {
                    response_mime_type = "application/json"
                }
            };

            var json = JsonConvert.SerializeObject(requestBody);
            var content = new StringContent(json);
            content.Headers.ContentType = new MediaTypeHeaderValue("application/json");

            var response = await http.PostAsync(
                $"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={_apiKey}",
                content
            );

            return await response.Content.ReadAsStringAsync();
        }

    }
}
