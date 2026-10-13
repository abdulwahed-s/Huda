using System.IO.Pipes;
using System.Security.AccessControl;
using System.Security.Principal;

namespace Huda.PrayerTaskbar;

internal static class CurrentUserPipe
{
    // CurrentUserOnly uses WindowsIdentity.Owner, which becomes Administrators
    // under elevation. Bind to the actual user SID so an elevated uninstaller
    // can stop that user's ordinary helper without granting other users access.
    public static NamedPipeServerStream Server(string name)
    {
        using var identity = WindowsIdentity.GetCurrent();
        var sid = identity.User!;
        var security = new PipeSecurity();
        security.SetAccessRuleProtection(isProtected: true, preserveInheritance: false);
        security.SetOwner(sid);
        security.AddAccessRule(new PipeAccessRule(sid, PipeAccessRights.FullControl, AccessControlType.Allow));
        return NamedPipeServerStreamAcl.Create(name, PipeDirection.InOut, 1,
            PipeTransmissionMode.Byte, PipeOptions.Asynchronous, 8192, 8192, security);
    }

    public static void VerifyServer(NamedPipeClientStream pipe)
    {
        using var identity = WindowsIdentity.GetCurrent();
        if (pipe.GetAccessControl().GetOwner(typeof(SecurityIdentifier)) != identity.User)
            throw new UnauthorizedAccessException("The IPC endpoint belongs to another user.");
    }
}
