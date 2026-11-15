{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - a game that is saved and loaded      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.AppSession;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.GameHost.Types,
  DelphiDoom.War.Ui.Intf, DelphiDoom.War.App.SessionTypes, DelphiDoom.War.App.Session;

type
  /// <summary>A game that writes down everything it is given: its log is its state</summary>
  TAppFakeGame = class(TInterfacedObject, IWarSessionGame)
  strict private
    FRequests: IWarSessionRequests;
    FFrames: Integer;
  public
    Log: TStringList;
    QuitAsked: Boolean;
    /// <summary>The frame (counted from 1) that raises an exception; 0 = none</summary>
    FailAtFrame: Integer;
    /// <summary>Asks to save in every frame, as a replayed click on the button would</summary>
    SaveEveryFrame: Boolean;
    Start: TWarSessionStart;
    Destroyed: PInteger;
    /// <summary>The picture that the game says it drew (RGBA)</summary>
    PictureWidth: Integer;
    PictureHeight: Integer;
    PictureBytes: TArray<Byte>;
    constructor Create(const AStart: TWarSessionStart; const ARequests: IWarSessionRequests);
    destructor Destroy; override;
    procedure Post(const AEvent: TGameHostEvent);
    procedure RunFrame(ADelta: Single);
    function QuitRequested: Boolean;
    function Settings: IWarGameSettings;
    function Pixels: TArray<Byte>;
    function Width: Integer;
    function Height: Integer;
  end;

  /// <summary>
  ///   Makes the games of a session for a test and keeps the ones it made, the starts it was asked for and what it
  ///   was told around the replay
  /// </summary>
  TAppSessionRig = class
  public
    Games: TList<TAppFakeGame>;
    Starts: TList<TWarSessionStart>;
    GamesDestroyed: Integer;
    BeforeCount: Integer;
    AfterCount: Integer;
    FailLoadedGameAtFrame: Integer;
    SaveEveryFrameWhenLoaded: Boolean;
    Session: TWarSession;
    constructor Create(ADataSize: Cardinal; ASeed: Cardinal = 1);
    destructor Destroy; override;
    function CurrentGame: TAppFakeGame;
  end;

  /// <summary>The session: history, hot keys, saving, loading and what happens when loading goes wrong</summary>
  [TestFixture]
  [Category('war')]
  TTestWarAppSession = class(TObject)
  strict private
    function Mouse(AX, AY: Integer): TGameHostEvent;
    function Key(AKind: TGameHostEventKind; AKey: Integer): TGameHostEvent;
  public
    [Test]
    procedure DovrebbeFareIlGiocoConLaPartenzaEDarglieLeRichieste;
    [Test]
    procedure DovrebbeDareAlGiocoGliEventiSubitoEIlTempoDiOgniFotogramma;
    [Test]
    procedure DovrebbeFarSalvareECaricareDaF5EF9SenzaDarliAlGioco;
    [Test]
    procedure DovrebbeNonSalvareGliEventiCheIlGiocoNonLegge;
    [Test]
    procedure DovrebbeRifareLoStessoGiocoCaricandoQuelloCheHaSalvato;
    [Test]
    procedure DovrebbeUsareLaPartenzaDelSalvataggio;
    [Test]
    procedure DovrebbeDireIntornoAlRifacimentoCheStaRifacendo;
    [Test]
    procedure DovrebbeLasciareIlGiocoVecchioQuandoIlNuovoEPronto;
    [Test]
    procedure DovrebbeTenereIlGiocoVecchioSeIlFileNonVa;
    [Test]
    procedure DovrebbeTenereIlGiocoVecchioSeIlRifacimentoFallisce;
    [Test]
    procedure DovrebbeDimenticareLeRichiesteFatteDalRifacimento;
    [Test]
    procedure DovrebbeContinuareLaStoriaDopoUnCaricamento;
    [Test]
    procedure DovrebbeRifiutareUnSalvataggioGiocatoConAltriDati;
    [Test]
    procedure DovrebbeRifiutareUnCostruttoreNil;
  end;

implementation

uses
  DelphiDoom.War.Save.Types, DelphiDoom.War.Ui.GameSettings;

const
  VK_F5 = $74;
  VK_F9 = $78;
  DATA_SIZE = 1000;

{ TAppFakeGame }

constructor TAppFakeGame.Create(const AStart: TWarSessionStart; const ARequests: IWarSessionRequests);
begin
  inherited Create;
  Start := AStart;
  FRequests := ARequests;
  Log := TStringList.Create;
end;

destructor TAppFakeGame.Destroy;
begin
  if Assigned(Destroyed) then
    Inc(Destroyed^);
  Log.Free;
  inherited Destroy;
end;

procedure TAppFakeGame.Post(const AEvent: TGameHostEvent);
begin
  Log.Add(Format('E %d %d %d %d', [Ord(AEvent.Kind), AEvent.VirtualKey, AEvent.X, AEvent.Y]));
end;

procedure TAppFakeGame.RunFrame(ADelta: Single);
begin
  Inc(FFrames);
  if FFrames = FailAtFrame then
    raise EInvalidOperation.Create('the game fails');
  if SaveEveryFrame then
    FRequests.RequestSave;
  Log.Add(Format('F %.6f', [ADelta], TFormatSettings.Invariant));
end;

function TAppFakeGame.QuitRequested: Boolean;
begin
  Result := QuitAsked;
end;

function TAppFakeGame.Settings: IWarGameSettings;
begin
  Result := TWarGameSettings.Create;
end;

function TAppFakeGame.Pixels: TArray<Byte>;
begin
  Result := PictureBytes;
end;

function TAppFakeGame.Width: Integer;
begin
  Result := PictureWidth;
end;

function TAppFakeGame.Height: Integer;
begin
  Result := PictureHeight;
end;

{ TAppSessionRig }

constructor TAppSessionRig.Create(ADataSize: Cardinal; ASeed: Cardinal);
var
  LStart: TWarSessionStart;
begin
  inherited Create;
  Games := TList<TAppFakeGame>.Create;
  Starts := TList<TWarSessionStart>.Create;
  LStart := Default(TWarSessionStart);
  LStart.Seed := ASeed;
  Session := TWarSession.Create(
    function(const AStart: TWarSessionStart; const ARequests: IWarSessionRequests): IWarSessionGame
    var
      LGame: TAppFakeGame;
    begin
      Starts.Add(AStart);
      LGame := TAppFakeGame.Create(AStart, ARequests);
      LGame.Destroyed := @GamesDestroyed;
      // a game that is built by a load (not the first one)
      if Games.Count > 0 then
      begin
        LGame.FailAtFrame := FailLoadedGameAtFrame;
        LGame.SaveEveryFrame := SaveEveryFrameWhenLoaded;
      end;
      Games.Add(LGame);
      Result := LGame;
    end, LStart, ADataSize,
    procedure
    begin
      Inc(BeforeCount);
    end,
    procedure
    begin
      Inc(AfterCount);
    end);
end;

destructor TAppSessionRig.Destroy;
begin
  Session.Free;
  Starts.Free;
  Games.Free;
  inherited Destroy;
end;

function TAppSessionRig.CurrentGame: TAppFakeGame;
begin
  Result := Games[Games.Count - 1];
end;

{ TTestWarAppSession }

function TTestWarAppSession.Mouse(AX, AY: Integer): TGameHostEvent;
begin
  Result := TGameHostEvent.Make(hekMouseMotion);
  Result.X := AX;
  Result.Y := AY;
end;

function TTestWarAppSession.Key(AKind: TGameHostEventKind; AKey: Integer): TGameHostEvent;
begin
  Result := TGameHostEvent.Make(AKind);
  Result.VirtualKey := AKey;
end;

procedure TTestWarAppSession.DovrebbeFareIlGiocoConLaPartenzaEDarglieLeRichieste;
var
  LRig: TAppSessionRig;
begin
  LRig := TAppSessionRig.Create(DATA_SIZE, 77);
  try
    Assert.AreEqual<Integer>(1, LRig.Games.Count);
    Assert.AreEqual<Cardinal>(77, LRig.Starts[0].Seed);
    Assert.AreEqual<Cardinal>(77, LRig.Session.Start.Seed);
    Assert.IsTrue(Assigned(LRig.Session.Requests));
    Assert.AreEqual(0, LRig.Session.FrameCount);
  finally
    LRig.Free;
  end;
end;

procedure TTestWarAppSession.DovrebbeDareAlGiocoGliEventiSubitoEIlTempoDiOgniFotogramma;
var
  LRig: TAppSessionRig;
begin
  LRig := TAppSessionRig.Create(DATA_SIZE);
  try
    LRig.Session.Post(Mouse(5, 6));
    Assert.AreEqual<Integer>(1, LRig.CurrentGame.Log.Count, 'subito, non al fotogramma dopo');
    LRig.Session.RunFrame(0.25);
    Assert.AreEqual('E 3 0 5 6', LRig.CurrentGame.Log[0]);
    Assert.AreEqual('F 0.250000', LRig.CurrentGame.Log[1]);
    Assert.AreEqual(1, LRig.Session.FrameCount);
  finally
    LRig.Free;
  end;
end;

procedure TTestWarAppSession.DovrebbeFarSalvareECaricareDaF5EF9SenzaDarliAlGioco;
var
  LRig: TAppSessionRig;
begin
  LRig := TAppSessionRig.Create(DATA_SIZE);
  try
    LRig.Session.Post(Key(hekKeyDown, VK_F5));
    LRig.Session.Post(Key(hekKeyUp, VK_F5));
    Assert.IsTrue(LRig.Session.RequestsObject.TakeSave);
    Assert.IsFalse(LRig.Session.RequestsObject.TakeSave, 'una richiesta si prende una volta');
    Assert.IsFalse(LRig.Session.RequestsObject.TakeLoad);
    LRig.Session.Post(Key(hekKeyDown, VK_F9));
    LRig.Session.Post(Key(hekKeyUp, VK_F9));
    Assert.IsTrue(LRig.Session.RequestsObject.TakeLoad);
    Assert.AreEqual<Integer>(0, LRig.CurrentGame.Log.Count, 'i tasti non sono del gioco');
    LRig.Session.RunFrame(0.1);
    Assert.AreEqual<Integer>(1, LRig.CurrentGame.Log.Count);
  finally
    LRig.Free;
  end;
end;

procedure TTestWarAppSession.DovrebbeNonSalvareGliEventiCheIlGiocoNonLegge;
var
  LSaving: TAppSessionRig;
  LLoading: TAppSessionRig;
begin
  LSaving := TAppSessionRig.Create(DATA_SIZE);
  LLoading := TAppSessionRig.Create(DATA_SIZE);
  try
    LSaving.Session.Post(TGameHostEvent.Make(hekMouseWheel));
    LSaving.Session.Post(Mouse(1, 2));
    LSaving.Session.RunFrame(0.1);
    // the wheel went to the game now...
    Assert.AreEqual<Integer>(3, LSaving.CurrentGame.Log.Count);
    LLoading.Session.Load(LSaving.Session.Save);
    // ...and is not in the history
    Assert.AreEqual<Integer>(2, LLoading.CurrentGame.Log.Count);
    Assert.AreEqual('E 3 0 1 2', LLoading.CurrentGame.Log[0]);
  finally
    LLoading.Free;
    LSaving.Free;
  end;
end;

procedure TTestWarAppSession.DovrebbeRifareLoStessoGiocoCaricandoQuelloCheHaSalvato;
var
  LSaving: TAppSessionRig;
  LLoading: TAppSessionRig;
begin
  LSaving := TAppSessionRig.Create(DATA_SIZE);
  LLoading := TAppSessionRig.Create(DATA_SIZE);
  try
    LSaving.Session.Post(Mouse(10, 20));
    LSaving.Session.RunFrame(1 / 60);
    LSaving.Session.RunFrame(0.033);
    LSaving.Session.Post(Key(hekKeyDown, $41));
    LSaving.Session.Post(Key(hekKeyUp, $41));
    LSaving.Session.RunFrame(0.1);
    LLoading.Session.Load(LSaving.Session.Save);
    Assert.AreEqual<Integer>(2, LLoading.Games.Count);
    Assert.AreEqual(LSaving.CurrentGame.Log.Text, LLoading.CurrentGame.Log.Text);
    Assert.AreEqual(3, LLoading.Session.FrameCount);
  finally
    LLoading.Free;
    LSaving.Free;
  end;
end;

procedure TTestWarAppSession.DovrebbeUsareLaPartenzaDelSalvataggio;
var
  LSaving: TAppSessionRig;
  LLoading: TAppSessionRig;
begin
  LSaving := TAppSessionRig.Create(DATA_SIZE, 9);
  LLoading := TAppSessionRig.Create(DATA_SIZE, 1);
  try
    LSaving.Session.RunFrame(0.1);
    LLoading.Session.Load(LSaving.Session.Save);
    Assert.AreEqual<Cardinal>(9, LLoading.Starts[1].Seed);
    Assert.AreEqual<Cardinal>(9, LLoading.Session.Start.Seed);
  finally
    LLoading.Free;
    LSaving.Free;
  end;
end;

procedure TTestWarAppSession.DovrebbeDireIntornoAlRifacimentoCheStaRifacendo;
var
  LSaving: TAppSessionRig;
  LLoading: TAppSessionRig;
begin
  LSaving := TAppSessionRig.Create(DATA_SIZE);
  LLoading := TAppSessionRig.Create(DATA_SIZE);
  try
    LSaving.Session.RunFrame(0.1);
    LLoading.Session.Load(LSaving.Session.Save);
    Assert.AreEqual(1, LLoading.BeforeCount);
    Assert.AreEqual(1, LLoading.AfterCount);
  finally
    LLoading.Free;
    LSaving.Free;
  end;
end;

procedure TTestWarAppSession.DovrebbeLasciareIlGiocoVecchioQuandoIlNuovoEPronto;
var
  LSaving: TAppSessionRig;
  LLoading: TAppSessionRig;
  LOld: IWarSessionGame;
begin
  LSaving := TAppSessionRig.Create(DATA_SIZE);
  LLoading := TAppSessionRig.Create(DATA_SIZE);
  try
    LSaving.Session.RunFrame(0.1);
    LOld := LLoading.Session.Game;
    LLoading.Session.Load(LSaving.Session.Save);
    Assert.IsFalse(LOld = LLoading.Session.Game);
    Assert.AreEqual(0, LLoading.GamesDestroyed, 'chi lo tiene ancora lo ha');
    LOld := nil;
    Assert.AreEqual(1, LLoading.GamesDestroyed);
  finally
    LLoading.Free;
    LSaving.Free;
  end;
end;

procedure TTestWarAppSession.DovrebbeTenereIlGiocoVecchioSeIlFileNonVa;
var
  LRig: TAppSessionRig;
  LOld: IWarSessionGame;
begin
  LRig := TAppSessionRig.Create(DATA_SIZE);
  try
    LRig.Session.RunFrame(0.1);
    LOld := LRig.Session.Game;
    Assert.WillRaise(
      procedure
      begin
        LRig.Session.Load([1, 2, 3, 4]);
      end, EWarSaveException);
    Assert.IsTrue(LOld = LRig.Session.Game);
    Assert.AreEqual<Integer>(1, LRig.Games.Count, 'nessun gioco nuovo');
    Assert.AreEqual(1, LRig.Session.FrameCount);
    Assert.AreEqual(0, LRig.BeforeCount, 'il file e'' controllato prima di rifare qualcosa');
  finally
    LRig.Free;
  end;
end;

procedure TTestWarAppSession.DovrebbeTenereIlGiocoVecchioSeIlRifacimentoFallisce;
var
  LSaving: TAppSessionRig;
  LLoading: TAppSessionRig;
  LOld: IWarSessionGame;
begin
  LSaving := TAppSessionRig.Create(DATA_SIZE);
  LLoading := TAppSessionRig.Create(DATA_SIZE);
  try
    LSaving.Session.RunFrame(0.1);
    LSaving.Session.RunFrame(0.1);
    LLoading.FailLoadedGameAtFrame := 2;
    LLoading.Session.RunFrame(0.1);
    LOld := LLoading.Session.Game;
    Assert.WillRaise(
      procedure
      begin
        LLoading.Session.Load(LSaving.Session.Save);
      end, EInvalidOperation);
    Assert.IsTrue(LOld = LLoading.Session.Game);
    Assert.AreEqual(1, LLoading.Session.FrameCount);
    Assert.AreEqual(1, LLoading.AfterCount, 'il suono torna anche se il rifacimento e'' fallito');
  finally
    LLoading.Free;
    LSaving.Free;
  end;
end;

procedure TTestWarAppSession.DovrebbeDimenticareLeRichiesteFatteDalRifacimento;
var
  LSaving: TAppSessionRig;
  LLoading: TAppSessionRig;
begin
  LSaving := TAppSessionRig.Create(DATA_SIZE);
  LLoading := TAppSessionRig.Create(DATA_SIZE);
  try
    LSaving.Session.RunFrame(0.1);
    LLoading.SaveEveryFrameWhenLoaded := True;
    LLoading.Session.Load(LSaving.Session.Save);
    Assert.IsFalse(LLoading.Session.RequestsObject.TakeSave, 'un clic rigiocato non e'' un clic di adesso');
  finally
    LLoading.Free;
    LSaving.Free;
  end;
end;

procedure TTestWarAppSession.DovrebbeContinuareLaStoriaDopoUnCaricamento;
var
  LSaving: TAppSessionRig;
  LLoading: TAppSessionRig;
  LAgain: TAppSessionRig;
begin
  LSaving := TAppSessionRig.Create(DATA_SIZE);
  LLoading := TAppSessionRig.Create(DATA_SIZE);
  LAgain := TAppSessionRig.Create(DATA_SIZE);
  try
    LSaving.Session.RunFrame(0.1);
    LSaving.Session.RunFrame(0.2);
    LLoading.Session.Load(LSaving.Session.Save);
    LLoading.Session.Post(Mouse(3, 4));
    LLoading.Session.RunFrame(0.3);
    Assert.AreEqual(3, LLoading.Session.FrameCount);
    LAgain.Session.Load(LLoading.Session.Save);
    Assert.AreEqual(LLoading.CurrentGame.Log.Text, LAgain.CurrentGame.Log.Text);
  finally
    LAgain.Free;
    LLoading.Free;
    LSaving.Free;
  end;
end;

procedure TTestWarAppSession.DovrebbeRifiutareUnSalvataggioGiocatoConAltriDati;
var
  LSaving: TAppSessionRig;
  LLoading: TAppSessionRig;
begin
  LSaving := TAppSessionRig.Create(DATA_SIZE);
  LLoading := TAppSessionRig.Create(DATA_SIZE + 1);
  try
    Assert.WillRaise(
      procedure
      begin
        LLoading.Session.Load(LSaving.Session.Save);
      end, EWarSaveException);
  finally
    LLoading.Free;
    LSaving.Free;
  end;
end;

procedure TTestWarAppSession.DovrebbeRifiutareUnCostruttoreNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarSession.Create(nil, Default(TWarSessionStart), DATA_SIZE, nil, nil);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarAppSession);

end.
