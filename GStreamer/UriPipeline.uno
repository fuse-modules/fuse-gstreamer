using Uno;
using Uno.Compiler.ExportTargetInterop;
using Uno.Diagnostics;
using Uno.Graphics;
using Uno.Threading;

namespace GStreamer
{
    extern(CPLUSPLUS)
    public class UriPipeline : GStreamer, IVideoPipeline
    {
        const int FramebufferCount = 2;

        readonly IVideoCallbacks _callbacks;
        readonly byte[][] _framebuffers = new byte[FramebufferCount][];
        readonly Thread _thread;

        GMainLoopPtr _loop;
        GstElementPtr _pipeline;
        GstElementPtr _decodebin;
        GstElementPtr _videosink;
        GstBusPtr _bus;
        guint _bus_watch_id;

        Exception _error;

        int _currFramebuffer;
        int _nextFramebuffer;
        bool _dirty;
        bool _disposed;

        int _width;
        int _height;
        string _format;
        texture2D _tex;

        public int2 Size
        {
            get { return int2(_width, _height); }
        }

        public texture2D Texture
        {
            get { return _tex; }
        }

        public UriPipeline(IVideoCallbacks callbacks, string uri)
        {
            _callbacks = callbacks;
            Configure(uri);
            _thread = new Thread(MainLoop);
            _thread.Start();
        }

        public void Dispose()
        {
            if (_disposed)
                return;

            _disposed = true;
            _dirty = false;

            Stop();
            _thread.Join();
            Free();
            
            if (_tex != null)
                _tex.Dispose();
        }

        public void Update()
        {
            if (_error != null)
                throw _error;

            if (!_dirty)
                return;

            var bytes = _framebuffers[_currFramebuffer];
            _dirty = false;

            // Create texture on first frame
            if (_tex == null)
            {
                if (_format != "RGBA")
                    throw new UnsupportedFormatException(_format);

                _tex = new texture2D(int2(_width, _height), Format.RGBA8888, false);
                _callbacks.OnReady();
            }

            // Update texture
            _tex.Update(bytes);
            _callbacks.OnFrameAvailable();
        }

        void Configure(string uri)
        @{
            @{$$._loop} = g_main_loop_new(NULL, FALSE);

            GError* error = NULL;
            @{$$._pipeline} = gst_parse_launch("uridecodebin name=decodebin ! videoconvert ! video/x-raw,format=RGBA ! fakesink name=videosink", &error);

            if (error)
            {
                U_ERROR(error->message);
                U_THROW_IOE("GStreamer: Failed to create the pipeline");
            }

            @{$$._decodebin} = gst_bin_get_by_name(GST_BIN(@{$$._pipeline}), "decodebin");
            @{$$._videosink} = gst_bin_get_by_name(GST_BIN(@{$$._pipeline}), "videosink");

            if (!@{$$._decodebin})
                U_THROW_IOE("GStreamer: The 'decodebin' element is missing");
            if (!@{$$._videosink})
                U_THROW_IOE("GStreamer: The 'fakesink' element is missing");

            g_object_set(G_OBJECT(@{$$._decodebin}), "uri", uCString($0).Ptr, NULL);

            // Reduce latency
            g_signal_connect(@{$$._decodebin}, "source-setup", G_CALLBACK(@{OnSourceSetup(GstElementPtr,GstElementPtr,UriPipeline)}), $$);

            // Setup the pipeline
            g_signal_connect(@{$$._decodebin}, "pad-added", G_CALLBACK(@{OnPadAdded(GstElementPtr,GstPadPtr,UriPipeline)}), $$);

            @{$$._bus} = gst_pipeline_get_bus(GST_PIPELINE(@{$$._pipeline}));
            @{$$._bus_watch_id} = gst_bus_add_watch(@{$$._bus}, (GstBusFunc) @{OnBusCall(GstBusPtr,GstMessagePtr,UriPipeline)}, $$);

            // Start the pipeline
            if (GST_STATE_CHANGE_FAILURE ==
                gst_element_set_state(GST_ELEMENT(@{$$._pipeline}), GST_STATE_PLAYING))
            {
                @{OnError(GstMessagePtr,UriPipeline):Call(gst_bus_poll(@{$$._bus}, GST_MESSAGE_ERROR, 0), $$)};
                U_THROW_IOE("GStreamer: Failed to start the pipeline");
            }
        @}

        void MainLoop()
        @{
            g_main_loop_run(@{$$._loop});
        @}

        void Stop()
        @{
            gst_element_set_state(GST_ELEMENT(@{$$._pipeline}), GST_STATE_NULL);
            g_main_loop_quit(@{$$._loop});
        @}

        void Free()
        @{
            gst_object_unref(@{$$._bus});
            gst_object_unref(@{$$._pipeline});
            g_source_remove(@{$$._bus_watch_id});
        @}

