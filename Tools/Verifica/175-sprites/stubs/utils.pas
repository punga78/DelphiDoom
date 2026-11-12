unit utils;
// stub of the harness: KillSprite, hurt, heal, medpaks and addscore write the call in the trace and do what the
// stand-ins of the library do
interface
uses g_delphi, r_public_h;
procedure KillSprite(const sp: Pscaleobj_t; const weapon: integer);
procedure addscore(const n: integer);
procedure heal(const n: integer);
procedure medpaks(const n: integer);
procedure hurt(n: integer);
implementation
uses r_public, raven, harness_convert, DelphiDoom.Greed.Actor.Types, DelphiDoom.Tests.Greed.SpriteScenarios;
procedure KillSprite(const sp: Pscaleobj_t; const weapon: integer);
var g: TGreedSprite;
begin
  HarnessTrace.Add(sp.typ, 'kill.typ');
  HarnessTrace.Add(sp.x, 'kill.x');
  HarnessTrace.Add(sp.y, 'kill.y');
  HarnessTrace.Add(weapon, 'kill.weapon');
  g := ToLibrary(sp^);
  if TSpriteScenarioRunner.ApplyKill(g, weapon) then
    RF_RemoveSprite(sp)
  else
    FromLibrary(g, sp);
end;
procedure addscore(const n: integer); begin HarnessTrace.Add(n, 'addscore'); end;
procedure heal(const n: integer); begin HarnessTrace.Add(n, 'heal'); end;
procedure medpaks(const n: integer); begin HarnessTrace.Add(n, 'medpaks'); end;
procedure hurt(n: integer);
begin
  HarnessTrace.Add(n, 'hurt');
  player.angst := player.angst - n;
  if player.angst < 0 then player.angst := 0;
end;
end.
