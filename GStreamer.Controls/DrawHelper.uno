using Uno;
using Uno.Graphics;
using Uno.Math;
using Uno.Vector;
using Fuse;
using Fuse.Drawing.Planar;

namespace GStreamer.Controls
{
    class DrawHelper
    {
        public static readonly DrawHelper Instance = new DrawHelper();

        DrawHelper()
        {
            // Private dummy constructor because this class is a singleton.
        }

        public void DrawClipped(DrawContext dc, Visual visual, float2 position, float2 size, texture2D texture, float4 uvClip)
        {
            var uvPosition = uvClip.XY;	
            var uvSize = uvClip.ZW - uvPosition;

            draw Rectangle
            {
                DrawContext:
                    dc;
                Visual:
                    visual;
                Position:
                    Floor(position + .5f);
                Size:
                    Floor(size + .5f);
                TexCoord:
                    VertexData * uvSize + uvPosition;
                PixelColor:
                    sample(texture, TexCoord, SamplerState.LinearClamp);
            };
        }
    }
}
