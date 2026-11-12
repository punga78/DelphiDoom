unit modplay;
// stub of the harness: SoundEffect and UpdateSound in the trace; SC is the settings record of the original
interface
uses g_delphi, r_public_h, protos_h;
var
  SC: SoundCard;
procedure SoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);
procedure UpdateSound;
implementation
uses harness_level;
procedure SoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);
begin
  HarnessTrace.Call('SoundEffect', [n, variation, x, y]);
end;
procedure UpdateSound; begin HarnessTrace.Call('UpdateSound', []); end;
end.
