program NetOriginale;
{$APPTYPE CONSOLE}
// Harness fuori dalla suite (issue #175): compila net.pas di xGreed COSI' COM'E' (Reference\xGreed\Greed\net.pas,
// nessuna riga cambiata) con un greedcom finto e chiama ogni sua routine. Prova quello che si legge nel sorgente:
// le routine sono vuote (il codice e' in un commento dopo "end."), NetInit non prende nemmeno l'indirizzo di
// greedcom, nessun pacchetto viene costruito e nessuna variabile cambia. Esce con 1 se non e' cosi'.
uses
  SysUtils, protos_h, r_public_h, net;

var
  Com: greedcom_t;
  Before: array[0..SizeOf(greedcom_t) - 1] of Byte;
  Failures: Integer;

procedure Check(ACondition: Boolean; const AText: string);
begin
  if ACondition then
    Writeln('  ok   ', AText)
  else
  begin
    Writeln('  NO   ', AText);
    Inc(Failures);
  end;
end;

function AllZero(const ABuffer; ASize: Integer): Boolean;
var
  LIndex: Integer;
begin
  Result := True;
  for LIndex := 0 to ASize - 1 do
    if PByte(NativeUInt(@ABuffer) + NativeUInt(LIndex))^ <> 0 then
      Exit(False);
end;

begin
  Failures := 0;
  FillChar(Com, SizeOf(Com), 0);
  Com.id := Integer(GREEDCOM_ID);
  Com.nettype := NETIPX;
  Com.numnodes := 2;
  Com.numplayers := 2;
  Com.consoleplayer := 1;
  Move(Com, Before, SizeOf(Com));

  NetInit(@Com);
  Check(greedcom = nil, 'NetInit non prende l''indirizzo di greedcom (resta nil)');
  Check(playernum = 1, 'playernum resta 1 (non diventa greedcom.consoleplayer: qui sarebbe 1 comunque, vedi sotto)');
  Com.consoleplayer := 0;
  NetInit(@Com);
  Check(playernum = 1, 'playernum resta 1 anche con consoleplayer 0');
  Move(Com, Before, SizeOf(Com));

  NetWaitStart;
  NetGetData;
  NetSendPlayerData;
  NetNewPlayerData;
  NetSendSpawn(505, 1, 2, 3, 4, 5, 6, True, 0);
  NetSoundEffect(1, 2, 3, 4);
  NetItemPickup(1, 2);
  NetDeath(0);
  NetGetClosestPlayer(1, 2);
  NetOpenDoor(1, 2);
  NetCheckHere(1, 2, 3);
  NetBonusItem;
  NetPause;
  NetUnPause;
  NetSendMessage('hello');
  NetQuitGame;

  Check(CompareMem(@Com, @Before, SizeOf(Com)), '17 routine chiamate: greedcom_t non e'' stato toccato (nessun pacchetto)');
  Check(AllZero(fragcount, SizeOf(fragcount)), 'fragcount non cambia');
  Check(AllZero(playerdata, SizeOf(playerdata)), 'playerdata non cambia');
  Check(not netpaused and not netwarpjammer, 'netpaused e netwarpjammer restano falsi');
  if Failures = 0 then
    Writeln('net.pas originale: le routine sono vuote, la rete di xGreed e'' codice morto')
  else
    Writeln('net.pas originale: ', Failures, ' controlli falliti');
  ExitCode := Ord(Failures <> 0);
end.
