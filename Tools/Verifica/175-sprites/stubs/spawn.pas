unit spawn;
// stub of the harness: SpawnSprite writes the call in the trace and makes the sprite of
// TSpriteScenarioRunner.FillSpawned at the end of the list, as the stand-in of the library does
interface
uses g_delphi, r_public_h;
function SpawnSprite(const value: integer; const x, y, z: fixed_t; const zadj: fixed_t;
  angle, angle2: integer; const active: boolean; const spawnid: integer): Pscaleobj_t;
procedure DemandLoadMonster(const lump, num: integer);
implementation
uses r_public, harness_convert, DelphiDoom.Greed.Actor.Types, DelphiDoom.Tests.Greed.SpriteScenarios;
function SpawnSprite(const value: integer; const x, y, z: fixed_t; const zadj: fixed_t;
  angle, angle2: integer; const active: boolean; const spawnid: integer): Pscaleobj_t;
var g: TGreedSprite;
begin
  HarnessTrace.Add(value, 'spawn.value');
  HarnessTrace.Add(x, 'spawn.x');
  HarnessTrace.Add(y, 'spawn.y');
  HarnessTrace.Add(z, 'spawn.z');
  HarnessTrace.Add(zadj, 'spawn.zadj');
  HarnessTrace.Add(angle, 'spawn.angle');
  HarnessTrace.Add(angle2, 'spawn.angle2');
  HarnessTrace.Add(active, 'spawn.active');
  HarnessTrace.Add(spawnid, 'spawn.spawnid');
  TSpriteScenarioRunner.FillSpawned(g, value, x, y, z, zadj, angle, angle2, active, spawnid);
  Result := RF_GetSprite;
  FromLibrary(g, Result);
end;
procedure DemandLoadMonster(const lump, num: integer); begin end;
end.
