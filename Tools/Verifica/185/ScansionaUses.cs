using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

public static class UsesScan
{
  static readonly Encoding Enc = Encoding.GetEncoding(1252);
  static readonly Regex IdRx = new Regex(@"[A-Za-z_][A-Za-z0-9_]*", RegexOptions.Compiled);
  static readonly Regex IncRx = new Regex(@"\{\$(?:I|INCLUDE)\s+([^\s}]+)\s*\}", RegexOptions.Compiled | RegexOptions.IgnoreCase);
  static readonly HashSet<string> Kw = new HashSet<string>(StringComparer.OrdinalIgnoreCase) {
    "type","var","const","record","class","end","private","public","protected","published","strict","procedure","function","constructor","destructor","property","uses","interface","implementation","packed","array","of","set","case","if","then","else","begin","out","inline","overload","virtual","override","static","stdcall","cdecl","forward","external","platform","deprecated","sealed","abstract","final","default","read","write","index","message","unit","initialization","finalization","threadvar","resourcestring","object","string","integer","boolean","pointer","operator","helper","for","automated","nil","not","and","or","xor","div","mod","shl","shr","in","is","as","to","downto","do","while","repeat","until","with","try","except","finally","raise","result","self","true","false","register","safecall","assembler","name","reintroduce","dynamic","varargs","experimental"
  };


  static string Expand(string text, Dictionary<string, string> incs, int depth)
  {
    if (depth > 3) return text;
    return IncRx.Replace(text, m =>
    {
      string n = Path.GetFileName(m.Groups[1].Value.Trim('\'', '"'));
      string t;
      if (incs.TryGetValue(n.ToLowerInvariant(), out t)) return Expand(t, incs, depth + 1);
      return m.Value;
    });
  }

  static string StripKeepStrings(string s) { return DeadScan.Strip(s, false); }

  // identificatori dichiarati nell'interface (sovrainsieme prudente: i nomi che non sono parole riservate)
  static HashSet<string> Declared(string stripped)
  {
    var set = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
    var lines = stripped.Split('\n');
    bool inIface = false, inEnum = false;
    foreach (var raw in lines)
    {
      string L = raw.TrimEnd('\r');
      if (Regex.IsMatch(L, @"^interface\b", RegexOptions.IgnoreCase)) { inIface = true; continue; }
      if (Regex.IsMatch(L, @"^implementation\b", RegexOptions.IgnoreCase)) break;
      if (!inIface) continue;
      var rm = Regex.Match(L, @"^\s*(?:class\s+)?(?:procedure|function)\s+(?:\w+\.)?([A-Za-z_]\w*)", RegexOptions.IgnoreCase);
      if (rm.Success && !L.StartsWith("    ")) { set.Add(rm.Groups[1].Value); continue; }
      if (inEnum)
      {
        foreach (var seg in L.Split(','))
        {
          var mm = Regex.Match(seg, @"^\s*\)?\s*([A-Za-z_]\w*)");
          if (mm.Success && !Kw.Contains(mm.Groups[1].Value)) set.Add(mm.Groups[1].Value);
        }
        if (L.Contains(");") || Regex.IsMatch(L, @"\)\s*;")) inEnum = false;
        continue;
      }
      L = Regex.Replace(L, @"^(  [A-Za-z_]\w*)<[^>]*>", "$1");
      var dm = Regex.Match(L, @"^  ([A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)*)\s*([:=])(.*)$");
      if (dm.Success)
      {
        foreach (var nm in dm.Groups[1].Value.Split(',')) { var n = nm.Trim(); if (!Kw.Contains(n)) set.Add(n); }
        string rest = dm.Groups[3].Value;
        if (dm.Groups[2].Value == "=" && Regex.IsMatch(rest, @"^\s*\("))
        {
          // enumerazione (non un insieme di costanti con parentesi di espressione: prudente, e' comunque solo un sovrainsieme)
          foreach (var seg in rest.TrimStart().TrimStart('(').Split(','))
          {
            var mm = Regex.Match(seg, @"^\s*([A-Za-z_]\w*)");
            if (mm.Success && !Kw.Contains(mm.Groups[1].Value)) set.Add(mm.Groups[1].Value);
          }
          if (!Regex.IsMatch(rest, @"\)\s*;")) inEnum = true;
        }
        continue;
      }
    }
    return set;
  }

