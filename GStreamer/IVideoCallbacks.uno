using Uno;

namespace GStreamer
{
    interface IVideoCallbacks
    {
        void OnFrameAvailable();
        void OnReady();
    }
}
