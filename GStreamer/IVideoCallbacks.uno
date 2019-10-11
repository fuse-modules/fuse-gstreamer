using Uno;

namespace GStreamer
{
    public interface IVideoCallbacks
    {
        void OnFrameAvailable();
        void OnReady();
    }
}
