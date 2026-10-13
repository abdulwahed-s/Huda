using Microsoft.UI.Composition;
using Microsoft.UI.Xaml;
using Microsoft.UI.Xaml.Media;
using System.Runtime.InteropServices;

namespace Huda.PrayerTaskbar;

// A transparent XAML brush alone leaves the island's opaque composition fill.
// Give this island its own transparent backdrop without changing Explorer.
internal sealed class TaskbarBackdrop : SystemBackdrop
{
    private static Windows.System.DispatcherQueueController? _dispatcherController;
    private Windows.UI.Composition.Compositor? _compositor;
    private Windows.UI.Composition.CompositionColorBrush? _brush;

    protected override void OnTargetConnected(ICompositionSupportsSystemBackdrop target, XamlRoot root)
    {
        base.OnTargetConnected(target, root);
        // The system compositor uses Windows.System's queue, independently of
        // WinUI's Microsoft.UI dispatcher. Retain it for this UI thread's life.
        if (Windows.System.DispatcherQueue.GetForCurrentThread() is null)
        {
            var options = new DispatcherQueueOptions { Size = Marshal.SizeOf<DispatcherQueueOptions>(),
                ThreadType = 2, ApartmentType = 2 };
            Marshal.ThrowExceptionForHR(CreateDispatcherQueueController(options, out var controller));
            try { _dispatcherController = WinRT.MarshalInterface<Windows.System.DispatcherQueueController>.FromAbi(controller); }
            finally { Marshal.Release(controller); }
        }
        _compositor = new Windows.UI.Composition.Compositor();
        _brush = _compositor.CreateColorBrush(Microsoft.UI.Colors.Transparent);
        target.SystemBackdrop = _brush;
    }

    protected override void OnTargetDisconnected(ICompositionSupportsSystemBackdrop target)
    {
        target.SystemBackdrop = null;
        _brush?.Dispose(); _brush = null;
        _compositor?.Dispose(); _compositor = null;
        base.OnTargetDisconnected(target);
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct DispatcherQueueOptions { public int Size, ThreadType, ApartmentType; }
    [DllImport("CoreMessaging.dll")]
    private static extern int CreateDispatcherQueueController(DispatcherQueueOptions options, out nint controller);
}
