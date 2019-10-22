using Uno;
using Uno.Collections;
using GStreamer;

partial class Main
{
    public Main()
    {
        // Force landscape on Desktop.
        if defined(!MOBILE)
            Application.Current.Window.ClientSize = int2(1280, 720);

        // List available GST elements.
        if defined(CPLUSPLUS)
            PrintGstElements();

        InitializeUX();
    }

    extern(CPLUSPLUS) void PrintGstElements()
    {
        var plugins = new List<string>();
        var elements = new List<string>();

        GStreamer.GStreamer.GetPlugins(plugins);

        foreach (var p in plugins)
            GStreamer.GStreamer.GetElements(p, elements);

        elements.Sort(string.Compare);

        debug_log "\nAvailable GST elements:";

        var str = string.Join(", ", elements.ToArray());
        const int limit = 100;

        // Hard-wrap at {limit} chars to please Android logcat.
        for (int i = 0; i < str.Length; i += limit)
            debug_log i + limit < str.Length
                ? str.Substring(i, limit)
                : str.Substring(i) + ".";

        debug_log "";
    }
}
