using Uno;
using Uno.UX;
using Uno.Graphics;
using Uno.Math;
using Uno.Vector;

using Fuse;
using Fuse.Triggers;
using Fuse.Elements;
using Fuse.Controls;
using Fuse.Controls.Graphics;
using Fuse.Internal;
using Fuse.Nodes;

namespace GStreamer.Controls
{
    public class Player : Panel
    {
        static readonly Selector StatusSelector = "Status";
        static readonly Selector IsPlayingSelector = "IsPlaying";
        static readonly Selector UriSelector = "Uri";

        readonly Visual _visual = new Visual();

        string _status;
        public string Status
        {
            get { return _status; }
            private set
            {
                if (_status == value)
                    return;

                _status = value;
                OnPropertyChanged(StatusSelector, this);
            }
        }

        bool _isPlaying;
        public bool IsPlaying
        {
            get { return _isPlaying; }
            private set
            {
                if (_isPlaying == value)
                    return;

                _isPlaying = value;
                OnPropertyChanged(IsPlayingSelector, this);
            }
        }

        string _uri;
        public string Uri
        {
            get { return _uri; }
            set
            {
                if (_uri == value)
                    return;

                _uri = value;
                OnPropertyChanged(UriSelector, this);
            }
        }

        public void Stop()
        {
            _visual.Clear("Stopped.");
        }

        protected override void OnRooted()
        {
            base.OnRooted();
            Children.Add(_visual);
        }

        protected override void OnUnrooted()
        {
            RemoveAllChildren<Visual>();
            base.OnUnrooted();
        }

        class Visual : ControlVisual<Player>, IVideoCallbacks
        {
            readonly SizingContainer _sizing = new SizingContainer();

            IVideoPipeline _pipeline;
            BusyTask _busyTask;

            float2 _drawPosition;
            float2 _drawSize;
            float4 _uvClip;

            protected override void Attach()
            {
                PlayUri(Control.Uri);
            }

            protected override void Detach()
            {
                Clear();
            }

            internal void PlayUri(string uri)
            {
                if (string.IsNullOrEmpty(uri))
                {
                    Clear("No video stream.");
                    return;
                }

                OnLoading();

                try
                {
                    if defined(CPLUSPLUS)
                    {
                        _pipeline = new UriPipeline(this, uri);
                        UpdateManager.AddAction(Update);
                    }
                    else
                    {
                        throw new NotSupportedException("GStreamer is not available on this platform");
                    }
                }
                catch (Exception e)
                {
                    OnError(e);
                }
            }

            internal void Clear(string status = null)
            {
                Control.Status = status;
                Control.IsPlaying = false;

                if (_pipeline == null)
                    return;

                UpdateManager.RemoveAction(Update);
                _pipeline.Dispose();
                _pipeline = null;

                InvalidateVisual();
            }

            void Update()
            {
                try
                {
                    _pipeline.Update();
                }
                catch (Exception e)
                {
                    OnError(e);
                }
            }

            void OnError(Exception e)
            {
                Clear(e.Message);
                BusyTask.SetBusy(Control, ref _busyTask, BusyTaskActivity.Failed, e.Message);
                Fuse.Diagnostics.UnknownException("Player", e, this);
            }

            void OnLoading()
            {
                Clear("Waiting for video to load...");
                BusyTask.SetBusy(Control, ref _busyTask, BusyTaskActivity.Loading);
            }

            void IVideoCallbacks.OnReady()
            {
                if defined(!MOBILE)
                    Application.Current.Window.ClientSize = _pipeline.Size;

                BusyTask.SetBusy(Control, ref _busyTask, BusyTaskActivity.None);
                Control.Status = null;
                Control.IsPlaying = true;
                InvalidateLayout();
            }

            void IVideoCallbacks.OnFrameAvailable()
            {
                InvalidateVisual();
            }

            protected sealed override float2 OnArrangeMarginBox(float2 position, LayoutParams lp)
            {
                var size = base.OnArrangeMarginBox(position, lp);

                if (_pipeline == null)
                    return size;

                var videoSize = (float2) _pipeline.Size;

                // Avoid division by zero
                if (videoSize.X < 1 || size.X < 1 ||
                    videoSize.Y < 1 || size.Y < 1)
                    return size;

                var videoAspect = videoSize.X / videoSize.Y;
                var visualAspect = size.X / size.Y;

                // Fill entire visual with video (rather than fit-to-box)
                if (videoAspect > visualAspect)
                {
                    _drawSize.X = videoSize.X * (size.Y / videoSize.Y);
                    _drawSize.Y = size.Y;
                    _drawPosition.X = (size.X - _drawSize.X) * .5f;
                    _drawPosition.Y = 0;
                }
                else
                {
                    _drawSize.X = size.X;
                    _drawSize.Y = videoSize.Y * (size.X / videoSize.X);
                    _drawPosition.X = 0;
                    _drawPosition.Y = (size.Y - _drawSize.Y) * .5f;
                }

                // Clip to avoid drawing outside of the visual
                _uvClip = _sizing.CalcClip(size, ref _drawPosition, ref _drawSize);

                return size;
            }

            public sealed override void Draw(DrawContext dc)
            {
                if (_pipeline == null)
                    return;

                var texture = _pipeline.Texture;
                if (texture == null)
                    return;

                DrawHelper.Instance.DrawClipped(dc, this, _drawPosition, _drawSize, texture, _uvClip);
            }
        }
    }
}
