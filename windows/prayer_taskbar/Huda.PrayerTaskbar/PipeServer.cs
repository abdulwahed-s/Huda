using System.IO.Pipes;
using System.Text.Json;
using Huda.PrayerTaskbar.Core;
using Microsoft.UI.Dispatching;

namespace Huda.PrayerTaskbar;

internal sealed class PipeServer(DispatcherQueue dispatcher,
    Func<string, JsonElement, Task<string>> command) : IDisposable
{
    private readonly CancellationTokenSource _stop = new();
    public void Start() => _ = Task.Run(Listen);

    private async Task Listen()
    {
        while (!_stop.IsCancellationRequested)
        {
            try
            {
                await using var pipe = CurrentUserPipe.Server(Paths.PipeName);
                await pipe.WaitForConnectionAsync(_stop.Token);
                using var timeout = CancellationTokenSource.CreateLinkedTokenSource(_stop.Token);
                timeout.CancelAfter(TimeSpan.FromSeconds(5));
                var request = await ReadFrame(pipe, timeout.Token);
                using var json = JsonDocument.Parse(request);
                if (json.RootElement.ValueKind != JsonValueKind.Object ||
                    !json.RootElement.TryGetProperty("command", out var property) ||
                    property.ValueKind != JsonValueKind.String) throw new InvalidDataException("Missing IPC command.");
                var verb = property.GetString()!;
                var arguments = json.RootElement.Clone();
                var completion = new TaskCompletionSource<string>(TaskCreationOptions.RunContinuationsAsynchronously);
                if (!dispatcher.TryEnqueue(async () => {
                    try { completion.TrySetResult(await command(verb, arguments)); }
                    catch (Exception error) {
                        if (Paths.InstanceSuffix.Length > 0) Console.Error.WriteLine(error);
                        completion.TrySetResult(JsonSerializer.Serialize(new { error = error.Message }));
                    }
                })) break;
                var response = await completion.Task.WaitAsync(timeout.Token);
                await WriteFrame(pipe, response, timeout.Token);
            }
            catch (Exception error) when (error is IOException or OperationCanceledException or JsonException or InvalidDataException or UnauthorizedAccessException)
            {
                // Also bound retries when a competing process holds the name.
                try { await Task.Delay(100, _stop.Token); }
                catch (OperationCanceledException) { }
            }
        }
    }

    internal static Task<string> ReadFrame(Stream stream, CancellationToken token) => IpcFrames.Read(stream, token);

    internal static Task WriteFrame(Stream stream, string json, CancellationToken token) => IpcFrames.Write(stream, json, token);

    public static bool RequestShutdown()
    {
        if (!Mutex.TryOpenExisting(Paths.MutexName, out var guard)) return false;
        using (guard)
        {
            bool idle;
            try { idle = guard.WaitOne(0); }
            catch (AbandonedMutexException) { idle = true; }
            if (idle) { guard.ReleaseMutex(); return false; }
            using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(4));
            using var pipe = new NamedPipeClientStream(".", Paths.PipeName, PipeDirection.InOut,
                PipeOptions.Asynchronous);
            pipe.ConnectAsync(timeout.Token).GetAwaiter().GetResult();
            CurrentUserPipe.VerifyServer(pipe);
            WriteFrame(pipe, "{\"command\":\"shutdown\"}", timeout.Token).GetAwaiter().GetResult();
            using var response = JsonDocument.Parse(ReadFrame(pipe, timeout.Token).GetAwaiter().GetResult());
            if (!response.RootElement.TryGetProperty("stopped", out var stopped) || stopped.ValueKind != JsonValueKind.True)
                throw new IOException("The countdown companion did not acknowledge shutdown.");
            // Give the primary process time to release installed binaries before an upgrade.
            bool exited;
            try { exited = guard.WaitOne(TimeSpan.FromSeconds(5)); }
            catch (AbandonedMutexException) { exited = true; }
            if (!exited) throw new IOException("The countdown companion is still running.");
            guard.ReleaseMutex();
            return true;
        }
    }

    public void Dispose() { _stop.Cancel(); }
}
