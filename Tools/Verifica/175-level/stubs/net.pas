unit net;
// stub of the harness: the net game is off (netmode is false), none of these is ever called
interface
uses g_delphi, r_public_h;
type
  greedcom_t = record
    numplayers: integer;
  end;
  Pgreedcom_t = ^greedcom_t;
var
  playernum: integer = 1;
  netwarpjammer: boolean = false;
  netwarpjamtime: integer;
  greedcom: Pgreedcom_t;
procedure NetGetData;
procedure NetSendPlayerData;
procedure NetBonusItem;
procedure NetItemPickup(const x, y: integer);
procedure NetSoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);
procedure NetSendSpawn(const value: integer; const x, y, z: fixed_t; const zadj: fixed_t;
  const angle, angle2: integer; const active: boolean; const spawnid: integer);
procedure NetOpenDoor(const x, y: fixed_t);
procedure NetCheckHere(const centerx, centery: fixed_t; const angle: integer);
implementation
uses SysUtils;
procedure NetGetData; begin raise Exception.Create('NetGetData'); end;
procedure NetSendPlayerData; begin raise Exception.Create('NetSendPlayerData'); end;
procedure NetBonusItem; begin raise Exception.Create('NetBonusItem'); end;
procedure NetItemPickup(const x, y: integer); begin raise Exception.Create('NetItemPickup'); end;
procedure NetSoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);
begin raise Exception.Create('NetSoundEffect'); end;
procedure NetSendSpawn(const value: integer; const x, y, z: fixed_t; const zadj: fixed_t;
  const angle, angle2: integer; const active: boolean; const spawnid: integer);
begin raise Exception.Create('NetSendSpawn'); end;
procedure NetOpenDoor(const x, y: fixed_t); begin raise Exception.Create('NetOpenDoor'); end;
procedure NetCheckHere(const centerx, centery: fixed_t; const angle: integer);
begin raise Exception.Create('NetCheckHere'); end;
end.
