{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the loop of the program              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.AppRunner;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Clock.Intf,
  DelphiDoom.War.Ui.Intf, DelphiDoom.War.App.Intf, DelphiDoom.War.App.Runner, DelphiDoom.Tests.War.AppSession;

type
  /// <summary>A clock that only moves when it is told to, or when the program sleeps</summary>
  TAppFakeClock = class(TInterfacedObject, IClock)
  public
    Now: Double;
    SleepCalls: Integer;
    procedure Advance(ASeconds: Double);
    function Seconds: Double;
    function Steps(ARate: Integer): Integer;
    function ScaledSteps(ARate, AScale: Integer): Integer;
    procedure Sleep(AMilliseconds: Integer);
    procedure Wait(AMilliseconds: Integer);
  end;

  /// <summary>A window that keeps what it was shown and told</summary>
  TAppFakePresenter = class(TInterfacedObject, IWarFramePresenter)
  public
    Pictures: Integer;
    LastPixels: TArray<Cardinal>;
    LastWidth: Integer;
    LastHeight: Integer;
    Status: TStringList;
    constructor Create;
    destructor Destroy; override;
    procedure Present(const APixels: TArray<Cardinal>; AWidth, AHeight: Integer);
    procedure SetStatus(const AText: string);
  end;

  /// <summary>A quick slot in memory</summary>
  TAppFakeStorage = class(TInterfacedObject, IWarSaveStorage)
  public
    Bytes: TBytes;
    Writes: Integer;
    procedure Write(const ABytes: TBytes);
    function TryRead(out ABytes: TBytes): Boolean;
  end;

  /// <summary>The loop: time, pictures, requests, and the ways it ends</summary>
  [TestFixture]
  [Category('war')]
  TTestWarAppRunner = class(TObject)
  strict private
    FRig: TAppSessionRig;
    FPresenter: TAppFakePresenter;
    FPresenterRef: IWarFramePresenter;
    FStorage: TAppFakeStorage;
    FStorageRef: IWarSaveStorage;
    FClock: TAppFakeClock;
    FClockRef: IClock;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeFermarsiDopoIFotogrammiChiesti;
    [Test]
    procedure DovrebbeDareAlGiocoUnSessantesimoSenzaOrologio;
    [Test]
    procedure DovrebbeFermarsiQuandoIlGiocoVuoleFinire;
    [Test]
    procedure DovrebbeFermarsiQuandoLaFinestraVieneChiusa;
    [Test]
    procedure DovrebbeAspettareUnSessantesimoEDareIlTempoVero;
    [Test]
    procedure DovrebbeLimitareIlTempoDiUnFotogramma;
    [Test]
    procedure DovrebbeMostrareLaPitturaDiOgniFotogramma;
    [Test]
    procedure DovrebbeFunzionareSenzaFinestra;
    [Test]
    procedure DovrebbeDareLeImpostazioniAlSuonoDopoOgniFotogramma;
    [Test]
    procedure DovrebbeSalvareNelloSlotESalutare;
    [Test]
    procedure DovrebbeCaricareDalloSlotETornareAlFotogrammaSalvato;
    [Test]
    procedure DovrebbeDireCheNonCeUnSalvataggio;
    [Test]
    procedure DovrebbeDireCheUnSalvataggioNonVaETenereIlGioco;
    [Test]
    procedure DovrebbeTenereIlGiocoSeIlRifacimentoFallisceDentroIlGioco;
    [Test]
    procedure DovrebbeIgnorareLeRichiesteSenzaSlot;
    [Test]
    procedure DovrebbeRifiutareUnaSessioneNil;
  end;

implementation

uses
  DelphiDoom.GameHost.Types, DelphiDoom.War.App.SessionTypes;

{ TAppFakeClock }

procedure TAppFakeClock.Advance(ASeconds: Double);
begin
  Now := Now + ASeconds;
end;

function TAppFakeClock.Seconds: Double;
begin
  Result := Now;
end;

function TAppFakeClock.Steps(ARate: Integer): Integer;
begin
  Result := 0;
end;

function TAppFakeClock.ScaledSteps(ARate, AScale: Integer): Integer;
begin
  Result := 0;
end;

procedure TAppFakeClock.Sleep(AMilliseconds: Integer);
begin
  Inc(SleepCalls);
  Now := Now + AMilliseconds / 1000;
end;

procedure TAppFakeClock.Wait(AMilliseconds: Integer);
begin
  Sleep(AMilliseconds);
end;

{ TAppFakePresenter }

constructor TAppFakePresenter.Create;
begin
  inherited Create;
  Status := TStringList.Create;
end;

destructor TAppFakePresenter.Destroy;
begin
  Status.Free;
  inherited Destroy;
end;

procedure TAppFakePresenter.Present(const APixels: TArray<Cardinal>; AWidth, AHeight: Integer);
begin
  Inc(Pictures);
  LastPixels := Copy(APixels);
  LastWidth := AWidth;
  LastHeight := AHeight;
end;

procedure TAppFakePresenter.SetStatus(const AText: string);
begin
  Status.Add(AText);
end;

{ TAppFakeStorage }

procedure TAppFakeStorage.Write(const ABytes: TBytes);
begin
  Bytes := Copy(ABytes);
  Inc(Writes);
end;

function TAppFakeStorage.TryRead(out ABytes: TBytes): Boolean;
begin
  Result := Length(Bytes) > 0;
  ABytes := Copy(Bytes);
end;

{ TTestWarAppRunner }

procedure TTestWarAppRunner.Setup;
begin
  FRig := TAppSessionRig.Create(1000);
  FPresenter := TAppFakePresenter.Create;
  FPresenterRef := FPresenter;
  FStorage := TAppFakeStorage.Create;
  FStorageRef := FStorage;
  FClock := TAppFakeClock.Create;
  FClockRef := FClock;
end;

procedure TTestWarAppRunner.TearDown;
begin
  FClockRef := nil;
  FStorageRef := nil;
  FPresenterRef := nil;
  FRig.Free;
end;

procedure TTestWarAppRunner.DovrebbeFermarsiDopoIFotogrammiChiesti;
var
  LRunner: TWarRunner;
begin
  LRunner := TWarRunner.Create(FRig.Session, nil, nil, nil, nil, nil);
  try
    Assert.AreEqual(25, LRunner.Run(25));
    Assert.AreEqual(25, FRig.Session.FrameCount);
  finally
    LRunner.Free;
  end;
end;

procedure TTestWarAppRunner.DovrebbeDareAlGiocoUnSessantesimoSenzaOrologio;
var
  LRunner: TWarRunner;
begin
  LRunner := TWarRunner.Create(FRig.Session, nil, nil, nil, nil, nil);
  try
    LRunner.Run(2);
    Assert.AreEqual('F 0.016667', FRig.CurrentGame.Log[0]);
    Assert.AreEqual('F 0.016667', FRig.CurrentGame.Log[1]);
  finally
    LRunner.Free;
  end;
end;

procedure TTestWarAppRunner.DovrebbeFermarsiQuandoIlGiocoVuoleFinire;
var
  LRunner: TWarRunner;
begin
  FRig.CurrentGame.QuitAsked := True;
  LRunner := TWarRunner.Create(FRig.Session, nil, nil, nil, nil, nil);
  try
    Assert.AreEqual(0, LRunner.Run(0), 'senza limite si ferma solo da se''');
  finally
    LRunner.Free;
  end;
end;

procedure TTestWarAppRunner.DovrebbeFermarsiQuandoLaFinestraVieneChiusa;
var
  LRunner: TWarRunner;
  LPumped: Integer;
begin
  LPumped := 0;
  LRunner := TWarRunner.Create(FRig.Session, nil, nil,
    function: Boolean
    begin
      Inc(LPumped);
      Result := LPumped <= 4;
    end, nil, nil);
  try
    Assert.AreEqual(4, LRunner.Run(0));
    Assert.AreEqual(5, LPumped);
  finally
    LRunner.Free;
  end;
end;

procedure TTestWarAppRunner.DovrebbeAspettareUnSessantesimoEDareIlTempoVero;
var
  LRunner: TWarRunner;
begin
  LRunner := TWarRunner.Create(FRig.Session, nil, FClockRef, nil, nil, nil);
  try
    LRunner.Run(2);
    Assert.IsTrue(FClock.SleepCalls > 0, 'il fotogramma non e'' piu'' corto di un sessantesimo');
    // 17 sleeps of a millisecond make 17 ms, the first time over 1/60
    Assert.AreEqual('F 0.017000', FRig.CurrentGame.Log[0]);
    Assert.AreEqual('F 0.017000', FRig.CurrentGame.Log[1]);
  finally
    LRunner.Free;
  end;
end;

procedure TTestWarAppRunner.DovrebbeLimitareIlTempoDiUnFotogramma;
var
  LRunner: TWarRunner;
begin
  LRunner := TWarRunner.Create(FRig.Session, nil, FClockRef,
    function: Boolean
    begin
      // a window that was dragged: five seconds pass before the frame
      FClock.Advance(5);
      Result := True;
    end, nil, nil);
  try
    LRunner.Run(1);
    Assert.AreEqual('F 0.100000', FRig.CurrentGame.Log[0]);
  finally
    LRunner.Free;
  end;
end;

procedure TTestWarAppRunner.DovrebbeMostrareLaPitturaDiOgniFotogramma;
var
  LRunner: TWarRunner;
begin
  FRig.CurrentGame.PictureWidth := 2;
  FRig.CurrentGame.PictureHeight := 1;
  FRig.CurrentGame.PictureBytes := [$11, $22, $33, 0, $AA, $BB, $CC, 0];
  LRunner := TWarRunner.Create(FRig.Session, FPresenterRef, nil, nil, nil, nil);
  try
    LRunner.Run(3);
    Assert.AreEqual(3, FPresenter.Pictures);
    Assert.AreEqual(2, FPresenter.LastWidth);
    Assert.AreEqual(1, FPresenter.LastHeight);
    Assert.AreEqual<Cardinal>($FF112233, FPresenter.LastPixels[0]);
    Assert.AreEqual<Cardinal>($FFAABBCC, FPresenter.LastPixels[1]);
  finally
    LRunner.Free;
  end;
end;

procedure TTestWarAppRunner.DovrebbeFunzionareSenzaFinestra;
var
  LRunner: TWarRunner;
begin
  LRunner := TWarRunner.Create(FRig.Session, nil, nil, nil, FStorageRef, nil);
  try
    LRunner.Run(3);
    Assert.AreEqual(0, FPresenter.Pictures);
    FRig.Session.RequestsObject.RequestSave;
    LRunner.Run(1);
    Assert.AreEqual(1, LRunner.Saves);
  finally
    LRunner.Free;
  end;
end;

procedure TTestWarAppRunner.DovrebbeDareLeImpostazioniAlSuonoDopoOgniFotogramma;
var
  LRunner: TWarRunner;
  LCalls: Integer;
  LGiven: IWarGameSettings;
begin
  LCalls := 0;
  LRunner := TWarRunner.Create(FRig.Session, nil, nil, nil, nil,
    procedure(const ASettings: IWarGameSettings)
    begin
      Inc(LCalls);
      LGiven := ASettings;
    end);
  try
    LRunner.Run(6);
    Assert.AreEqual(6, LCalls);
    Assert.IsTrue(Assigned(LGiven));
  finally
    LRunner.Free;
    LGiven := nil;
  end;
end;

procedure TTestWarAppRunner.DovrebbeSalvareNelloSlotESalutare;
var
  LRunner: TWarRunner;
begin
  LRunner := TWarRunner.Create(FRig.Session, FPresenterRef, nil, nil, FStorageRef, nil);
  try
    LRunner.Run(5);
    FRig.Session.RequestsObject.RequestSave;
    LRunner.Run(1);
    Assert.AreEqual(1, FStorage.Writes);
    Assert.AreEqual(1, LRunner.Saves);
    Assert.IsTrue(Length(FStorage.Bytes) > 0);
    Assert.AreEqual('Game saved (6 frames)', FPresenter.Status[FPresenter.Status.Count - 1]);
  finally
    LRunner.Free;
  end;
end;

procedure TTestWarAppRunner.DovrebbeCaricareDalloSlotETornareAlFotogrammaSalvato;
var
  LRunner: TWarRunner;
begin
  LRunner := TWarRunner.Create(FRig.Session, FPresenterRef, nil, nil, FStorageRef, nil);
  try
    LRunner.Run(4);
    FRig.Session.RequestsObject.RequestSave;
    LRunner.Run(1);
    // five frames saved; ten more are played, then the game is loaded
    LRunner.Run(10);
    Assert.AreEqual(15, FRig.Session.FrameCount);
    FRig.Session.RequestsObject.RequestLoad;
    LRunner.Run(1);
    Assert.AreEqual(1, LRunner.Loads);
    Assert.AreEqual(5, FRig.Session.FrameCount);
    Assert.AreEqual(2, FRig.Games.Count);
    Assert.AreEqual('Game loaded (5 frames)', FPresenter.Status[FPresenter.Status.Count - 1]);
  finally
    LRunner.Free;
  end;
end;

procedure TTestWarAppRunner.DovrebbeDireCheNonCeUnSalvataggio;
var
  LRunner: TWarRunner;
begin
  LRunner := TWarRunner.Create(FRig.Session, FPresenterRef, nil, nil, FStorageRef, nil);
  try
    FRig.Session.RequestsObject.RequestLoad;
    LRunner.Run(1);
    Assert.AreEqual(1, LRunner.LoadErrors);
    Assert.AreEqual(0, LRunner.Loads);
    Assert.AreEqual('There is no saved game', FPresenter.Status[0]);
    Assert.AreEqual<Integer>(1, FRig.Games.Count);
  finally
    LRunner.Free;
  end;
end;

procedure TTestWarAppRunner.DovrebbeDireCheUnSalvataggioNonVaETenereIlGioco;
var
  LRunner: TWarRunner;
  LOld: IWarSessionGame;
begin
  FStorage.Bytes := [1, 2, 3, 4, 5];
  LRunner := TWarRunner.Create(FRig.Session, FPresenterRef, nil, nil, FStorageRef, nil);
  try
    LOld := FRig.Session.Game;
    FRig.Session.RequestsObject.RequestLoad;
    LRunner.Run(1);
    Assert.AreEqual(1, LRunner.LoadErrors);
    Assert.IsTrue(LOld = FRig.Session.Game);
    Assert.IsTrue(FPresenter.Status[0].StartsWith('The game cannot be loaded'), FPresenter.Status[0]);
  finally
    LRunner.Free;
    LOld := nil;
  end;
end;

procedure TTestWarAppRunner.DovrebbeTenereIlGiocoSeIlRifacimentoFallisceDentroIlGioco;
var
  LRunner: TWarRunner;
  LOld: IWarSessionGame;
begin
  LRunner := TWarRunner.Create(FRig.Session, FPresenterRef, nil, nil, FStorageRef, nil);
  try
    LRunner.Run(3);
    FRig.Session.RequestsObject.RequestSave;
    LRunner.Run(1);
    // the game that is made by the load fails in its second frame, as a model that cannot play a mission would
    FRig.FailLoadedGameAtFrame := 2;
    LOld := FRig.Session.Game;
    FRig.Session.RequestsObject.RequestLoad;
    LRunner.Run(1);
    Assert.AreEqual(1, LRunner.LoadErrors);
    Assert.AreEqual(0, LRunner.Loads);
    Assert.IsTrue(LOld = FRig.Session.Game);
    Assert.IsTrue(FPresenter.Status[FPresenter.Status.Count - 1].StartsWith('The game cannot be loaded'));
  finally
    LRunner.Free;
    LOld := nil;
  end;
end;

procedure TTestWarAppRunner.DovrebbeIgnorareLeRichiesteSenzaSlot;
var
  LRunner: TWarRunner;
begin
  LRunner := TWarRunner.Create(FRig.Session, FPresenterRef, nil, nil, nil, nil);
  try
    FRig.Session.RequestsObject.RequestSave;
    FRig.Session.RequestsObject.RequestLoad;
    LRunner.Run(1);
    Assert.AreEqual(0, LRunner.Saves);
    Assert.AreEqual(0, LRunner.Loads);
    Assert.AreEqual(0, FPresenter.Status.Count);
  finally
    LRunner.Free;
  end;
end;

procedure TTestWarAppRunner.DovrebbeRifiutareUnaSessioneNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarRunner.Create(nil, nil, nil, nil, nil, nil);
    end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarAppRunner);

end.
