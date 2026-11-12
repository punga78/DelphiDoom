unit net;
// stub of the harness: the net game is not ported, NetSendSpawn must never be called
interface
uses r_public_h, protos_h;
var
  playernum: integer = 1;
  greedcomdata: greedcom_t;
  greedcom: Pgreedcom_t = @greedcomdata;
procedure NetSendSpawn(const value: integer; const x, y, z: fixed_t; const zadj: fixed_t;
  const angle, angle2: integer; const active: boolean; const spawnid: integer);
implementation
uses SysUtils;
procedure NetSendSpawn(const value: integer; const x, y, z: fixed_t; const zadj: fixed_t;
  const angle, angle2: integer; const active: boolean; const spawnid: integer);
begin
  raise Exception.Create('NetSendSpawn');
end;
end.
