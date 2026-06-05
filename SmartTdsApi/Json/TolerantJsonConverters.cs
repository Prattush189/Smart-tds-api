using System.Globalization;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace SmartTdsApi.Json;

// The legacy WinForms desktop (Newtonsoft, loose typing) serializes some values in shapes the
// API's strict System.Text.Json body-binding rejects with an empty-body 400 — e.g. a bool sent
// as the STRING "false"/"true" (the exact bug that broke Excel import on PUT /api/payees:
// PayeeDto.DirFlag is bool? but the desktop sends "DirFlag":"false"), an absent number as "",
// or a number wrapped in quotes. These converters accept those loose shapes on READ; WRITE
// always emits canonical JSON so API responses stay clean for every client.
internal static class Tolerant
{
    public static bool? ReadBool(ref Utf8JsonReader r)
    {
        switch (r.TokenType)
        {
            case JsonTokenType.True: return true;
            case JsonTokenType.False: return false;
            case JsonTokenType.Null: return null;
            case JsonTokenType.Number:
                return r.TryGetInt64(out var n) ? n != 0 : r.GetDouble() != 0d;
            case JsonTokenType.String:
                var s = r.GetString();
                if (s is null) return null;
                s = s.Trim();
                if (s.Length == 0) return null;
                switch (s.ToLowerInvariant())
                {
                    case "true": case "1": case "y": case "yes": case "t": return true;
                    case "false": case "0": case "n": case "no": case "f": return false;
                }
                return bool.TryParse(s, out var b) ? b : (bool?)null;
            default: return null;
        }
    }

    /// <summary>Trimmed numeric text from a String/Null token, or null for null/empty. (Number
    /// tokens are read directly by each converter.)</summary>
    public static string? NumberText(ref Utf8JsonReader r)
    {
        if (r.TokenType != JsonTokenType.String) return null;
        var s = r.GetString()?.Trim();
        return string.IsNullOrEmpty(s) ? null : s;
    }

    private static readonly string[] DateFormats =
    {
        "dd-MM-yyyy", "dd/MM/yyyy", "yyyy-MM-dd", "dd-MM-yyyy HH:mm:ss",
        "dd/MM/yyyy HH:mm:ss", "MM/dd/yyyy", "yyyy-MM-ddTHH:mm:ss"
    };

    public static DateTime? ReadDate(ref Utf8JsonReader r)
    {
        switch (r.TokenType)
        {
            case JsonTokenType.Null: return null;
            case JsonTokenType.String:
                if (r.TryGetDateTime(out var iso)) return iso;     // fast path: ISO 8601
                var s = r.GetString();
                if (string.IsNullOrWhiteSpace(s)) return null;
                s = s.Trim();
                if (DateTime.TryParse(s, CultureInfo.InvariantCulture, DateTimeStyles.None, out var p)) return p;
                if (DateTime.TryParseExact(s, DateFormats, CultureInfo.InvariantCulture, DateTimeStyles.None, out var pe)) return pe;
                return null;
            case JsonTokenType.StartObject:
            case JsonTokenType.StartArray:
                r.Skip(); return null;
            default: return null;
        }
    }
}

public sealed class TolerantBooleanConverter : JsonConverter<bool>
{
    public override bool Read(ref Utf8JsonReader r, Type t, JsonSerializerOptions o) => Tolerant.ReadBool(ref r) ?? false;
    public override void Write(Utf8JsonWriter w, bool v, JsonSerializerOptions o) => w.WriteBooleanValue(v);
}

public sealed class TolerantNullableBooleanConverter : JsonConverter<bool?>
{
    public override bool? Read(ref Utf8JsonReader r, Type t, JsonSerializerOptions o) => Tolerant.ReadBool(ref r);
    public override void Write(Utf8JsonWriter w, bool? v, JsonSerializerOptions o)
    { if (v.HasValue) w.WriteBooleanValue(v.Value); else w.WriteNullValue(); }
}

