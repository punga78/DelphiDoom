unit hoststub;
// CheckForSwitch and SwitchWall of raven.pas belong to another part of the port: here they are written in the log
interface
function CheckForSwitch(const x, y: integer; const angle: integer; const doubleswitch: boolean): boolean;
procedure SwitchWall(const x, y: integer; const angle: integer; const doubleswitch: boolean);
implementation
uses calllog, DelphiDoom.Tests.Greed.PlayerScenarios;
function CheckForSwitch(const x, y: integer; const angle: integer; const doubleswitch: boolean): boolean;
begin
  Calls.AddCall(PLAYER_CALL_CHECK_SWITCH, [x, y, angle, Ord(doubleswitch)]);
  result := TPlayerScenarios.SwitchAnswer(x, y, angle);
end;
procedure SwitchWall(const x, y: integer; const angle: integer; const doubleswitch: boolean);
begin
  Calls.AddCall(PLAYER_CALL_SWITCH_WALL, [x, y, angle, Ord(doubleswitch)]);
end;
end.
