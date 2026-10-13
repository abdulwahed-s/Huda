using System.Buffers.Binary;
using System.Text;

namespace Huda.PrayerTaskbar.Core;

public static class IpcFrames
{
    public const int MaximumLength = 1048576;

    public static async Task<string> Read(Stream stream, CancellationToken token)
    {
        var header = new byte[4];
        await stream.ReadExactlyAsync(header, token).ConfigureAwait(false);
        var length = BinaryPrimitives.ReadInt32LittleEndian(header);
        if (length is <= 0 or > MaximumLength) throw new InvalidDataException("Invalid IPC frame length.");
        var data = new byte[length];
        await stream.ReadExactlyAsync(data, token).ConfigureAwait(false);
        return Encoding.UTF8.GetString(data);
    }

    public static async Task Write(Stream stream, string text, CancellationToken token)
    {
        var data = Encoding.UTF8.GetBytes(text);
        if (data.Length is <= 0 or > MaximumLength) throw new InvalidDataException("Invalid IPC frame length.");
        var header = new byte[4];
        BinaryPrimitives.WriteInt32LittleEndian(header, data.Length);
        // Activation callers can synchronously wait on the WinUI thread.
        // Frame continuations must never require that thread's context.
        await stream.WriteAsync(header, token).ConfigureAwait(false);
        await stream.WriteAsync(data, token).ConfigureAwait(false);
        await stream.FlushAsync(token).ConfigureAwait(false);
    }
}
