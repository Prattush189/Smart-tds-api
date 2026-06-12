namespace SmartTdsApi.Logging;

/// <summary>
/// Minimal rolling file logger for support diagnostics. Writes Warning+ lines to
/// <c>&lt;dir&gt;/api-yyyyMMdd.log</c> (one file per day, 30-day retention) so client
/// issues can be decoded from ProgramData without digging through the Windows Event
/// Log / journalctl. Intentionally tiny — no buffering, no background thread, and
/// every failure is swallowed: logging must never take the API down.
/// </summary>
public sealed class FileLoggerProvider : ILoggerProvider
{
    private readonly string _dir;
    private readonly LogLevel _min;
    private readonly object _gate = new();

    public FileLoggerProvider(string dir, LogLevel min = LogLevel.Warning)
    {
        _dir = dir; _min = min;
        try
        {
            Directory.CreateDirectory(_dir);
            foreach (var f in Directory.GetFiles(_dir, "api-*.log"))
                if (File.GetLastWriteTimeUtc(f) < DateTime.UtcNow.AddDays(-30))
                    File.Delete(f);
        }
        catch { /* best-effort */ }
    }

    public ILogger CreateLogger(string categoryName) => new FileLogger(this, categoryName);
    public void Dispose() { }

    private void Write(string category, LogLevel level, string message, Exception? ex)
    {
        try
        {
            var line = string.Format("{0:yyyy-MM-dd HH:mm:ss.fff} [{1,-5}] {2}: {3}",
                DateTime.Now, Abbrev(level), category, message);
            if (ex is not null) line += Environment.NewLine + ex;
            var path = Path.Combine(_dir, "api-" + DateTime.Now.ToString("yyyyMMdd") + ".log");
            lock (_gate) File.AppendAllText(path, line + Environment.NewLine);
        }
        catch { /* never throw from logging */ }
    }

    private static string Abbrev(LogLevel l) => l switch
    {
        LogLevel.Warning => "WARN",
        LogLevel.Error => "ERROR",
        LogLevel.Critical => "FATAL",
        LogLevel.Information => "INFO",
        _ => l.ToString().ToUpperInvariant()
    };

    private sealed class FileLogger : ILogger
    {
        private readonly FileLoggerProvider _p;
        private readonly string _category;
        public FileLogger(FileLoggerProvider p, string category) { _p = p; _category = category; }

        public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;
        public bool IsEnabled(LogLevel logLevel) => logLevel >= _p._min && logLevel != LogLevel.None;

        public void Log<TState>(LogLevel logLevel, EventId eventId, TState state,
            Exception? exception, Func<TState, Exception?, string> formatter)
        {
            if (!IsEnabled(logLevel)) return;
            _p.Write(_category, logLevel, formatter(state, exception), exception);
        }
    }
}
