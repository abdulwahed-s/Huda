using System.Runtime.InteropServices;
using System.Text;

namespace Huda.PrayerTaskbar;

internal static class NativeMethods
{
    internal const uint WS_CHILD = 0x40000000, WS_POPUP = 0x80000000, WS_CLIPCHILDREN = 0x02000000;
    internal const uint WS_EX_TOOLWINDOW = 0x80, SWP_NOACTIVATE = 0x10, SWP_SHOWWINDOW = 0x40;
    internal const uint WM_TIMECHANGE = 0x1E, WM_POWERBROADCAST = 0x218, WM_SETTINGCHANGE = 0x1A,
        WM_DISPLAYCHANGE = 0x7E, WM_DPICHANGED = 0x2E0, WM_HOTKEY = 0x312;
    [DllImport("user32.dll", SetLastError = true)] internal static extern bool RegisterHotKey(nint window, int id, uint modifiers, uint key);
    [DllImport("user32.dll")] internal static extern bool UnregisterHotKey(nint window, int id);
    internal delegate nint KeyboardHook(int code, nint message, nint data);
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)] internal static extern nint SetWindowsHookEx(int type, KeyboardHook callback, nint module, uint thread);
    [DllImport("user32.dll")] internal static extern bool UnhookWindowsHookEx(nint hook);
    [DllImport("user32.dll")] internal static extern nint CallNextHookEx(nint hook, int code, nint message, nint data);
    [DllImport("user32.dll")] internal static extern short GetAsyncKeyState(int key);
    [DllImport("kernel32.dll")] internal static extern uint GetCurrentThreadId();
    [StructLayout(LayoutKind.Sequential)] internal struct KeyboardInput {
        internal uint Key, Scan, Flags, Time; internal nuint Extra;
    }
    [StructLayout(LayoutKind.Sequential)] internal struct NativeMessage {
        internal nint Window; internal uint Message; internal nint WParam, LParam;
        internal uint Time; internal Point Point; internal uint Private;
    }
    [DllImport("user32.dll")] internal static extern bool PeekMessage(out NativeMessage message, nint window, uint first, uint last, uint flags);
    [DllImport("user32.dll")] internal static extern int GetMessage(out NativeMessage message, nint window, uint first, uint last);
    [DllImport("user32.dll")] internal static extern bool PostThreadMessage(uint thread, uint message, nint wparam, nint lparam);
    internal delegate nint WindowProc(nint hwnd, uint message, nint wparam, nint lparam);
    internal delegate bool MonitorEnumeration(nint monitor, nint dc, ref Rect rect, nint data);
    [DllImport("user32.dll")] internal static extern bool EnumDisplayMonitors(nint dc, nint clip, MonitorEnumeration callback, nint data);
    [DllImport("user32.dll", SetLastError = true)] internal static extern nint OpenInputDesktop(uint flags, bool inherit, uint access);
    [DllImport("user32.dll")] internal static extern bool CloseDesktop(nint desktop);
    [DllImport("user32.dll", CharSet = CharSet.Unicode, EntryPoint = "GetUserObjectInformationW", SetLastError = true)]
    internal static extern bool GetUserObjectInformation(nint handle, int index, StringBuilder data, uint length, out uint needed);
    [StructLayout(LayoutKind.Sequential)] internal struct Rect
    {
        internal int Left, Top, Right, Bottom;
        internal readonly int Width => Right - Left;
        internal readonly int Height => Bottom - Top;
    }
    [StructLayout(LayoutKind.Sequential)] internal struct Point { internal int X, Y; }
    [StructLayout(LayoutKind.Sequential)] internal struct NotifyIconIdentifier
    {
        internal uint Size;
        internal nint Window;
        internal uint Id;
        internal Guid Guid;
    }
    [StructLayout(LayoutKind.Sequential)] internal struct MonitorInfo
    {
        internal int Size;
        internal Rect Monitor, Work;
        internal uint Flags;
    }
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)] internal struct WindowClass
    {
        internal uint Style;
        internal WindowProc WndProc;
        internal int ClassExtra, WindowExtra;
        internal nint Instance, Icon, Cursor, Background;
        internal string? MenuName;
        internal string ClassName;
    }
    [DllImport("shell32.dll")] internal static extern int SHGetKnownFolderPath(ref Guid id, uint flags, nint token, out nint path);
    [DllImport("shell32.dll")] internal static extern int Shell_NotifyIconGetRect(ref NotifyIconIdentifier icon, out Rect bounds);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)] internal static extern int GetCurrentPackageFullName(ref uint length, StringBuilder? name);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)] internal static extern nint GetModuleHandle(string? name);
    [DllImport("kernel32.dll")] internal static extern bool GetNamedPipeServerProcessId(nint pipe, out uint processId);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] internal static extern ushort RegisterClass(ref WindowClass windowClass);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] internal static extern nint CreateWindowEx(uint exStyle, string className, string title, uint style, int x, int y, int width, int height, nint parent, nint menu, nint instance, nint parameter);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] internal static extern nint DefWindowProc(nint hwnd, uint message, nint wparam, nint lparam);
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] internal static extern bool DestroyWindow(nint hwnd);
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] internal static extern bool IsWindow(nint hwnd);
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] internal static extern bool IsWindowVisible(nint hwnd);
    [DllImport("user32.dll")] internal static extern nint GetParent(nint hwnd);
    [DllImport("user32.dll", SetLastError = true)] internal static extern nint SetParent(nint hwnd, nint parent);
    [DllImport("user32.dll", EntryPoint = "SetWindowLongPtrW", SetLastError = true)] internal static extern nint SetWindowLongPtr(nint hwnd, int index, nint value);
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)] internal static extern bool SetWindowPos(nint hwnd, nint insertAfter, int x, int y, int width, int height, uint flags);
    [DllImport("user32.dll")] internal static extern bool ShowWindow(nint hwnd, int command);
    [DllImport("user32.dll")] internal static extern bool SetForegroundWindow(nint hwnd);
    [DllImport("user32.dll")] internal static extern bool AllowSetForegroundWindow(uint processId);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] internal static extern nint FindWindow(string className, string? title);
    [DllImport("user32.dll")] internal static extern bool GetWindowRect(nint hwnd, out Rect rect);
    [DllImport("user32.dll")] internal static extern bool GetClientRect(nint hwnd, out Rect rect);
    [DllImport("user32.dll")] internal static extern uint GetDpiForWindow(nint hwnd);
    [DllImport("shcore.dll")] internal static extern int GetDpiForMonitor(nint monitor, int type, out uint x, out uint y);
    [DllImport("dwmapi.dll")] internal static extern int DwmSetWindowAttribute(nint hwnd, uint attribute, ref int value, int size);
    [DllImport("user32.dll")] internal static extern nint GetWindowDpiAwarenessContext(nint hwnd);
    [DllImport("user32.dll")] internal static extern bool AreDpiAwarenessContextsEqual(nint first, nint second);
    [DllImport("user32.dll")] internal static extern uint GetWindowThreadProcessId(nint hwnd, out uint processId);
    [DllImport("user32.dll")] internal static extern nint GetForegroundWindow();
    [DllImport("user32.dll")] internal static extern bool GetCursorPos(out Point point);
    [DllImport("user32.dll")] internal static extern nint MonitorFromWindow(nint hwnd, uint flags);
    [DllImport("user32.dll")] internal static extern nint MonitorFromPoint(Point point, uint flags);
    [DllImport("user32.dll")] internal static extern bool GetMonitorInfo(nint monitor, ref MonitorInfo info);
}

