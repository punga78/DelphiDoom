unit utils;
// loadweapon of utils.pas reads the pictures of a weapon from the archive: here they only have a size
interface
uses d_video;
var
  weaponpics: array[0..6] of pic_t;
procedure loadweapon(const n: integer);
implementation
uses raven, calllog, DelphiDoom.Tests.Greed.PlayerScenarios;
procedure loadweapon(const n: integer);
var
  i: integer;
begin
  Calls.AddCall(PLAYER_CALL_LOAD_WEAPON, [n]);
  for i := 0 to 6 do
  begin
    weaponpics[i].width := TPlayerScenarios.PictureWidth(n, i);
    weaponpics[i].height := TPlayerScenarios.PictureHeight(n, i);
    weaponpic[i] := @weaponpics[i];
  end;
end;
end.
