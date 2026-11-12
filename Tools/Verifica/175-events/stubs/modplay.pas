unit modplay;
// stub of the harness: SoundEffect writes down the call
interface
uses r_public_h, protos_h;
var
  SC: SoundCard;
procedure SoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);
implementation
uses calllog, DelphiDoom.Tests.Greed.EventScenarios;
procedure SoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);
begin
  Calls.AddCall(EVENT_CALL_SOUND, [n, variation, x, y]);
end;
end.
