using System.Runtime.InteropServices;
using Huda.PrayerTaskbar.Core;

namespace Huda.PrayerTaskbar;

internal sealed record TaskbarLayout(nint Handle, NativeMethods.Rect Bounds, int X,
    int Width, uint Dpi, bool Visible);

// All Explorer discovery lives here. Polling is coalesced on a separate STA;
// no UIAutomation callback can re-enter the helper's WinUI tree.
internal sealed class TaskbarInspector(Func<int> width, Action<TaskbarLayout?> publish) : IDisposable
{
    private readonly ManualResetEventSlim _stop = new();
    private Thread? _thread;
    public void Start()
    {
        _thread = new Thread(Inspect) { IsBackground = true, Name = "Huda taskbar inspection" };
        _thread.SetApartmentState(ApartmentState.STA);
        _thread.Start();
    }

    private void Inspect()
    {
        while (!_stop.IsSet)
        {
            TaskbarLayout? layout = null;
            try { layout = ReadLayout(); }
            catch (Exception error) when (error is COMException or InvalidCastException or ArgumentException) { }
            if (!_stop.IsSet) publish(layout);
            _stop.Wait(TimeSpan.FromSeconds(2));
        }
    }

    private TaskbarLayout? ReadLayout()
    {
        if (Environment.OSVersion.Version.Build < 22000 || width() == 0) return null;
        var taskbar = NativeMethods.FindWindow("Shell_TrayWnd", null);
        if (taskbar == 0 || !NativeMethods.GetWindowRect(taskbar, out var rect)) return null;
        var info = new NativeMethods.MonitorInfo { Size = Marshal.SizeOf<NativeMethods.MonitorInfo>() };
        if (!NativeMethods.GetMonitorInfo(NativeMethods.MonitorFromWindow(taskbar, 2), ref info) ||
            (info.Flags & 1) == 0 || rect.Width < rect.Height || rect.Top < info.Monitor.Top + info.Monitor.Height / 2)
            return null;
        var dpi = NativeMethods.GetDpiForWindow(taskbar);
        if (dpi == 0 || rect.Height > 120 * dpi / 96) return null;
        var automation = (IUIAutomation)Activator.CreateInstance(Type.GetTypeFromCLSID(
            new Guid("FF48DBA4-60EF-4201-AA87-54103EEF594E"), true)!)!;
        IUIAutomationElement? root = null;
        IUIAutomationTreeWalker? walker = null;
        var occupied = new List<HorizontalSpan>();
        try
        {
            root = automation.ElementFromHandle(taskbar);
            walker = automation.ControlViewWalker();
            var count = 0;
            void Visit(IUIAutomationElement element, int depth)
            {
                if (++count > 512 || depth > 12 || _stop.IsSet) return;
                if (Convert.ToInt32(element.Property(30002)) == Environment.ProcessId) return;
                var type = Convert.ToInt32(element.Property(30003));
                var bounds = element.Property(30001) as double[];
                if (depth > 0 && bounds is { Length: 4 } && bounds[2] > 0 && bounds[3] > 0 &&
                    bounds[1] < rect.Bottom && bounds[1] + bounds[3] > rect.Top &&
                    type is not (50021 or 50026 or 50032 or 50033) &&
                    (type != 50025 || bounds[2] < rect.Width * .45))
                    occupied.Add(new HorizontalSpan((int)Math.Floor(bounds[0]), (int)Math.Ceiling(bounds[0] + bounds[2])));
                var child = walker.GetFirstChild(element);
                while (child is not null)
                {
                    IUIAutomationElement? next = null;
                    try { Visit(child, depth + 1); next = walker.GetNextSibling(child); }
                    finally { Marshal.ReleaseComObject(child); }
                    child = next;
                }
            }
            Visit(root, 0);
            // Empty, incomplete or enormous trees cannot establish a safe gap.
            if (occupied.Count == 0 || count > 512) return null;
        }
        finally
        {
            if (root is not null) Marshal.ReleaseComObject(root);
            if (walker is not null) Marshal.ReleaseComObject(walker);
            Marshal.ReleaseComObject(automation);
        }
        var physicalWidth = (int)Math.Ceiling(width() * dpi / 96.0);
        var x = TaskbarSpace.FindGap(rect.Left, rect.Right, occupied, physicalWidth, (int)(8 * dpi / 96));
        if (x is null) return null;
        var foreground = NativeMethods.GetForegroundWindow();
        var fullscreen = foreground != taskbar && foreground != 0 &&
            NativeMethods.GetWindowRect(foreground, out var active) &&
            active.Left <= info.Monitor.Left && active.Top <= info.Monitor.Top &&
            active.Right >= info.Monitor.Right && active.Bottom >= info.Monitor.Bottom;
        return new TaskbarLayout(taskbar, rect, x.Value, physicalWidth, dpi,
            !fullscreen && NativeMethods.IsWindowVisible(taskbar));
    }

    public void Dispose() => _stop.Set();

    // Only the leading, used vtable entries are declared. Unused entries preserve order.
    [ComImport, Guid("30CBE57D-D9D0-452A-AB13-7AC5AC4825EE"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IUIAutomation
    {
        void CompareElements(); void CompareRuntimeIds();
        IUIAutomationElement GetRootElement();
        IUIAutomationElement ElementFromHandle(nint hwnd);
        void ElementFromPoint(); void GetFocusedElement(); void GetRootElementBuildCache();
        void ElementFromHandleBuildCache(); void ElementFromPointBuildCache(); void GetFocusedElementBuildCache();
        void CreateTreeWalker();
        IUIAutomationTreeWalker ControlViewWalker();
    }
    [ComImport, Guid("D22108AA-8AC5-49A5-837B-37BBB3D7591E"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IUIAutomationElement
    {
        void SetFocus(); void GetRuntimeId(); void FindFirst(); void FindAll();
        void FindFirstBuildCache(); void FindAllBuildCache(); void BuildUpdatedCache();
        [return: MarshalAs(UnmanagedType.Struct)] object Property(int propertyId);
    }
    [ComImport, Guid("4042C624-389C-4AFC-A630-9DF854A541FC"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IUIAutomationTreeWalker
    {
        IUIAutomationElement? GetParent(IUIAutomationElement element);
        IUIAutomationElement? GetFirstChild(IUIAutomationElement element);
        IUIAutomationElement? GetLastChild(IUIAutomationElement element);
        IUIAutomationElement? GetNextSibling(IUIAutomationElement element);
    }
}
