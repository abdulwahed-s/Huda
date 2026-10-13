using System.Diagnostics;
using System.IO.Pipes;

namespace Huda.PrayerTaskbar;

internal static class HudaActivation
{
    public static void Open(bool settings) => Open(settings ? "settings" : "prayers");

    public static void Open(string page)
    {
        var argument = page switch {
            "settings" => "--prayer-settings", "prayers" => "--prayer-times",
            "quran" => "--quran", "athkar" => "--athkar", "home" => "--open-huda",
            _ => throw new ArgumentException("Unknown Huda page.", nameof(page)),
        };
        if (Send(page)) return;
        if (File.Exists(Paths.HudaExecutable)) Process.Start(new ProcessStartInfo(Paths.HudaExecutable) {
            Arguments = argument,
            WorkingDirectory = Path.GetDirectoryName(Paths.HudaExecutable), UseShellExecute = true,
        });
    }

    public static bool Send(string command)
    {
        try
        {
            using var pipe = new NamedPipeClientStream(".", "Huda.App." + Paths.UserSid,
                PipeDirection.InOut, PipeOptions.Asynchronous);
            pipe.Connect(350);
            CurrentUserPipe.VerifyServer(pipe);
            if (NativeMethods.GetNamedPipeServerProcessId(pipe.SafePipeHandle.DangerousGetHandle(), out var pid))
                NativeMethods.AllowSetForegroundWindow(pid);
            using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(2));
            PipeServer.WriteFrame(pipe, command, timeout.Token).GetAwaiter().GetResult();
            if (PipeServer.ReadFrame(pipe, timeout.Token).GetAwaiter().GetResult() != "ok") return false;
            PipeServer.WriteFrame(pipe, "ack", timeout.Token).GetAwaiter().GetResult();
            return true;
        }
        catch (Exception error) when (error is IOException or TimeoutException or OperationCanceledException or UnauthorizedAccessException)
        { return false; }
    }
}
