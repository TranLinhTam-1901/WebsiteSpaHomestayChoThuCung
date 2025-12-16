using Newtonsoft.Json;
using System.Net.Http.Headers;

public class OpenAIVisionService
{
    private readonly string _apiKey;

    public OpenAIVisionService(IConfiguration config)
    {
        _apiKey = config["OpenAI:ApiKey"];
    }

    public async Task<string> AnalyzeImageAsync(IFormFile image)
    {
        using var http = new HttpClient();
        http.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", _apiKey);

        using var ms = new MemoryStream();
        await image.CopyToAsync(ms);
        var base64 = Convert.ToBase64String(ms.ToArray());

        var body = new
        {
            model = "gpt-4o-mini",
            messages = new[]
            {
                new {
                    role = "user",
                    content = new object[]
                    {
                        new { type = "text", text = "Analyze pet image and return JSON with keys: type, breed, color, marks" },
                        new {
                            type = "image_url",
                            image_url = new {
                                url = $"data:{image.ContentType};base64,{base64}"
                            }
                        }
                    }
                }
            }
        };

        var json = JsonConvert.SerializeObject(body);
        var content = new StringContent(json);
        content.Headers.ContentType = new MediaTypeHeaderValue("application/json");

        var res = await http.PostAsync(
            "https://api.openai.com/v1/chat/completions",
            content
        );

        return await res.Content.ReadAsStringAsync();
    }

    public async Task<string> TranslateAsync(string text)
    {
        using var http = new HttpClient();
        http.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", _apiKey);

        var body = new
        {
            model = "gpt-4o-mini",
            messages = new[]
            {
            new
            {
                role = "user",
                content = $"Dịch câu sau sang tiếng Việt và CHỈ trả về bản dịch: {text}"
            }
        }
        };

        var json = JsonConvert.SerializeObject(body);
        var content = new StringContent(json);
        content.Headers.ContentType = new MediaTypeHeaderValue("application/json");

        var response = await http.PostAsync(
            "https://api.openai.com/v1/chat/completions",
            content
        );

        return await response.Content.ReadAsStringAsync();
    }

}
