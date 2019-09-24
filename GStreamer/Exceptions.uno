using Uno;

namespace GStreamer
{
    class PipelineException : Exception
    {
        public PipelineException(string msg)
            : base(msg)
        {
        }

        extern(CPLUSPLUS)
        public PipelineException(ConstCharPtr msg)
            : base(extern<string>(msg) "uString::Utf8($0)")
        {
        }
    }

    class UnsupportedFormatException : PipelineException
    {
        public UnsupportedFormatException(string format)
            : base("Unsupported video format: " + format)
        {
        }
    }

    class EndOfStreamException : PipelineException
    {
        public EndOfStreamException()
            : base("Reached end of stream.")
        {
        }
    }
}
