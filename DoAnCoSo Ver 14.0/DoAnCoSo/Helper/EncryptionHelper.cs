using System;
using System.IO;
using System.Security.Cryptography;
using System.Text;

namespace DoAnCoSo.Helpers
{
    public static class EncryptionHelper
    {
        // 🧩 Tạo cặp khóa RSA (Public / Private)
        public static (string publicKey, string privateKey) GenerateRsaKeyPair()
        {
            using var rsa = RSA.Create(2048);
            var pub = rsa.ExportRSAPublicKey();
            var priv = rsa.ExportRSAPrivateKey();
            return (Convert.ToBase64String(pub), Convert.ToBase64String(priv));
        }

        // -------------------- AES cơ bản --------------------
        public static (string Cipher, string Key, string IV) EncryptAES(string plain)
        {
            using var aes = Aes.Create();
            aes.KeySize = 256;
            aes.GenerateKey();
            aes.GenerateIV();

            using var encryptor = aes.CreateEncryptor(aes.Key, aes.IV);
            using var ms = new MemoryStream();
            using (var cs = new CryptoStream(ms, encryptor, CryptoStreamMode.Write))
            using (var sw = new StreamWriter(cs))
            {
                sw.Write(plain);
            }

            return (Convert.ToBase64String(ms.ToArray()),
                    Convert.ToBase64String(aes.Key),
                    Convert.ToBase64String(aes.IV));
        }

        public static string DecryptAES(string cipherBase64, string keyBase64, string ivBase64)
        {
            var cipher = Convert.FromBase64String(cipherBase64);
            var key = Convert.FromBase64String(keyBase64);
            var iv = Convert.FromBase64String(ivBase64);

            using var aes = Aes.Create();
            aes.Key = key;
            aes.IV = iv;

            using var decryptor = aes.CreateDecryptor();
            using var ms = new MemoryStream(cipher);
            using var cs = new CryptoStream(ms, decryptor, CryptoStreamMode.Read);
            using var sr = new StreamReader(cs);
            return sr.ReadToEnd();
        }

        // -------------------- RSA cơ bản --------------------
        public static string EncryptWithPublicKey(string plain, string publicKeyBase64)
        {
            if (string.IsNullOrEmpty(plain)) return plain;
            var pub = Convert.FromBase64String(publicKeyBase64);
            using var rsa = RSA.Create();
            rsa.ImportRSAPublicKey(pub, out _);
            var data = Encoding.UTF8.GetBytes(plain);
            var enc = rsa.Encrypt(data, RSAEncryptionPadding.OaepSHA256);
            return Convert.ToBase64String(enc);
        }

        public static string DecryptWithPrivateKey(string cipherBase64, string privateKeyBase64)
        {
            if (string.IsNullOrEmpty(cipherBase64)) return cipherBase64;
            var priv = Convert.FromBase64String(privateKeyBase64);
            using var rsa = RSA.Create();
            rsa.ImportRSAPrivateKey(priv, out _);
            var data = Convert.FromBase64String(cipherBase64);
            var dec = rsa.Decrypt(data, RSAEncryptionPadding.OaepSHA256);
            return Encoding.UTF8.GetString(dec);
        }

        // -------------------- 🔐 Hybrid RSA + AES --------------------
        public static (string Cipher, string EncryptedKey) EncryptHybrid(string plain, string receiverPublicKey)
        {
            var (cipher, aesKey, iv) = EncryptAES(plain);
            var combined = $"{aesKey}:{iv}";
            var encKey = EncryptWithPublicKey(combined, receiverPublicKey);
            return (cipher, encKey);
        }

        public static string DecryptHybrid(string cipher, string encryptedAesKey, string receiverPrivateKey)
        {
            var combined = DecryptWithPrivateKey(encryptedAesKey, receiverPrivateKey);
            var parts = combined.Split(':');
            if (parts.Length != 2) return cipher;
            return DecryptAES(cipher, parts[0], parts[1]);
        }
    }
}
