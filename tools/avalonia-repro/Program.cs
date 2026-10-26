// Reproduction minimale : le contenu initial d'un ScrollViewer reste retenu après avoir été remplacé.
// Avalonia 12.1.4. ScrollContentPresenter.MeasureOverride appelle UpdateSnapPoints() une seule fois
// (drapeau _isSnapPointsUpdated) ; le champ _scrollSnapPointsInfo garde alors le contenu d'origine
// et ChildChanged ne le met jamais à jour.
using System;
using System.Runtime.CompilerServices;
using Avalonia;
using Avalonia.Controls;
using Avalonia.Headless;
using Avalonia.Themes.Fluent;
using Avalonia.Threading;

public class App : Application
{
    public override void Initialize() => Styles.Add(new FluentTheme());
}

public static class Program
{
    static ScrollViewer viewer;
    static StackPanel host;

    [MethodImpl(MethodImplOptions.NoInlining)]
    static WeakReference ShowContent(string name, bool useStableHost)
    {
        var content = new StackPanel { Name = name, Children = { new Button { Content = name } } };
        if (useStableHost) { host.Children.Clear(); host.Children.Add(content); }
        else viewer.Content = content;
        Dispatcher.UIThread.RunJobs();
        AvaloniaHeadlessPlatform.ForceRenderTimerTick();
        return new WeakReference(content);
    }

    static int Run(bool useStableHost)
    {
        var window = new Window { Width = 300, Height = 300 };
        viewer = new ScrollViewer();
        host = new StackPanel();
        window.Content = viewer;
        if (useStableHost) viewer.Content = host;
        window.Show();

        var first = ShowContent("first", useStableHost);   // présent au premier Measure
        var second = ShowContent("second", useStableHost); // remplace le premier
        var third = ShowContent("third", useStableHost);   // remplace le deuxième

        for (int i = 0; i < 10; i++) { GC.Collect(); GC.WaitForPendingFinalizers(); }
        Console.WriteLine($"  first  vivant = {first.IsAlive}");
        Console.WriteLine($"  second vivant = {second.IsAlive}");
        Console.WriteLine($"  third  vivant = {third.IsAlive}  (contenu courant, attendu)");
        window.Close();
        return first.IsAlive ? 1 : 0;
    }

    public static int Main()
    {
        AppBuilder.Configure<App>().UseHeadless(new AvaloniaHeadlessPlatformOptions { UseHeadlessDrawing = true }).SetupWithoutStarting();
        Console.WriteLine("Remplacement direct de ScrollViewer.Content :");
        int leak = Run(false);
        Console.WriteLine("Contournement (panneau hôte stable dans le ScrollViewer) :");
        int fixedRun = Run(true);
        Console.WriteLine(leak == 1 && fixedRun == 0 ? "=> BUG REPRODUIT : le premier contenu reste retenu, pas avec le contournement" : "=> non reproduit");
        return leak == 1 && fixedRun == 0 ? 0 : 2;
    }
}
