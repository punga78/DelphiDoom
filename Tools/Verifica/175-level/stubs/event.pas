unit event;
// stub of the harness: the triggers and the switches of the script; RunEvent and Process in the trace
interface
uses r_public_h;
var
  triggers: packed array[0..MAPROWS - 1, 0..MAPCOLS - 1] of byte;
  switches: packed array[0..MAPROWS - 1, 0..MAPCOLS - 1] of byte;
  numprocesses: integer;
  fliplayed: integer;
procedure RunEvent(const eval: integer; const netsend: boolean);
procedure Process;
implementation
uses harness_level, DelphiDoom.Tests.Greed.LevelScenarios;
procedure RunEvent(const eval: integer; const netsend: boolean);
begin
  HarnessTrace.Call('RunEvent', [eval, Ord(netsend)]);
  TLevelStandIns.RunEvent(@triggers, @switches, eval);
end;
procedure Process; begin HarnessTrace.Call('Process', []); end;
end.
