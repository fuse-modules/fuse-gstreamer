using Uno;

namespace GStreamer
{
    public interface IVideoPipeline : IDisposable
    {
        int2 Size { get; }
        texture2D Texture { get; }
        void Update();
    }
}
