unit event;
interface
uses r_public_h;
var
  triggers: packed array[0..MAPROWS - 1, 0..MAPCOLS - 1] of byte;
  switches: packed array[0..MAPROWS - 1, 0..MAPCOLS - 1] of byte;
procedure RunEvent(const eval: integer; const netsend: boolean);
implementation
uses calllog, DelphiDoom.Tests.Greed.PlayerScenarios;
procedure RunEvent(const eval: integer; const netsend: boolean);
begin
  Calls.AddCall(PLAYER_CALL_RUN_EVENT, [eval, Ord(netsend)]);
end;
end.
