{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the keen library - the functions of the states,    }
{  the spawners and the score box                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.GameActions;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes,
  DelphiDoom.Keen.InputTypes, DelphiDoom.Keen.Intf, DelphiDoom.Keen.GameActions, DelphiDoom.Keen.PlayState,
  DelphiDoom.Tests.Keen.GameWorld;

type
  /// <summary>The view of the actions for a test: fixed tics and time, an origin that the test sets, and the sprites placed</summary>
  TTestActionView = class(TInterfacedObject, IKeenActionView)
  strict private
    FOriginX: Integer;
    FOriginY: Integer;
  public
    Placed: Integer;
    function GetTics: Integer;
    function GetLastTimeCount: Integer;
    function GetTimeCount: Integer;
    function GetOriginXGlobal: Integer;
    function GetOriginYGlobal: Integer;
    function GetOriginXTile: Integer;
    function GetOriginYTile: Integer;
    function GetOriginXTileMax: Integer;
    function GetOriginYTileMax: Integer;
    procedure PlaceSprite(var AUser: TKeenSpriteHandle; AGlobalX, AGlobalY, ASpriteChunk, APriority: Integer);
    procedure RemoveSprite(var AUser: TKeenSpriteHandle);
    procedure SetOrigin(AX, AY: Integer);
    property OriginXGlobal: Integer read FOriginX;
    property OriginYGlobal: Integer read FOriginY;
  end;

  [TestFixture]
  [Category('keen')]
  TTestKeenGameActions = class(TObject)
  strict private
    FWorld: TKeenTestWorld;
    FPlay: IKeenPlayState;
    FView: TTestActionView;
    FViewIntf: IKeenActionView;
    FContext: IKeenActionContext;
    FGame: TKeenGameActions;
    FActions: IKeenActions;
    procedure Press(AXAxis, AYAxis: Integer; AButton0, AButton1: Boolean);
    function NewActor(AClass: TKeenClass; AState: Integer; APixelX, APixelY: Integer): PKeenObject;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeFareIlGiocatoreInStatoDiAttesa;
    [Test]
    procedure DovrebbeFareKeenDellaMappaDelMondoDallaPosizioneSalvata;
    [Test]
    procedure DovrebbeFareKeenDellaMappaDelMondoDalPuntoDiPartenza;
    [Test]
    procedure DovrebbeAlzareDiUnBloccoIlFioreDelBonus;
    [Test]
    procedure DovrebbeDareQuattroFotogrammiAlSuperBonus;
    [Test]
    procedure DovrebbeFareOgniAttoreNellaClasseENelloStatoGiusti;
    [Test]
    procedure DovrebbeDareLaDirezioneAMelonLips;
    [Test]
    procedure DovrebbeDareUnaEccezioneAUnaFunzioneSenzaCodice;
    [Test]
    procedure DovrebbeLeggereZeroFuoriDallaMappa;
    [Test]
    procedure DovrebbeDareUnaVitaExtraAVentimilaPunti;
    [Test]
    procedure DovrebbeMettereIlGiocatoreNellaCamminataConLaDirezione;
    [Test]
    procedure DovrebbeSaltareDritto;
    [Test]
    procedure DovrebbeNonSaltareSeIlPulsanteEraGiaPremuto;
    [Test]
    procedure DovrebbeLanciareIlFioreAdEst;
    [Test]
    procedure DovrebbeNonLanciareSenzaFiori;
    [Test]
    procedure DovrebbeModificareL_UltimoAttoreSeIlLancioInAriaNonHaFiori;
    [Test]
    procedure DovrebbeUsareLeBombeNelLivelloQuindici;
    [Test]
    procedure DovrebbeNonUccidereKeenInGodMode;
    [Test]
    procedure DovrebbeUccidereKeenFuoriDaGodMode;
    [Test]
    procedure DovrebbeRaccogliereUnBonusDiPunti;
    [Test]
    procedure DovrebbeRaccogliereLaChiaveEAprireLaPorta;
    [Test]
    procedure DovrebbeSpingereKeenViaDaUnaPortaSenzaChiavi;
    [Test]
    procedure DovrebbeUccidereKeenConUnPomodoro;
    [Test]
    procedure DovrebbeTrasformareUnNemicoInFiore;
    [Test]
    procedure DovrebbeTornareNemicoQuandoIlFioreFinisce;
    [Test]
    procedure DovrebbeEntrareNelLivelloDallaMappaDelMondo;
    [Test]
    procedure DovrebbeChiedereLeBombePerIlLivelloDelRe;
    [Test]
    procedure DovrebbeLasciareChiDormeRimuovereGliZ;
    [Test]
    procedure DovrebbeUsareLeFasceDellaPendenzaNelFondoDelRimbalzo;
    [Test]
    procedure DovrebbeRimuovereIlProiettileChePerdeForza;
    [Test]
    procedure DovrebbeFarEsplodereBoobusAlleBombe;
    [Test]
    procedure DovrebbeDisegnareLeCifreDelPunteggio;
    [Test]
    procedure DovrebbeAggiornarePunteggioFioriEVite;
    [Test]
    procedure DovrebbeDisegnareIlFioreOLaBombaNellaScatola;
    [Test]
    procedure DovrebbeFarePartireIlPuntoDellaMappaDelloScanner;
    [Test]
    procedure DovrebbeDareLeMisureDellaVistaAlleAzioni;
    [Test]
    procedure DovrebbeInoltrareLeFunzioniDiMovimentoAlMotore;
    [Test]
    procedure DovrebbePosareERimuovereGliSpriteSulGestoreDelloSchermo;
    [Test]
    procedure DovrebbeRispondereAlleInterfacceSenzaContareIRiferimenti;
    [Test]
    procedure DovrebbeRifiutareIParametriNulli;
  end;

implementation

uses
  DelphiDoom.Keen.ActionIds, DelphiDoom.Keen.AudioIds, DelphiDoom.Keen.GraphicsIds, DelphiDoom.Keen.StateTable,
  DelphiDoom.Keen.StateTypes, DelphiDoom.Keen.ActionContext, DelphiDoom.Keen.ActionAdapters,
  DelphiDoom.Keen.LevelScanner, DelphiDoom.Keen.ScoreBox, DelphiDoom.Keen.CommonActions,
  DelphiDoom.Tests.Keen.GameFakes, DelphiDoom.Tests.Keen.VideoFakes;

type
  /// <summary>A sprite cache with only the score box: a sprite of 8 bytes by 40 rows with its three shifted copies</summary>
  TScoreSpriteCache = class(TInterfacedObject, IKeenSpriteCache)
  strict private
    FSprite: TKeenSprite;
    FEntry: TKeenSpriteEntry;
  public
    constructor Create;
    function GetSprite(ASpriteChunk: Integer): TKeenSprite;
    function GetEntry(ASpriteChunk: Integer): TKeenSpriteEntry;
  end;

type
  /// <summary>The motion of the actors for a test: a new state changes the state and the shape, and nothing moves</summary>
  TTestPhysics = class(TInterfacedObject, IKeenActorPhysics)
  strict private
    FStates: IKeenStateTable;
  public
    Clips: Integer;
    constructor Create(const AStates: IKeenStateTable);
    procedure ClipToWalls(AObject: PKeenObject);
    procedure ClipToSprite(APush, ASolid: PKeenObject; ASquish: Boolean);
    procedure ClipToSpriteSide(APush, ASolid: PKeenObject);
    procedure NewState(AObject: PKeenObject; AState: Integer);
  end;

{ TTestPhysics }

constructor TTestPhysics.Create(const AStates: IKeenStateTable);
begin
  inherited Create;
  FStates := AStates;
end;

procedure TTestPhysics.ClipToWalls(AObject: PKeenObject);
begin
  Inc(Clips);
end;

procedure TTestPhysics.ClipToSprite(APush, ASolid: PKeenObject; ASquish: Boolean);
begin
end;

procedure TTestPhysics.ClipToSpriteSide(APush, ASolid: PKeenObject);
begin
end;

procedure TTestPhysics.NewState(AObject: PKeenObject; AState: Integer);
var
  LDef: TKeenStateDef;
begin
  AObject^.State := AState;
  LDef := FStates[AState];
  if LDef.RightShape <> 0 then
  begin
    if AObject^.XDir > 0 then
      AObject^.ShapeNum := Word(LDef.RightShape)
    else
      AObject^.ShapeNum := Word(LDef.LeftShape);
  end;
end;
{ TScoreSpriteCache }

constructor TScoreSpriteCache.Create;
var
  LShift: Integer;
begin
  inherited Create;
  FEntry.Width := 8;
  FEntry.Height := 40;
  FEntry.Shifts := 4;
  SetLength(FSprite.Data, 5 * 320 + 3 * 5 * 9 * 40);
  FSprite.SourceOffset[0] := 0;
  FSprite.PlaneSize[0] := 320;
  FSprite.Width[0] := 8;
  for LShift := 1 to 3 do
  begin
    FSprite.SourceOffset[LShift] := 1600 + (LShift - 1) * 1800;
    FSprite.PlaneSize[LShift] := 360;
    FSprite.Width[LShift] := 9;
  end;
end;

function TScoreSpriteCache.GetSprite(ASpriteChunk: Integer): TKeenSprite;
begin
  Result := FSprite;
end;

function TScoreSpriteCache.GetEntry(ASpriteChunk: Integer): TKeenSpriteEntry;
begin
  Result := FEntry;
end;

{ TTestActionView }

function TTestActionView.GetTics: Integer;
begin
  Result := 2;
end;

function TTestActionView.GetLastTimeCount: Integer;
begin
  Result := 101;
end;

function TTestActionView.GetTimeCount: Integer;
begin
  Result := 101;
end;

function TTestActionView.GetOriginXGlobal: Integer;
begin
  Result := FOriginX;
end;

function TTestActionView.GetOriginYGlobal: Integer;
begin
  Result := FOriginY;
end;

function TTestActionView.GetOriginXTile: Integer;
begin
  Result := FOriginX shr 8;
end;

function TTestActionView.GetOriginYTile: Integer;
begin
  Result := FOriginY shr 8;
end;

function TTestActionView.GetOriginXTileMax: Integer;
begin
  Result := GetOriginXTile + KEEN_PORTTILESWIDE - 1;
end;

function TTestActionView.GetOriginYTileMax: Integer;
begin
  Result := GetOriginYTile + KEEN_PORTTILESHIGH - 1;
end;

procedure TTestActionView.PlaceSprite(var AUser: TKeenSpriteHandle; AGlobalX, AGlobalY, ASpriteChunk,
  APriority: Integer);
begin
  Inc(Placed);
  AUser := 1;
end;

procedure TTestActionView.RemoveSprite(var AUser: TKeenSpriteHandle);
begin
  AUser := 0;
end;

procedure TTestActionView.SetOrigin(AX, AY: Integer);
begin
  FOriginX := AX;
  FOriginY := AY;
end;

{ TTestKeenGameActions }

procedure TTestKeenGameActions.Setup;
begin
  FWorld := TKeenTestWorld.Create(40, 30, KEEN_STATES);
  FPlay := TKeenPlayState.Create(FWorld.Events);
  FView := TTestActionView.Create;
  FViewIntf := FView;
  FContext := TKeenActionContext.Create(FWorld.Objects, FWorld.States, FWorld.Random, FWorld.Events, FViewIntf,
    TTestPhysics.Create(FWorld.States), FPlay, FWorld.Map, FWorld.TileInfo);
  FGame := TKeenGameActions.Create(FContext, FWorld.Graphics, FWorld.Sprites);
  FActions := FGame;
  FView.SetOrigin(0, 0);
end;

procedure TTestKeenGameActions.TearDown;
begin
  FActions := nil;
  FGame := nil;
  FContext := nil;
  FPlay := nil;
  FViewIntf := nil;
  FView := nil;
  FWorld.Free;
end;

procedure TTestKeenGameActions.Press(AXAxis, AYAxis: Integer; AButton0, AButton1: Boolean);
var
  LControl: TKeenControlInfo;
begin
  FillChar(LControl, SizeOf(LControl), 0);
  LControl.XAxis := AXAxis;
  LControl.YAxis := AYAxis;
  LControl.Button0 := AButton0;
  LControl.Button1 := AButton1;
  if (AXAxis = 0) and (AYAxis = 0) then
    LControl.Direction := kdNone
  else if AXAxis = 1 then
    LControl.Direction := kdEast
  else if AXAxis = -1 then
    LControl.Direction := kdWest
  else
    LControl.Direction := kdNorth;
  FPlay.Control := LControl;
end;

function TTestKeenGameActions.NewActor(AClass: TKeenClass; AState: Integer; APixelX, APixelY: Integer): PKeenObject;
begin
  Result := FWorld.Objects.GetNewObj(False);
  Result^.ObClass := AClass;
  Result^.X := Word(APixelX * 16);
  Result^.Y := Word(APixelY * 16);
  Result^.XDir := 1;
  FContext.Physics.NewState(Result, AState);
end;

procedure TTestKeenGameActions.DovrebbeFareIlGiocatoreInStatoDiAttesa;
var
  LPlayer: PKeenObject;
begin
  (FActions as IKeenActorSpawner).SpawnKeen(5, 10, -1);
  LPlayer := FWorld.Objects.Player;
  Assert.AreEqual(Ord(kcKeen), Ord(LPlayer^.ObClass));
  Assert.AreEqual(KEEN_STATE_S_KEENSTAND, Integer(LPlayer^.State));
  Assert.AreEqual(5 * 256, Integer(LPlayer^.X));
  Assert.AreEqual(10 * 256 - 256, Integer(LPlayer^.Y));
  Assert.AreEqual(-1, Integer(LPlayer^.XDir));
  Assert.AreEqual(1, Integer(LPlayer^.YDir));
  Assert.IsTrue(LPlayer^.NeedToClip);
  Assert.AreEqual(Integer(KEEN_GFX_KEENSTANDLSPR), Integer(LPlayer^.ShapeNum));
end;

procedure TTestKeenGameActions.DovrebbeFareKeenDellaMappaDelMondoDallaPosizioneSalvata;
var
  LPlayer: PKeenObject;
begin
  FPlay.GameState^.WorldX := 1234;
  FPlay.GameState^.WorldY := 4321;
  (FActions as IKeenActorSpawner).SpawnWorldKeen(3, 4);
  LPlayer := FWorld.Objects.Player;
  Assert.AreEqual(1234, Integer(LPlayer^.X));
  Assert.AreEqual(4321, Integer(LPlayer^.Y));
  Assert.AreEqual(KEEN_STATE_S_WORLDKEEN, Integer(LPlayer^.State));
  Assert.AreEqual(Ord(kdWest), Integer(LPlayer^.Temp1));
  Assert.AreEqual(3, Integer(LPlayer^.Temp2));
end;

procedure TTestKeenGameActions.DovrebbeFareKeenDellaMappaDelMondoDalPuntoDiPartenza;
begin
  (FActions as IKeenActorSpawner).SpawnWorldKeen(3, 4);
  Assert.AreEqual(3 * 256, Integer(FWorld.Objects.Player^.X));
  Assert.AreEqual(4 * 256, Integer(FWorld.Objects.Player^.Y));
  Assert.AreEqual(Integer(3 + KEEN_GFX_WORLDKEENL1SPR - 1), Integer(FWorld.Objects.Player^.ShapeNum), 'feet together');
end;

procedure TTestKeenGameActions.DovrebbeAlzareDiUnBloccoIlFioreDelBonus;
var
  LBonus: PKeenObject;
begin
  (FActions as IKeenActorSpawner).SpawnBonus(6, 7, 9);
  LBonus := FWorld.Objects[2];
  Assert.AreEqual(7 * 256 - 128, Integer(LBonus^.Y));
  Assert.AreEqual(9, Integer(LBonus^.Temp1));
  Assert.AreEqual(Integer(KEEN_GFX_FLOWERPOWERUP1SPR), Integer(LBonus^.Temp2));
  Assert.AreEqual(Integer(KEEN_GFX_FLOWERPOWERUP1SPR) + 2, Integer(LBonus^.Temp3));
  Assert.IsFalse(LBonus^.NeedToClip);
end;

procedure TTestKeenGameActions.DovrebbeDareQuattroFotogrammiAlSuperBonus;
var
  LBonus: PKeenObject;
begin
  (FActions as IKeenActorSpawner).SpawnBonus(6, 7, 7);
  LBonus := FWorld.Objects[2];
  Assert.AreEqual(Integer(LBonus^.Temp2) + 4, Integer(LBonus^.Temp3));
  // the animation goes round the four shapes
  FActions.Think(KEEN_ACTION_BONUSTHINK, LBonus);
  Assert.AreEqual(Integer(LBonus^.Temp2) + 1, Integer(LBonus^.ShapeNum));
  LBonus^.ShapeNum := Word(LBonus^.Temp3 - 1);
  FActions.Think(KEEN_ACTION_BONUSTHINK, LBonus);
  Assert.AreEqual(Integer(LBonus^.Temp2), Integer(LBonus^.ShapeNum));
end;

procedure TTestKeenGameActions.DovrebbeFareOgniAttoreNellaClasseENelloStatoGiusti;
type
  TCase = record
    Call: TProc<IKeenActorSpawner>;
    ObClass: TKeenClass;
    State: Integer;
  end;
var
  LCases: array of TCase;
  LCase: TCase;
  LSpawner: IKeenActorSpawner;
  LIndex: Integer;

  procedure Add(const ACall: TProc<IKeenActorSpawner>; AClass: TKeenClass; AState: Integer);
  begin
    SetLength(LCases, Length(LCases) + 1);
    LCases[High(LCases)].Call := ACall;
    LCases[High(LCases)].ObClass := AClass;
    LCases[High(LCases)].State := AState;
  end;

begin
  LSpawner := FActions as IKeenActorSpawner;
  Add(procedure(S: IKeenActorSpawner) begin S.SpawnDoor(4, 5); end, kcDoor, KEEN_STATE_S_DOOR);
  Add(procedure(S: IKeenActorSpawner) begin S.SpawnBrocco(4, 5); end, kcBrocco, KEEN_STATE_S_BROCCOWALK1);
  Add(procedure(S: IKeenActorSpawner) begin S.SpawnTomat(4, 5); end, kcTomat, KEEN_STATE_S_TOMATBOUNCE);
  Add(procedure(S: IKeenActorSpawner) begin S.SpawnCarrot(4, 5); end, kcCarrot, KEEN_STATE_S_CARROTWALK1);
  Add(procedure(S: IKeenActorSpawner) begin S.SpawnAspar(4, 5); end, kcAspar, KEEN_STATE_S_ASPARWALK1);
  Add(procedure(S: IKeenActorSpawner) begin S.SpawnGrape(4, 5); end, kcGrape, KEEN_STATE_S_GRAPEWAIT);
  Add(procedure(S: IKeenActorSpawner) begin S.SpawnTater(4, 5); end, kcTater, KEEN_STATE_S_TATERWALK1);
  Add(procedure(S: IKeenActorSpawner) begin S.SpawnCart(4, 5); end, kcCart, KEEN_STATE_S_CARTROLL1);
  Add(procedure(S: IKeenActorSpawner) begin S.SpawnFrenchy(4, 5); end, kcFrenchy, KEEN_STATE_S_FRENCHYWALK1);
  Add(procedure(S: IKeenActorSpawner) begin S.SpawnSquasher(4, 5); end, kcSquash, KEEN_STATE_S_SQUASHERWALK1);
  Add(procedure(S: IKeenActorSpawner) begin S.SpawnApel(4, 5); end, kcApel, KEEN_STATE_S_APELWALK1);
  Add(procedure(S: IKeenActorSpawner) begin S.SpawnPeaPod(4, 5); end, kcPeaPod, KEEN_STATE_S_PEAPODWALK1);
  Add(procedure(S: IKeenActorSpawner) begin S.SpawnPeaBrain(4, 5); end, kcPeaBrain, KEEN_STATE_S_PEABRAINWALK1);
  Add(procedure(S: IKeenActorSpawner) begin S.SpawnBoobus(4, 5); end, kcBoobus, KEEN_STATE_S_BOOBUSWALK1);
  for LIndex := 0 to High(LCases) do
  begin
    LCase := LCases[LIndex];
    LCase.Call(LSpawner);
    Assert.AreEqual(Ord(LCase.ObClass), Ord(FWorld.Objects.New^.ObClass), 'class ' + IntToStr(LIndex));
    Assert.AreEqual(LCase.State, Integer(FWorld.Objects.New^.State), 'state ' + IntToStr(LIndex));
    Assert.AreEqual(4 * 256, Integer(FWorld.Objects.New^.X), 'x ' + IntToStr(LIndex));
  end;
  // the boss has 12 hit points and is 11 blocks above where he is placed
  Assert.AreEqual(12, Integer(FWorld.Objects.New^.Temp4));
  Assert.AreEqual(Integer(Word(5 * 256 - 11 * KEEN_BLOCKSIZE)), Integer(FWorld.Objects.New^.Y));
end;

procedure TTestKeenGameActions.DovrebbeDareLaDirezioneAMelonLips;
var
  LSpawner: IKeenActorSpawner;
begin
  LSpawner := FActions as IKeenActorSpawner;
  LSpawner.SpawnMelon(2, 2, 0);
  Assert.AreEqual(-1, Integer(FWorld.Objects.New^.XDir));
  Assert.AreEqual(KEEN_STATE_S_MELONSIDE, Integer(FWorld.Objects.New^.State));
  LSpawner.SpawnMelon(2, 2, 1);
  Assert.AreEqual(1, Integer(FWorld.Objects.New^.XDir));
  LSpawner.SpawnMelon(2, 2, 2);
  Assert.AreEqual(KEEN_STATE_S_MELONDOWN, Integer(FWorld.Objects.New^.State));
  Assert.AreEqual(2, Integer(FWorld.Objects.New^.Temp1));
end;

procedure TTestKeenGameActions.DovrebbeDareUnaEccezioneAUnaFunzioneSenzaCodice;
var
  LObject: PKeenObject;
begin
  LObject := FWorld.Objects.Player;
  Assert.WillRaise(procedure begin FActions.Think(KEEN_ACTION_NONE, LObject); end, EKeenException);
  Assert.WillRaise(procedure begin FActions.Contact(KEEN_ACTION_NONE, LObject, LObject); end, EKeenException);
  Assert.WillRaise(procedure begin FActions.React(999, LObject); end, EKeenException);
  // a think function is not a react function
  Assert.WillRaise(procedure begin FActions.React(KEEN_ACTION_KEENWALKTHINK, LObject); end, EKeenException);
end;

procedure TTestKeenGameActions.DovrebbeLeggereZeroFuoriDallaMappa;
begin
  FWorld.SetTile(3, 3, 1);
  Assert.AreEqual(1, FContext.Tile(1, 3, 3));
  Assert.AreEqual(0, FContext.Tile(1, -1, 3));
  Assert.AreEqual(0, FContext.Tile(1, 3, 30));
  Assert.AreEqual(0, FContext.Tile(1, 40, 0));
  // a tile that the table does not have is no wall
  Assert.AreEqual(0, FContext.NorthWall(5000));
  Assert.AreEqual(0, FContext.InTile(-1));
end;

procedure TTestKeenGameActions.DovrebbeDareUnaVitaExtraAVentimilaPunti;
begin
  FPlay.GameState^.Lives := 3;
  FPlay.GameState^.NextExtra := 20000;
  FPlay.GameState^.Score := 19950;
  FPlay.GivePoints(100);
  Assert.AreEqual(4, Integer(FPlay.GameState^.Lives));
  Assert.AreEqual(40000, FPlay.GameState^.NextExtra);
  Assert.AreEqual(KEEN_SND_EXTRAKEENSND, FWorld.EventsFake.Sounds[0]);
end;

procedure TTestKeenGameActions.DovrebbeMettereIlGiocatoreNellaCamminataConLaDirezione;
var
  LPlayer: PKeenObject;
begin
  (FActions as IKeenActorSpawner).SpawnKeen(5, 10, 1);
  LPlayer := FWorld.Objects.Player;
  FView.SetOrigin(0, 0);
  Press(-1, 0, False, False);
  FActions.Think(KEEN_ACTION_KEENSTANDTHINK, LPlayer);
  Assert.AreEqual(-1, Integer(LPlayer^.XDir));
  Assert.AreEqual(KEEN_STATE_S_KEENWALK1, Integer(LPlayer^.State));
end;

procedure TTestKeenGameActions.DovrebbeSaltareDritto;
var
  LPlayer: PKeenObject;
begin
  (FActions as IKeenActorSpawner).SpawnKeen(5, 10, 1);
  LPlayer := FWorld.Objects.Player;
  Press(0, 0, True, False);
  FActions.Think(KEEN_ACTION_KEENSTANDTHINK, LPlayer);
  Assert.AreEqual(KEEN_STATE_S_KEENJUMPUP1, Integer(LPlayer^.State));
  Assert.AreEqual(-40, Integer(LPlayer^.YSpeed));
  Assert.AreEqual(16, FGame.Player.JumpTime);
  Assert.IsTrue(FPlay.Button0Held);
  Assert.AreEqual(KEEN_SND_JUMPSND, FWorld.EventsFake.Sounds[0]);
end;

procedure TTestKeenGameActions.DovrebbeNonSaltareSeIlPulsanteEraGiaPremuto;
var
  LPlayer: PKeenObject;
begin
  (FActions as IKeenActorSpawner).SpawnKeen(5, 10, 1);
  LPlayer := FWorld.Objects.Player;
  FPlay.Button0Held := True;
  Press(0, 0, True, False);
  FActions.Think(KEEN_ACTION_KEENSTANDTHINK, LPlayer);
  Assert.AreEqual(KEEN_STATE_S_KEENSTAND, Integer(LPlayer^.State));
end;

procedure TTestKeenGameActions.DovrebbeLanciareIlFioreAdEst;
var
  LPlayer: PKeenObject;
  LPower: PKeenObject;
begin
  (FActions as IKeenActorSpawner).SpawnKeen(5, 10, 1);
  LPlayer := FWorld.Objects.Player;
  FPlay.GameState^.FlowerPowers := 3;
  LPlayer^.State := KEEN_STATE_S_KEENTHROW3;
  FActions.Think(KEEN_ACTION_KEENTHROW, LPlayer);
  LPower := FWorld.Objects.New;
  Assert.AreEqual(Ord(kcPower), Ord(LPower^.ObClass));
  Assert.AreEqual(64, Integer(LPower^.XSpeed));
  Assert.AreEqual(-20, Integer(LPower^.YSpeed));
  Assert.AreEqual(KEEN_STATE_S_FLOWERPOWER1, Integer(LPower^.State));
  Assert.AreEqual(Ord(kaRemovable), Ord(LPower^.Active));
  Assert.AreEqual(2, Integer(FPlay.GameState^.FlowerPowers));
  Assert.AreEqual(8, Integer(LPower^.Temp1));
end;

procedure TTestKeenGameActions.DovrebbeNonLanciareSenzaFiori;
var
  LPlayer: PKeenObject;
  LBefore: Integer;
begin
  (FActions as IKeenActorSpawner).SpawnKeen(5, 10, 1);
  LPlayer := FWorld.Objects.Player;
  FPlay.GameState^.FlowerPowers := 0;
  LPlayer^.State := KEEN_STATE_S_KEENTHROW3;
  LBefore := FWorld.Objects.Count;
  FActions.Think(KEEN_ACTION_KEENTHROW, LPlayer);
  Assert.AreEqual(LBefore, FWorld.Objects.Count);
  Assert.AreEqual(KEEN_SND_NOWAYSND, FWorld.EventsFake.Sounds[0]);
end;

procedure TTestKeenGameActions.DovrebbeModificareL_UltimoAttoreSeIlLancioInAriaNonHaFiori;
var
  LPlayer: PKeenObject;
  LLast: PKeenObject;
begin
  // defect of the C kept: the speed of the player is added to "new", the last actor made, even if no flower was thrown
  (FActions as IKeenActorSpawner).SpawnKeen(5, 10, 1);
  LPlayer := FWorld.Objects.Player;
  LLast := NewActor(kcInert, KEEN_STATE_S_BOOBUSDIE3, 20, 20);
  LLast^.XSpeed := 5;
  LPlayer^.XSpeed := 10;
  LPlayer^.YSpeed := -20;
  FPlay.GameState^.FlowerPowers := 0;
  LPlayer^.State := KEEN_STATE_S_KEENAIRTHROW2;
  FActions.Think(KEEN_ACTION_KEENTHROW, LPlayer);
  Assert.AreEqual(10, Integer(LLast^.XSpeed));
  Assert.AreEqual(-10, Integer(LLast^.YSpeed));
end;

procedure TTestKeenGameActions.DovrebbeUsareLeBombeNelLivelloQuindici;
var
  LPlayer: PKeenObject;
begin
  (FActions as IKeenActorSpawner).SpawnKeen(5, 10, 1);
  LPlayer := FWorld.Objects.Player;
  FPlay.MapOn := 15;
  FPlay.GameState^.BoobusBombs := 2;
  FPlay.GameState^.BombsThisLevel := 2;
  LPlayer^.State := KEEN_STATE_S_KEENTHROW3;
  FActions.Think(KEEN_ACTION_KEENTHROW, LPlayer);
  Assert.AreEqual(1, Integer(FPlay.GameState^.BoobusBombs));
  Assert.AreEqual(1, Integer(FPlay.GameState^.BombsThisLevel));
  Assert.AreEqual(KEEN_STATE_S_BOOBUSBOMB1, Integer(FWorld.Objects.New^.State));
  Assert.AreEqual(10, Integer(FWorld.Objects.New^.Temp1));
  Assert.AreEqual(KEEN_SND_THROWBOMBSND, FWorld.EventsFake.Sounds[0]);
end;

procedure TTestKeenGameActions.DovrebbeNonUccidereKeenInGodMode;
begin
  (FActions as IKeenActorSpawner).SpawnKeen(5, 10, 1);
  FWorld.EventsFake.GodMode := True;
  (FActions as IKeenPlayerFunctions).KillKeen;
  Assert.AreEqual(KEEN_STATE_S_KEENSTAND, Integer(FWorld.Objects.Player^.State));
  Assert.AreEqual(0, FWorld.EventsFake.Sounds.Count);
end;

procedure TTestKeenGameActions.DovrebbeUccidereKeenFuoriDaGodMode;
var
  LPlayer: PKeenObject;
begin
  (FActions as IKeenActorSpawner).SpawnKeen(5, 10, 1);
  LPlayer := FWorld.Objects.Player;
  (FActions as IKeenPlayerFunctions).KillKeen;
  Assert.AreEqual(KEEN_STATE_S_KEENDIE1, Integer(LPlayer^.State));
  Assert.IsFalse(LPlayer^.NeedToClip);
  Assert.AreEqual(KEEN_SND_WAKEUPSND, FWorld.EventsFake.Sounds[0]);
  // the end of the death makes the level end
  FActions.Think(KEEN_ACTION_KEENDIETHINK, LPlayer);
  Assert.AreEqual(Ord(keDied), Ord(FPlay.PlayState));
end;

procedure TTestKeenGameActions.DovrebbeRaccogliereUnBonusDiPunti;
var
  LPlayer: PKeenObject;
  LBonus: PKeenObject;
begin
  (FActions as IKeenActorSpawner).SpawnKeen(5, 10, 1);
  LPlayer := FWorld.Objects.Player;
  (FActions as IKeenActorSpawner).SpawnBonus(5, 10, 2);
  LBonus := FWorld.Objects.New;
  FActions.Contact(KEEN_ACTION_KEENCONTACT, LPlayer, LBonus);
  Assert.AreEqual(500, FPlay.GameState^.Score);
  Assert.AreEqual(Ord(kcInert), Ord(LBonus^.ObClass));
  Assert.AreEqual(KEEN_STATE_S_BONUSRISE, Integer(LBonus^.State));
  Assert.AreEqual(Integer(KEEN_GFX_BONUS100SPR) + 2, Integer(LBonus^.ShapeNum));
end;

procedure TTestKeenGameActions.DovrebbeRaccogliereLaChiaveEAprireLaPorta;
var
  LPlayer: PKeenObject;
  LKey: PKeenObject;
  LDoor: PKeenObject;
begin
  (FActions as IKeenActorSpawner).SpawnKeen(5, 10, 1);
  LPlayer := FWorld.Objects.Player;
  (FActions as IKeenActorSpawner).SpawnBonus(5, 10, 11);
  LKey := FWorld.Objects.New;
  FActions.Contact(KEEN_ACTION_KEENCONTACT, LPlayer, LKey);
  Assert.AreEqual(1, Integer(FPlay.GameState^.Keys));
  (FActions as IKeenActorSpawner).SpawnDoor(6, 10);
  LDoor := FWorld.Objects.New;
  FActions.Contact(KEEN_ACTION_KEENCONTACT, LPlayer, LDoor);
  Assert.AreEqual(0, Integer(FPlay.GameState^.Keys));
  Assert.AreEqual(KEEN_STATE_S_DOORRAISE, Integer(LDoor^.State));
  // an open door does not take another key
  FPlay.GameState^.Keys := 1;
  FActions.Contact(KEEN_ACTION_KEENCONTACT, LPlayer, LDoor);
  Assert.AreEqual(1, Integer(FPlay.GameState^.Keys));
end;

procedure TTestKeenGameActions.DovrebbeSpingereKeenViaDaUnaPortaSenzaChiavi;
var
  LPlayer: PKeenObject;
  LDoor: PKeenObject;
begin
  (FActions as IKeenActorSpawner).SpawnKeen(5, 10, 1);
  LPlayer := FWorld.Objects.Player;
  (FActions as IKeenActorSpawner).SpawnDoor(5, 10);
  LDoor := FWorld.Objects.New;
  LDoor^.Left := LDoor^.X + 64;
  LDoor^.Right := LDoor^.X + 128;
  LDoor^.Top := 0;
  LDoor^.Bottom := 4096;
  LPlayer^.Left := LDoor^.Left - 100;
  LPlayer^.Right := LDoor^.Left + 10;
  LPlayer^.Top := 100;
  LPlayer^.Bottom := 500;
  FActions.Contact(KEEN_ACTION_KEENCONTACT, LPlayer, LDoor);
  Assert.AreEqual(KEEN_SND_NOWAYSND, FWorld.EventsFake.Sounds[0]);
  Assert.AreEqual(Ord(kcDoor), Ord(LDoor^.ObClass), 'the door stays closed');
end;

procedure TTestKeenGameActions.DovrebbeUccidereKeenConUnPomodoro;
var
  LTomat: PKeenObject;
begin
  (FActions as IKeenActorSpawner).SpawnKeen(5, 10, 1);
  (FActions as IKeenActorSpawner).SpawnTomat(5, 10);
  LTomat := FWorld.Objects.New;
  FActions.Contact(KEEN_ACTION_KEENCONTACT, FWorld.Objects.Player, LTomat);
  Assert.AreEqual(KEEN_STATE_S_KEENDIE1, Integer(FWorld.Objects.Player^.State));
end;

procedure TTestKeenGameActions.DovrebbeTrasformareUnNemicoInFiore;
var
  LPower: PKeenObject;
  LEnemy: PKeenObject;
  LPoof: PKeenObject;
begin
  (FActions as IKeenActorSpawner).SpawnBrocco(8, 10);
  LEnemy := FWorld.Objects.New;
  LEnemy^.Bottom := LEnemy^.Y + 400;
  (FActions as IKeenActorSpawner).SpawnKeen(5, 10, 1);
  FPlay.GameState^.FlowerPowers := 1;
  FWorld.Objects.Player^.State := KEEN_STATE_S_KEENTHROW3;
  FActions.Think(KEEN_ACTION_KEENTHROW, FWorld.Objects.Player);
  LPower := FWorld.Objects.New;
  FActions.Contact(KEEN_ACTION_POWERCONTACT, LPower, LEnemy);
  Assert.AreEqual(Ord(kcInert), Ord(LEnemy^.ObClass));
  Assert.AreEqual(KEEN_STATE_S_FLOWER1, Integer(LEnemy^.State));
  Assert.AreEqual(Ord(kaAllways), Ord(LEnemy^.Active));
  Assert.AreEqual(Ord(kcBrocco), Integer(LEnemy^.Temp1));
  Assert.AreEqual(KEEN_STATE_S_BROCCOWALK1, Integer(LEnemy^.Temp2));
  // the power is gone and a puff of smoke took its place at the end of the list
  Assert.AreEqual(KEEN_STATE_S_POOFTO1, Integer(FWorld.Objects.New^.State));
  LPoof := FWorld.Objects.New;
  Assert.AreEqual(Ord(kaRemovable), Ord(LPoof^.Active));
end;

procedure TTestKeenGameActions.DovrebbeTornareNemicoQuandoIlFioreFinisce;
var
  LEnemy: PKeenObject;
  LPoof: PKeenObject;
begin
  (FActions as IKeenActorSpawner).SpawnBrocco(8, 10);
  LEnemy := FWorld.Objects.New;
  FActions.Contact(KEEN_ACTION_POWERCONTACT, NewActor(kcPower, KEEN_STATE_S_FLOWERPOWER1, 20, 20), LEnemy);
  FPlay.GameState^.Difficulty := 3;
  FView.SetOrigin(0, 0);
  // the flower of the hardest level lasts 175 tics: at that time a puff of smoke gives the enemy back
  LEnemy^.Temp3 := 175;
  FActions.Think(KEEN_ACTION_FLOWERTHINK, LEnemy);
  LPoof := FWorld.Objects.New;
  Assert.AreEqual(KEEN_STATE_S_POOFFROM1, Integer(LPoof^.State));
  Assert.AreEqual(Integer(LEnemy^.Slot), Integer(LPoof^.Temp1));
  FActions.Think(KEEN_ACTION_CHANGEFROMFLOWER, LPoof);
  Assert.AreEqual(Ord(kcBrocco), Ord(LEnemy^.ObClass));
  Assert.AreEqual(KEEN_STATE_S_BROCCOWALK1, Integer(LEnemy^.State));
  Assert.AreEqual(Ord(kaYes), Ord(LEnemy^.Active));
end;

procedure TTestKeenGameActions.DovrebbeEntrareNelLivelloDallaMappaDelMondo;
var
  LPlayer: PKeenObject;
begin
  (FActions as IKeenActorSpawner).SpawnWorldKeen(3, 4);
  LPlayer := FWorld.Objects.Player;
  FWorld.Map.Planes[2][LPlayer^.TileTop * 40 + LPlayer^.TileLeft] := 7;
  Press(0, 0, True, False);
  FActions.Think(KEEN_ACTION_KEENWORLDTHINK, LPlayer);
  Assert.AreEqual(Ord(keLevelComplete), Ord(FPlay.PlayState));
  Assert.AreEqual(5, Integer(FPlay.GameState^.MapOn));
  Assert.AreEqual(Integer(LPlayer^.X), Integer(FPlay.GameState^.WorldX));
  Assert.AreEqual(KEEN_SND_ENTERLEVELSND, FWorld.EventsFake.Sounds[0]);
end;

procedure TTestKeenGameActions.DovrebbeChiedereLeBombePerIlLivelloDelRe;
var
  LPlayer: PKeenObject;
begin
  (FActions as IKeenActorSpawner).SpawnWorldKeen(3, 4);
  LPlayer := FWorld.Objects.Player;
  FWorld.Map.Planes[2][LPlayer^.TileTop * 40 + LPlayer^.TileLeft] := 17;
  FPlay.GameState^.BoobusBombs := 11;
  Press(0, 0, False, True);
  FActions.Think(KEEN_ACTION_KEENWORLDTHINK, LPlayer);
  Assert.AreEqual(1, FWorld.EventsFake.NeedBombsShown);
  Assert.AreEqual(Ord(keNotDone), Ord(FPlay.PlayState));
  FPlay.GameState^.BoobusBombs := 12;
  FActions.Think(KEEN_ACTION_KEENWORLDTHINK, LPlayer);
  Assert.AreEqual(Ord(keLevelComplete), Ord(FPlay.PlayState));
  Assert.AreEqual(15, Integer(FPlay.GameState^.MapOn));
end;

procedure TTestKeenGameActions.DovrebbeLasciareChiDormeRimuovereGliZ;
var
  LPlayer: PKeenObject;
  LZees: PKeenObject;
  LCount: Integer;
begin
  (FActions as IKeenActorSpawner).SpawnKeen(5, 10, 1);
  LPlayer := FWorld.Objects.Player;
  FActions.Think(KEEN_ACTION_KEENGOSLEEPTHINK, LPlayer);
  LZees := FWorld.Objects.New;
  Assert.AreEqual(KEEN_STATE_S_KEENZEE1, Integer(LZees^.State));
  Assert.AreEqual(Integer(LZees^.Slot), Integer(LPlayer^.Temp1));
  LCount := FWorld.Objects.Count;
  Press(1, 0, False, False);
  FActions.Think(KEEN_ACTION_KEENSLEEPTHINK, LPlayer);
  Assert.AreEqual(LCount - 1, FWorld.Objects.Count);
  Assert.AreEqual(KEEN_STATE_S_KEENGETUP, Integer(LPlayer^.State));
end;

procedure TTestKeenGameActions.DovrebbeUsareLeFasceDellaPendenzaNelFondoDelRimbalzo;
var
  LObject: PKeenObject;
  LSpeed: Cardinal;
  LXSpeed: SmallInt;
  LYSpeed: SmallInt;
begin
  // difference from the C: bounceangle has 8 rows and a wall number of 8 or more reads other memory; here the
  // bits of the slope (wall and 7) choose the row
  LObject := NewActor(kcShot, KEEN_STATE_S_FRY1, 20, 20);
  LObject^.XSpeed := 30;
  LObject^.YSpeed := 30;
  LObject^.HitNorth := 9;
  LSpeed := FContext.BounceOffFloor(LObject);
  LXSpeed := LObject^.XSpeed;
  LYSpeed := LObject^.YSpeed;
  LObject^.XSpeed := 30;
  LObject^.YSpeed := 30;
  LObject^.HitNorth := 1;
  Assert.AreEqual(Integer(LSpeed), Integer(FContext.BounceOffFloor(LObject)));
  Assert.AreEqual(Integer(LXSpeed), Integer(LObject^.XSpeed));
  Assert.AreEqual(Integer(LYSpeed), Integer(LObject^.YSpeed));
  // 45 degrees... no: 30 against 30 is 67 degrees, the speed is 30 * 286 / 2
  Assert.AreEqual(30 * 286 div 2, Integer(LSpeed));
end;

procedure TTestKeenGameActions.DovrebbeRimuovereIlProiettileChePerdeForza;
var
  LShot: PKeenObject;
  LCount: Integer;
begin
  LShot := NewActor(kcShot, KEEN_STATE_S_FRY1, 20, 20);
  LShot^.XSpeed := 2;
  LShot^.YSpeed := 3;
  LShot^.HitNorth := 1;
  LCount := FWorld.Objects.Count;
  FActions.React(KEEN_ACTION_PROJECTILEREACT, LShot);
  Assert.AreEqual(LCount - 1, FWorld.Objects.Count);
end;

procedure TTestKeenGameActions.DovrebbeFarEsplodereBoobusAlleBombe;
var
  LBoss: PKeenObject;
  LBomb: PKeenObject;
begin
  (FActions as IKeenActorSpawner).SpawnBoobus(10, 10);
  LBoss := FWorld.Objects.New;
  LBomb := NewActor(kcPower, KEEN_STATE_S_BOOBUSBOMB1, 20, 20);
  LBoss^.Temp4 := 1;
  FActions.Contact(KEEN_ACTION_POWERCONTACT, LBomb, LBoss);
  Assert.AreEqual(100000, FPlay.GameState^.Score);
  Assert.AreEqual(Ord(kcInert), Ord(LBoss^.ObClass));
  Assert.AreEqual(KEEN_STATE_S_BOOBUSDIE, Integer(LBoss^.State));
  Assert.AreEqual(KEEN_STATE_S_BOMBEXPLODE, Integer(LBomb^.State));
  // the end of the boss ends the game
  FActions.Think(KEEN_ACTION_FINISHTHINK, LBoss);
  Assert.AreEqual(Ord(keVictorious), Ord(FPlay.PlayState));
end;

procedure TTestKeenGameActions.DovrebbeDisegnareLeCifreDelPunteggio;
var
  LCache: IKeenSpriteCache;
  LContext: IKeenActionContext;
  LBox: TKeenScoreBox;
  LSprite: TKeenSprite;
  LGraphics: IKeenGraphics;
  LTile: TBytes;
  LRow: Integer;
  LBase: Integer;
begin
  LCache := TScoreSpriteCache.Create;
  LGraphics := TFakeKeenGraphics.Create(7);
  LContext := FContext;
  LBox := TKeenScoreBox.Create(LContext, LGraphics, LCache);
  try
    FWorld.Objects.ScoreObj^.Temp1 := -1;
    FWorld.Objects.ScoreObj^.Temp2 := -1;
    FPlay.GameState^.Score := 5;
    LBox.ScoreThink(FWorld.Objects.ScoreObj);
    LSprite := LCache.GetSprite(KEEN_GFX_SCOREBOXSPR);
    // the number goes after the five spaces of a six digit field: the digit 5 is the tile 6, in the plane 0
    LBase := LSprite.PlaneSize[0] + LSprite.Width[0] * 4 + 1 + 6;
    LTile := LGraphics.Tile8(6);
    for LRow := 0 to 7 do
      Assert.AreEqual(Integer(LTile[LRow]), Integer(LSprite.Data[LBase + LRow * LSprite.Width[0]]));
    // the second plane of the same character
    for LRow := 0 to 7 do
      Assert.AreEqual(Integer(LTile[8 + LRow]),
        Integer(LSprite.Data[LBase + LSprite.PlaneSize[0] + LRow * LSprite.Width[0]]));
    Assert.IsTrue(FWorld.Objects.ScoreObj^.NeedToReact);
    Assert.AreEqual(5, Integer(FWorld.Objects.ScoreObj^.Temp2));
  finally
    LBox.Free;
  end;
end;

procedure TTestKeenGameActions.DovrebbeAggiornarePunteggioFioriEVite;
var
  LBox: TKeenScoreBox;
  LScore: PKeenObject;
begin
  LBox := TKeenScoreBox.Create(FContext, TFakeKeenGraphics.Create(7), TScoreSpriteCache.Create);
  try
    LScore := FWorld.Objects.ScoreObj;
    LBox.SpawnScore;
    Assert.AreEqual(KEEN_STATE_S_SCORE, Integer(LScore^.State));
    Assert.AreEqual(Ord(kaAllways), Ord(LScore^.Active));
    Assert.AreEqual(-1, Integer(LScore^.Temp3));
    FPlay.GameState^.Score := 70000;
    FPlay.GameState^.FlowerPowers := 120;
    FPlay.GameState^.Lives := 12;
    FView.SetOrigin(256, 512);
    LBox.ScoreThink(LScore);
    Assert.AreEqual(1, Integer(LScore^.Temp1), 'the high word of the score');
    Assert.AreEqual(Integer(SmallInt(70000 - 65536)), Integer(LScore^.Temp2));
    Assert.AreEqual(120, Integer(LScore^.Temp3));
    Assert.AreEqual(12, Integer(LScore^.Temp4));
    // nothing changed: the box does not ask to be drawn again, until the view moves
    LScore^.NeedToReact := False;
    LScore^.X := Word(FView.OriginXGlobal);
    LScore^.Y := Word(FView.OriginYGlobal);
    LBox.ScoreThink(LScore);
    Assert.IsFalse(LScore^.NeedToReact);
    FView.SetOrigin(512, 512);
    LBox.ScoreThink(LScore);
    Assert.IsTrue(LScore^.NeedToReact);
    // the react puts the box at the corner of the view, at the top priority
    LBox.ScoreReact(LScore);
    Assert.AreEqual(Integer(Word(FView.OriginXGlobal)), Integer(LScore^.X));
    Assert.AreNotEqual(0, LScore^.Sprite);
  finally
    LBox.Free;
  end;
end;

procedure TTestKeenGameActions.DovrebbeDisegnareIlFioreOLaBombaNellaScatola;
var
  LCache: IKeenSpriteCache;
  LGraphics: IKeenGraphics;
  LBox: TKeenScoreBox;
  LSprite: TKeenSprite;
  LTile: TBytes;
  LBase: Integer;
begin
  LCache := TScoreSpriteCache.Create;
  LGraphics := TFakeKeenGraphics.Create(7);
  LBox := TKeenScoreBox.Create(FContext, LGraphics, LCache);
  try
    FPlay.MapOn := 15;
    LBox.FixScoreBox;
    LSprite := LCache.GetSprite(KEEN_GFX_SCOREBOXSPR);
    LBase := LSprite.PlaneSize[0] + LSprite.Width[0] * 16 + 4;
    LTile := LGraphics.Tile8(20);
    Assert.AreEqual(Integer(LTile[0]), Integer(LSprite.Data[LBase]));
    FPlay.MapOn := 3;
    LBox.FixScoreBox;
    LTile := LGraphics.Tile8(28);
    Assert.AreEqual(Integer(LTile[0]), Integer(LSprite.Data[LBase]));
    // the lower left character of the flower is the tile 30, one row of characters below
    LTile := LGraphics.Tile8(30);
    Assert.AreEqual(Integer(LTile[0]), Integer(LSprite.Data[LBase + LSprite.Width[0] * 8]));
  finally
    LBox.Free;
  end;
end;

procedure TTestKeenGameActions.DovrebbeFarePartireIlPuntoDellaMappaDelloScanner;
var
  LScanner: TKeenLevelScanner;
begin
  FWorld.Map.Planes[2][10 * 40 + 5] := 1; // the start of Keen
  FWorld.Map.Planes[2][12 * 40 + 9] := 41; // a Broccolash
  LScanner := TKeenLevelScanner.Create(FWorld.Objects, FActions as IKeenActorSpawner);
  try
    LScanner.ScanInfoPlane(FWorld.Map);
  finally
    LScanner.Free;
  end;
  Assert.AreEqual(Ord(kcKeen), Ord(FWorld.Objects.Player^.ObClass));
  Assert.AreEqual(5 * 256, Integer(FWorld.Objects.Player^.X));
  Assert.AreEqual(Ord(kcBrocco), Ord(FWorld.Objects.New^.ObClass));
  Assert.AreEqual(Ord(kaNo), Ord(FWorld.Objects.New^.Active), 'the scanner puts the actors to sleep');
end;

procedure TTestKeenGameActions.DovrebbeInoltrareLeFunzioniDiMovimentoAlMotore;
var
  LPhysics: IKeenActorPhysics;
  LObject: PKeenObject;
begin
  LPhysics := TKeenActorPhysics.Create(FWorld.Mover, FWorld.Machine);
  LObject := FWorld.Objects.GetNewObj(False);
  LObject^.XDir := 1;
  LPhysics.NewState(LObject, KEEN_STATE_S_SCORE);
  Assert.AreEqual(KEEN_STATE_S_SCORE, Integer(LObject^.State));
  LObject^.NeedToClip := False;
  LPhysics.ClipToWalls(LObject);
  Assert.AreEqual(KEEN_STATE_S_SCORE, Integer(LObject^.State));
end;

procedure TTestKeenGameActions.DovrebbePosareERimuovereGliSpriteSulGestoreDelloSchermo;
var
  LView: IKeenActionView;
  LHandle: TKeenSpriteHandle;
begin
  LView := TKeenActionView.Create(FWorld.Refresh, FWorld.Clock);
  LHandle := 0;
  LView.PlaceSprite(LHandle, 100, 200, KEEN_STARTSPRITES, 2);
  Assert.AreNotEqual(0, LHandle);
  LView.RemoveSprite(LHandle);
  Assert.AreEqual(0, LHandle);
  Assert.AreEqual(FWorld.Refresh.LastTimeCount, LView.LastTimeCount);
  Assert.AreEqual(FWorld.Refresh.OriginXGlobal, LView.OriginXGlobal);
  Assert.AreEqual(FWorld.Refresh.OriginYGlobal, LView.OriginYGlobal);
end;

procedure TTestKeenGameActions.DovrebbeRispondereAlleInterfacceSenzaContareIRiferimenti;
var
  LGroup: TKeenCommonActions;
  LInterface: IKeenActionGroup;
begin
  LGroup := TKeenCommonActions.Create(FContext);
  try
    Assert.IsTrue(Supports(LGroup, IKeenActionGroup, LInterface));
    LInterface := nil; // the object is still there: the owner frees it
    Assert.IsFalse(Supports(LGroup, IKeenHuffman));
    Assert.IsTrue(LGroup.TryReact(KEEN_ACTION_DRAWREACT, FWorld.Objects.Player));
    Assert.IsFalse(LGroup.TryReact(KEEN_ACTION_KEENWALKREACT, FWorld.Objects.Player));
  finally
    LGroup.Free;
  end;
end;

procedure TTestKeenGameActions.DovrebbeRifiutareIParametriNulli;
begin
  Assert.WillRaise(procedure begin TKeenActionContext.Create(nil, FWorld.States, FWorld.Random, FWorld.Events,
    FViewIntf, TTestPhysics.Create(FWorld.States), FPlay, FWorld.Map, FWorld.TileInfo); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TKeenCommonActions.Create(nil); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TKeenPlayState.Create(nil); end, EArgumentNilException);
  Assert.WillRaise(procedure begin FContext.SetMap(nil); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TKeenActionView.Create(nil, FWorld.Clock); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TKeenActorPhysics.Create(nil, nil); end, EArgumentNilException);
end;

procedure TTestKeenGameActions.DovrebbeDareLeMisureDellaVistaAlleAzioni;
var
  LView: IKeenActionView;
begin
  FWorld.Refresh.NewPosition(3 * 256, 2 * 256);
  LView := TKeenActionView.Create(FWorld.Refresh, FWorld.Clock);
  Assert.AreEqual(3, LView.OriginXTile);
  Assert.AreEqual(2, LView.OriginYTile);
  Assert.AreEqual(3 + KEEN_PORTTILESWIDE - 1, LView.OriginXTileMax);
  Assert.AreEqual(2 + KEEN_PORTTILESHIGH - 1, LView.OriginYTileMax);
  Assert.AreEqual(FWorld.Refresh.Tics, LView.Tics);
  Assert.AreEqual(FWorld.Clock.TimeCount, LView.TimeCount);
end;

end.
