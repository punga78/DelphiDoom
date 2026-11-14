{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the computer player (AI)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.AiPlayers;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.War.Ai.Command, DelphiDoom.War.Ai.Environment,
  DelphiDoom.War.Ai.Handler, DelphiDoom.War.Ai.Players, DelphiDoom.Tests.War.ModelRig;

type
  /// <summary>A handler that counts how many times it is called and answers what it is told</summary>
  TCountingHandler = class(TWarAiCommandHandler)
  strict private
    FCalls: Integer;
    FAnswer: Boolean;
  public
    constructor Create(AAnswer: Boolean);
    function Execute(const AEnvironment: TWarAiEnvironment; const ACommand: TWarAiCommand): Boolean; override;
    property Calls: Integer read FCalls;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarAiCommand = class(TObject)
  public
    [Test]
    procedure DovrebbeComporreEScomporreLaManiglia;
    [Test]
    procedure DovrebbeContareUnaRichiestaFinoAlCompletamento;
    [Test]
    procedure DovrebbeIgnorareIlProgressoSeNonERichiestaOSenzaUnita;
    [Test]
    procedure DovrebbeConfrontareICommandiDallId;
  end;

  [TestFixture]
  [Category('war')]
  TTestWarUnitProducers = class(TObject)
  public
    [Test]
    procedure DovrebbeDareIlMunicipioPerGliOperaiELaCasermaPerISoldati;
    [Test]
    procedure DovrebbeDareMenoUnoPerCioCheNessunoAddestra;
    [Test]
    procedure DovrebbeRiconoscereITipiValidi;
  end;

  /// <summary>The registry, the handlers, the player and the players, on a world of the model</summary>
  [TestFixture]
  [Category('war')]
  TTestWarComputerPlayers = class(TObject)
  strict private
    FRig: TModelRig;
    FPlayers: TWarComputerPlayers;
    function TownHall(AX: Integer; APlayer: Byte = 1): Integer;
    function Environment: TWarAiEnvironment;
    function Request(AUnitType, ACount: Integer; AId: Cardinal = 90): TWarAiCommand;
    function TrainingsHolding(AHandle: Cardinal): Integer;
    function PendingTrain(ASlot: Integer): Boolean;
    /// <summary>The players of the AI in the world (they run in every Update, with the script of their race)</summary>
    procedure StartAi;
    /// <summary>The players of the AI that no tic runs: only what the test calls moves them</summary>
    procedure StartDetached;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRegistrareRichiestaAttesaEPausaMaNonAttaccoEDifesa;
    [Test]
    procedure DovrebbeDareUnAvvisoEFinireSubitoPerUnComandoSenzaGestore;
    [Test]
    procedure DovrebbeFinireSenzaAvvisoUnComandoGiaCompletato;
    [Test]
    procedure DovrebbeSostituireUnGestoreEUsareQuelloNuovo;
    [Test]
    procedure DovrebbeRifiutareUnTipoDiComandoNonValido;
    [Test]
    procedure DovrebbeAspettareCheIlGiocatoreAbbiaLeUnita;
    [Test]
    procedure DovrebbeAspettareIlTempoRealeDellaPausa;
    [Test]
    procedure DovrebbeDareUnEdificioPerFattoSenzaCostruireNiente;
    [Test]
    procedure DovrebbeAddestrareUnaUnitaCollegandoLaRichiestaAlloStato;
    [Test]
    procedure DovrebbeContareLUnitaQuandoSiPagaNonQuandoNasce;
    [Test]
    procedure DovrebbeContareLUnitaAncheSeLAddestramentoViene;
    [Test]
    procedure DovrebbeRiprovareFinoAvereOro;
    [Test]
    procedure DovrebbeRiprovareFinoAvereCibo;
    [Test]
    procedure DovrebbeRiprovareFinoAvereUnEdificio;
    [Test]
    procedure DovrebbeScegliereIlPrimoEdificioLiberoDelGiocatore;
    [Test]
    procedure DovrebbeAddestrareUnaSolaVoltaPerRichiestaNelloStessoTic;
    [Test]
    procedure DovrebbeUsareUnEdificioInCostruzioneComeFaIlC;
    [Test]
    procedure DovrebbeDareUnAvvisoPerUnTipoDiUnitaSconosciuto;
    [Test]
    procedure DovrebbeLasciareSenzaRichiestaLoStatoDiUnOrdineDelGiocatore;
    [Test]
    procedure DovrebbeSeguireIlCopioneNeiPrimiTic;
    [Test]
    procedure DovrebbeUsareLeUnitaDellaRazzaDelGiocatore;
    [Test]
    procedure DovrebbeRestareFermoSullAttesaSenzaMunicipio;
    [Test]
    procedure DovrebbeDormireDopoIlCopioneELiberareLePause;
    [Test]
    procedure DovrebbeEseguireUnComandoDiUnTipoRegistratoDopo;
    [Test]
    procedure DovrebbeIgnorareIlProgressoDiUnaManigliaSconosciuta;
    [Test]
    procedure DovrebbeContareIlProgressoDiUnaManigliaDelCopione;
    [Test]
    procedure DovrebbeRifiutareUnGiocatoreDueVolteOFuoriDalGioco;
    [Test]
    procedure DovrebbeRifiutareDueVolteLaStessaAttivazione;
    [Test]
    procedure DovrebbeSegnalareIndiciFuoriDaiLimiti;
    [Test]
    procedure DovrebbeNonFarNullaSeNessunoGiocaIlComputer;
  end;
implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Level.Types, DelphiDoom.War.Ai.Types, DelphiDoom.War.Ai.Player,
  DelphiDoom.War.Ai.Registry, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.State.Types,
  DelphiDoom.War.Model.Factory, DelphiDoom.War.Model.Context, DelphiDoom.War.Model.Commands.Dispatcher,
  DelphiDoom.War.Model.UnitProducers, DelphiDoom.War.Model.Stats.Types;

{ TCountingHandler }

constructor TCountingHandler.Create(AAnswer: Boolean);
begin
  inherited Create;
  FAnswer := AAnswer;
end;

function TCountingHandler.Execute(const AEnvironment: TWarAiEnvironment; const ACommand: TWarAiCommand): Boolean;
begin
  Inc(FCalls);
  Result := FAnswer;
end;

{ TTestWarAiCommand }

procedure TTestWarAiCommand.DovrebbeComporreEScomporreLaManiglia;
var
  LHandle: Cardinal;
begin
  LHandle := TWarAiCommand.MakeHandle(1, 5);
  Assert.AreEqual(1, TWarAiCommand.HandlePlayer(LHandle));
  Assert.AreEqual<Cardinal>(5, TWarAiCommand.HandleId(LHandle));
  // the player 0 with the id 1 is not "no request"
  Assert.AreNotEqual<Cardinal>(0, TWarAiCommand.MakeHandle(0, 1));
  Assert.AreEqual(-1, TWarAiCommand.HandlePlayer(0));
end;

procedure TTestWarAiCommand.DovrebbeContareUnaRichiestaFinoAlCompletamento;
var
  LCommand: TWarAiCommand;
begin
  LCommand := TWarAiCommand.Create(1, WAR_AI_COMMAND_REQUEST);
  try
    LCommand.Count := 2;
    Assert.AreEqual(WAR_AI_STATUS_CREATED, LCommand.Status);
    LCommand.ApplyUnitRequestProgress;
    Assert.AreEqual(WAR_AI_STATUS_STARTED, LCommand.Status);
    Assert.AreEqual(1, LCommand.Count);
    LCommand.ApplyUnitRequestProgress;
    Assert.AreEqual(WAR_AI_STATUS_COMPLETED, LCommand.Status);
    Assert.AreEqual(0, LCommand.Count);
    // nothing left: no more progress (the count never goes below zero)
    LCommand.ApplyUnitRequestProgress;
    Assert.AreEqual(0, LCommand.Count);
  finally
    LCommand.Free;
  end;
end;

procedure TTestWarAiCommand.DovrebbeIgnorareIlProgressoSeNonERichiestaOSenzaUnita;
var
  LWait: TWarAiCommand;
  LEmpty: TWarAiCommand;
begin
  LWait := TWarAiCommand.Create(1, WAR_AI_COMMAND_WAIT);
  LEmpty := TWarAiCommand.Create(2, WAR_AI_COMMAND_REQUEST);
  try
    LWait.Count := 3;
    LWait.ApplyUnitRequestProgress;
    Assert.AreEqual(3, LWait.Count);
    Assert.AreEqual(WAR_AI_STATUS_CREATED, LWait.Status);
    LEmpty.ApplyUnitRequestProgress;
    Assert.AreEqual(WAR_AI_STATUS_CREATED, LEmpty.Status);
  finally
    LEmpty.Free;
    LWait.Free;
  end;
end;

procedure TTestWarAiCommand.DovrebbeConfrontareICommandiDallId;
var
  LFirst: TWarAiCommand;
  LSame: TWarAiCommand;
  LOther: TWarAiCommand;
begin
  LFirst := TWarAiCommand.Create(4, WAR_AI_COMMAND_SLEEP);
  LSame := TWarAiCommand.Create(4, WAR_AI_COMMAND_WAIT);
  LOther := TWarAiCommand.Create(5, WAR_AI_COMMAND_SLEEP);
  try
    Assert.IsTrue(LFirst.SameAs(LSame));
    Assert.IsFalse(LFirst.SameAs(LOther));
  finally
    LOther.Free;
    LSame.Free;
    LFirst.Free;
  end;
end;

{ TTestWarUnitProducers }

procedure TTestWarUnitProducers.DovrebbeDareIlMunicipioPerGliOperaiELaCasermaPerISoldati;
begin
  Assert.AreEqual(WAR_UNIT_TOWNHALL_HUMANS, TWarUnitProducers.ProducerOf(WAR_UNIT_PEASANT));
  Assert.AreEqual(WAR_UNIT_TOWNHALL_ORCS, TWarUnitProducers.ProducerOf(WAR_UNIT_PEON));
  Assert.AreEqual(WAR_UNIT_BARRACKS_HUMANS, TWarUnitProducers.ProducerOf(WAR_UNIT_FOOTMAN));
  Assert.AreEqual(WAR_UNIT_BARRACKS_ORCS, TWarUnitProducers.ProducerOf(WAR_UNIT_GRUNT));
  Assert.AreEqual(WAR_UNIT_CHURCH, TWarUnitProducers.ProducerOf(WAR_UNIT_CLERIC));
  Assert.AreEqual(WAR_UNIT_TEMPLE, TWarUnitProducers.ProducerOf(WAR_UNIT_NECROLYTE));
end;

procedure TTestWarUnitProducers.DovrebbeDareMenoUnoPerCioCheNessunoAddestra;
begin
  Assert.AreEqual(-1, TWarUnitProducers.ProducerOf(WAR_UNIT_TOWNHALL_ORCS));
  Assert.AreEqual(-1, TWarUnitProducers.ProducerOf(WAR_UNIT_SKELETON));
  Assert.AreEqual(-1, TWarUnitProducers.ProducerOf(-5));
  Assert.AreEqual(-1, TWarUnitProducers.ProducerOf(WAR_UNIT_COUNT));
end;

procedure TTestWarUnitProducers.DovrebbeRiconoscereITipiValidi;
begin
  Assert.IsFalse(TWarUnitProducers.IsValidType(-1));
  Assert.IsTrue(TWarUnitProducers.IsValidType(WAR_UNIT_FOOTMAN));
  Assert.IsTrue(TWarUnitProducers.IsValidType(WAR_UNIT_COUNT - 1));
  Assert.IsFalse(TWarUnitProducers.IsValidType(WAR_UNIT_COUNT));
end;

{ TTestWarComputerPlayers }

procedure TTestWarComputerPlayers.Setup;
begin
  FRig := TModelRig.Create(1);
  FPlayers := nil;
  FRig.World.Context.Players[1]^.Gold := 5000;
  FRig.World.Context.Players[1]^.Wood := 5000;
end;

procedure TTestWarComputerPlayers.TearDown;
begin
  // the players belong to the world
  FRig.Free;
end;

procedure TTestWarComputerPlayers.StartAi;
begin
  FPlayers := TWarModelFactory.AttachComputerPlayers(FRig.World, [1]);
end;

procedure TTestWarComputerPlayers.StartDetached;
begin
  // the context holds it (an interface), so it is freed with the world; the world does not run it
  FPlayers := TWarComputerPlayers.Create(FRig.World, TWarAiCommandRegistry.CreateDefault);
  FRig.World.Context.AiProgress := FPlayers;
  FPlayers.AddPlayer(1);
end;

function TTestWarComputerPlayers.TownHall(AX: Integer; APlayer: Byte): Integer;
begin
  Result := FRig.AddBuilding(WAR_UNIT_TOWNHALL_ORCS, AX, 4, APlayer);
end;

function TTestWarComputerPlayers.Environment: TWarAiEnvironment;
begin
  Result := FPlayers.FindPlayer(1).Environment;
end;

function TTestWarComputerPlayers.Request(AUnitType, ACount: Integer; AId: Cardinal): TWarAiCommand;
begin
  Result := TWarAiCommand.Create(AId, WAR_AI_COMMAND_REQUEST);
  Result.UnitType := AUnitType;
  Result.Count := ACount;
end;

function TTestWarComputerPlayers.TrainingsHolding(AHandle: Cardinal): Integer;
var
  LContext: TWarModelContext;
  LIndex: Integer;
begin
  Result := 0;
  LContext := FRig.World.Context;
  for LIndex := 0 to WAR_MODEL_MAX_STATES_PER_TYPE - 1 do
    if LContext.Storage.Occupied[WAR_STATE_TRAIN, LIndex] and
      (PWarStateTrain(LContext.Storage.StateAt(WAR_STATE_TRAIN, LIndex))^.AiCommand = AHandle) then
      Inc(Result);
end;

function TTestWarComputerPlayers.PendingTrain(ASlot: Integer): Boolean;
begin
  Result := FRig.World.Machine.HasPending(ASlot, WAR_STATE_TRAIN);
end;

procedure TTestWarComputerPlayers.DovrebbeRegistrareRichiestaAttesaEPausaMaNonAttaccoEDifesa;
var
  LRegistry: TWarAiCommandRegistry;
begin
  LRegistry := TWarAiCommandRegistry.CreateDefault;
  try
    Assert.IsTrue(LRegistry.HasHandler(WAR_AI_COMMAND_REQUEST));
    Assert.IsTrue(LRegistry.HasHandler(WAR_AI_COMMAND_WAIT));
    Assert.IsTrue(LRegistry.HasHandler(WAR_AI_COMMAND_SLEEP));
    Assert.IsFalse(LRegistry.HasHandler(WAR_AI_COMMAND_ATTACK));
    Assert.IsFalse(LRegistry.HasHandler(WAR_AI_COMMAND_DEFEND));
    Assert.IsFalse(LRegistry.HasHandler(-1));
    Assert.IsFalse(LRegistry.HasHandler(WAR_AI_COMMAND_COUNT));
  finally
    LRegistry.Free;
  end;
end;

procedure TTestWarComputerPlayers.DovrebbeDareUnAvvisoEFinireSubitoPerUnComandoSenzaGestore;
var
  LCommand: TWarAiCommand;
begin
  StartDetached;
  LCommand := TWarAiCommand.Create(99, WAR_AI_COMMAND_ATTACK);
  try
    // the default of the switch of wai_executeAICommand: a warning and "done" (the status stays as it was)
    Assert.IsTrue(FPlayers.Registry.Execute(Environment, LCommand));
    Assert.AreEqual(1, Environment.Warnings);
    Assert.IsTrue(Pos('2', Environment.LastWarning) > 0, 'il tipo nell''avviso');
    Assert.AreEqual(WAR_AI_STATUS_CREATED, LCommand.Status);
    // a type that does not exist at all is the same
    LCommand.Free;
    LCommand := TWarAiCommand.Create(100, 77);
    Assert.IsTrue(FPlayers.Registry.Execute(Environment, LCommand));
    Assert.AreEqual(2, Environment.Warnings);
  finally
    LCommand.Free;
  end;
end;

procedure TTestWarComputerPlayers.DovrebbeFinireSenzaAvvisoUnComandoGiaCompletato;
var
  LCommand: TWarAiCommand;
begin
  StartDetached;
  LCommand := TWarAiCommand.Create(99, WAR_AI_COMMAND_DEFEND);
  try
    LCommand.Status := WAR_AI_STATUS_COMPLETED;
    Assert.IsTrue(FPlayers.Registry.Execute(Environment, LCommand));
    Assert.AreEqual(0, Environment.Warnings);
  finally
    LCommand.Free;
  end;
end;

procedure TTestWarComputerPlayers.DovrebbeSostituireUnGestoreEUsareQuelloNuovo;
var
  LSecond: TCountingHandler;
  LCommand: TWarAiCommand;
begin
  StartDetached;
  LSecond := TCountingHandler.Create(True);
  LCommand := TWarAiCommand.Create(99, WAR_AI_COMMAND_ATTACK);
  try
    FPlayers.Registry.RegisterHandler(WAR_AI_COMMAND_ATTACK, TCountingHandler.Create(False));
    Assert.IsFalse(FPlayers.Registry.Execute(Environment, LCommand));
    // the registry frees the one it replaces
    FPlayers.Registry.RegisterHandler(WAR_AI_COMMAND_ATTACK, LSecond);
    Assert.IsTrue(FPlayers.Registry.Execute(Environment, LCommand));
    Assert.AreEqual(1, LSecond.Calls);
    Assert.AreEqual(0, Environment.Warnings);
  finally
    LCommand.Free;
  end;
end;

procedure TTestWarComputerPlayers.DovrebbeRifiutareUnTipoDiComandoNonValido;
var
  LRegistry: TWarAiCommandRegistry;
begin
  LRegistry := TWarAiCommandRegistry.CreateDefault;
  try
    Assert.WillRaise(
      procedure
      begin
        LRegistry.RegisterHandler(WAR_AI_COMMAND_COUNT, TCountingHandler.Create(True));
      end, EWarException);
    Assert.WillRaise(
      procedure
      begin
        LRegistry.RegisterHandler(-1, TCountingHandler.Create(True));
      end, EWarException);
  finally
    LRegistry.Free;
  end;
end;

procedure TTestWarComputerPlayers.DovrebbeAspettareCheIlGiocatoreAbbiaLeUnita;
var
  LCommand: TWarAiCommand;
begin
  StartDetached;
  TownHall(4);
  LCommand := TWarAiCommand.Create(99, WAR_AI_COMMAND_WAIT);
  try
    LCommand.UnitType := WAR_UNIT_TOWNHALL_ORCS;
    LCommand.Count := 2;
    Assert.IsFalse(FPlayers.Registry.Execute(Environment, LCommand), 'ne ha uno solo');
    Assert.AreEqual(WAR_AI_STATUS_STARTED, LCommand.Status);
    // one of another player does not count
    TownHall(12, 2);
    Assert.IsFalse(FPlayers.Registry.Execute(Environment, LCommand));
    TownHall(20);
    Assert.IsTrue(FPlayers.Registry.Execute(Environment, LCommand));
    Assert.AreEqual(WAR_AI_STATUS_COMPLETED, LCommand.Status);
  finally
    LCommand.Free;
  end;
end;

procedure TTestWarComputerPlayers.DovrebbeAspettareIlTempoRealeDellaPausa;
var
  LCommand: TWarAiCommand;
begin
  StartDetached;
  LCommand := TWarAiCommand.Create(99, WAR_AI_COMMAND_SLEEP);
  try
    LCommand.EndRealTime := 10.0;
    FRig.World.Context.RealTime := 9.99;
    Assert.IsFalse(FPlayers.Registry.Execute(Environment, LCommand));
    Assert.AreEqual(WAR_AI_STATUS_STARTED, LCommand.Status);
    // the time of the game does not count: only the real one
    FRig.World.Context.Clock^.GameTime := 1000;
    Assert.IsFalse(FPlayers.Registry.Execute(Environment, LCommand));
    FRig.World.Context.RealTime := 10.0;
    Assert.IsTrue(FPlayers.Registry.Execute(Environment, LCommand));
    Assert.AreEqual(WAR_AI_STATUS_COMPLETED, LCommand.Status);
  finally
    LCommand.Free;
  end;
end;

procedure TTestWarComputerPlayers.DovrebbeDareUnEdificioPerFattoSenzaCostruireNiente;
var
  LCommand: TWarAiCommand;
  LEntities: Integer;
begin
  StartDetached;
  LEntities := FRig.World.Context.Pool.EntityCount;
  LCommand := Request(WAR_UNIT_FARM_ORCS, 2);
  try
    // the original only has the plan of what it would do: the request counts the building and nothing appears
    Assert.IsTrue(FPlayers.Registry.Execute(Environment, LCommand));
    Assert.AreEqual(WAR_AI_STATUS_STARTED, LCommand.Status);
    Assert.AreEqual(1, LCommand.Count);
    Assert.IsTrue(FPlayers.Registry.Execute(Environment, LCommand));
    Assert.AreEqual(WAR_AI_STATUS_COMPLETED, LCommand.Status);
    Assert.AreEqual(LEntities, FRig.World.Context.Pool.EntityCount);
    Assert.AreEqual(5000, FRig.World.Context.Players[1]^.Gold, 'nessun costo');
  finally
    LCommand.Free;
  end;
end;

procedure TTestWarComputerPlayers.DovrebbeAddestrareUnaUnitaCollegandoLaRichiestaAlloStato;
var
  LCommand: TWarAiCommand;
  LSlot: Integer;
  LContext: TWarModelContext;
  LCost: TWarUnitStatsFull;
begin
  StartDetached;
  LSlot := TownHall(4);
  LContext := FRig.World.Context;
  LCost := LContext.Database.GetUnitStats(WAR_UNIT_PEON);
  LCommand := Request(WAR_UNIT_PEON, 2, 7);
  try
    Assert.IsTrue(FPlayers.Registry.Execute(Environment, LCommand));
    Assert.IsTrue(PendingTrain(LSlot), 'l''ordine aspetta il tic');
    Assert.AreEqual(5000, LContext.Players[1]^.Gold, 'il costo si paga all''ingresso nello stato');
    Assert.AreEqual(1, TrainingsHolding(TWarAiCommand.MakeHandle(1, 7)), 'lo stato porta la richiesta');
    Assert.AreEqual(WAR_AI_STATUS_STARTED, LCommand.Status);
    Assert.AreEqual(2, LCommand.Count);
    FRig.Tick;
    Assert.AreEqual(5000 - LCost.GoldCost, LContext.Players[1]^.Gold);
    Assert.AreEqual(0, TrainingsHolding(TWarAiCommand.MakeHandle(1, 7)), 'la richiesta e'' stata contata una volta');
  finally
    LCommand.Free;
  end;
end;

procedure TTestWarComputerPlayers.DovrebbeContareLUnitaQuandoSiPagaNonQuandoNasce;
var
  LPlayer: TWarComputerPlayer;
  LCommand: TWarAiCommand;
begin
  StartDetached;
  TownHall(4);
  LPlayer := FPlayers.FindPlayer(1);
  LCommand := LPlayer.NewCommand(WAR_AI_COMMAND_REQUEST);
  LCommand.UnitType := WAR_UNIT_PEON;
  LCommand.Count := 2;
  LPlayer.Enqueue(LCommand);
  // two updates of the player: the first moves the command to the running ones (and the script starts), the second runs it
  LPlayer.Update;
  LPlayer.Update;
  Assert.AreEqual(2, LCommand.Count, 'ordinata ma non ancora pagata');
  FRig.Tick;
  Assert.AreEqual(1, LCommand.Count, 'pagata: conta');
  Assert.AreEqual(0, FRig.World.Queries.CountUnitsOfType(1, WAR_UNIT_PEON), 'non e'' ancora nata');
  FRig.Run(60);
  Assert.AreEqual(1, FRig.World.Queries.CountUnitsOfType(1, WAR_UNIT_PEON), 'nata');
  Assert.AreEqual(1, LCommand.Count, 'la nascita non conta un''altra volta');
end;

procedure TTestWarComputerPlayers.DovrebbeContareLUnitaAncheSeLAddestramentoViene;
var
  LPlayer: TWarComputerPlayer;
  LCommand: TWarAiCommand;
  LSlot: Integer;
  LCommands: TWarCommands;
begin
  // defect of the original, kept: the unit counts when the cost is charged, so cancelling the training (which gives the
  // money back) leaves the request one unit shorter
  StartDetached;
  LSlot := TownHall(4);
  LPlayer := FPlayers.FindPlayer(1);
  LCommand := LPlayer.NewCommand(WAR_AI_COMMAND_REQUEST);
  LCommand.UnitType := WAR_UNIT_PEON;
  LCommand.Count := 2;
  LPlayer.Enqueue(LCommand);
  LCommands := TWarModelFactory.CreateCommands(FRig.World);
  try
    // the first update runs the command (it is moved among the running ones), the second is its turn
    LPlayer.Update;
    LPlayer.Update;
    FRig.Tick;
    Assert.AreEqual(1, LCommand.Count);
    Assert.IsTrue(LCommands.Construction.Cancel(LSlot));
    FRig.Tick(3);
    Assert.AreEqual(5000, FRig.World.Context.Players[1]^.Gold, 'il denaro e'' tornato');
    Assert.AreEqual(1, LCommand.Count, 'la richiesta no');
  finally
    LCommands.Free;
  end;
end;

procedure TTestWarComputerPlayers.DovrebbeRiprovareFinoAvereOro;
var
  LCommand: TWarAiCommand;
  LSlot: Integer;
begin
  StartDetached;
  LSlot := TownHall(4);
  FRig.World.Context.Players[1]^.Gold := 0;
  LCommand := Request(WAR_UNIT_PEON, 1);
  try
    FPlayers.Registry.Execute(Environment, LCommand);
    Assert.IsFalse(PendingTrain(LSlot));
    Assert.AreEqual(WAR_AI_STATUS_STARTED, LCommand.Status, 'la richiesta vive');
    FRig.World.Context.Players[1]^.Gold := 5000;
    FPlayers.Registry.Execute(Environment, LCommand);
    Assert.IsTrue(PendingTrain(LSlot));
  finally
    LCommand.Free;
  end;
end;

procedure TTestWarComputerPlayers.DovrebbeRiprovareFinoAvereCibo;
var
  LCommand: TWarAiCommand;
  LSlot: Integer;
begin
  StartDetached;
  LSlot := TownHall(4);
  // no farm: room for one dude (the town hall feeds one); a peon is there already
  FRig.AddDude(WAR_UNIT_PEON, 10, 10, 1);
  LCommand := Request(WAR_UNIT_PEON, 1);
  try
    FPlayers.Registry.Execute(Environment, LCommand);
    Assert.IsFalse(PendingTrain(LSlot), 'senza cibo');
    Assert.AreEqual<Cardinal>(0, FRig.Observer.FlashCount, 'senza il messaggio che da'' l''ordine del giocatore');
    FRig.AddBuilding(WAR_UNIT_FARM_ORCS, 20, 4, 1);
    FPlayers.Registry.Execute(Environment, LCommand);
    Assert.IsTrue(PendingTrain(LSlot));
  finally
    LCommand.Free;
  end;
end;

procedure TTestWarComputerPlayers.DovrebbeRiprovareFinoAvereUnEdificio;
var
  LCommand: TWarAiCommand;
  LSlot: Integer;
begin
  StartDetached;
  LCommand := Request(WAR_UNIT_PEON, 1);
  try
    FPlayers.Registry.Execute(Environment, LCommand);
    Assert.AreEqual(0, FRig.World.Context.Storage.ActiveCount[WAR_STATE_TRAIN], 'nessuno stato creato');
    Assert.AreEqual(WAR_AI_STATUS_STARTED, LCommand.Status);
    // a building of another player is not a building of the AI
    TownHall(4, 2);
    FPlayers.Registry.Execute(Environment, LCommand);
    Assert.AreEqual(0, FRig.World.Context.Storage.ActiveCount[WAR_STATE_TRAIN]);
    LSlot := TownHall(12);
    FPlayers.Registry.Execute(Environment, LCommand);
    Assert.IsTrue(PendingTrain(LSlot));
  finally
    LCommand.Free;
  end;
end;

procedure TTestWarComputerPlayers.DovrebbeScegliereIlPrimoEdificioLiberoDelGiocatore;
var
  LOther: Integer;
  LFirst: Integer;
  LSecond: Integer;
  LCommand: TWarAiCommand;
begin
  StartDetached;
  LOther := TownHall(4, 2);
  LFirst := TownHall(12);
  LSecond := TownHall(20);
  LCommand := Request(WAR_UNIT_PEON, 2);
  try
    FPlayers.Registry.Execute(Environment, LCommand);
    Assert.IsFalse(PendingTrain(LOther), 'no a quello di un altro');
    Assert.IsTrue(PendingTrain(LFirst), 'il primo della lista');
    Assert.IsFalse(PendingTrain(LSecond));
    // the first is busy now (its request is not "unresolved" any more once it is paid): the next one is used
    FRig.Tick;
    FPlayers.Registry.Execute(Environment, LCommand);
    Assert.IsTrue(PendingTrain(LSecond), 'il secondo, perche'' il primo addestra');
  finally
    LCommand.Free;
  end;
end;

procedure TTestWarComputerPlayers.DovrebbeAddestrareUnaSolaVoltaPerRichiestaNelloStessoTic;
var
  LFirst: Integer;
  LSecond: Integer;
  LCommand: TWarAiCommand;
begin
  StartDetached;
  LFirst := TownHall(4);
  LSecond := TownHall(12);
  LCommand := Request(WAR_UNIT_PEON, 2, 5);
  try
    FPlayers.Registry.Execute(Environment, LCommand);
    FPlayers.Registry.Execute(Environment, LCommand);
    FPlayers.Registry.Execute(Environment, LCommand);
    Assert.IsTrue(PendingTrain(LFirst));
    Assert.IsFalse(PendingTrain(LSecond), 'una richiesta non risolta non ne chiede un''altra');
    Assert.AreEqual(1, TrainingsHolding(TWarAiCommand.MakeHandle(1, 5)));
  finally
    LCommand.Free;
  end;
end;

procedure TTestWarComputerPlayers.DovrebbeUsareUnEdificioInCostruzioneComeFaIlC;
var
  LSlot: Integer;
  LCommand: TWarAiCommand;
  LWait: TWarAiCommand;
begin
  // defect of the original, kept: the AI does not look whether the building is finished (a state of construction accepts
  // the order of the AI, and the training replaces it)
  StartDetached;
  LSlot := FRig.World.Entities.CreateBuilding(WAR_UNIT_TOWNHALL_ORCS, 4, 4, 1, True);
  FRig.Tick;
  Assert.IsTrue(FRig.World.Machine.IsBuilding(LSlot), 'si sta costruendo');
  LCommand := Request(WAR_UNIT_PEON, 1);
  LWait := TWarAiCommand.Create(91, WAR_AI_COMMAND_WAIT);
  try
    FPlayers.Registry.Execute(Environment, LCommand);
    Assert.IsTrue(PendingTrain(LSlot));
    // and the wait for a town hall is satisfied by one that is only a building site
    LWait.UnitType := WAR_UNIT_TOWNHALL_ORCS;
    LWait.Count := 1;
    Assert.IsTrue(FPlayers.Registry.Execute(Environment, LWait));
  finally
    LWait.Free;
    LCommand.Free;
  end;
end;

procedure TTestWarComputerPlayers.DovrebbeDareUnAvvisoPerUnTipoDiUnitaSconosciuto;
var
  LCommand: TWarAiCommand;
begin
  StartDetached;
  LCommand := Request(WAR_UNIT_HUMAN_CORPSE, 1);
  try
    // neither a dude nor a building: the original logs a warning and the request stays
    Assert.IsTrue(FPlayers.Registry.Execute(Environment, LCommand));
    Assert.AreEqual(1, Environment.Warnings);
    Assert.AreEqual(WAR_AI_STATUS_STARTED, LCommand.Status);
    Assert.AreEqual(1, LCommand.Count);
  finally
    LCommand.Free;
  end;
end;

procedure TTestWarComputerPlayers.DovrebbeLasciareSenzaRichiestaLoStatoDiUnOrdineDelGiocatore;
var
  LSlot: Integer;
  LCommands: TWarCommands;
begin
  StartDetached;
  LSlot := TownHall(4);
  LCommands := TWarModelFactory.CreateCommands(FRig.World);
  try
    Assert.IsTrue(LCommands.Construction.OrderTrain(LSlot, WAR_UNIT_PEON, WAR_CAUSE_PLAYER_ORDER));
    Assert.IsTrue(PendingTrain(LSlot));
    // a training that no AI request ordered holds no handle: paying it tells nobody
    Assert.AreEqual(1, TrainingsHolding(0));
    Assert.AreEqual(0, TrainingsHolding(TWarAiCommand.MakeHandle(1, 1)));
    FRig.Tick;
    Assert.AreEqual(0, FRig.World.Context.Players[1]^.Gold - 5000 + FRig.World.Context.Database.GetUnitStats(WAR_UNIT_PEON).GoldCost);
  finally
    LCommands.Free;
  end;
end;

procedure TTestWarComputerPlayers.DovrebbeSeguireIlCopioneNeiPrimiTic;
var
  LPlayer: TWarComputerPlayer;
begin
  TownHall(4);
  StartAi;
  LPlayer := FPlayers.FindPlayer(1);
  Assert.AreEqual<Cardinal>(6, LPlayer.StaticCommandId, 'i sei comandi del copione hanno gli id da 1 a 6');
  Assert.AreEqual(0, LPlayer.CurrentCount);
  FRig.Tick;
  Assert.AreEqual(1, LPlayer.CurrentCount);
  Assert.AreEqual(1, LPlayer.ScriptIndex);
  Assert.AreEqual(WAR_AI_COMMAND_REQUEST, LPlayer.Current[0].CommandType);
  Assert.AreEqual(WAR_UNIT_TOWNHALL_ORCS, LPlayer.Current[0].UnitType);
  // the request of a building is done at once and leaves, the wait for it takes its place
  FRig.Tick;
  Assert.AreEqual(2, LPlayer.ScriptIndex);
  Assert.AreEqual(1, LPlayer.CurrentCount);
  Assert.AreEqual(WAR_AI_COMMAND_WAIT, LPlayer.Current[0].CommandType);
  // the town hall is there: the wait ends and the request of two peons arrives
  FRig.Tick;
  Assert.AreEqual(3, LPlayer.ScriptIndex);
  Assert.AreEqual(1, LPlayer.CurrentCount);
  Assert.AreEqual(WAR_AI_COMMAND_REQUEST, LPlayer.Current[0].CommandType);
  Assert.AreEqual(WAR_UNIT_PEON, LPlayer.Current[0].UnitType);
  // it runs (a request always lets the script go on): the wait for two peons joins it
  FRig.Tick;
  Assert.AreEqual(4, LPlayer.ScriptIndex);
  Assert.AreEqual(2, LPlayer.CurrentCount);
  Assert.AreEqual(WAR_AI_COMMAND_WAIT, LPlayer.Current[1].CommandType);
  Assert.AreEqual(0, Environment.Warnings);
end;

procedure TTestWarComputerPlayers.DovrebbeUsareLeUnitaDellaRazzaDelGiocatore;
const
  RACES: array[0..2] of TWarRace = (wraNeutral, wraHumans, wraOrcs);
  TOWN_HALLS: array[0..2] of Integer = (WAR_UNIT_TOWNHALL_HUMANS, WAR_UNIT_TOWNHALL_HUMANS, WAR_UNIT_TOWNHALL_ORCS);
  WORKERS: array[0..2] of Integer = (WAR_UNIT_PEASANT, WAR_UNIT_PEASANT, WAR_UNIT_PEON);
var
  LRace: Integer;
  LRig: TModelRig;
  LPlayers: TWarComputerPlayers;
begin
  // the neutral race has no types of its own: the original logs a warning and keeps the ones of the humans
  for LRace := 0 to 2 do
  begin
    LRig := TModelRig.Create(1);
    try
      LRig.World.Context.Players[1]^.Race := RACES[LRace];
      LPlayers := TWarModelFactory.AttachComputerPlayers(LRig.World, [1]);
      Assert.AreEqual(TOWN_HALLS[LRace], LPlayers.FindPlayer(1).FindCommand(1).UnitType, 'municipio');
      Assert.AreEqual(WORKERS[LRace], LPlayers.FindPlayer(1).FindCommand(3).UnitType, 'operaio');
      Assert.AreEqual(4, LPlayers.FindPlayer(1).FindCommand(6).Count);
    finally
      LRig.Free;
    end;
  end;
end;

procedure TTestWarComputerPlayers.DovrebbeRestareFermoSullAttesaSenzaMunicipio;
var
  LPlayer: TWarComputerPlayer;
begin
  StartAi;
  LPlayer := FPlayers.FindPlayer(1);
  FRig.Tick(40);
  Assert.AreEqual(2, LPlayer.ScriptIndex, 'ferma sull''attesa del municipio');
  Assert.AreEqual(1, LPlayer.CurrentCount);
  Assert.AreEqual<Cardinal>(6, LPlayer.StaticCommandId, 'nessuna pausa: il copione non e'' finito');
  Assert.AreEqual(WAR_AI_STATUS_STARTED, LPlayer.Current[0].Status);
  Assert.AreEqual(0, Environment.Warnings);
end;

procedure TTestWarComputerPlayers.DovrebbeDormireDopoIlCopioneELiberareLePause;
var
  LPlayer: TWarComputerPlayer;
  LTic: Integer;
  LFarm: Integer;
begin
  TownHall(4);
  for LFarm := 0 to 2 do
    FRig.AddBuilding(WAR_UNIT_FARM_ORCS, 20 + 4 * LFarm, 4, 1);
  StartAi;
  LPlayer := FPlayers.FindPlayer(1);
  LTic := 0;
  // the real time stays at 0: the first pause ends at 10 seconds of real time
  while (LPlayer.StaticCommandId = 6) and (LTic < 30000) do
  begin
    FRig.World.Context.Players[1]^.Gold := 5000;
    FRig.World.Context.Players[1]^.Wood := 5000;
    FRig.Tick;
    Inc(LTic);
  end;
  Assert.AreEqual(6, LPlayer.ScriptIndex, 'il copione e'' finito');
  Assert.AreEqual<Cardinal>(7, LPlayer.StaticCommandId, 'la prima pausa');
  Assert.AreEqual(4, FRig.World.Queries.CountUnitsOfType(1, WAR_UNIT_PEON), 'i quattro operai del copione');
  FRig.Tick(10);
  Assert.AreEqual(1, LPlayer.CurrentCount);
  Assert.AreEqual(WAR_AI_COMMAND_SLEEP, LPlayer.Current[0].CommandType);
  Assert.AreEqual(10.0, LPlayer.Current[0].EndRealTime, 0.0);
  // the pause ends at the real time: the next one is made and the old one leaves (the original keeps them all)
  FRig.World.Context.RealTime := 10.0;
  FRig.Tick;
  Assert.AreEqual(1, LPlayer.CurrentCount);
  Assert.AreEqual<Cardinal>(8, LPlayer.Current[0].Id);
  Assert.AreEqual(20.0, LPlayer.Current[0].EndRealTime, 0.0);
end;

procedure TTestWarComputerPlayers.DovrebbeEseguireUnComandoDiUnTipoRegistratoDopo;
var
  LHandler: TCountingHandler;
  LPlayer: TWarComputerPlayer;
begin
  TownHall(4);
  StartAi;
  LPlayer := FPlayers.FindPlayer(1);
  LHandler := TCountingHandler.Create(True);
  FPlayers.Registry.RegisterHandler(WAR_AI_COMMAND_ATTACK, LHandler);
  LPlayer.Enqueue(LPlayer.NewCommand(WAR_AI_COMMAND_ATTACK));
  FRig.Tick;
  Assert.AreEqual(0, LHandler.Calls, 'entra tra i comandi in corso');
  FRig.Tick(3);
  Assert.IsTrue(LHandler.Calls >= 3, 'e'' eseguito a ogni tic');
end;

procedure TTestWarComputerPlayers.DovrebbeIgnorareIlProgressoDiUnaManigliaSconosciuta;
begin
  StartAi;
  // no request, a player that nobody plays, a command that does not exist: nothing happens
  FPlayers.UnitRequestProgress(0);
  FPlayers.UnitRequestProgress(TWarAiCommand.MakeHandle(3, 1));
  FPlayers.UnitRequestProgress(TWarAiCommand.MakeHandle(1, 999));
  Assert.AreEqual(2, FPlayers.FindPlayer(1).FindCommand(3).Count);
end;

procedure TTestWarComputerPlayers.DovrebbeContareIlProgressoDiUnaManigliaDelCopione;
begin
  StartAi;
  FPlayers.UnitRequestProgress(TWarAiCommand.MakeHandle(1, 3));
  Assert.AreEqual(1, FPlayers.FindPlayer(1).FindCommand(3).Count);
  Assert.AreEqual(WAR_AI_STATUS_STARTED, FPlayers.FindPlayer(1).FindCommand(3).Status);
  Assert.IsTrue(FPlayers.FindPlayer(1).FindCommand(500) = nil, 'nessun comando 500');
  Assert.IsTrue(FPlayers.FindPlayer(2) = nil, 'il giocatore 2 e'' di una persona');
end;

procedure TTestWarComputerPlayers.DovrebbeRifiutareUnGiocatoreDueVolteOFuoriDalGioco;
begin
  StartAi;
  Assert.WillRaise(
    procedure
    begin
      FPlayers.AddPlayer(1);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      FPlayers.AddPlayer(9);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      FPlayers.AddPlayer(-1);
    end, EWarException);
  FPlayers.AddPlayer(2);
  Assert.AreEqual(2, FPlayers.Count);
end;

procedure TTestWarComputerPlayers.DovrebbeRifiutareDueVolteLaStessaAttivazione;
begin
  StartAi;
  Assert.WillRaise(
    procedure
    begin
      TWarModelFactory.AttachComputerPlayers(FRig.World, [2]);
    end, EWarException);
end;

procedure TTestWarComputerPlayers.DovrebbeSegnalareIndiciFuoriDaiLimiti;
begin
  StartAi;
  Assert.WillRaise(
    procedure
    begin
      FPlayers.Players[3].Update;
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      FPlayers.Players[0].Current[7].ApplyUnitRequestProgress;
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      TWarComputerPlayer.Create(nil, nil);
    end, EWarException);
  Assert.WillRaise(
    procedure
    begin
      TWarComputerPlayers.Create(nil, nil);
    end, EWarException);
end;

procedure TTestWarComputerPlayers.DovrebbeNonFarNullaSeNessunoGiocaIlComputer;
begin
  TownHall(4);
  FPlayers := TWarModelFactory.AttachComputerPlayers(FRig.World, []);
  Assert.AreEqual(0, FPlayers.Count);
  FRig.Tick(10);
  Assert.AreEqual(0, FRig.World.Context.Storage.ActiveCount[WAR_STATE_TRAIN]);
end;

end.