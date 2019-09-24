using Uno;

namespace GStreamer
{
    interface IVideoPipeline : IDisposable
    {
        int2 Size { get; }
        texture2D Texture { get; }
        void Update();
    }
}
