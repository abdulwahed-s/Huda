using System.Runtime.InteropServices;

namespace Huda.PrayerTaskbar;

/// Alt+F4 cannot be registered as a hotkey on every Windows configuration.
/// Listen only during Focus, on a dedicated message thread; retain no input.
internal sealed class PrayerCloseShortcut : IDisposable
{
    private readonly Func<bool> _dismiss;
    private readonly Thread _thread;
    private readonly NativeMethods.KeyboardHook _procedure;
    private readonly ManualResetEventSlim _ready = new();
    private nint _hook;
    private uint _threadId;
    private int _active = 1;
    private bool _requested;
    public bool Installed { get; private set; }

    public PrayerCloseShortcut(Func<bool> dismiss)
    {
        _dismiss = dismiss; _procedure = OnKey;
        _thread = new Thread(Listen) { IsBackground = true, Name = "Huda.FocusClose" };
        _thread.Start();
        _ready.Wait(TimeSpan.FromSeconds(2));
    }

    private void Listen()
    {
        _threadId = NativeMethods.GetCurrentThreadId();
        NativeMethods.PeekMessage(out _, 0, 0, 0, 0); // Establish the message queue.
        try {
            _hook = NativeMethods.SetWindowsHookEx(13, _procedure, NativeMethods.GetModuleHandle(null), 0);
            Installed = _hook != 0;
            _ready.Set();
            if (_hook == 0 || Volatile.Read(ref _active) == 0) return;
            while (NativeMethods.GetMessage(out _, 0, 0, 0) > 0) { }
        } finally {
            if (_hook != 0) NativeMethods.UnhookWindowsHookEx(_hook);
            _hook = 0; Installed = false;
            _ready.Set();
        }
    }

    private nint OnKey(int code, nint message, nint data)
    {
        if (code >= 0 && Volatile.Read(ref _active) != 0 && (message == 0x100 || message == 0x104)) {
            var input = Marshal.PtrToStructure<NativeMethods.KeyboardInput>(data);
            // F4 is the current key; modifier state belongs to preceding events.
            if (input.Key == 0x73 && (input.Flags & 0x20) != 0 &&
                !Down(0x11) && !Down(0x10) && !Down(0x5B) && !Down(0x5C)) {
                if (_requested || _dismiss()) { _requested = true; return 1; }
            }
        }
        return NativeMethods.CallNextHookEx(_hook, code, message, data);
    }
    private static bool Down(int key) => (NativeMethods.GetAsyncKeyState(key) & 0x8000) != 0;

    public void Dispose()
    {
        if (Interlocked.Exchange(ref _active, 0) == 0) return;
        if (_threadId != 0) NativeMethods.PostThreadMessage(_threadId, 0x12, 0, 0);
        if (_thread.Join(200)) _ready.Dispose();
    }
}
