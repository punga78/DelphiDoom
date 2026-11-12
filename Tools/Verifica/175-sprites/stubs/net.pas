unit net;
// stub of the harness: the net game is off (netmode is false), the two calls of sprites.pas are never made
interface
var
  playernum: integer = 1;
procedure NetDeath(const bulletid: integer);
procedure NetGetClosestPlayer(const sx, sy: integer);
implementation
uses SysUtils;
procedure NetDeath(const bulletid: integer); begin raise Exception.Create('NetDeath'); end;
procedure NetGetClosestPlayer(const sx, sy: integer); begin raise Exception.Create('NetGetClosestPlayer'); end;
end.
