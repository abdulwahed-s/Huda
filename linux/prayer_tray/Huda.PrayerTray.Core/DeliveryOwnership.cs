using System.Runtime.InteropServices;
using System.Text.Json;
using NodaTime;

namespace Huda.PrayerTray.Core;

public static class DurableFile
{
    public static void Write(string path, string content)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(path))!);
        using (var stream = new FileStream(path + ".tmp", FileMode.Create, FileAccess.Write, FileShare.None))
        {
            using var writer = new StreamWriter(stream, leaveOpen: true);
            writer.Write(content); writer.Flush(); stream.Flush(true);
        }
        File.Move(path + ".tmp", path, true);
    }
}