        static void OnSourceSetup(GstElementPtr pipeline, GstElementPtr source, UriPipeline p)
        @{
            // Reduce latency
            gint latency = 0;
            GValue val = G_VALUE_INIT;
            g_value_init(&val, G_TYPE_INT);
            g_value_set_int(&val, latency);
            g_object_set_property(G_OBJECT($1), "latency", &val);
        @}

        static void OnPadAdded(GstElementPtr element, GstPadPtr pad, UriPipeline p)
        @{
            GstCaps* caps = gst_pad_get_current_caps($1);
            GstStructure* str = gst_caps_get_structure(caps, 0);

            if (g_strrstr(gst_structure_get_name(str), "video"))
            {
                GstPad* sink = gst_element_get_static_pad(@{$2._videosink}, "sink");

                g_object_set(G_OBJECT(@{$2._videosink}),
                    "sync", TRUE,
                    "signal-handoffs", TRUE,
                    NULL);
                g_signal_connect(@{$2._videosink},
                    "preroll-handoff",
                    G_CALLBACK(@{OnBufferData(GstElementPtr,GstBufferPtr,GstPadPtr,UriPipeline)}),
                    $2);
                g_signal_connect(@{$2._videosink},
                    "handoff",
                    G_CALLBACK(@{OnBufferData(GstElementPtr,GstBufferPtr,GstPadPtr,UriPipeline)}),
                    $2);

                gst_pad_link($1, sink);
                gst_object_unref(sink);
            }

            gst_caps_unref(caps);
        @}

        static void OnBufferData(GstElementPtr element, GstBufferPtr buf, GstPadPtr pad, UriPipeline p)
        @{
            if (!@{$3._format})
            {
                GstCaps* caps = gst_pad_get_current_caps(pad);
                
                if (!caps)
                {
                    @{$3._error} = @{PipelineException(ConstCharPtr):New("Stream error.")};
                    U_ERROR("Could not get caps for pad=%p!", $2);
                    return;
                }

                gchar* tmp = gst_caps_to_string(caps);
                U_LOG(tmp);
                g_free(tmp);

                GstStructure* str = gst_caps_get_structure(caps, 0);
                gst_structure_get_int(str, "width", &@{$3._width});
                gst_structure_get_int(str, "height", &@{$3._height});
                @{$3._format} = uString::Utf8(gst_structure_get_string(str, "format"));
                
                int size = (int) gst_buffer_get_size(buf);
                for (int i = 0; i < @{FramebufferCount}; i++)
                    @{$3._framebuffers}->Unsafe<uArray*>(i) = uArray::New(@{byte[]:TypeOf}, size);
            }

            int next = @{$3._nextFramebuffer};
            uArray* bytes = @{$3._framebuffers}->Unsafe<uArray*>(next);

            // OPTIMIZE: it's possible to avoid this copy-pass via byte[]?
            U_ASSERT(len == gst_buffer_get_size(buf));
            gst_buffer_extract(buf, 0, bytes->Ptr(), bytes->Length());

            @{$3._currFramebuffer} = next;
            @{$3._nextFramebuffer} = (next + 1) % @{FramebufferCount};
            @{$3._dirty} = true;
        @}

        [Require("Source.Include", "@{EndOfStreamException:Include}")]
        static gboolean OnBusCall(GstBusPtr bus, GstMessagePtr msg, UriPipeline p)
        @{
            switch (GST_MESSAGE_TYPE($1))
            {
            case GST_MESSAGE_EOS:
                @{$2._error} = @{EndOfStreamException():New()};
                @{$2.Stop():Call()};
                break;

            case GST_MESSAGE_ERROR:
                @{OnError(GstMessagePtr,UriPipeline):Call($1, $2)};
                @{$2.Stop():Call()};
                break;

            case GST_MESSAGE_WARNING:
                @{OnWarning(GstMessagePtr,UriPipeline):Call($1, $2)};
                break;
            }

            return TRUE;
        @}

        static void OnError(GstMessagePtr msg, UriPipeline p)
        @{
            if (!$0)
                return;

            GError* err = NULL;
            gchar* debug = NULL;
            gst_message_parse_error($0, &err, &debug);

            if (err)
            {
                @{$1._error} = @{PipelineException(ConstCharPtr):New(err->message)};
                U_ERROR(err->message);
                g_error_free(err);
            }

            if (debug)
            {
                U_LOG("Debug details: %s", debug);
                g_free(debug);
            }
        @}

        static void OnWarning(GstMessagePtr msg, UriPipeline p)
        @{
            GError* err = NULL;
            gchar* debug = NULL;
            gst_message_parse_warning($0, &err, &debug);

            if (err)
            {
                uLog(uLogLevelWarning, err->message);
                g_error_free(err);
            }

            if (debug)
            {
                U_LOG("Debug details: %s", debug);
                g_free(debug);
            }
        @}
    }
}
