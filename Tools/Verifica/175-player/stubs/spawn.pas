unit spawn;
// SpawnSprite belongs to another part of the port (it has its own parity): here the call is written in the log
interface
uses g_delphi, r_public_h;
function SpawnSprite(const value: integer; const x, y, z: fixed_t; const zadj: fixed_t;
  const angle, angle2: integer; const active: boolean; const spawnid: integer): Pscaleobj_t;
implementation
uses calllog, DelphiDoom.Tests.Greed.PlayerScenarios;
function SpawnSprite(const value: integer; const x, y, z: fixed_t; const zadj: fixed_t;
  const angle, angle2: integer; const active: boolean; const spawnid: integer): Pscaleobj_t;
begin
  Calls.AddCall(PLAYER_CALL_SPAWN, [value, x, y, z, zadj, angle, angle2, Ord(active), spawnid]);
  result := nil;
end;
end.
