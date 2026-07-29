using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;

// Usage:
// dotnet run -c Release --f net9.0 

class Program
{
    // ANSI colors (\x1b = ESC; C# doesn't support octal \033)
    const string C_OK    = "\x1b[32m";   // green
    const string C_ERR   = "\x1b[31m";   // red
    const string C_WARN  = "\x1b[33m";   // darkyellow-ish
    const string C_INFO  = "\x1b[36m";   // cyan
    const string C_RESET = "\x1b[0m";

    // Hard-coded dirs to compare
    //static readonly string dir1 = "/media2/my_files/my_docs";
    //static readonly string dir2 = "/media/my_files/my_docs";

    //static readonly string dir1 = "/home/jonas/Downloads/yt/test/dir1";
    //static readonly string dir2 = "/home/jonas/Downloads/yt/test/dir2";

    //static readonly string dir1 = "/media2/Movies";
    //static readonly string dir2 = "/media/Movies";

    //static readonly string dir1 = "/media2/2025/mpq";
    //static readonly string dir2 = "/media/2025/mpq";

    //static readonly string dir1 = "/media2/my_files";
    //static readonly string dir2 = "/media/my_files";

    //static readonly string dir1 = "/media2/2024";
    //static readonly string dir2 = "/media/2024";

    //static readonly string dir1 = "/media2/2025";
    //static readonly string dir2 = "/media/2025";

    static readonly string dir1 = "/media2";
    static readonly string dir2 = "/media";

    // Log file
    static readonly string targetLog = "diff_check.log";

    // Toggle for ignoring paths
    static readonly bool IGNORE_PATH_FILTERS = true; // set to false to disable all ignoring

    // Paths that cause "starts with" skip
    static readonly string[] IGNORE_PREFIXES = new[]
    {
        "$RECYCLE.BIN/",
        "2024/wow/",
        ".Trash-1000/",
        "System Volume Information/",
    };

    // Paths that cause "contains" skip
    static readonly string[] IGNORE_CONTAINS = new[]
    {
        "node_modules/",
        "llama2.c/.git",
        "llama3.2.c/.git",
        "torchless/.git",
        "llama2.c/build",
        "llama3.2.c/build",
        "torchless/build",
        "__pycache__/",
        ".git/",
        "build/",
    };

    // Paths that cause "equals" skip
    static readonly string[] IGNORE_EQUALS = new[]
    {
        //"Movies",
        //"recordings",
        "Magician Launcher.app",
        "Magician Launcher.exe",
        "RootCA.crt",
        "Program.puml",
        "SamsungPortableSSD_Setup_Mac_1.0.pkg",
        "SamsungPortableSSD_Setup_Win_1.0.exe",
        "Samsung Portable SSD SW for Android.txt",
    };

    // Whitelisted paths: these are expected differences and will be printed in a
    // non-bad color (cyan) instead of red.  Matches exact path or anything under it.
    static readonly string[] WHITELIST_PATHS = new[]
    {
        "Install Western Digital Software for Mac.dmg",
        "Install Western Digital Software for Windows.exe",
        "Movies/Series/Anime/Boku No Hero Academia - My Hero Academia",
        "Movies/Series/Anime/Kimetsu no Yaiba - Demon Slayer",
        "Movies/Series/Anime/made_in_abyss",
        "Movies/Series/Anime/Naruto",
        "Movies/Series/Anime/Re Zero - kara Hajimeru Isekai Seikatsu - Starting Life in Another World",
        "Movies/Series/Anime/Shingeki no Kyojin - Attack on Titan",
        "Movies/Series/Anime/Vinland Saga",
        "my_files/my_docs/ai/models/llama3.2.c/data",
        "my_files/my_docs/ai/models/llama3.2.c/out/cs",
        "my_files/my_docs/ai/models/llama3.2.c/pcre.h",
        "my_files/my_docs/ai/models/llama3.2.c/run.exe",
        "my_files/my_docs/ai/models/llama3.2.c/run.obj",
        "my_files/my_docs/ai/models/llama3.2.c/win.obj",
        "my_files/my_docs/ai/models/llama3.2.c/out/Llama3.2-3B.bin",
        "my_files/my_docs/ai/models/llama3.2.c/out/Llama3.2-3B-Instruct.bin",
        "my_files/my_docs/ai/models/torchless",
        "p",
        "p2",
    };

