using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

public class Cand
{
  public string File; public int Line; public string Kind; public string Name; public string Extra;
}

public static class DeadScan
{
  // Toglie commenti ( // , { } , (* *) ) lasciando intatte le stringhe; mantiene i ritorni a capo.
  public static string Strip(string s, bool keepDirectives)
  {
    var sb = new StringBuilder(s.Length);
    int i = 0, n = s.Length;
    while (i < n)
    {
      char c = s[i];
      if (c == '\'')
      {
        sb.Append(c); i++;
        while (i < n)
        {
          char d = s[i];
          sb.Append(d); i++;
          if (d == '\'') { if (i < n && s[i] == '\'') { sb.Append('\''); i++; } else break; }
          else if (d == '\n') break;
        }
      }
      else if (c == '/' && i + 1 < n && s[i + 1] == '/')
      {
        while (i < n && s[i] != '\n') i++;
      }
      else if (c == '{')
      {
        bool dir = i + 1 < n && s[i + 1] == '$';
        int j = i;
        while (j < n && s[j] != '}') j++;
        if (dir && keepDirectives) { sb.Append(s, i, Math.Min(j + 1, n) - i); }
        else { for (int k = i; k <= j && k < n; k++) if (s[k] == '\n') sb.Append('\n'); }
        i = j + 1;
      }
      else if (c == '(' && i + 1 < n && s[i + 1] == '*')
      {
        int j = s.IndexOf("*)", i + 2, StringComparison.Ordinal);
        if (j < 0) j = n - 2;
        for (int k = i; k < j + 2 && k < n; k++) if (s[k] == '\n') sb.Append('\n');
        i = j + 2;
      }
      else { sb.Append(c); i++; }
    }
    return sb.ToString();
  }

  static readonly Regex IdRx = new Regex(@"[A-Za-z_][A-Za-z0-9_]*", RegexOptions.Compiled);
  static readonly Regex RoutineRx = new Regex(@"^(\s*)(class\s+)?(procedure|function)\s+([A-Za-z_]\w*)(\.([A-Za-z_]\w*))?", RegexOptions.Compiled | RegexOptions.IgnoreCase);
  static readonly Regex SecRx = new Regex(@"^(var|const|type|threadvar|resourcestring)\b", RegexOptions.Compiled | RegexOptions.IgnoreCase);
  static readonly Regex KwRx = new Regex(@"^(procedure|function|constructor|destructor|class|end;|end\.|begin|implementation|interface|uses|initialization|finalization|type|var|const)\b", RegexOptions.Compiled | RegexOptions.IgnoreCase);
  static readonly Regex DeclRx = new Regex(@"^  ([A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)*)\s*([:=])", RegexOptions.Compiled);

  public static List<Cand> Run(string root, string[] files, out Dictionary<string, int> counts)
  {
    counts = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
    var sites = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
    var cands = new List<Cand>();
    var perFile = new List<Tuple<string, string[]>>();
    foreach (var f in files)
    {
      string text;
      try { text = File.ReadAllText(Path.Combine(root, f), Encoding.GetEncoding(1252)); } catch { continue; }
      string st = Strip(text, false);
      foreach (Match m in IdRx.Matches(st))
      {
        int v; counts.TryGetValue(m.Value, out v); counts[m.Value] = v + 1;
      }
      if (f.EndsWith(".pas", StringComparison.OrdinalIgnoreCase)) perFile.Add(Tuple.Create(f, st.Split('\n')));
    }
    foreach (var pf in perFile)
    {
      var lines = pf.Item2;

      string lastKw = ""; bool inIface = false;
      string sec = null; bool secGlobal = false;
      for (int i = 0; i < lines.Length; i++)
      {
        string L = lines[i].TrimEnd('\r');
        if (L.Length > 0 && !char.IsWhiteSpace(L[0]))
        {
          var km = KwRx.Match(L);
          if (km.Success)
          {
            string kw = km.Groups[1].Value.ToLowerInvariant();
            
            if (kw == "interface") inIface = true; if (kw == "implementation") inIface = false; if (kw == "type" || kw == "var" || kw == "const") { /* sezione */ }
            else lastKw = kw;
            var sm = SecRx.Match(L);
            if (sm.Success) { sec = sm.Groups[1].Value.ToLowerInvariant(); secGlobal = inIface || !(lastKw == "procedure" || lastKw == "function" || lastKw == "constructor" || lastKw == "destructor" || lastKw == "class" || lastKw == "begin"); }
            else sec = null;
          }
          else if (L.StartsWith("{$")) { }

        }
        var rm = RoutineRx.Match(L);
        if (rm.Success)
        {
          string nm = rm.Groups[6].Success && rm.Groups[6].Length > 0 ? rm.Groups[6].Value : rm.Groups[4].Value;
          int v; sites.TryGetValue(nm, out v); sites[nm] = v + 1;
          cands.Add(new Cand { File = pf.Item1, Line = i + 1, Kind = rm.Groups[6].Success && rm.Groups[6].Length > 0 ? "method" : "routine", Name = nm, Extra = L.Trim() });
          continue;
        }
        if (sec != null && secGlobal && L.Length > 2 && L.StartsWith("  ") && !char.IsWhiteSpace(L[2]))
        {
          var dm = DeclRx.Match(L);
          if (dm.Success)
          {
            string kind = sec == "type" ? "type" : sec == "const" ? "const" : sec == "resourcestring" ? "const" : "var";
            // in type: solo T... = / in var: solo ':' / in const: ':' o '='
            if (kind == "var" && dm.Groups[2].Value != ":") continue;
            if (kind == "type" && dm.Groups[2].Value != "=") continue;
            foreach (var nm0 in dm.Groups[1].Value.Split(','))
            {
              string nm = nm0.Trim();
              int v; sites.TryGetValue(nm, out v); sites[nm] = v + 1;
              cands.Add(new Cand { File = pf.Item1, Line = i + 1, Kind = kind, Name = nm, Extra = L.Trim() });
            }
          }
        }
      }
    }
    var res = new List<Cand>();
    foreach (var c in cands)
    {
      int tot; counts.TryGetValue(c.Name, out tot);
      int st; sites.TryGetValue(c.Name, out st);
      if (tot == st) res.Add(c);
    }
    return res;
  }
}
