unit modplay;
interface
uses r_public_h, protos_h;
var
  SC: SoundCard;
procedure SoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);
implementation
uses calllog, DelphiDoom.Tests.Greed.PlayerScenarios;
procedure SoundEffect(const n: integer; const variation: integer; const x, y: fixed_t);
begin
  Calls.AddCall(PLAYER_CALL_SOUND, [n, variation, x, y]);
end;
end.
