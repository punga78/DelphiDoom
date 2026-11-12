unit spawn;
// stub of the harness: SpawnSprite belongs to another part of the port (it has its own parity). Here the call is
// written in the log and a plain sprite is made for the values that TEventScenarios.SpawnMakesSprite says, as the
// stand-in of the test of the library does
interface
uses g_delphi, r_public_h;
function SpawnSprite(const value: integer; const x, y, z: fixed_t; const zadj: fixed_t;
  const angle, angle2: integer; const active: boolean; const spawnid: integer): Pscaleobj_t;
procedure DemandLoadMonster(const lump, num: integer);
implementation
uses r_public, calllog, DelphiDoom.Tests.Greed.EventScenarios;
function SpawnSprite(const value: integer; const x, y, z: fixed_t; const zadj: fixed_t;
  const angle, angle2: integer; const active: boolean; const spawnid: integer): Pscaleobj_t;
begin
  Calls.AddCall(EVENT_CALL_SPAWN, [value, x, y, z, zadj, angle, angle2, Ord(active), spawnid]);
  Result := nil;
  if not TEventScenarios.SpawnMakesSprite(value) then
    exit;
  Result := RF_GetSprite;
  Result.typ := value;
  Result.x := x;
  Result.y := y;
  Result.z := z;
  Result.active := active;
  Result.moveSpeed := TEventScenarios.SpawnedMoveSpeed(value);
end;
procedure DemandLoadMonster(const lump, num: integer);
begin
  Calls.AddCall(EVENT_CALL_DEMAND, [lump, num]);
end;
end.
