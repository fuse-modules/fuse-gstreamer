using Uno;
using Uno.UX;
using Uno.Graphics;
using Uno.Diagnostics;
using Uno.Math;
using Uno.Vector;

using Fuse;
using Fuse.Controls.Graphics;
using Fuse.Drawing.Planar;

namespace GStreamer.Controls
{
    class BackgroundEffect : Fuse.Controls.Graphics.Visual
    {
        static readonly float3 Color1 = Uno.Color.Parse("#1d3042").XYZ;
        static readonly float3 Color2 = Uno.Color.Parse("#5e8e8e").XYZ * .75f;

        float2 _drawSize;

        protected override void OnRooted()
        {
            base.OnRooted();
            UpdateManager.AddAction(InvalidateVisual);
        }

        protected override void OnUnrooted()
        {
            UpdateManager.RemoveAction(InvalidateVisual);
            base.OnUnrooted();
        }

        protected sealed override float2 OnArrangeMarginBox(float2 position, LayoutParams lp)
        {
            return _drawSize = base.OnArrangeMarginBox(position, lp);
        }

        public sealed override void Draw(DrawContext dc)
        {
            var t = Clock.GetSeconds() * .3;
            var a1 = (float) Mod(t, PI * 2);
            var a2 = (float) Mod(t * .3, PI * 2);

            draw Rectangle
            {
                DrawContext:
                    dc;
                Visual:
                    this;
                Size:
                    _drawSize;
                float Gradient:
                    Sin(pixel Rotate(VertexData, a2).Y * PIf - a1) * .5f + .5f;
                PixelColor:
                    float4(Lerp(Color1, Color2, Gradient), 1);
            };
        }
    }
}
