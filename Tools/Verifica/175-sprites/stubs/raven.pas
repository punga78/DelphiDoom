unit raven;
// stub of the harness: the globals of raven.pas that the renderer and sprites.pas read, and Thrust in the trace
interface
uses SysUtils, g_delphi, r_public_h, protos_h;
type
  TSC = record vrhelmet: integer; end;
var
  player: player_t;
  spritemovetime: integer;
  debugmode: boolean = false;
  newascii: boolean = false;
  lastascii: char = #0;
  SC: TSC;
  backdrop: PByteArray;
  backdroplookup: array[0..255] of PByteArray;
  player_angle64: integer;
  specialeffect: integer;
  netmode: boolean = false;
procedure TimeUpdate;
function Thrust(const ang: integer; const speed: fixed_t): boolean;
implementation
uses harness_convert;
procedure TimeUpdate; begin end;
function Thrust(const ang: integer; const speed: fixed_t): boolean;
begin
  HarnessTrace.Add(ang, 'thrust.angle');
  HarnessTrace.Add(speed, 'thrust.speed');
  Result := false;
end;
end.
