namespace Huda.PrayerTaskbar.Core;

public readonly record struct HorizontalSpan(int Left, int Right);

public static class TaskbarSpace
{
    // Explorer supplies no reservable slot. Only use a measured, unoccupied gap.
    public static int? FindGap(int left, int right, IEnumerable<HorizontalSpan> occupied, int width, int margin)
    {
        var merged = new List<HorizontalSpan>();
        foreach (var span in occupied.Where(span => span.Right > left && span.Left < right)
            .OrderBy(span => span.Left))
        {
            var clipped = new HorizontalSpan(Math.Max(left, span.Left - margin), Math.Min(right, span.Right + margin));
            if (merged.Count > 0 && clipped.Left <= merged[^1].Right)
                merged[^1] = new HorizontalSpan(merged[^1].Left, Math.Max(merged[^1].Right, clipped.Right));
            else merged.Add(clipped);
        }
        var end = right - margin;
        for (var index = merged.Count - 1; index >= 0; index--)
        {
            if (end - merged[index].Right >= width) return end - width;
            end = Math.Min(end, merged[index].Left);
        }
        return end - (left + margin) >= width ? end - width : null;
    }
}
