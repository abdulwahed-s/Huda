using Huda.PrayerTaskbar.Core;
using Xunit;

namespace Huda.PrayerTaskbar.Tests;

public class IpcFramesTests
{
    [Fact]
    public async Task AsyncFramesDoNotCaptureTheUiContext()
    {
        await Task.Run(() => {
            var previous = SynchronizationContext.Current;
            var context = new TrackingContext();
            SynchronizationContext.SetSynchronizationContext(context);
            try
            {
                using var stream = new AsyncStream();
                var write = IpcFrames.Write(stream, "settings — الإعدادات", CancellationToken.None);
                Assert.True(write.Wait(TimeSpan.FromSeconds(3)), "Write requires the blocked UI thread.");
                stream.Position = 0;
                var read = IpcFrames.Read(stream, CancellationToken.None);
                Assert.True(read.Wait(TimeSpan.FromSeconds(3)), "Read requires the blocked UI thread.");
                Assert.Equal("settings — الإعدادات", read.Result);
                Assert.Equal(0, context.Posts);
            }
            finally { SynchronizationContext.SetSynchronizationContext(previous); }
        });
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-1)]
    [InlineData(IpcFrames.MaximumLength + 1)]
    public async Task RejectsInvalidLengths(int length)
    {
        using var stream = new MemoryStream(BitConverter.GetBytes(length));
        await Assert.ThrowsAsync<InvalidDataException>(() => IpcFrames.Read(stream, CancellationToken.None));
    }

    [Fact]
    public async Task TruncatedPayloadCannotBeAcknowledged()
    {
        using var stream = new MemoryStream([3, 0, 0, 0, 65]);
        await Assert.ThrowsAsync<EndOfStreamException>(() => IpcFrames.Read(stream, CancellationToken.None));
    }

    private sealed class TrackingContext : SynchronizationContext
    {
        public int Posts;
        public override void Post(SendOrPostCallback callback, object? state)
        {
            Interlocked.Increment(ref Posts);
            ThreadPool.QueueUserWorkItem(_ => callback(state));
        }
    }

    private sealed class AsyncStream : MemoryStream
    {
        public override async ValueTask<int> ReadAsync(Memory<byte> buffer, CancellationToken cancellationToken = default)
        {
            await Task.Delay(10, cancellationToken).ConfigureAwait(false);
            return await base.ReadAsync(buffer, cancellationToken).ConfigureAwait(false);
        }
        public override async ValueTask WriteAsync(ReadOnlyMemory<byte> buffer, CancellationToken cancellationToken = default)
        {
            await Task.Delay(10, cancellationToken).ConfigureAwait(false);
            await base.WriteAsync(buffer, cancellationToken).ConfigureAwait(false);
        }
    }
}
