using System.Security.Cryptography;

namespace DoAnCoSo.Helper
{
    public static class TokenHelper
    {
        public static string GenerateToken(int length = 32)
        {
            var bytes = new byte[length];
            RandomNumberGenerator.Fill(bytes);
            return Convert.ToBase64String(bytes)
                .Replace("+", "-").Replace("/", "_").TrimEnd('=');
        }
    }

}