public sealed class TolerantNullableInt32Converter : JsonConverter<int?>
{
    public override int? Read(ref Utf8JsonReader r, Type t, JsonSerializerOptions o)
    {
        if (r.TokenType == JsonTokenType.Number) return r.TryGetInt32(out var n) ? n : (int)r.GetDouble();
        var s = Tolerant.NumberText(ref r);
        if (s is null) return null;
        if (int.TryParse(s, NumberStyles.Any, CultureInfo.InvariantCulture, out var v)) return v;
        return double.TryParse(s, NumberStyles.Any, CultureInfo.InvariantCulture, out var d) ? (int)d : (int?)null;
    }
    public override void Write(Utf8JsonWriter w, int? v, JsonSerializerOptions o)
    { if (v.HasValue) w.WriteNumberValue(v.Value); else w.WriteNullValue(); }
}

public sealed class TolerantNullableInt64Converter : JsonConverter<long?>
{
    public override long? Read(ref Utf8JsonReader r, Type t, JsonSerializerOptions o)
    {
        if (r.TokenType == JsonTokenType.Number) return r.TryGetInt64(out var n) ? n : (long)r.GetDouble();
        var s = Tolerant.NumberText(ref r);
        if (s is null) return null;
        if (long.TryParse(s, NumberStyles.Any, CultureInfo.InvariantCulture, out var v)) return v;
        return double.TryParse(s, NumberStyles.Any, CultureInfo.InvariantCulture, out var d) ? (long)d : (long?)null;
    }
    public override void Write(Utf8JsonWriter w, long? v, JsonSerializerOptions o)
    { if (v.HasValue) w.WriteNumberValue(v.Value); else w.WriteNullValue(); }
}

public sealed class TolerantNullableDecimalConverter : JsonConverter<decimal?>
{
    public override decimal? Read(ref Utf8JsonReader r, Type t, JsonSerializerOptions o)
    {
        if (r.TokenType == JsonTokenType.Number) return r.TryGetDecimal(out var n) ? n : (decimal)r.GetDouble();
        var s = Tolerant.NumberText(ref r);
        if (s is null) return null;
        return decimal.TryParse(s, NumberStyles.Any, CultureInfo.InvariantCulture, out var v) ? v : (decimal?)null;
    }
    public override void Write(Utf8JsonWriter w, decimal? v, JsonSerializerOptions o)
    { if (v.HasValue) w.WriteNumberValue(v.Value); else w.WriteNullValue(); }
}

public sealed class TolerantNullableDoubleConverter : JsonConverter<double?>
{
    public override double? Read(ref Utf8JsonReader r, Type t, JsonSerializerOptions o)
    {
        if (r.TokenType == JsonTokenType.Number) return r.GetDouble();
        var s = Tolerant.NumberText(ref r);
        if (s is null) return null;
        return double.TryParse(s, NumberStyles.Any, CultureInfo.InvariantCulture, out var v) ? v : (double?)null;
    }
    public override void Write(Utf8JsonWriter w, double? v, JsonSerializerOptions o)
    { if (v.HasValue) w.WriteNumberValue(v.Value); else w.WriteNullValue(); }
}

// ── Non-nullable numerics (e.g. AddChallanDto.Tax/Interest/… are plain `double`,
//    SubCode/AyId are plain `int`). A legacy "" / quoted-number / null coerces to 0. ──
public sealed class TolerantInt32Converter : JsonConverter<int>
{
    public override int Read(ref Utf8JsonReader r, Type t, JsonSerializerOptions o)
    {
        if (r.TokenType == JsonTokenType.Number) return r.TryGetInt32(out var n) ? n : (int)r.GetDouble();
        if (r.TokenType == JsonTokenType.True) return 1;
        if (r.TokenType == JsonTokenType.False) return 0;
        var s = Tolerant.NumberText(ref r);
        if (s is null) return 0;
        if (int.TryParse(s, NumberStyles.Any, CultureInfo.InvariantCulture, out var v)) return v;
        return double.TryParse(s, NumberStyles.Any, CultureInfo.InvariantCulture, out var d) ? (int)d : 0;
    }
    public override void Write(Utf8JsonWriter w, int v, JsonSerializerOptions o) => w.WriteNumberValue(v);
}

