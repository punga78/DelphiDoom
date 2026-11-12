unit modplay;
// stub of the harness: SoundEffect writes down the call
interface
uses r_public_h, protos_h;
var
  SC: SoundCard;
procedure SoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);
procedure StopMusic;
implementation
uses calllog, DelphiDoom.Tests.Greed.EventScenarios;
procedure SoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);
begin
  Calls.AddCall(EVENT_CALL_SOUND, [n, variation, x, y]);
end;
procedure StopMusic;
begin
  Calls.AddCall(EVENT_CALL_STOP_MUSIC, []);
end;
end.
