using Uno;

partial class Main
{
    public Main()
    {
        // Force landscape on Desktop.
        if defined(!MOBILE)
            Application.Current.Window.ClientSize = int2(1280, 720);

        InitializeUX();
    }
}
