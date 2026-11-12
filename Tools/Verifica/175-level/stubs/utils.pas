unit utils;
// stub of the harness: the goals of the level, and heal, medpaks, addscore, loadweapon and newmap that write the
// call in the trace and do what the stand-ins of the library do
interface
uses r_public_h;
var
  primaries: array[0..3] of integer;
  secondaries: array[0..13] of integer;
  pcount: array[0..1] of integer;
  scount: array[0..6] of integer;
  bonustime: integer;
  levelscore: integer;
procedure addscore(const n: integer);
procedure heal(const n: integer);
procedure medpaks(const n: integer);
procedure loadweapon(const n: integer);
procedure newmap(const map: integer; const activate: integer);
procedure respawnplayer;
procedure KillSprite(const sp: Pscaleobj_t; const weapon: integer);
implementation
uses SysUtils, raven, d_video, r_public, harness_level, DelphiDoom.Greed.SaveTypes, DelphiDoom.Greed.Actor.Types,
  DelphiDoom.Tests.Greed.LevelScenarios;
type
  PGreedPlayerRecord = ^TGreedPlayerRecord;
var
  weaponpicture: pic_t;
procedure addscore(const n: integer);
begin
  HarnessTrace.Call('addscore', [n]);
  TLevelStandIns.AddScore(PGreedPlayerRecord(@player)^, n);
end;
procedure heal(const n: integer);
begin
  HarnessTrace.Call('heal', [n]);
  TLevelStandIns.Heal(PGreedPlayerRecord(@player)^, n);
end;
procedure medpaks(const n: integer);
begin
  HarnessTrace.Call('medpaks', [n]);
  TLevelStandIns.MedPaks(PGreedPlayerRecord(@player)^, n);
end;
procedure loadweapon(const n: integer);
begin
  HarnessTrace.Call('loadweapon', [n]);
  weaponpicture.height := TLevelStandIns.WeaponPictureHeight(n);
  weaponpic[0] := @weaponpicture;
end;
procedure newmap(const map: integer; const activate: integer);
begin
  HarnessTrace.Call('newmap', [map, activate]);
end;
procedure respawnplayer; begin raise Exception.Create('respawnplayer'); end;
procedure KillSprite(const sp: Pscaleobj_t; const weapon: integer);
var g: TGreedSprite;
begin
  HarnessTrace.Call('KillSprite', [sp.typ, sp.x, sp.y, weapon]);
  g := ToLibrary(sp^);
  if TLevelStandIns.Kill(g, weapon) then
    RF_RemoveSprite(sp)
  else
    FromLibrary(g, sp);
end;
initialization
  weaponpic[0] := @weaponpicture;
end.