    static void Main()
    {
        var scriptStart = Stopwatch.StartNew();

        using var logWriter = new StreamWriter(targetLog, append: false, encoding: Encoding.UTF8);

        void Log(string msg = "", string color = "")
        {
            if (!string.IsNullOrEmpty(color))
            {
                Console.WriteLine($"{color}{msg}{C_RESET}");
                logWriter.WriteLine($"{color}{msg}{C_RESET}");
            }
            else
            {
                Console.WriteLine(msg);
                logWriter.WriteLine(msg);
            }
            logWriter.Flush();
        }

        Log($"Comparison started at {DateTime.Now:yyyy-MM-dd HH:mm:ss}", C_INFO);
        Log($"Comparing {dir1} <-> {dir2}", C_INFO);

        // Listing / "find" phase
        var findSw = Stopwatch.StartNew();
        var paths1 = CollectPaths(dir1);
        var paths2 = CollectPaths(dir2);
        findSw.Stop();

        int findElapsedMs = (int)findSw.Elapsed.TotalMilliseconds;
        Log();
        Log($"Listing phase (walk) took {FormatMs(findElapsedMs)}", C_INFO);
        Log();

        // Compute diffs
        var set1 = new HashSet<string>(paths1);
        var set2 = new HashSet<string>(paths2);

        var missingIn2 = set1.Except(set2).OrderBy(p => p).ToList();
        var missingIn1 = set2.Except(set1).OrderBy(p => p).ToList();

        // Counters for summary
        int countUnexpected = 0;
        int countWhitelisted = 0;

        if (missingIn2.Count == 0 && missingIn1.Count == 0)
        {
            Log("[ok] Both directories contain the same files and directories.", C_OK);
        }
        else
        {
            if (missingIn2.Count > 0)
            {
                Log($"Entries in {dir1} missing in {dir2}:", C_WARN);
                foreach (var p in CompressPaths(missingIn2))
                {
                    if (IsWhitelisted(p))
                    {
                        Log($"  {p}  (whitelisted)", C_INFO);
                        countWhitelisted++;
                    }
                    else
                    {
                        Log($"  {p}", C_ERR);
                        countUnexpected++;
                    }
                }
            }

            if (missingIn1.Count > 0)
            {
                Log($"Entries in {dir2} missing in {dir1}:", C_WARN);
                foreach (var p in CompressPaths(missingIn1))
                {
                    if (IsWhitelisted(p))
                    {
                        Log($"  {p}  (whitelisted)", C_INFO);
                        countWhitelisted++;
                    }
                    else
                    {
                        Log($"  {p}", C_ERR);
                        countUnexpected++;
                    }
                }
            }
        }

        // Print difference summary
        Log();
        if (countUnexpected == 0 && countWhitelisted == 0)
        {
            Log("[ok] No differences found.", C_OK);
        }
        else if (countUnexpected == 0)
        {
            Log($"[ok] All differences are whitelisted ({countWhitelisted} whitelisted).", C_OK);
        }
        else
        {
            Log($"[!!] {countUnexpected} unexpected difference(s) found ({countWhitelisted} whitelisted).", C_ERR);
        }

        // Total runtime
        scriptStart.Stop();
        int totalElapsedMs = (int)scriptStart.Elapsed.TotalMilliseconds;
        Log();
        Log($"Total runtime: {FormatMs(totalElapsedMs)}", C_INFO);
    }

    static bool ShouldSkipPath(string path)
    {
        if (!IGNORE_PATH_FILTERS)
            return false;

        // starts with prefixes
        // If prefix ends with "/", also skip the directory name itself (without "/")
        foreach (var p in IGNORE_PREFIXES)
        {
            if (p.EndsWith("/"))
            {
                var pDir = p[..^1]; // trim trailing "/"
                if (string.Equals(path, pDir, StringComparison.Ordinal) ||
                    path.StartsWith(p, StringComparison.Ordinal))
                    return true;
            }
            else
            {
                if (path.StartsWith(p, StringComparison.Ordinal))
                    return true;
            }
        }

        // contains substrings
        foreach (var p in IGNORE_CONTAINS)
        {
            if (path.IndexOf(p, StringComparison.Ordinal) >= 0)
                return true;
        }

        // equals specific names (and anything under them)
        foreach (var p in IGNORE_EQUALS)
        {
            if (string.Equals(path, p, StringComparison.Ordinal) ||
                path.StartsWith(p + "/", StringComparison.Ordinal))
                return true;
        }

        return false;
    }

    static bool IsWhitelisted(string path)
    {
        foreach (var w in WHITELIST_PATHS)
        {
            if (string.Equals(path, w, StringComparison.Ordinal) ||
                path.StartsWith(w + "/", StringComparison.Ordinal))
                return true;
        }
        return false;
    }

    static List<string> CollectPaths(string baseDir)
    {
        var paths = new HashSet<string>(StringComparer.Ordinal);

        var dirsToProcess = new Stack<string>();
        dirsToProcess.Push(baseDir);

        while (dirsToProcess.Count > 0)
        {
            var current = dirsToProcess.Pop();
            string relRoot = Path.GetRelativePath(baseDir, current);
            if (relRoot == ".")
            {
                relRoot = string.Empty;
            }

            string[] subdirs;
            try
            {
                subdirs = Directory.GetDirectories(current);
            }
            catch
            {
                continue;
            }

            // Handle directories (with pruning)
            foreach (var d in subdirs)
            {
                var name = Path.GetFileName(d);
                string relPath = string.IsNullOrEmpty(relRoot) ? name : $"{relRoot}/{name}";
                // normalize to '/'
                relPath = relPath.Replace(Path.DirectorySeparatorChar, '/');

                if (ShouldSkipPath(relPath))
                {
                    // don't push into stack -> pruning
                    continue;
                }

                paths.Add(relPath);
                dirsToProcess.Push(d);
            }

            string[] files;
            try
            {
                files = Directory.GetFiles(current);
            }
            catch
            {
                continue;
            }

            // Handle files
            foreach (var f in files)
            {
                var name = Path.GetFileName(f);
                string relPath = string.IsNullOrEmpty(relRoot) ? name : $"{relRoot}/{name}";
                relPath = relPath.Replace(Path.DirectorySeparatorChar, '/');

                if (ShouldSkipPath(relPath))
                    continue;

                paths.Add(relPath);
            }
        }

        return paths.OrderBy(p => p, StringComparer.Ordinal).ToList();
    }

    static List<string> CompressPaths(List<string> paths)
    {
        // Mimic the awk/top-level only logic
        var result = new List<string>();

        foreach (var p in paths.OrderBy(p => p, StringComparer.Ordinal))
        {
            bool skip = false;
            foreach (var prev in result)
            {
                if (p.StartsWith(prev + "/", StringComparison.Ordinal))
                {
                    skip = true;
                    break;
                }
            }
            if (!skip)
            {
                result.Add(p);
            }
        }

        return result;
    }

    static string FormatMs(int ms)
    {
        int sec = ms / 1000;
        int rem = ms % 1000;
        return $"{sec}.{rem:000} seconds ({ms} ms)";
    }
}
