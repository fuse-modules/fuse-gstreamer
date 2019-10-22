using Uno.Collections;
using Uno.Compiler.ExportTargetInterop;

namespace GStreamer
{
    [TargetSpecificType]
    [Set("TypeName", "const char*")]
    extern(CPLUSPLUS) public struct ConstCharPtr {}

    [TargetSpecificType]
    [Set("Include", "gst/gst.h")]
    [Set("TypeName", "gboolean")]
    extern(CPLUSPLUS) public struct gboolean {}

    [TargetSpecificType]
    [Set("Include", "gst/gst.h")]
    [Set("TypeName", "guint")]
    extern(CPLUSPLUS) public struct guint {}

    [TargetSpecificType]
    [Set("Include", "gst/gst.h")]
    [Set("TypeName", "GMainLoop*")]
    extern(CPLUSPLUS) public struct GMainLoopPtr {}

    [TargetSpecificType]
    [Set("Include", "gst/gst.h")]
    [Set("TypeName", "GstBuffer*")]
    extern(CPLUSPLUS) public struct GstBufferPtr {}

    [TargetSpecificType]
    [Set("Include", "gst/gst.h")]
    [Set("TypeName", "GstBus*")]
    extern(CPLUSPLUS) public struct GstBusPtr {}

    [TargetSpecificType]
    [Set("Include", "gst/gst.h")]
    [Set("TypeName", "GstElement*")]
    extern(CPLUSPLUS) public struct GstElementPtr {}

    [TargetSpecificType]
    [Set("Include", "gst/gst.h")]
    [Set("TypeName", "GstMessage*")]
    extern(CPLUSPLUS) public struct GstMessagePtr {}

    [TargetSpecificType]
    [Set("Include", "gst/gst.h")]
    [Set("TypeName", "GstPad*")]
    extern(CPLUSPLUS) public struct GstPadPtr {}

    [TargetSpecificType]
    [Set("Include", "gst/gst.h")]
    [Set("TypeName", "GstStructure*")]
    extern(CPLUSPLUS) public struct GstStructurePtr {}

    [Require("Template", "GStreamer")]
    extern(CPLUSPLUS) public class GStreamer
    {
        public static void Init()
        {
            // Referencing this method will invoke the static ctor,
            // which will initialize GStreamer.
        }

        [Require("Source.Include", "gst/gst.h")]
        [extern(IOS) Require("Source.Include", "gst_ios_init.h")]
        [extern(WIN32) Require("Source.Include", "Uno/WinAPIHelper.h")]
        [extern(WIN32) Require("Source.Include", "string")]
        static GStreamer()
        {
            if defined(ANDROID)
                AndroidInit();
            else if defined(IOS)
                extern "gst_ios_init()";
            else if defined(WIN32)
            @{
                WCHAR basedir[2048];
                DWORD len = GetModuleFileNameW(GetModuleHandle(0), basedir, sizeof(basedir));

                while (--len > 0)
                {
                    if (basedir[len] == L'\\')
                    {
                        basedir[len] = L'\0';
                        break;
                    }
                }

                // Add plugins from system-installed GStreamer.
                std::wstring pluginPath = basedir;
                pluginPath += L";%GSTREAMER_1_0_ROOT_X86_64%\\lib\\gstreamer-1.0";

                SetEnvironmentVariableW(L"GST_PLUGIN_PATH", pluginPath.c_str());
                SetEnvironmentVariableW(L"GST_DEBUG_DUMP_DOT_DIR", basedir);
            @}

            extern "gst_init(NULL, NULL)";
        }

        [Foreign(Language.Java)]
        extern(ANDROID) static void AndroidInit()
        @{
            try {
                System.loadLibrary("gstreamer_android");
                org.freedesktop.gstreamer.GStreamer.init(
                    com.fuse.Activity
                        .getRootActivity()
                        .getApplication()
                        .getApplicationContext());
            } catch (Exception e) {
                android.util.Log.e("GStreamer.init()", e.getMessage());
            }
        @}

        [Require("Source.Include", "gst/gstregistry.h")]
        public static void GetPlugins(List<string> result)
        @{
            GList* plugins = gst_registry_get_plugin_list(gst_registry_get());

            for (GList* it = plugins; it; it = g_list_next(it))
            {
                GstPlugin* plugin = (GstPlugin*)it->data;
                @{$0.Add(string):Call(uString::Utf8(gst_plugin_get_name(plugin)))};
            }

            gst_plugin_list_free(plugins);
        @}

        [Require("Source.Include", "gst/gstregistry.h")]
        public static void GetElements(string plugin, List<string> result)
        @{
            GList* features = gst_registry_get_feature_list_by_plugin(gst_registry_get(), uCString($0).Ptr);

            for (GList* it = features; it; it = g_list_next(it))
            {
                if (!it->data)
                    continue;

                GstPluginFeature* feature = GST_PLUGIN_FEATURE(it->data);
                if (!GST_IS_ELEMENT_FACTORY(feature))
                    continue;

                GstElementFactory* factory = GST_ELEMENT_FACTORY(gst_plugin_feature_load(feature));
                @{$1.Add(string):Call(uString::Utf8(gst_plugin_feature_get_name(factory)))};
            }

            gst_plugin_feature_list_free(features);
        @}
    }
}
