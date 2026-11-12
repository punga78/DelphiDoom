unit net;
// the net game is not run: a call is an error of the scenario
interface
uses r_public_h, protos_h;
var
  playernum: integer = 0;
  greedcomdata: greedcom_t;
  greedcom: Pgreedcom_t = @greedcomdata;
procedure NetSendSpawn(const value: integer; const x, y, z: fixed_t; const zadj: fixed_t;
  const angle, angle2: integer; const active: boolean; const spawnid: integer);
procedure NetSoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);
procedure NetOpenDoor(const x, y: fixed_t);
procedure NetCheckHere(const centerx, centery: fixed_t; const angle: integer);
implementation
uses SysUtils;
procedure NetSendSpawn(const value: integer; const x, y, z: fixed_t; const zadj: fixed_t;
  const angle, angle2: integer; const active: boolean; const spawnid: integer);
begin
  raise Exception.Create('NetSendSpawn');
end;
procedure NetSoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);
begin
  raise Exception.Create('NetSoundEffect');
end;
procedure NetOpenDoor(const x, y: fixed_t);
begin
  raise Exception.Create('NetOpenDoor');
end;
procedure NetCheckHere(const centerx, centery: fixed_t; const angle: integer);
begin
  raise Exception.Create('NetCheckHere');
end;
end.
