unit spawn;
// stub of the harness: SpawnSprite in the trace, no sprite is made (as the stand-in of the library)
interface
uses g_delphi, r_public_h;
function SpawnSprite(const value: integer; const x, y, z: fixed_t; const zadj: fixed_t;
  angle, angle2: integer; const active: boolean; const spawnid: integer): Pscaleobj_t;
procedure DemandLoadMonster(const lump, num: integer);
implementation
uses harness_hud;
function SpawnSprite(const value: integer; const x, y, z: fixed_t; const zadj: fixed_t;
  angle, angle2: integer; const active: boolean; const spawnid: integer): Pscaleobj_t;
begin
  HarnessTrace.Add(1); HarnessTrace.Add(value); HarnessTrace.Add(x); HarnessTrace.Add(y); HarnessTrace.Add(z);
  HarnessTrace.Add(zadj); HarnessTrace.Add(angle); HarnessTrace.Add(angle2); HarnessTrace.Add(Ord(active));
  HarnessTrace.Add(spawnid);
  Result := nil;
end;
procedure DemandLoadMonster(const lump, num: integer); begin end;
end.
