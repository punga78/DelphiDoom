program NetGolden;
{$APPTYPE CONSOLE}
{$Q-}
{$R-}
// Harness fuori dalla suite (issue #175): fa girare gli scenari di Tests\Source\DelphiDoom.Tests.Greed.NetScenarios
// sul codice di net.pas di xGreed e scrive il golden Tests\Data\Greed\net.golden.txt (per ogni passo: i pacchetti
// mandati byte per byte, l'impronta delle chiamate al resto del gioco, l'impronta dello stato).
// ATTENZIONE: in xGreed le routine di net.pas sono VUOTE e il codice e' in un commento che non compila (C tradotto
// a meta'). La unit "net" di questo programma e' generata da Compila.ps1: l'interfaccia ORIGINALE di net.pas piu'
// il corpo del commento completato riga per riga (net_body.inc). Il resto del gioco e' stubs\harness_net_game.pas;
// greedcom_t, pevent_t, player_t, scaleobj_t e le costanti sono quelli veri di protos_h.pas e r_public_h.pas.
// Uso: NetGolden <golden.txt | nessuno> [verbose]
uses
  SysUtils, Classes, Generics.Collections,
  protos_h, r_public_h, constant, net, harness_net_game,
  DelphiDoom.Tests.Greed.NetScenarios, DelphiDoom.Tests.Greed.NetRunner;

type
  ECancelled = class(Exception);

  TOriginalNetRunner = class(TNetScenarioRunner)
  private
    FCom: greedcom_t;
    FTurn: Integer;
  protected
    procedure Open(const AScenario: TNetScenario); override;
    procedure Close; override;
    procedure SetClock(AValue: Integer); override;
    procedure SetPlayer(const AValues: array of Integer); override;
    procedure QueueIncoming(const ABytes: TBytes); override;
    procedure SetMapSprite(ASpot, AValue: Integer); override;
    procedure SetBonus(const AValues: array of Integer); override;
    procedure AddSprite(AKind, AX, AY: Integer); override;
    procedure Call(const AOp: TNetOp); override;
    function RunWait: Boolean; override;
    function TakeSent: TArray<TBytes>; override;
    procedure GetState(out AState: TNetStateDump); override;
  public
    procedure TurnOfTheWait;
  end;

var
  Runner: TOriginalNetRunner;

procedure UpdateWaitCallback;
begin
  Runner.TurnOfTheWait;
end;

{ TOriginalNetRunner }

procedure TOriginalNetRunner.TurnOfTheWait;
begin
  if not WaitTurnBegin(FTurn) then
    raise ECancelled.Create('cancelled');
  Inc(FTurn);
end;

procedure TOriginalNetRunner.Open(const AScenario: TNetScenario);
var
  i: Integer;
begin
  HarnessReset;
  HarnessRunner := Self;
  HarnessUpdateWait := UpdateWaitCallback;
  // le variabili di net.pas
  FillChar(fragcount, SizeOf(fragcount), 0);
  FillChar(playerdata, SizeOf(playerdata), 0);
  for i := 0 to MAXPLAYERS - 1 do
    netnames[i] := '';
  netwarpjammer := False;
  netwarpjamtime := 0;
  netpaused := False;
  HarnessClearNet;
  player.map := AScenario.Map;
  player.difficulty := AScenario.Difficulty;
  SC.netname := ShortString(AScenario.NetName);
  // quello che il driver scriveva in greedcom_t prima di lanciare il gioco
  FillChar(FCom, SizeOf(FCom), 0);
  FCom.id := Integer(GREEDCOM_ID);
  FCom.nettype := AScenario.NetType;
  FCom.numnodes := AScenario.NumPlayers;
  FCom.consoleplayer := AScenario.ConsolePlayer;
  FCom.numplayers := AScenario.NumPlayers;
  NetInit(@FCom);
end;

procedure TOriginalNetRunner.Close;
begin
  HarnessRunner := nil;
end;

procedure TOriginalNetRunner.SetClock(AValue: Integer);
begin
  timecount := AValue;
end;

procedure TOriginalNetRunner.SetPlayer(const AValues: array of Integer);
begin
  player.x := AValues[0];
  player.y := AValues[1];
  player.z := AValues[2];
  player.angle := AValues[3];
  player.angst := AValues[4];
  player.height := AValues[5];
  player.chartype := AValues[6];
  player.status := AValues[7];
  player.holopic := AValues[8];
  player.holoscale := AValues[9];
  specialeffect := AValues[10];