public sealed class TolerantInt64Converter : JsonConverter<long>
{
    public override long Read(ref Utf8JsonReader r, Type t, JsonSerializerOptions o)
    {
        if (r.TokenType == JsonTokenType.Number) return r.TryGetInt64(out var n) ? n : (long)r.GetDouble();
        var s = Tolerant.NumberText(ref r);
        if (s is null) return 0;
        if (long.TryParse(s, NumberStyles.Any, CultureInfo.InvariantCulture, out var v)) return v;
        return double.TryParse(s, NumberStyles.Any, CultureInfo.InvariantCulture, out var d) ? (long)d : 0;
    }
    public override void Write(Utf8JsonWriter w, long v, JsonSerializerOptions o) => w.WriteNumberValue(v);
}

public sealed class TolerantDecimalConverter : JsonConverter<decimal>
{
    public override decimal Read(ref Utf8JsonReader r, Type t, JsonSerializerOptions o)
    {
        if (r.TokenType == JsonTokenType.Number) return r.TryGetDecimal(out var n) ? n : (decimal)r.GetDouble();
        var s = Tolerant.NumberText(ref r);
        if (s is null) return 0m;
        return decimal.TryParse(s, NumberStyles.Any, CultureInfo.InvariantCulture, out var v) ? v : 0m;
    }
    public override void Write(Utf8JsonWriter w, decimal v, JsonSerializerOptions o) => w.WriteNumberValue(v);
}

public sealed class TolerantDoubleConverter : JsonConverter<double>
{
    public override double Read(ref Utf8JsonReader r, Type t, JsonSerializerOptions o)
    {
        if (r.TokenType == JsonTokenType.Number) return r.GetDouble();
        var s = Tolerant.NumberText(ref r);
        if (s is null) return 0d;
        return double.TryParse(s, NumberStyles.Any, CultureInfo.InvariantCulture, out var v) ? v : 0d;
    }
    public override void Write(Utf8JsonWriter w, double v, JsonSerializerOptions o) => w.WriteNumberValue(v);
}

// String DTO fields that the desktop fills with a NUMBER or bool (e.g.
// AddChallanDto.ActualTds/DeductedTds/DepositedTds are string? but carry numeric amounts).
// Default System.Text.Json refuses number->string; accept it and keep the raw text.
public sealed class TolerantStringConverter : JsonConverter<string>
{
    public override string? Read(ref Utf8JsonReader r, Type t, JsonSerializerOptions o)
    {
        switch (r.TokenType)
        {
            case JsonTokenType.Null: return null;
            case JsonTokenType.String: return r.GetString();
            case JsonTokenType.Number:
                return r.TryGetInt64(out var l)
                    ? l.ToString(CultureInfo.InvariantCulture)
                    : r.GetDouble().ToString(CultureInfo.InvariantCulture);
            case JsonTokenType.True: return "true";
            case JsonTokenType.False: return "false";
            default: r.Skip(); return null;   // objects/arrays -> ignore gracefully
        }
    }
    public override void Write(Utf8JsonWriter w, string? v, JsonSerializerOptions o)
    { if (v is null) w.WriteNullValue(); else w.WriteStringValue(v); }
}

// DateTime DTO fields (CreatedOn/ModifiedOn/billDt/receiptDt/instrumentDt …). Accept the
// desktop's loose dates: ISO, dd-MM-yyyy / dd/MM/yyyy, or "" (-> MinValue / null) instead of 400.
public sealed class TolerantDateTimeConverter : JsonConverter<DateTime>
{
    public override DateTime Read(ref Utf8JsonReader r, Type t, JsonSerializerOptions o) => Tolerant.ReadDate(ref r) ?? default;
    public override void Write(Utf8JsonWriter w, DateTime v, JsonSerializerOptions o) => w.WriteStringValue(v);
}

public sealed class TolerantNullableDateTimeConverter : JsonConverter<DateTime?>
{
    public override DateTime? Read(ref Utf8JsonReader r, Type t, JsonSerializerOptions o) => Tolerant.ReadDate(ref r);
    public override void Write(Utf8JsonWriter w, DateTime? v, JsonSerializerOptions o)
    { if (v.HasValue) w.WriteStringValue(v.Value); else w.WriteNullValue(); }
}
