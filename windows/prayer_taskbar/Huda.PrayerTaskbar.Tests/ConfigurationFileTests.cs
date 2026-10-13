using System.Text.Json;
using Huda.PrayerTaskbar.Core;
using Xunit;

namespace Huda.PrayerTaskbar.Tests;

public sealed class ConfigurationFileTests
{
    [Fact]
    public async Task ConcurrentReadersAllowAtomicConfigurationReplacement()
    {
        var directory = Path.Combine(Path.GetTempPath(), "HudaTaskbarAtomic-" + Guid.NewGuid());
        Directory.CreateDirectory(directory);
        try
        {
            var path = Path.Combine(directory, "configuration.json");
            var temporary = Path.Combine(directory, "replacement.json");
            var sample = ContractsTests.Sample();
            string Json(int revision) => JsonSerializer.Serialize(sample with { Revision = revision },
                TaskbarConfiguration.JsonOptions) + new string(' ', 100_000);
            File.WriteAllText(path, Json(1));
            var store = new ConfigurationStore(path);
            Assert.True(store.Reload());
            using var start = new ManualResetEventSlim();
            var reader = Task.Factory.StartNew(() => {
                start.Wait();
                for (var count = 0; count < 250; count++) store.Reload();
            }, CancellationToken.None, TaskCreationOptions.LongRunning, TaskScheduler.Default);
            var writer = Task.Factory.StartNew(() => {
                start.Wait();
                for (var revision = 2; revision <= 251; revision++)
                {
                    File.WriteAllText(temporary, Json(revision));
                    File.Replace(temporary, path, null);
                }
            }, CancellationToken.None, TaskCreationOptions.LongRunning, TaskScheduler.Default);
            start.Set();
            await Task.WhenAll(reader, writer).WaitAsync(TimeSpan.FromSeconds(30));
            store.Reload();
            Assert.Equal(251, store.Current!.Revision);
            Assert.Null(store.Error);
        }
        finally { Directory.Delete(directory, recursive: true); }
    }
}
