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
        debug_log string.Join(", ", elements.ToArray());
        debug_log "";
    }
}
