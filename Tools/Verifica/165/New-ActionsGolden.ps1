<#
  Turns the output of the C harness (OUT.TXT) into the golden file of the actions: a line for each scenario with its
  number, the name of the function, the kind (T think, C contact, R react) and the FNV-1a (32 bit) of the text from
  the line "S" to the line "E", with LF line ends. Usage:
    New-ActionsGolden.ps1 -Out <OUT.TXT> -Golden Tests\Data\Keen\actions.golden.txt
#>
param([string]$Out, [string]$Golden)
$ErrorActionPreference = 'Stop'
Add-Type -TypeDefinition @'
using System; using System.Text; using System.Collections.Generic;
public static class ActionsGolden {
  public static string Build(string text) {
    text = text.Replace("\r\n", "\n");
    var sb = new StringBuilder();
    int pos = 0, index = 0;
    while (true) {
      int s = text.IndexOf("S ", pos, StringComparison.Ordinal);
      while (s > 0 && text[s - 1] != '\n') s = text.IndexOf("S ", s + 1, StringComparison.Ordinal);
      if (s < 0) break;
      int e = text.IndexOf("\nE\n", s, StringComparison.Ordinal);
      if (e < 0) break;
      string block = text.Substring(s, e + 3 - s);
      string header = block.Substring(0, block.IndexOf('\n'));
      string[] parts = header.Split(' ');
      uint h = 2166136261;
      foreach (byte b in Encoding.UTF8.GetBytes(block)) h = (h ^ b) * 16777619;
      sb.Append(index).Append(' ').Append(parts[1]).Append(' ').Append(parts[2]).Append(' ').Append(h.ToString("X8")).Append('\n');
      index++;
      pos = e + 3;
    }
    return sb.ToString();
  }
}
'@
$text = [IO.File]::ReadAllText($Out, [Text.Encoding]::ASCII)
if ($text -match '(?m)^(QUIT|unknown)') { throw 'the harness stopped: ' + $Matches[0] }
$lines = [ActionsGolden]::Build($text)
[IO.File]::WriteAllText($Golden, $lines)
"scenarios: " + ($lines.Split("`n").Count - 1)
