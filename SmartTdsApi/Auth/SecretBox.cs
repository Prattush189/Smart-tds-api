using System.Security.Cryptography;
using System.Text;

namespace SmartTdsApi.Auth;

/// <summary>
/// Reversible (recoverable) secret storage for the in-app "view password" / forgotten-
/// password support feature. AES-256-CBC with a random IV prepended; the key is derived
/// (SHA-256) from a server-held secret (the JWT signing key), so the ciphertext can only
/// be read back by this deployment's API.
///
/// This is DISTINCT from authentication: login still verifies the one-way PBKDF2 hash
/// (<see cref="PasswordHasher"/>). SecretBox only lets an ADMIN recover the original
/// password on demand — it never participates in login. It is also distinct from
/// LicenceService's blob crypto, whose key is machine-bound.
/// </summary>
public static class SecretBox
{
    private static byte[] DeriveKey(string serverKey) =>
        SHA256.HashData(Encoding.UTF8.GetBytes("SmartTds.RecoverableSecret.v1|" + serverKey));

    /// <summary>Encrypt plaintext → base64(IV || ciphertext). Returns null for null/empty input.</summary>
    public static string? Encrypt(string? plaintext, string serverKey)
    {
        if (string.IsNullOrEmpty(plaintext)) return null;
        using var aes = Aes.Create();
        aes.Key = DeriveKey(serverKey);
        aes.GenerateIV();
        using var enc = aes.CreateEncryptor();
        var data = Encoding.UTF8.GetBytes(plaintext);
        var cipher = enc.TransformFinalBlock(data, 0, data.Length);
        var outBuf = new byte[aes.IV.Length + cipher.Length];
        Buffer.BlockCopy(aes.IV, 0, outBuf, 0, aes.IV.Length);
        Buffer.BlockCopy(cipher, 0, outBuf, aes.IV.Length, cipher.Length);
        return Convert.ToBase64String(outBuf);
    }

    /// <summary>Decrypt base64(IV || ciphertext) → plaintext. Returns null on any failure
    /// (null/empty input, wrong key, tampering) — recovery is best-effort, never throws.</summary>
    public static string? Decrypt(string? stored, string serverKey)
    {
        if (string.IsNullOrEmpty(stored)) return null;
        try
        {
            var raw = Convert.FromBase64String(stored);
            if (raw.Length <= 16) return null;
            using var aes = Aes.Create();
            aes.Key = DeriveKey(serverKey);
            var iv = new byte[16];
            Buffer.BlockCopy(raw, 0, iv, 0, 16);
            aes.IV = iv;
            using var dec = aes.CreateDecryptor();
            return Encoding.UTF8.GetString(dec.TransformFinalBlock(raw, 16, raw.Length - 16));
        }
        catch { return null; }
    }
}