end;

procedure TOriginalNetRunner.QueueIncoming(const ABytes: TBytes);
begin
  HarnessIncoming.Enqueue(Copy(ABytes));
end;

procedure TOriginalNetRunner.SetMapSprite(ASpot, AValue: Integer);
begin
  mapsprites[ASpot] := AValue;
end;

procedure TOriginalNetRunner.SetBonus(const AValues: array of Integer);
begin
  BonusItem.time := AValues[0];
  BonusItem.score := AValues[1];
  BonusItem.tilex := AValues[2];
  BonusItem.tiley := AValues[3];
  BonusItem.num := AValues[4];
end;

procedure TOriginalNetRunner.AddSprite(AKind, AX, AY: Integer);
var
  s: Pscaleobj_t;
begin
  s := RF_GetSprite;
  s.typ := AKind;
  s.x := AX;
  s.y := AY;
end;

procedure TOriginalNetRunner.Call(const AOp: TNetOp);
begin
  case AOp.Kind of
    noGetData:
      NetGetData;
    noSendPlayer:
      NetSendPlayerData;
    noNewPlayer:
      NetNewPlayerData;
    noSendSpawn:
      NetSendSpawn(AOp.A[0], AOp.A[1], AOp.A[2], AOp.A[3], AOp.A[4], AOp.A[5], AOp.A[6], AOp.A[7] <> 0, AOp.A[8]);
    noSound:
      NetSoundEffect(AOp.A[0], AOp.A[1], AOp.A[2], AOp.A[3]);
    noItemPickup:
      NetItemPickup(AOp.A[0], AOp.A[1]);
    noDeath:
      NetDeath(AOp.A[0]);
    noClosest:
      NetGetClosestPlayer(AOp.A[0], AOp.A[1]);
    noOpenDoor:
      NetOpenDoor(AOp.A[0], AOp.A[1]);
    noCheckHere:
      NetCheckHere(AOp.A[0], AOp.A[1], AOp.A[2]);
    noBonus:
      NetBonusItem;
    noPause:
      NetPause;
    noUnPause:
      NetUnPause;
    noMessage:
      NetSendMessage(string(AOp.Text));
    noQuit:
      NetQuitGame;
    noWarpJam:
      NetWarpJam;
    noEvent:
      NetEvent(AOp.A[0]);
  end;
end;

function TOriginalNetRunner.RunWait: Boolean;
begin
  timecount := 0;
  FTurn := 0;
  try
    NetWaitStart;
    Result := True;
  except
    on ECancelled do
      Result := False;
  end;
end;

function TOriginalNetRunner.TakeSent: TArray<TBytes>;
begin
  Result := HarnessSent.ToArray;
  HarnessSent.Clear;
end;

procedure TOriginalNetRunner.GetState(out AState: TNetStateDump);
var
  LPlayer, LIndex, LCount: Integer;
  s: Pscaleobj_t;
