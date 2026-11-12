unit spawn;
// stub of the harness: SpawnSprite writes the call in the trace and makes the sprite of TLevelStandIns.Spawned
// at the end of the list, as the stand-in of the library does
interface
uses g_delphi, r_public_h;
function SpawnSprite(const value: integer; const x, y, z: fixed_t; const zadj: fixed_t;
  angle, angle2: integer; const active: boolean; const spawnid: integer): Pscaleobj_t;
procedure DemandLoadMonster(const lump, num: integer);
implementation
uses r_public, r_render, harness_level, DelphiDoom.Greed.Actor.Types, DelphiDoom.Tests.Greed.LevelScenarios;
function SpawnSprite(const value: integer; const x, y, z: fixed_t; const zadj: fixed_t;
  angle, angle2: integer; const active: boolean; const spawnid: integer): Pscaleobj_t;
var
  g: TGreedSprite;
  spot, mapvalue: Integer;
begin
  HarnessTrace.Call('SpawnSprite', [value, x, y, z, zadj, angle, angle2, Ord(active), spawnid]);
  TLevelStandIns.Spawned(g, spot, mapvalue, value, x, y, z, zadj, angle, angle2, active, spawnid);
  Result := RF_GetSprite;
  FromLibrary(g, Result);
  if mapvalue <> 0 then
    mapsprites[spot] := mapvalue;
end;
procedure DemandLoadMonster(const lump, num: integer); begin end;
end.