  static List<string> UnitsOf(string clauseBody)
  {
    var res = new List<string>();
    foreach (var part in clauseBody.Split(','))
    {
      var m = Regex.Match(part, @"^\s*([A-Za-z_][\w\.]*)");
      if (m.Success) res.Add(m.Groups[1].Value);
    }
    return res;
  }

  public static List<string> Run(string root, string[] allFiles, string[] targetFiles)
  {
    var incs = new Dictionary<string, string>();
    var unitFiles = new Dictionary<string, List<string>>(StringComparer.OrdinalIgnoreCase);
    foreach (var f in allFiles)
    {
      string n = Path.GetFileName(f).ToLowerInvariant();
      if (n.EndsWith(".inc")) { try { incs[n] = File.ReadAllText(Path.Combine(root, f), Enc); } catch { } }
      if (n.EndsWith(".pas"))
      {
        string un = Path.GetFileNameWithoutExtension(f);
        List<string> l; if (!unitFiles.TryGetValue(un, out l)) { l = new List<string>(); unitFiles[un] = l; }
        l.Add(f);
      }
    }
    var declCache = new Dictionary<string, HashSet<string>>();
    var hasSideEffects = new Dictionary<string, bool>();
    Func<string, HashSet<string>> declOf = f =>
    {
      HashSet<string> d;
      if (declCache.TryGetValue(f, out d)) return d;
      string t = Expand(File.ReadAllText(Path.Combine(root, f), Enc), incs, 0);
      string st = StripKeepStrings(t);
      d = Declared(st);
      declCache[f] = d;
      bool se = Regex.IsMatch(st, @"^\s*(initialization|finalization)\b", RegexOptions.Multiline | RegexOptions.IgnoreCase)
        || Regex.IsMatch(st, @"\boperator\s+\w+|\bhelper\s+for\b", RegexOptions.IgnoreCase)
        || Regex.IsMatch(t, @"\{\$R\s", RegexOptions.IgnoreCase);
      hasSideEffects[f] = se;
      return d;
    };
    var out_ = new List<string>();
    foreach (var f in targetFiles)
    {
      string orig;
      try { orig = File.ReadAllText(Path.Combine(root, f), Enc); } catch { continue; }
      string expanded = Expand(orig, incs, 0);
      var ids = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
      foreach (Match m in IdRx.Matches(DeadScan.Strip(expanded, true))) ids.Add(m.Value);
      // clausole uses sull'originale (maiuscole/minuscole e righe come sono)
      foreach (Match cm in Regex.Matches(orig, @"(?im)^(uses)\b(.*?);", RegexOptions.Singleline))
      {
        string body = cm.Groups[2].Value;
        if (body.Contains("{") || body.Contains("//") || body.Contains("(*")) { out_.Add("CLAUSOLA-CON-DIRETTIVE|" + f + "|" + cm.Index); continue; }
        int pos = cm.Index;
        int implPos = Regex.Match(orig, @"(?im)^implementation\b").Index;
        string clause = pos < implPos ? "interface" : "implementation";
        foreach (var u in UnitsOf(body))
        {
          List<string> cand;
          if (!unitFiles.TryGetValue(u, out cand)) continue; // unit di sistema o di terzi
          // preferisci la stessa cartella; altrimenti tutte
          string dir = Path.GetDirectoryName(f);
          var same = cand.Where(c => Path.GetDirectoryName(c) == dir).ToList();
          var use = same.Count > 0 ? same : cand;
          bool needed = false; bool side = false;
          foreach (var uf in use)
          {
            var d = declOf(uf);
            if (hasSideEffects[uf]) side = true;
            if (d.Overlaps(ids)) needed = true;
          }
          if (!needed && !side) out_.Add("INUTILE|" + f + "|" + u + "|" + clause);
        }
      }
    }
    return out_;
  }
}
