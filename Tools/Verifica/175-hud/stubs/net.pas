unit net;
// stub of the harness: the net game is off (netmode is false), none of the routines is ever called
interface
uses g_delphi, r_public_h, protos_h;
type
  greedcom_t = record
    numplayers: integer;
    maxusage: integer;
  end;
  Pgreedcom_t = ^greedcom_t;
var
  playernum: integer = 1;
  fragcount: array[0..MAXPLAYERS - 1] of integer;
  playerdata: array[0..MAXPLAYERS - 1] of pevent_t;
  netnames: array[0..MAXPLAYERS - 1] of string[13];
  greedcom: Pgreedcom_t;
procedure NetGetData;
procedure NetSoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);
procedure NetSendSpawn(const value: integer; const x, y, z: fixed_t; const zadj: fixed_t;
  const angle, angle2: integer; const active: boolean; const spawnid: integer);
implementation
uses SysUtils;
procedure NetGetData; begin raise Exception.Create('NetGetData'); end;
procedure NetSoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);
begin raise Exception.Create('NetSoundEffect'); end;
procedure NetSendSpawn(const value: integer; const x, y, z: fixed_t; const zadj: fixed_t;
  const angle, angle2: integer; const active: boolean; const spawnid: integer);
begin raise Exception.Create('NetSendSpawn'); end;
end.