// Hidden top-level window receives time/resume/Explorer broadcasts even when the
// countdown is parented to Explorer. UI changes are deferred out of its WndProc.
internal sealed class NativeWindow : IDisposable
{
    private static readonly Dictionary<nint, NativeWindow> Windows = [];
    private static readonly NativeMethods.WindowProc Procedure = WndProc;
    private static bool _registered;
    public nint Handle { get; private set; }
    public event Action<uint>? Message;

    public NativeWindow()
    {
        if (!_registered)
        {
            var windowClass = new NativeMethods.WindowClass { WndProc = Procedure,
                Instance = NativeMethods.GetModuleHandle(null), ClassName = "Huda.PrayerTaskbar.Host" };
            if (NativeMethods.RegisterClass(ref windowClass) == 0)
                throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
            _registered = true;
        }
        Handle = NativeMethods.CreateWindowEx(NativeMethods.WS_EX_TOOLWINDOW, "Huda.PrayerTaskbar.Host",
            "Huda Prayer Countdown", NativeMethods.WS_POPUP | NativeMethods.WS_CLIPCHILDREN,
            0, 0, 1, 1, 0, 0, NativeMethods.GetModuleHandle(null), 0);
        if (Handle == 0) throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
        Windows[Handle] = this;
    }

    private static nint WndProc(nint hwnd, uint message, nint wparam, nint lparam)
    {
        if (Windows.TryGetValue(hwnd, out var window)) window.Message?.Invoke(message);
        return NativeMethods.DefWindowProc(hwnd, message, wparam, lparam);
    }

    public void Dispose()
    {
        Windows.Remove(Handle);
        if (NativeMethods.IsWindow(Handle)) NativeMethods.DestroyWindow(Handle);
        Handle = 0;
    }
}
