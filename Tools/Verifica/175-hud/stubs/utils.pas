unit utils;
// stub of the harness: the goals of the level; heal and medpaks in the trace; loadweapon is the ORIGINAL one, cut
// from utils.pas by Compila.ps1 into hud_loadweapon.inc
interface
uses g_delphi, r_public_h;
var
  primaries: array[0..3] of integer;
  secondaries: array[0..13] of integer;
  pcount: array[0..1] of integer;
  scount: array[0..6] of integer;
procedure heal(const n: integer);
procedure medpaks(const n: integer);
procedure loadweapon(const n: integer);
implementation
uses constant, d_disk, d_ints, d_video, net, raven, harness_hud;
procedure heal(const n: integer);
begin
  HarnessTrace.Add(3); HarnessTrace.Add(n);
end;
procedure medpaks(const n: integer);
begin
  HarnessTrace.Add(4); HarnessTrace.Add(n);
end;
{$I hud_loadweapon.inc}
end.
