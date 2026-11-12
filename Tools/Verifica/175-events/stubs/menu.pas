unit menu;
// stub of the harness: the picture that turns while a map is loaded is a call in the log
interface
procedure UpdateWait;
procedure StartWait;
procedure EndWait;
implementation
uses calllog, DelphiDoom.Tests.Greed.EventScenarios;
procedure UpdateWait;
begin
  Calls.AddCall(EVENT_CALL_WAIT, []);
end;
procedure StartWait;
begin
  Calls.AddCall(EVENT_CALL_START_WAIT, []);
end;
procedure EndWait;
begin
  Calls.AddCall(EVENT_CALL_END_WAIT, []);
end;
end.
