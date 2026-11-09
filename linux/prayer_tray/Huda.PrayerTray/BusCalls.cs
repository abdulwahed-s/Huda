using Tmds.DBus.Protocol;

namespace Huda.PrayerTray;

internal static class BusCalls
{
    public static MessageBuffer Message(DBusConnection connection, string destination, string path,
        string iface, string member, string? argument = null)
    {
        using var writer = connection.GetMessageWriter();
        writer.WriteMethodCallHeader(destination: destination, path: path, @interface: iface,
            member: member, signature: argument is null ? "" : "s");
        if (argument is not null) writer.WriteString(argument);
        return writer.CreateMessage();
    }
    public static async Task<string?> Owner(DBusConnection connection, string name)
    {
        try { return await connection.CallMethodAsync(Message(connection, "org.freedesktop.DBus",
            "/org/freedesktop/DBus", "org.freedesktop.DBus", "GetNameOwner", name),
            static (message, _) => message.GetBodyReader().ReadString()).WaitAsync(TimeSpan.FromSeconds(2)); }
        catch (Exception error) when (error is DBusExceptionBase or TimeoutException) { return null; }
    }
}
