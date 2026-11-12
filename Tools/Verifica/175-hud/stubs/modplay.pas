unit modplay;
// stub of the harness: SoundEffect in the trace; SC is the settings record of the original
interface
uses g_delphi, r_public_h, protos_h;
var
  SC: SoundCard;
procedure SoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);
implementation
uses harness_hud;
procedure SoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);
begin
  HarnessTrace.Add(2); HarnessTrace.Add(n); HarnessTrace.Add(variation); HarnessTrace.Add(x); HarnessTrace.Add(y);
end;
end.
