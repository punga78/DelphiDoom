unit raven;
interface
uses SysUtils, protos_h;
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
procedure TimeUpdate;
implementation
procedure TimeUpdate; begin end;
end.