begin
  AState := Default(TNetStateDump);
  AState.TimeCount := timecount;
  AState.PlayerStatus := player.status;
  AState.PlayerDifficulty := player.difficulty;
  AState.GoalItem := goalitem;
  AState.GameLoading := Ord(gameloading);
  AState.TargX := targx;
  AState.TargY := targy;
  AState.TargZ := targz;
  AState.BonusTime := BonusItem.time;
  AState.BonusScore := BonusItem.score;
  AState.BonusTileX := BonusItem.tilex;
  AState.BonusTileY := BonusItem.tiley;
  AState.BonusMapSpot := BonusItem.mapspot;
  AState.BonusNum := BonusItem.num;
  AState.BonusName := string(BonusItem.name);
  AState.BonusSpritePicture := -1;
  if BonusItem.sprite <> nil then
    AState.BonusSpritePicture := BonusItem.sprite.basepic;
  AState.Paused := Ord(netpaused);
  AState.WarpJammer := Ord(netwarpjammer);
  AState.WarpJamTime := netwarpjamtime;
  AState.RandomCalls := HarnessRandomCalls;
  // oldgoalitem := -1 di display.pas: i passi in cui net.pas l'ha fatto
  if oldgoalitem = -1 then
  begin
    Inc(HarnessGoalRefreshed);
    oldgoalitem := 0;
  end;
  AState.GoalRefreshed := HarnessGoalRefreshed;
  for LPlayer := 0 to NET_DUMP_PLAYERS - 1 do
  begin
    AState.PlayerFrags[LPlayer] := player.frags[LPlayer];
    AState.FragCount[LPlayer] := fragcount[LPlayer];
    AState.Names[LPlayer] := AnsiString(netnames[LPlayer]);
    Move(playerdata[LPlayer], AState.PlayerData[LPlayer, 0], SizeOf(pevent_t));
    s := HarnessPlayerSprite(LPlayer);
    AState.PlayerMapSpot[LPlayer] := HarnessPlayerMapSpot(LPlayer);
    AState.PlayerSprites[LPlayer].Present := s <> nil;
    if s <> nil then
    begin
      AState.PlayerSprites[LPlayer].Values[0] := s.x;
      AState.PlayerSprites[LPlayer].Values[1] := s.y;
      AState.PlayerSprites[LPlayer].Values[2] := s.z;
      AState.PlayerSprites[LPlayer].Values[3] := s.angle;
      AState.PlayerSprites[LPlayer].Values[4] := s.basepic;
      AState.PlayerSprites[LPlayer].Values[5] := s.startpic;
      AState.PlayerSprites[LPlayer].Values[6] := s.scale;
      AState.PlayerSprites[LPlayer].Values[7] := Ord(s.rotate);
      AState.PlayerSprites[LPlayer].Values[8] := s.movemode;
      AState.PlayerSprites[LPlayer].Values[9] := s.modetime;
      AState.PlayerSprites[LPlayer].Values[10] := s.hitpoints;
      AState.PlayerSprites[LPlayer].Values[11] := Ord(s.specialtype);
      AState.PlayerSprites[LPlayer].Values[12] := s.animation;
      AState.PlayerSprites[LPlayer].Values[13] := Ord(s.active);
      AState.PlayerSprites[LPlayer].Values[14] := s.heat;
      AState.PlayerSprites[LPlayer].Values[15] := s.moveSpeed;
      AState.PlayerSprites[LPlayer].Values[16] := s.intelligence;
      AState.PlayerSprites[LPlayer].Values[17] := s.typ;
      AState.PlayerSprites[LPlayer].Values[18] := s.height;
    end;
  end;
  LCount := 0;
  s := firstscaleobj.next;
  while s <> @lastscaleobj do
  begin
    Inc(LCount);
    s := s.next;
  end;
  SetLength(AState.Sprites, LCount * 9);
  LCount := 0;
  s := firstscaleobj.next;
  while s <> @lastscaleobj do
  begin
    AState.Sprites[LCount] := s.typ;
    AState.Sprites[LCount + 1] := s.x;
    AState.Sprites[LCount + 2] := s.y;
    AState.Sprites[LCount + 3] := s.basepic;
    AState.Sprites[LCount + 4] := s.scale;
    AState.Sprites[LCount + 5] := s.animation;
    AState.Sprites[LCount + 6] := s.hitpoints;
    AState.Sprites[LCount + 7] := Ord(s.rotate);
    AState.Sprites[LCount + 8] := s.intelligence;
    Inc(LCount, 9);
    s := s.next;
  end;
  LCount := 0;
  SetLength(AState.MapSprites, MAPROWS * MAPCOLS);
  for LIndex := 0 to MAPROWS * MAPCOLS - 1 do
    if mapsprites[LIndex] <> 0 then
    begin
      AState.MapSprites[LCount] := LIndex * 256 + mapsprites[LIndex];
      Inc(LCount);
    end;
  SetLength(AState.MapSprites, LCount);
end;

var
  Lines: TStringList;
  Index, Packets, Line: Integer;
begin
  Lines := TStringList.Create;
  Runner := TOriginalNetRunner.Create;
  try
    Runner.Verbose := (ParamCount >= 2) and SameText(ParamStr(2), 'verbose');
    for Index := 0 to TNetScenarios.Count - 1 do
      Runner.Run(Index, Lines);
    Packets := 0;
    for Line := 0 to Lines.Count - 1 do
      if (Pos(' | ', Lines[Line]) > 0) and (Pos('|  |', Lines[Line]) = 0) then
        Inc(Packets);
    Writeln(Format('net.pas (ripristinato dal commento): %d scenari, %d righe, %d passi con pacchetti',
      [TNetScenarios.Count, Lines.Count, Packets]));
    if (ParamCount >= 1) and not SameText(ParamStr(1), 'nessuno') then
    begin
      Lines.SaveToFile(ParamStr(1), TEncoding.ASCII);
      Writeln('golden: ', ParamStr(1));
    end;
  finally
    Runner.Free;
    Lines.Free;
  end;
end.
