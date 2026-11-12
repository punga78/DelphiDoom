unit net;
// stub of the harness: the net game is not ported. NetNewPlayerData of respawnplayer does nothing
interface
uses r_public_h, protos_h;
var
  playernum: integer = 1;
  greedcomdata: greedcom_t;
  greedcom: Pgreedcom_t = @greedcomdata;
procedure NetNewPlayerData;
implementation
procedure NetNewPlayerData;
begin
end;
end.
