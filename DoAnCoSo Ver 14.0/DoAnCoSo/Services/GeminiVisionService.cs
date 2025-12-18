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
                            //new { text =
                            //    "Analyze this pet image and RETURN JSON ONLY with keys: type, breed, color, marks."
                            //}
                            // thêm mới ở đây
                            new { text =
                                    @"Phân tích ảnh.

                                    Nếu ảnh KHÔNG PHẢI là thú cưng (chó hoặc mèo),
                                    hãy trả về JSON sau:

                                    {
                                      ""isPet"": false
                                    }

                                    Nếu LÀ thú cưng, trả về JSON TIẾNG VIỆT:

                                    {
                                      ""isPet"": true,
                                      ""type"": ""Chó hoặc Mèo"",
                                      ""breed"": ""Giống"",
                                      ""color"": ""Màu sắc"",
                                      ""marks"": ""Dấu hiệu nhận dạng""
                                    }

                                    Chỉ trả JSON, không giải thích."
                                    }
                            // thêm mới ở đây
                                    ,
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
                $"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={_apiKey}",
                content
            );

            return await response.Content.ReadAsStringAsync();
        }

    }
}
