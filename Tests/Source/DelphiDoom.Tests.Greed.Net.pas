{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests - greed library: the packets, the session of the net game  }
{  and the net in memory of the tests                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.Net;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Net.Intf, DelphiDoom.Greed.Net.Types,
  DelphiDoom.Greed.Net.Intf, DelphiDoom.Greed.Net.PacketBuffer, DelphiDoom.Greed.Net.Session,
  DelphiDoom.Tests.Greed.GameFakes, DelphiDoom.Tests.Greed.NetFakes;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedNetPacketBuffer = class
  private
    FBuffer: TGreedNetPacketBuffer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAvereLeDimensioniDeiPacchettiOriginali;
    [Test]
    procedure DovrebbeScrivereINumeriInLittleEndian;
    [Test]
    procedure DovrebbeRileggereOgniTipoDiPacchetto;
    [Test]
    procedure DovrebbeLasciareIByteCheNonScrive;
    [Test]
    procedure DovrebbeCaricareAlMassimoIlSuoBuffer;
    [Test]
    procedure DovrebbeLasciareIlRestoQuandoIlPacchettoECorto;
    [Test]
    procedure DovrebbeRifiutareUnaLunghezzaFuoriDalBuffer;
    [Test]
    procedure DovrebbeAzzerareTutto;
    [Test]
    procedure DovrebbeMettereIlNomeEIlTestoAlLoroPosto;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedNetSession = class
  private
    FNet: TFakeGreedNet;
    FSetup: TFakeGameSetup;
    FStart: IGreedNetStart;
    function Link: IGreedNetLink;
    procedure Sit(APlayer, APlayers: Integer; ANetType: Integer = GREED_NET_IPX);
    procedure Arrive(const AValues: array of Integer; const ATail: TBytes = nil);
    function NewSession(const ATransport: INetTransport; const AConfig: TGreedNetConfig;
      AMissing: Integer): TGreedNetSession;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRifiutareUnaDipendenzaNil;
    [Test]
    procedure DovrebbeRifiutareUnTipoDiReteSconosciuto;
    [Test]
    procedure DovrebbeRifiutareGiocatoriFuoriDaiLimiti;
    [Test]
    procedure DovrebbeMandareOgniPacchettoATuttiGliAltri;
    [Test]
    procedure DovrebbeScartareIPacchettiTroppoCorti;
    [Test]
    procedure DovrebbeScartareIPacchettiDiUnGiocatoreCheNonEsiste;
    [Test]
    procedure DovrebbeScartareIPropriPacchetti;
    [Test]
    procedure NonDovrebbeCreareUnGiocatoreDiUnPersonaggioCheNonEsiste;
    [Test]
    procedure DovrebbeDireLaMorteDiChiNonHaUnoSprite;
    [Test]
    procedure NonDovrebbeCambiareIlBersaglioSeNessunoEVivo;
    [Test]
    procedure DovrebbeScegliereIlGiocatoreVivoPiuVicino;
    [Test]
    procedure DovrebbeTagliareUnTestoLungo;
    [Test]
    procedure DovrebbeLeggereUnTestoSenzaLoZero;
    [Test]
    procedure NonDovrebbeAspettareSenzaAverCominciato;
    [Test]
    procedure DovrebbeRifiutareUnGiocatoreSuUnAltraMappa;
    [Test]
    procedure DovrebbeRifiutareUnGiocatoreFuoriDaiLimitiNelleLetture;
    [Test]
    procedure DovrebbeFareLAnelloDiUnColpoArrivatoDallaRete;
    [Test]
    procedure NonDovrebbeRimandareUnoSpawnArrivatoDallaRete;
    [Test]
    procedure DovrebbeFarSentireUnSuonoArrivatoDallaRete;
    [Test]
    procedure DovrebbeFermareLeAreeConIlJammerDiUnAltro;
    [Test]
    procedure DovrebbeAccettareUnBonusSenzaNomeEUnaCasellaFuoriMappa;
    [Test]
    procedure DovrebbeDireChiHaLasciatoIlGioco;
    [Test]
    procedure DovrebbeMandareJammerEdEvento;
    [Test]
    procedure DovrebbeDireAgliAltriLoSparoDelGiocatore;
    [Test]
    procedure DovrebbePartireDalTic19SuUnaLineaSeriale;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedNetFakes = class
  private
    FNet: TFakeGreedNet;
    class function Bytes(AValue: Byte): TBytes; static;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeNumerareINodiSaltandoSeStesso;
    [Test]
    procedure DovrebbeDireChiHaMandato;
    [Test]
    procedure DovrebbeRifiutareUnNodoCheNonEsiste;
    [Test]
    procedure DovrebbePerdereIProssimiDatagrammi;
    [Test]
    procedure DovrebbeTrattenereERilasciareAlContrario;
    [Test]
    procedure DovrebbeRilasciareNellOrdineDiInvio;
    [Test]
    procedure DovrebbeRicordareCosaHaMandatoOgnuno;
  end;

implementation

uses
  DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf, DelphiDoom.Greed.Random, DelphiDoom.Greed.SaveTypes,
  DelphiDoom.Greed.Game.Constants, DelphiDoom.Greed.Game.Intf,
  DelphiDoom.Greed.Game.State, DelphiDoom.Greed.Game, DelphiDoom.Greed.PlayerControl.Intf,
  DelphiDoom.Greed.Net.Factory, DelphiDoom.Tests.Greed.NetScenarios;

const
  EV_PLAYER = GREED_NET_EVENT_PLAYER;
  TILE = GREED_FRACTILEUNIT;

{ TTestGreedNetPacketBuffer }

procedure TTestGreedNetPacketBuffer.Setup;
begin
  FBuffer := TGreedNetPacketBuffer.Create;
end;

procedure TTestGreedNetPacketBuffer.TearDown;
begin
  FBuffer.Free;
end;

procedure TTestGreedNetPacketBuffer.DovrebbeAvereLeDimensioniDeiPacchettiOriginali;
begin
  // the same at 32 and at 64 bit: packed records of 32 bit numbers and characters
  Assert.AreEqual(40, SizeOf(TGreedNetInitEvent));
  Assert.AreEqual(52, SizeOf(TGreedPlayerEvent));
  Assert.AreEqual(44, SizeOf(TGreedNetSpawnEvent));
  Assert.AreEqual(8, SizeOf(TGreedNetPlayerOnlyEvent));
  Assert.AreEqual(20, SizeOf(TGreedNetDoorEvent));
  Assert.AreEqual(12, SizeOf(TGreedNetFragEvent));
  Assert.AreEqual(28, SizeOf(TGreedNetBonusEvent));
  Assert.AreEqual(28, SizeOf(TGreedNetItemEvent));
  Assert.AreEqual(24, SizeOf(TGreedNetSoundEvent));
  Assert.AreEqual(40, SizeOf(TGreedNetMessageEvent));
  Assert.IsTrue(SizeOf(TGreedPlayerEvent) <= GREED_NET_MAX_DATA, 'every packet is in the buffer of greedcom');
end;

procedure TTestGreedNetPacketBuffer.DovrebbeScrivereINumeriInLittleEndian;
var
  LEvent: TGreedNetFragEvent;
  LBytes: TBytes;
begin
  LEvent.Id := GREED_NET_EVENT_FRAG;
  LEvent.PlayerId := $01020304;
  LEvent.BulletId := -2;
  FBuffer.WriteFrag(LEvent);
  LBytes := FBuffer.ToBytes(SizeOf(LEvent));
  Assert.AreEqual(12, Integer(Length(LBytes)));
  Assert.AreEqual(6, Integer(LBytes[0]));
  Assert.AreEqual(0, Integer(LBytes[1]));
  Assert.AreEqual(4, Integer(LBytes[4]), 'the low byte first');
  Assert.AreEqual(3, Integer(LBytes[5]));
  Assert.AreEqual(2, Integer(LBytes[6]));
  Assert.AreEqual(1, Integer(LBytes[7]));
  Assert.AreEqual($FE, Integer(LBytes[8]), 'a negative number is two''s complement');
  Assert.AreEqual($FF, Integer(LBytes[11]));
  Assert.AreEqual(GREED_NET_EVENT_FRAG, FBuffer.EventId);
  Assert.AreEqual($01020304, FBuffer.PlayerId);
end;

procedure TTestGreedNetPacketBuffer.DovrebbeRileggereOgniTipoDiPacchetto;
var
  LPlayer: TGreedPlayerEvent;
  LSpawn: TGreedNetSpawnEvent;
  LDoor: TGreedNetDoorEvent;
  LBonus: TGreedNetBonusEvent;
  LItem: TGreedNetItemEvent;
  LSound: TGreedNetSoundEvent;
  LOnly: TGreedNetPlayerOnlyEvent;
begin
  LPlayer := Default(TGreedPlayerEvent);
  LPlayer.Id := 2;
  LPlayer.X := 123456789;
  LPlayer.Height := -5;
  LPlayer.SpecialEffect := 4;
  FBuffer.WritePlayer(LPlayer);
  Assert.AreEqual(123456789, FBuffer.ReadPlayer.X);
  Assert.AreEqual(-5, FBuffer.ReadPlayer.Height);
  Assert.AreEqual(4, FBuffer.ReadPlayer.SpecialEffect);

  LSpawn := Default(TGreedNetSpawnEvent);
  LSpawn.Value := 524;
  LSpawn.SpawnId := 7;
  FBuffer.WriteSpawn(LSpawn);
  Assert.AreEqual(524, FBuffer.ReadSpawn.Value);
  Assert.AreEqual(7, FBuffer.ReadSpawn.SpawnId);

  LDoor := Default(TGreedNetDoorEvent);
  LDoor.Y := 99;
  LDoor.Angle := 1023;
  FBuffer.WriteDoor(LDoor);
  Assert.AreEqual(99, FBuffer.ReadDoor.Y);
  Assert.AreEqual(1023, FBuffer.ReadDoor.Angle);

  LBonus := Default(TGreedNetBonusEvent);
  LBonus.Time := 5000;
  LBonus.Num := 47;
  FBuffer.WriteBonus(LBonus);
  Assert.AreEqual(5000, FBuffer.ReadBonus.Time);
  Assert.AreEqual(47, FBuffer.ReadBonus.Num);

  LItem := Default(TGreedNetItemEvent);
  LItem.MapSpot := 4095;
  LItem.CharType := 5;
  FBuffer.WriteItem(LItem);
  Assert.AreEqual(4095, FBuffer.ReadItem.MapSpot);
  Assert.AreEqual(5, FBuffer.ReadItem.CharType);

  LSound := Default(TGreedNetSoundEvent);
  LSound.Effect := 46;
  LSound.Variation := 15;
  FBuffer.WriteSound(LSound);
  Assert.AreEqual(46, FBuffer.ReadSound.Effect);
  Assert.AreEqual(15, FBuffer.ReadSound.Variation);

  LOnly.Id := GREED_NET_EVENT_PAUSE;
  LOnly.PlayerId := 3;
  FBuffer.WritePlayerOnly(LOnly);
  Assert.AreEqual(GREED_NET_EVENT_PAUSE, FBuffer.ReadPlayerOnly.Id);
  Assert.AreEqual(3, FBuffer.ReadPlayerOnly.PlayerId);
  Assert.AreEqual(3, FBuffer.ReadFrag.PlayerId, 'every kind of packet looks at the same bytes');
end;

procedure TTestGreedNetPacketBuffer.DovrebbeLasciareIByteCheNonScrive;
var
  LOnly: TGreedNetPlayerOnlyEvent;
  LBytes: TBytes;
begin
  FBuffer.Load(TNetScenarios.Pack([5, 1, 111, 222, 333]));
  LOnly.Id := GREED_NET_EVENT_QUIT;
  LOnly.PlayerId := 0;
  FBuffer.WritePlayerOnly(LOnly);
  LBytes := FBuffer.ToBytes(20);
  Assert.AreEqual(GREED_NET_EVENT_QUIT, Integer(LBytes[0]));
  Assert.AreEqual(111, Integer(LBytes[8]), 'the bytes of the packet that was there before');
  Assert.AreEqual(222, Integer(LBytes[12]));
  Assert.AreEqual(333 and $FF, Integer(LBytes[16]));
  Assert.AreEqual(333, FBuffer.ReadDoor.Angle, 'a door packet made now would carry that angle');
end;

procedure TTestGreedNetPacketBuffer.DovrebbeCaricareAlMassimoIlSuoBuffer;
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  SetLength(LBytes, 200);
  for LIndex := 0 to High(LBytes) do
    LBytes[LIndex] := Byte(LIndex);
  FBuffer.Load(LBytes);
  LBytes := FBuffer.ToBytes(GREED_NET_MAX_DATA);
  Assert.AreEqual(GREED_NET_MAX_DATA, Integer(Length(LBytes)));
  Assert.AreEqual(127, Integer(LBytes[127]));
end;

procedure TTestGreedNetPacketBuffer.DovrebbeLasciareIlRestoQuandoIlPacchettoECorto;
begin
  FBuffer.Load(TNetScenarios.Pack([3, 1, 500, 10, 20, 30]));
  FBuffer.Load(TNetScenarios.Pack([5, 2]));
  FBuffer.Load(nil);
  Assert.AreEqual(5, FBuffer.EventId);
  Assert.AreEqual(2, FBuffer.PlayerId);
  Assert.AreEqual(500, FBuffer.ReadDoor.X, 'what the longer packet left');
  Assert.AreEqual(10, FBuffer.ReadDoor.Y);
end;

procedure TTestGreedNetPacketBuffer.DovrebbeRifiutareUnaLunghezzaFuoriDalBuffer;
begin
  Assert.WillRaise(
    procedure
    begin
      FBuffer.ToBytes(GREED_NET_MAX_DATA + 1);
    end, EArgumentOutOfRangeException);
  Assert.WillRaise(
    procedure
    begin
      FBuffer.ToBytes(-1);
    end, EArgumentOutOfRangeException);
  Assert.AreEqual(0, Integer(Length(FBuffer.ToBytes(0))));
end;

procedure TTestGreedNetPacketBuffer.DovrebbeAzzerareTutto;
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  FBuffer.Load(TNetScenarios.Pack([7, 7, 7, 7, 7, 7, 7, 7]));
  FBuffer.Clear;
  LBytes := FBuffer.ToBytes(GREED_NET_MAX_DATA);
  for LIndex := 0 to High(LBytes) do
    Assert.AreEqual(0, Integer(LBytes[LIndex]));
end;

procedure TTestGreedNetPacketBuffer.DovrebbeMettereIlNomeEIlTestoAlLoroPosto;
var
  LInit: TGreedNetInitEvent;
  LMessage: TGreedNetMessageEvent;
  LBytes: TBytes;
begin
  LInit := Default(TGreedNetInitEvent);
  LInit.Id := GREED_NET_EVENT_INIT;
  LInit.Start := 2;
  LInit.NetName[0] := 'A';
  LInit.NetName[11] := 'Z';
  LInit.Map := 9;
  LInit.Difficulty := 4;
  FBuffer.WriteInit(LInit);
  LBytes := FBuffer.ToBytes(SizeOf(LInit));
  Assert.AreEqual(Ord('A'), Integer(LBytes[16]), 'the name after four numbers');
  Assert.AreEqual(Ord('Z'), Integer(LBytes[27]));
  Assert.AreEqual(9, Integer(LBytes[32]), 'the map after the name and its padding');
  Assert.AreEqual(4, Integer(LBytes[36]));
  Assert.AreEqual(9, FBuffer.ReadInit.Map);
  Assert.AreEqual(AnsiChar('Z'), FBuffer.ReadInit.NetName[11]);

  LMessage := Default(TGreedNetMessageEvent);
  LMessage.Id := GREED_NET_EVENT_MESSAGE;
  LMessage.Text[0] := 'h';
  LMessage.Text[29] := '!';
  FBuffer.WriteMessage(LMessage);
  LBytes := FBuffer.ToBytes(SizeOf(LMessage));
  Assert.AreEqual(Ord('h'), Integer(LBytes[8]), 'the text after two numbers');
  Assert.AreEqual(Ord('!'), Integer(LBytes[37]));
  Assert.AreEqual(AnsiChar('!'), FBuffer.ReadMessage.Text[29]);
end;

{ TTestGreedNetSession }

procedure TTestGreedNetSession.Setup;
begin
  FNet := TFakeGreedNet.Create(3);
  FSetup := TFakeGameSetup.Create;
  FSetup.CreateGame;
end;

procedure TTestGreedNetSession.TearDown;
begin
  FStart := nil;
  FreeAndNil(FSetup);
  FreeAndNil(FNet);
end;

function TTestGreedNetSession.Link: IGreedNetLink;
begin
  Result := FSetup.Game.State.Net;
end;

procedure TTestGreedNetSession.Sit(APlayer, APlayers: Integer; ANetType: Integer);
var
  LConfig: TGreedNetConfig;
begin
  LConfig := TGreedNetConfig.Make(APlayer, APlayers, 'Me');
  LConfig.NetType := ANetType;
  FStart := TGreedNetFactory.Attach(FSetup.Game, FNet.Endpoint(0), LConfig);
  FSetup.Game.NewGame(0, 0, 2);
end;

procedure TTestGreedNetSession.Arrive(const AValues: array of Integer; const ATail: TBytes);
begin
  FNet.Inject(1, 0, TNetScenarios.Pack(AValues, ATail));
end;

function TTestGreedNetSession.NewSession(const ATransport: INetTransport; const AConfig: TGreedNetConfig;
  AMissing: Integer): TGreedNetSession;
var
  LGame: TGreedGame;
  LHost: IGreedNetHost;
  LState: TGreedGameState;
  LArchive: IInterface;

  function Unless(ANumber: Integer; const AValue: IInterface): IInterface;
  begin
    if AMissing = ANumber then
      Result := nil
    else
      Result := AValue;
  end;

begin
  LGame := FSetup.Game;
  LHost := LGame.NetHost;
  LState := LGame.State;
  if AMissing = 0 then
    LState := nil;
  LArchive := LGame.Parts.Archive;
  Result := TGreedNetSession.Create(LState, Unless(1, ATransport) as INetTransport, AConfig,
    Unless(2, LArchive) as IGreedArchive, Unless(3, LGame.Parts.SpawnerIntf) as IGreedSpawner,
    Unless(4, LHost) as IGreedGameSound, Unless(5, LGame.Parts.Messages) as IGreedMessages,
    Unless(6, LHost) as IGreedPlayerHealth, Unless(7, LGame.Parts.Random) as IGreedRandom,
    Unless(8, LGame.Parts.EventsIntf) as IGreedEventRunner, Unless(9, LHost) as IGreedNetHost);
end;

procedure TTestGreedNetSession.DovrebbeRifiutareUnaDipendenzaNil;
var
  LMissing: Integer;
  LRaised: Boolean;
  LSession: IGreedNetLink;
begin
  for LMissing := 0 to 9 do
  begin
    LRaised := False;
    try
      LSession := NewSession(FNet.Endpoint(0), TGreedNetConfig.Make(0, 2, 'x'), LMissing);
    except
      on EArgumentNilException do
        LRaised := True;
    end;
    Assert.IsTrue(LRaised, Format('the dependency %d', [LMissing]));
  end;
  LSession := NewSession(FNet.Endpoint(0), TGreedNetConfig.Make(0, 2, 'x'), -1);
  Assert.AreEqual(2, LSession.NumPlayers);
  Assert.AreEqual(0, LSession.ConsolePlayer);
end;

procedure TTestGreedNetSession.DovrebbeRifiutareUnTipoDiReteSconosciuto;
var
  LConfig: TGreedNetConfig;
  LRaised: Boolean;
  LSession: TGreedNetSession;
  LKeep: IGreedNetLink;
begin
  LConfig := TGreedNetConfig.Make(0, 2, 'x');
  LConfig.NetType := 9;
  LRaised := False;
  try
    NewSession(FNet.Endpoint(0), LConfig, -1).Free;
  except
    on E: EGreedNetException do
      LRaised := E.Message = SGreedNetUnknownType;
  end;
  Assert.IsTrue(LRaised, 'Unknown net type!');
  LConfig.NetType := GREED_NET_MODEM;
  LSession := NewSession(FNet.Endpoint(0), LConfig, -1);
  LKeep := LSession;
  Assert.AreEqual(GREED_NET_MODEM, LSession.NetType);
end;

procedure TTestGreedNetSession.DovrebbeRifiutareGiocatoriFuoriDaiLimiti;
var
  LBad: array[0..3] of TGreedNetConfig;
  LIndex: Integer;
  LRaised: Boolean;
begin
  LBad[0] := TGreedNetConfig.Make(0, 0, 'x');
  LBad[1] := TGreedNetConfig.Make(0, 9, 'x');
  LBad[2] := TGreedNetConfig.Make(-1, 2, 'x');
  LBad[3] := TGreedNetConfig.Make(2, 2, 'x');
  for LIndex := Low(LBad) to High(LBad) do
  begin
    LRaised := False;
    try
      NewSession(FNet.Endpoint(0), LBad[LIndex], -1).Free;
    except
      on EGreedNetException do
        LRaised := True;
    end;
    Assert.IsTrue(LRaised, Format('the configuration %d', [LIndex]));
  end;
end;

procedure TTestGreedNetSession.DovrebbeMandareOgniPacchettoATuttiGliAltri;
begin
  Sit(0, 3);
  Link.SendSpawn(505, 1, 2, 3, 4, 5, 6, True, 0);
  Assert.AreEqual(1, FNet.Pending(1));
  Assert.AreEqual(1, FNet.Pending(2));
  Assert.AreEqual(0, FNet.Pending(0), 'not to itself');
  Assert.AreEqual(2, Integer(Length(FNet.TakeSent(0))));
end;

procedure TTestGreedNetSession.DovrebbeScartareIPacchettiTroppoCorti;
begin
  Sit(0, 3);
  // a pause of player 1, then four bytes: the original would read the pause again
  Arrive([GREED_NET_EVENT_PAUSE, 1]);
  Link.GetData;
  Assert.IsTrue(Link.Paused);
  Arrive([GREED_NET_EVENT_UNPAUSE, 1]);
  FNet.Inject(1, 0, TBytes.Create(11, 0, 0, 0));
  FNet.Inject(1, 0, nil);
  Link.GetData;
  Assert.IsFalse(Link.Paused, 'the short packets are thrown away and the others are read');
  Assert.AreEqual(0, FNet.Pending(0));
end;

procedure TTestGreedNetSession.DovrebbeScartareIPacchettiDiUnGiocatoreCheNonEsiste;
begin
  Sit(0, 3);
  Arrive([GREED_NET_EVENT_PAUSE, 8]);
  Arrive([GREED_NET_EVENT_PAUSE, -1]);
  Arrive([GREED_NET_EVENT_FRAG, 99, 0]);
  Link.GetData;
  Assert.IsFalse(Link.Paused);
  Assert.AreEqual(0, Link.FragCount[0]);
end;

procedure TTestGreedNetSession.DovrebbeScartareIPropriPacchetti;
begin
  Sit(0, 3);
  Arrive([GREED_NET_EVENT_PAUSE, 0]);
  Link.GetData;
  Assert.IsFalse(Link.Paused, 'a packet with the number of this player is its own echo');
end;

procedure TTestGreedNetSession.NonDovrebbeCreareUnGiocatoreDiUnPersonaggioCheNonEsiste;
begin
  Sit(0, 3);
  Arrive([GREED_NET_EVENT_NEW_PLAYER, 1, 5 * TILE, 5 * TILE, 0, 0, 500, 6, 0, 0, 0, 48 shl 16, 0]);
  Arrive([GREED_NET_EVENT_NEW_PLAYER, 2, 5 * TILE, 5 * TILE, 0, 0, 500, -1, 0, 0, 0, 48 shl 16, 0]);
  Link.GetData;
  Assert.AreEqual(0, FSetup.SpritesOfKind(GREED_S_NETPLAYER));
  Arrive([GREED_NET_EVENT_NEW_PLAYER, 1, 5 * TILE, 5 * TILE, 0, 0, 500, 5, 0, 0, 0, 48 shl 16, 0]);
  Link.GetData;
  Assert.AreEqual(1, FSetup.SpritesOfKind(GREED_S_NETPLAYER));
end;

procedure TTestGreedNetSession.DovrebbeDireLaMorteDiChiNonHaUnoSprite;
begin
  Sit(0, 3);
  // player 1 never said where it is: the original would follow a nil pointer
  Arrive([GREED_NET_EVENT_FRAG, 1, 2]);
  Link.GetData;
  Assert.AreEqual(1, Link.FragCount[2]);
  Assert.AreEqual(3, FSetup.Game.State.GoalItem, 'the goal shows who killed');
  Assert.IsTrue(FSetup.View.Messages.IndexOf(' fragged .') >= 0, 'nobody has a name before the start');
  // a negative killer is nobody
  Arrive([GREED_NET_EVENT_FRAG, 1, -3]);
  Link.GetData;
  Assert.IsTrue(FSetup.View.Messages.IndexOf(' was killed.') >= 0);
end;

procedure TTestGreedNetSession.NonDovrebbeCambiareIlBersaglioSeNessunoEVivo;
var
  LState: TGreedGameState;
begin
  Sit(0, 3);
  LState := FSetup.Game.State;
  LState.TargX := 11;
  LState.TargY := 22;
  LState.TargZ := 33;
  Link.GetClosestPlayer(5, 5);
  Assert.AreEqual(11, LState.TargX);
  Assert.AreEqual(22, LState.TargY);
  Assert.AreEqual(33, LState.TargZ);
end;

procedure TTestGreedNetSession.DovrebbeScegliereIlGiocatoreVivoPiuVicino;
var
  LState: TGreedGameState;
begin
  Sit(0, 3);
  LState := FSetup.Game.State;
  Arrive([GREED_NET_EVENT_NEW_PLAYER, 1, 20 * TILE, 20 * TILE, 0, 0, 500, 1, 0, 0, 0, 48 shl 16, 0]);
  Arrive([GREED_NET_EVENT_NEW_PLAYER, 2, 40 * TILE, 40 * TILE, 0, 0, 500, 2, 0, 0, 0, 48 shl 16, 0]);
  // player 1 is alive at (20, 20); player 2 is nearer to (38, 38) but invisible
  Arrive([EV_PLAYER, 1, 20 * TILE, 20 * TILE, 7, 0, 500, 1, 0, 0, 0, 48 shl 16, 0]);
  Arrive([EV_PLAYER, 2, 40 * TILE, 40 * TILE, 9, 0, 500, 2, 0, 0, 0, 48 shl 16, GREED_SE_INVISIBILITY]);
  Link.GetData;
  Link.GetClosestPlayer(38, 38);
  Assert.AreEqual(20 * TILE, LState.TargX, 'the invisible player is not a target');
  Assert.AreEqual(7, LState.TargZ);
  // this player counts too, once it has said where it is
  Link.SendPlayerData;
  Link.GetClosestPlayer(FAKE_START_X, FAKE_START_Y);
  Assert.AreEqual(LState.Player.X, LState.TargX);
  // a dead player is not a target
  Arrive([EV_PLAYER, 1, 20 * TILE, 20 * TILE, 7, 0, 0, 1, 0, 0, 0, 48 shl 16, 0]);
  Link.GetData;
  Link.GetClosestPlayer(20, 20);
  Assert.AreEqual(LState.Player.X, LState.TargX);
end;

procedure TTestGreedNetSession.DovrebbeTagliareUnTestoLungo;
var
  LSent: TArray<TBytes>;
begin
  Sit(0, 2);
  FNet.TakeSent(0);
  Link.SendMessage('0123456789012345678901234567890123456789');
  LSent := FNet.TakeSent(0);
  Assert.AreEqual(2, Integer(Length(LSent)), 'the net of the test has three computers');
  Assert.AreEqual(SizeOf(TGreedNetMessageEvent), Integer(Length(LSent[0])));
  Assert.AreEqual(Ord('9'), Integer(LSent[0][37]), 'thirty characters travel');
  Assert.AreEqual(0, Integer(LSent[0][38]), 'the padding is not text');
  // a text with a zero inside ends there
  Link.SendMessage(AnsiString('ab'#0'cd'));
  LSent := FNet.TakeSent(0);
  Assert.AreEqual(Ord('b'), Integer(LSent[0][9]));
  Assert.AreEqual(0, Integer(LSent[0][10]));
  Assert.AreEqual(Ord('3'), Integer(LSent[0][11]), 'after the zero the bytes of the text before');
end;

procedure TTestGreedNetSession.DovrebbeLeggereUnTestoSenzaLoZero;
begin
  Sit(0, 2);
  Arrive([GREED_NET_EVENT_MESSAGE, 1], TNetScenarios.TextField('012345678901234567890123456789XY', 32));
  Link.GetData;
  Assert.IsTrue(FSetup.View.Messages.IndexOf(': 012345678901234567890123456789') >= 0,
    'the text ends at its thirty characters');
end;

procedure TTestGreedNetSession.NonDovrebbeAspettareSenzaAverCominciato;
begin
  Sit(0, 2);
  Assert.WillRaise(
    procedure
    begin
      FStart.WaitStartStep;
    end, EGreedNetException);
end;

procedure TTestGreedNetSession.DovrebbeRifiutareUnGiocatoreSuUnAltraMappa;
var
  LRaised: Boolean;
begin
  Sit(0, 2);
  FStart.BeginWaitStart;
  FNet.Inject(1, 0, TNetScenarios.InitPacket(1, 1, 0, 'Other', 7, 2));
  LRaised := False;
  try
    FStart.WaitStartStep;
  except
    on E: EGreedNetException do
      LRaised := E.Message = Format(SGreedNetDifferentMap, [1]);
  end;
  Assert.IsTrue(LRaised);
  // a player that does not exist is not even looked at
  FNet.Inject(1, 0, TNetScenarios.InitPacket(12, 1, 0, 'Nobody', 7, 2));
  Assert.IsFalse(FStart.WaitStartStep);
end;

procedure TTestGreedNetSession.DovrebbeRifiutareUnGiocatoreFuoriDaiLimitiNelleLetture;
var
  LSession: TGreedNetSession;
  LKeep: IGreedNetLink;
begin
  LSession := NewSession(FNet.Endpoint(0), TGreedNetConfig.Make(0, 2, 'x'), -1);
  LKeep := LSession;
  Assert.WillRaise(
    procedure
    begin
      LKeep.PlayerData[8];
    end, EArgumentOutOfRangeException);
  Assert.WillRaise(
    procedure
    begin
      LKeep.FragCount[-1];
    end, EArgumentOutOfRangeException);
  Assert.WillRaise(
    procedure
    begin
      LKeep.NetName[8];
    end, EArgumentOutOfRangeException);
  Assert.WillRaise(
    procedure
    begin
      LSession.PlayerSprite(8);
    end, EArgumentOutOfRangeException);
  Assert.WillRaise(
    procedure
    begin
      LSession.PlayerMapSpot(-1);
    end, EArgumentOutOfRangeException);
  Assert.AreEqual(GREED_NET_IPX, LSession.NetType);
  Assert.IsFalse(LSession.Waiting);
end;

procedure TTestGreedNetSession.DovrebbeFareLAnelloDiUnColpoArrivatoDallaRete;
begin
  Sit(0, 2);
  Arrive([GREED_NET_EVENT_SPAWN, 1, GREED_S_BULLET18, 30 * TILE, 30 * TILE, 0, 20 shl 16, 1020, 0, 1, 1]);
  Link.GetData;
  Assert.AreEqual(12, FSetup.SpritesOfKind(GREED_S_BULLET18), 'one packet, twelve shots');
  Arrive([GREED_NET_EVENT_SPAWN, 1, GREED_S_SOULBULLET, 30 * TILE, 30 * TILE, 0, 20 shl 16, 0, 0, 1, 1]);
  Link.GetData;
  Assert.AreEqual(16, FSetup.SpritesOfKind(GREED_S_SOULBULLET));
  Assert.IsFalse(FSetup.Game.State.GameLoading);
end;

procedure TTestGreedNetSession.NonDovrebbeRimandareUnoSpawnArrivatoDallaRete;
begin
  Sit(0, 2);
  FNet.TakeSent(0);
  Arrive([GREED_NET_EVENT_SPAWN, 1, GREED_S_PROXMINE, 30 * TILE, 30 * TILE, 0, 0, 0, 0, 0, 1]);
  Link.GetData;
  Assert.AreEqual(1, FSetup.SpritesOfKind(GREED_S_PROXMINE));
  Assert.AreEqual(0, Integer(Length(FNet.TakeSent(0))), 'what comes from the net is not told to the net');
end;

procedure TTestGreedNetSession.DovrebbeFarSentireUnSuonoArrivatoDallaRete;
begin
  Sit(0, 2);
  Arrive([GREED_NET_EVENT_SOUND, 1, 30 * TILE, 30 * TILE, GREED_SN_GRENADE, 0]);
  Link.GetData;
  Assert.AreEqual(1, FSetup.Sound.CountOf(GREED_SN_GRENADE));
end;

procedure TTestGreedNetSession.DovrebbeFermareLeAreeConIlJammerDiUnAltro;
begin
  Sit(0, 2);
  FSetup.Game.State.TimeCount := 100;
  Arrive([GREED_NET_EVENT_JAMMER, 1]);
  Link.GetData;
  Assert.IsTrue(Link.WarpJammer);
  Assert.AreEqual(100 + GREED_NET_WARP_JAM_TICS, Link.WarpJamTime);
  Assert.IsTrue(FSetup.View.Messages.IndexOf(' activated Warp Jammer!') >= 0);
end;

procedure TTestGreedNetSession.DovrebbeAccettareUnBonusSenzaNomeEUnaCasellaFuoriMappa;
var
  LSent: TArray<TBytes>;
begin
  Sit(0, 2);
  // a bonus item whose number is not in the table of the names: the original would read after the table
  Arrive([GREED_NET_EVENT_BONUS, 1, 9000, 2500, 12, 13, 99]);
  Link.GetData;
  Assert.AreEqual(2500, FSetup.Game.State.BonusItem.Score);
  Assert.AreEqual('', FSetup.Game.State.BonusItem.Name);
  Assert.AreEqual(13 * GREED_MAP_SIZE + 12, FSetup.Game.State.BonusItem.MapSpot);
  // a pickup outside the map says that the tile had nothing
  FNet.TakeSent(0);
  Link.ItemPickup(100, 100);
  LSent := FNet.TakeSent(0);
  Assert.AreEqual(SizeOf(TGreedNetItemEvent), Integer(Length(LSent[0])));
  Assert.AreEqual(0, Integer(LSent[0][20]), 'the kind of what was on the tile');
end;

procedure TTestGreedNetSession.DovrebbeDireChiHaLasciatoIlGioco;
begin
  Sit(0, 2);
  Arrive([GREED_NET_EVENT_QUIT, 1]);
  Arrive([GREED_NET_EVENT_EVENT, 1, 200]);
  Link.GetData;
  Assert.IsTrue(FSetup.View.Messages.IndexOf(' has left the game!') >= 0);
end;

procedure TTestGreedNetSession.DovrebbeMandareJammerEdEvento;
var
  LSession: TGreedNetSession;
  LKeep: IGreedNetLink;
  LSent: TArray<TBytes>;
begin
  LSession := NewSession(FNet.Endpoint(1), TGreedNetConfig.Make(1, 2, 'x'), -1);
  LKeep := LSession;
  LSession.WarpJam;
  LSession.Event(77);
  LSent := FNet.TakeSent(1);
  Assert.AreEqual(4, Integer(Length(LSent)), 'two packets to two computers');
  Assert.AreEqual(GREED_NET_EVENT_JAMMER, Integer(LSent[0][0]));
  Assert.AreEqual(1, Integer(LSent[0][4]), 'the number of the player');
  Assert.AreEqual(8, Integer(Length(LSent[0])));
  Assert.AreEqual(GREED_NET_EVENT_EVENT, Integer(LSent[2][0]));
  Assert.AreEqual(77, Integer(LSent[2][8]));
end;

procedure TTestGreedNetSession.DovrebbeDireAgliAltriLoSparoDelGiocatore;
var
  LSent: TArray<TBytes>;
  LIndex, LSpawns, LSounds: Integer;
begin
  Sit(0, 2);
  FSetup.Play(2);
  FNet.TakeSent(0);
  FSetup.Commands.Pressed := [gcFire];
  FSetup.Play(6);
  LSent := FNet.TakeSent(0);
  LSpawns := 0;
  LSounds := 0;
  for LIndex := 0 to High(LSent) do
    if LSent[LIndex][0] = GREED_NET_EVENT_SPAWN then
      Inc(LSpawns)
    else if LSent[LIndex][0] = GREED_NET_EVENT_SOUND then
      Inc(LSounds);
  Assert.IsTrue(LSpawns >= 2, 'the shot is told (to two computers)');
  Assert.IsTrue(LSounds >= 2, 'and its sound');
  FSetup.Commands.Pressed := [];
  FSetup.Play(6);
  Assert.AreEqual(0, FSetup.Game.State.Player.Status, 'the status of the player goes back to nothing when it is sent');
end;

procedure TTestGreedNetSession.DovrebbePartireDalTic19SuUnaLineaSeriale;
var
  LTic: Integer;
  LStarted: Boolean;
  LDatagram: TFakeGreedDatagram;
begin
  Sit(0, 2, GREED_NET_SERIAL);
  FStart.BeginWaitStart;
  LStarted := False;
  for LTic := 1 to 600 do
  begin
    Inc(FSetup.Game.State.TimeCount);
    // the other computer answers every packet with what it has found
    if FNet.Pending(1) > 0 then
    begin
      FNet.Inject(1, 0, TNetScenarios.InitPacket(1, 2, 0, 'Guest', 0, 2));
      while FNet.Pop(1, LDatagram) do
        ;
    end;
    if FStart.WaitStartStep then
    begin
      LStarted := True;
      Break;
    end;
  end;
  Assert.IsTrue(LStarted);
  Assert.AreEqual(19, FSetup.Game.State.TimeCount, 'the host of a serial game starts 19 tics ahead');
  Assert.AreEqual(AnsiString('Guest'), Link.NetName[1]);
  Assert.AreEqual(AnsiString('Me'), Link.NetName[0]);
end;

{ TTestGreedNetFakes }

class function TTestGreedNetFakes.Bytes(AValue: Byte): TBytes;
begin
  Result := TBytes.Create(AValue);
end;

procedure TTestGreedNetFakes.Setup;
begin
  FNet := TFakeGreedNet.Create(3);
end;

procedure TTestGreedNetFakes.TearDown;
begin
  FreeAndNil(FNet);
end;

procedure TTestGreedNetFakes.DovrebbeNumerareINodiSaltandoSeStesso;
var
  LMiddle: INetTransport;
begin
  LMiddle := FNet.Endpoint(1);
  Assert.AreEqual(3, LMiddle.NodeCount);
  // the nodes of the computer 1: 1 is the computer 0, 2 is the computer 2
  LMiddle.Send(1, Bytes(10));
  LMiddle.Send(2, Bytes(20));
  Assert.AreEqual(1, FNet.Pending(0));
  Assert.AreEqual(0, FNet.Pending(1));
  Assert.AreEqual(1, FNet.Pending(2));
end;

procedure TTestGreedNetFakes.DovrebbeDireChiHaMandato;
var
  LFirst, LLast: INetTransport;
  LNode: Integer;
  LData: TBytes;
begin
  LFirst := FNet.Endpoint(0);
  LLast := FNet.Endpoint(2);
  LFirst.Send(2, Bytes(1));
  FNet.Endpoint(1).Send(2, Bytes(2));
  Assert.IsTrue(LLast.Receive(LNode, LData));
  Assert.AreEqual(1, LNode, 'the computer 0 is the node 1 of the computer 2');
  Assert.AreEqual(1, Integer(LData[0]));
  Assert.IsTrue(LLast.Receive(LNode, LData));
  Assert.AreEqual(2, LNode);
  Assert.IsFalse(LLast.Receive(LNode, LData));
  Assert.AreEqual(-1, LNode);
  // seen from the computer 0, the computer 2 is the node 2
  LLast.Send(1, Bytes(3));
  Assert.IsTrue(LFirst.Receive(LNode, LData));
  Assert.AreEqual(2, LNode);
end;

procedure TTestGreedNetFakes.DovrebbeRifiutareUnNodoCheNonEsiste;
begin
  Assert.WillRaise(
    procedure
    begin
      FNet.Endpoint(0).Send(0, nil);
    end, EArgumentOutOfRangeException, 'node 0 is this computer');
  Assert.WillRaise(
    procedure
    begin
      FNet.Endpoint(0).Send(3, nil);
    end, EArgumentOutOfRangeException);
  Assert.WillRaise(
    procedure
    begin
      FNet.Endpoint(3);
    end, EArgumentOutOfRangeException);
end;

procedure TTestGreedNetFakes.DovrebbePerdereIProssimiDatagrammi;
var
  LFirst: INetTransport;
begin
  LFirst := FNet.Endpoint(0);
  FNet.LoseNext(2);
  LFirst.Send(1, Bytes(1));
  LFirst.Send(1, Bytes(2));
  LFirst.Send(1, Bytes(3));
  Assert.AreEqual(1, FNet.Pending(1));
  Assert.AreEqual(2, FNet.Lost);
end;

procedure TTestGreedNetFakes.DovrebbeTrattenereERilasciareAlContrario;
var
  LFirst, LSecond: INetTransport;
  LNode: Integer;
  LData: TBytes;
begin
  LFirst := FNet.Endpoint(0);
  LSecond := FNet.Endpoint(1);
  FNet.HoldBack := True;
  LFirst.Send(1, Bytes(1));
  LFirst.Send(1, Bytes(2));
  Assert.AreEqual(0, FNet.Pending(1));
  FNet.HoldBack := False;
  FNet.Release(True);
  Assert.IsTrue(LSecond.Receive(LNode, LData));
  Assert.AreEqual(2, Integer(LData[0]), 'the last one first');
  Assert.IsTrue(LSecond.Receive(LNode, LData));
  Assert.AreEqual(1, Integer(LData[0]));
end;

procedure TTestGreedNetFakes.DovrebbeRilasciareNellOrdineDiInvio;
var
  LFirst, LSecond: INetTransport;
  LNode: Integer;
  LData: TBytes;
begin
  LFirst := FNet.Endpoint(0);
  LSecond := FNet.Endpoint(1);
  FNet.HoldBack := True;
  LFirst.Send(1, Bytes(1));
  LFirst.Send(1, Bytes(2));
  FNet.Release(False);
  Assert.IsTrue(LSecond.Receive(LNode, LData));
  Assert.AreEqual(1, Integer(LData[0]));
  Assert.IsTrue(FNet.HoldBack);
end;

procedure TTestGreedNetFakes.DovrebbeRicordareCosaHaMandatoOgnuno;
var
  LSent: TArray<TBytes>;
begin
  FNet.Endpoint(0).Send(1, Bytes(1));
  FNet.Endpoint(1).Send(1, Bytes(2));
  FNet.Endpoint(0).Send(2, Bytes(3));
  FNet.Inject(2, 0, Bytes(9));
  LSent := FNet.TakeSent(0);
  Assert.AreEqual(2, Integer(Length(LSent)));
  Assert.AreEqual(1, Integer(LSent[0][0]));
  Assert.AreEqual(3, Integer(LSent[1][0]));
  Assert.AreEqual(0, Integer(Length(FNet.TakeSent(0))), 'taken once');
  Assert.AreEqual(1, Integer(Length(FNet.TakeSent(1))));
  Assert.AreEqual(0, Integer(Length(FNet.TakeSent(2))), 'what is injected was not sent by anybody');
  Assert.AreEqual(3, FNet.Count);
end;

end.
