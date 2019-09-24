using Uno.Compiler.ExportTargetInterop;

namespace GStreamer
{
    [TargetSpecificType]
    [Set("TypeName", "const char*")]
    extern(CPLUSPLUS) struct ConstCharPtr {}

    [TargetSpecificType]
    [Set("Include", "gst/gst.h")]
    [Set("TypeName", "gboolean")]
    extern(CPLUSPLUS) struct gboolean {}

    [TargetSpecificType]
    [Set("Include", "gst/gst.h")]
    [Set("TypeName", "GMainLoop*")]
    extern(CPLUSPLUS) struct GMainLoopPtr {}

    [TargetSpecificType]
    [Set("Include", "gst/gst.h")]
    [Set("TypeName", "GstBuffer*")]
    extern(CPLUSPLUS) struct GstBufferPtr {}

    [TargetSpecificType]
    [Set("Include", "gst/gst.h")]
    [Set("TypeName", "GstBus*")]
    extern(CPLUSPLUS) struct GstBusPtr {}

    [TargetSpecificType]
    [Set("Include", "gst/gst.h")]
    [Set("TypeName", "GstElement*")]
    extern(CPLUSPLUS) struct GstElementPtr {}

    [TargetSpecificType]
    [Set("Include", "gst/gst.h")]
    [Set("TypeName", "GstMessage*")]
    extern(CPLUSPLUS) struct GstMessagePtr {}

    [TargetSpecificType]
    [Set("Include", "gst/gst.h")]
    [Set("TypeName", "GstPad*")]
    extern(CPLUSPLUS) struct GstPadPtr {}

    [TargetSpecificType]
    [Set("Include", "gst/gst.h")]
    [Set("TypeName", "GstStructure*")]
    extern(CPLUSPLUS) struct GstStructurePtr {}

    [Require("Template", "GStreamer")]
    extern(CPLUSPLUS) class GStreamer
    {
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
    }
}
