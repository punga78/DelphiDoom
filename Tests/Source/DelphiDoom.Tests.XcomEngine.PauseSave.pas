{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the pause window and of saving a game: the names   }
{  of the files, the Save Game screen, SaveGameState, the pause menu and the    }
{  question "Abandon game?" (with a fake of the saved game in progress)         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.PauseSave;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.Session.Intf, DelphiDoom.XcomEngine.SaveCatalog.Intf, DelphiDoom.XcomEngine.SaveInfo,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.Tests.XcomEngine.World, DelphiDoom.Tests.XcomEngine.SaveScreens;

type
  /// <summary>The saved game in progress as the pause menu sees it: it records what it is asked</summary>
  TFakeSaver = class(TInterfacedObject, IXcomSavedGameSaver)
  public
    Ironman: Boolean;
    Name: string;
    Saved: TStringList;
    Abandoned: Integer;
    FailWith: string;
    constructor Create;
    destructor Destroy; override;
    function IsIronman: Boolean;
    procedure SetName(const AName: string);
    function GetName: string;
    procedure SaveGame(const AFileName: string);
    procedure AbandonGame;
  end;

  [TestFixture]
  [Category('XcomSaves')]
  TTestXcomSaveNames = class
  public
    [Test]
    [TestCase('barra', 'a/b,a_b')]
    [TestCase('due punti', 'a:b,a_b')]
    [TestCase('virgolette', 'a"b,a_b')]
    [TestCase('minore e maggiore', 'a<b>c,a_b_c')]
    [TestCase('punto interrogativo', 'a?b,a_b')]
    [TestCase('barra rovescia', 'a\b,a_b')]
    [TestCase('niente da cambiare', 'Save 01,Save 01')]
    procedure DovrebbeSostituireICaratteriNonAmmessi(const AName, AExpected: string);
  end;

  [TestFixture]
  [Category('XcomSaves')]
  TTestXcomPauseSave = class
  strict private
    FWorld: TTestWorld;
    FCatalog: TFakeCatalog;
    FCatalogRef: IXcomSaveCatalog;
    FSaver: TFakeSaver;
    FSaverRef: IXcomSavedGameSaver;
    procedure ClickButton(AButton: TXcomTextButton);
    /// <summary>The pause window and the save screen that a manual save closes</summary>
    procedure PushUnder;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeScrivereIlSalvataggioDopoDieciGiriEChiudereLeSchermate;
    [Test]
    procedure DovrebbeLasciareLaFinestraDellePausaSeIronman;
    [Test]
    procedure DovrebbeDareIlNomeFissoALSalvataggioRapido;
    [Test]
    procedure DovrebbeMostrareLErroreSeIlSalvataggioFallisce;
    [Test]
    procedure DovrebbeMostrareLErroreSenzaIlSalvatore;
    [Test]
    procedure DovrebbeAbbandonareLaPartitaDopoIlSalvataggioIronman;
    [Test]
    procedure LaListaDeiSalvataggiHaLaRigaDelNuovoSlotInCima;
    [Test]
    procedure IlPulsanteSalvaSenzaUnaRigaSceltaNonFaNulla;
    [Test]
    procedure IronmanNonHaIlPulsanteAnnulla;
    [Test]
    procedure LaPausaApreLeSchermateDeiPulsanti;
    [Test]
    procedure LaPausaNascondeCaricaESalvaInIronman;
    [Test]
    procedure AnnullaChiudeLaPausa;
    [Test]
    procedure OpzioniSenzaNavigatoreNonFaNulla;
    [Test]
    procedure AbbandonaSiRispondeNoOSi;
    [Test]
    procedure AbbandonareInIronmanSalvaPrima;
  end;

implementation

uses
  DelphiDoom.XcomMenu.SaveNames, DelphiDoom.XcomMenu.SaveGameState, DelphiDoom.XcomMenu.ListSaveState,
  DelphiDoom.XcomMenu.PauseState, DelphiDoom.XcomMenu.AbandonGameState, DelphiDoom.XcomMenu.ErrorMessageState,
  DelphiDoom.XcomMenu.OptionsTypes, DelphiDoom.XcomMenu.ListLoadState;

{ TFakeSaver }

constructor TFakeSaver.Create;
begin
  inherited Create;
  Saved := TStringList.Create;
end;

destructor TFakeSaver.Destroy;
begin
  Saved.Free;
  inherited Destroy;
end;

function TFakeSaver.IsIronman: Boolean;
begin
  Result := Ironman;
end;

procedure TFakeSaver.SetName(const AName: string);
begin
  Name := AName;
end;

function TFakeSaver.GetName: string;
begin
  Result := Name;
end;

procedure TFakeSaver.SaveGame(const AFileName: string);
begin
  if FailWith <> '' then
    raise Exception.Create(FailWith);
  Saved.Add(AFileName);
end;

procedure TFakeSaver.AbandonGame;
begin
  Inc(Abandoned);
end;

{ TTestXcomSaveNames }

procedure TTestXcomSaveNames.DovrebbeSostituireICaratteriNonAmmessi(const AName, AExpected: string);
begin
  Assert.AreEqual(AExpected, TXcomSaveNames.Sanitize(AName));
end;

{ TTestXcomPauseSave }

procedure TTestXcomPauseSave.Setup;
begin
  FWorld := TTestWorld.Create;
  FCatalog := TFakeCatalog.Create;
  FCatalogRef := FCatalog;
  FWorld.Game.SetSaveCatalog(FCatalogRef);
  FSaver := TFakeSaver.Create;
  FSaverRef := FSaver;
  FWorld.Game.SetSavedGameSaver(FSaverRef);
end;

procedure TTestXcomPauseSave.TearDown;
begin
  FSaverRef := nil;
  FCatalogRef := nil;
  FWorld.Free;
end;

procedure TTestXcomPauseSave.ClickButton(AButton: TXcomTextButton);
begin
  FWorld.Click(Round((AButton.X + 5) * FWorld.Game.Screen.XScale), Round((AButton.Y + 5) * FWorld.Game.Screen.YScale));
end;

procedure TTestXcomPauseSave.PushUnder;
begin
  FWorld.Game.PushState(TXcomPauseState.Create(FWorld.Game, ooGeoscape, nil));
  FWorld.Game.PushState(TXcomListSaveState.Create(FWorld.Game, ooGeoscape));
  FWorld.Wait(400);
end;

procedure TTestXcomPauseSave.DovrebbeScrivereIlSalvataggioDopoDieciGiriEChiudereLeSchermate;
begin
  PushUnder;
  FWorld.Game.PushState(TXcomSaveGameState.Create(FWorld.Game, ooGeoscape, 'mine.sav', nil));
  FWorld.Wait(400);
  Assert.AreEqual('mine.sav', FSaver.Saved.CommaText);
  Assert.IsFalse(FWorld.Game.TopState is TXcomSaveGameState);
end;

procedure TTestXcomPauseSave.DovrebbeLasciareLaFinestraDellePausaSeIronman;
begin
  FSaver.Ironman := True;
  PushUnder;
  FWorld.Game.PushState(TXcomSaveGameState.Create(FWorld.Game, ooGeoscape, 'mine.sav', nil));
  FWorld.Wait(400);
  Assert.AreEqual(1, FSaver.Saved.Count);
end;

procedure TTestXcomPauseSave.DovrebbeDareIlNomeFissoALSalvataggioRapido;
begin
  FWorld.Game.PushState(TXcomSaveGameState.Create(FWorld.Game, ooGeoscape, stQuick, nil));
  FWorld.Wait(400);
  Assert.AreEqual(TXcomSaveNames.QUICKSAVE, FSaver.Saved.CommaText);
  // the name of the saved game is the name of the file
  Assert.AreEqual(TXcomSaveNames.QUICKSAVE, FSaver.Name);
end;

procedure TTestXcomPauseSave.DovrebbeMostrareLErroreSeIlSalvataggioFallisce;
begin
  FSaver.FailWith := 'disk full';
  PushUnder;
  FWorld.Game.PushState(TXcomSaveGameState.Create(FWorld.Game, ooGeoscape, 'mine.sav', nil));
  FWorld.Wait(400);
  Assert.IsTrue(FWorld.Game.TopState is TXcomErrorMessageState);
end;

procedure TTestXcomPauseSave.DovrebbeMostrareLErroreSenzaIlSalvatore;
begin
  FWorld.Game.SetSavedGameSaver(nil);
  PushUnder;
  FWorld.Game.PushState(TXcomSaveGameState.Create(FWorld.Game, ooGeoscape, 'mine.sav', nil));
  FWorld.Wait(400);
  Assert.IsTrue(FWorld.Game.TopState is TXcomErrorMessageState);
end;

procedure TTestXcomPauseSave.DovrebbeAbbandonareLaPartitaDopoIlSalvataggioIronman;
begin
  FSaver.Ironman := True;
  FSaver.Name := 'My: game';
  FWorld.Game.PushState(TXcomSaveGameState.Create(FWorld.Game, ooGeoscape, stIronmanEnd, nil));
  FWorld.Wait(400);
  Assert.AreEqual('My_ game.sav', FSaver.Saved.CommaText.DeQuotedString('"'));
  Assert.AreEqual(1, FSaver.Abandoned);
end;

procedure TTestXcomPauseSave.LaListaDeiSalvataggiHaLaRigaDelNuovoSlotInCima;
var
  LState: TXcomListSaveState;
  LInfo: TXcomSaveInfo;
begin
  LInfo := Default(TXcomSaveInfo);
  LInfo.FileName := 'a.sav';
  LInfo.DisplayName := 'a';
  LInfo.Timestamp := 40000;
  LInfo.IsoDate := '2009-07-06';
  LInfo.IsoTime := '10:00';
  FCatalog.Saves := [LInfo];
  LState := TXcomListSaveState.Create(FWorld.Game, ooGeoscape);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  Assert.AreEqual(2, LState.List.GetRows);
  Assert.AreEqual('a', LState.List.GetCellText(1, 0));
  Assert.IsFalse(LState.Edit.Visible);
end;

procedure TTestXcomPauseSave.IlPulsanteSalvaSenzaUnaRigaSceltaNonFaNulla;
var
  LState: TXcomListSaveState;
begin
  LState := TXcomListSaveState.Create(FWorld.Game, ooGeoscape);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  ClickButton(LState.SaveButton);
  FWorld.Wait(50);
  Assert.IsTrue(FWorld.Game.TopState is TXcomListSaveState);
end;

procedure TTestXcomPauseSave.IronmanNonHaIlPulsanteAnnulla;
var
  LState: TXcomListSaveState;
begin
  FSaver.Ironman := True;
  LState := TXcomListSaveState.Create(FWorld.Game, ooGeoscape);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  Assert.AreEqual(200, LState.SaveButton.Width);
end;

procedure TTestXcomPauseSave.LaPausaApreLeSchermateDeiPulsanti;
var
  LState: TXcomPauseState;
begin
  LState := TXcomPauseState.Create(FWorld.Game, ooGeoscape, nil);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  ClickButton(LState.LoadButton);
  Assert.IsTrue(FWorld.Game.TopState is TXcomListLoadState, 'load');
  FWorld.Game.PopState;
  FWorld.Wait(50);
  ClickButton(LState.SaveButton);
  Assert.IsTrue(FWorld.Game.TopState is TXcomListSaveState, 'save');
end;

procedure TTestXcomPauseSave.LaPausaNascondeCaricaESalvaInIronman;
var
  LState: TXcomPauseState;
begin
  FSaver.Ironman := True;
  LState := TXcomPauseState.Create(FWorld.Game, ooGeoscape, nil);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  Assert.IsFalse(LState.LoadButton.Visible);
  Assert.IsFalse(LState.SaveButton.Visible);
end;

procedure TTestXcomPauseSave.AnnullaChiudeLaPausa;
var
  LState: TXcomPauseState;
begin
  LState := TXcomPauseState.Create(FWorld.Game, ooGeoscape, nil);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  ClickButton(LState.CancelButton);
  FWorld.Wait(50);
  Assert.IsFalse(FWorld.Game.TopState is TXcomPauseState);
end;

procedure TTestXcomPauseSave.OpzioniSenzaNavigatoreNonFaNulla;
var
  LState: TXcomPauseState;
begin
  LState := TXcomPauseState.Create(FWorld.Game, ooGeoscape, nil);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  ClickButton(LState.OptionsButton);
  Assert.IsTrue(FWorld.Game.TopState is TXcomPauseState);
end;

procedure TTestXcomPauseSave.AbbandonaSiRispondeNoOSi;
var
  LState: TXcomAbandonGameState;
begin
  LState := TXcomAbandonGameState.Create(FWorld.Game, ooGeoscape);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  ClickButton(LState.NoButton);
  FWorld.Wait(50);
  Assert.AreEqual(0, FSaver.Abandoned);
  Assert.IsFalse(FWorld.Game.TopState is TXcomAbandonGameState);
  LState := TXcomAbandonGameState.Create(FWorld.Game, ooGeoscape);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  ClickButton(LState.YesButton);
  Assert.AreEqual(1, FSaver.Abandoned);
end;

procedure TTestXcomPauseSave.AbbandonareInIronmanSalvaPrima;
var
  LState: TXcomAbandonGameState;
begin
  FSaver.Ironman := True;
  LState := TXcomAbandonGameState.Create(FWorld.Game, ooGeoscape);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  ClickButton(LState.YesButton);
  FWorld.Wait(400);
  // saved first (a file named after the game), then abandoned
  Assert.AreEqual(1, FSaver.Saved.Count);
  Assert.AreEqual(1, FSaver.Abandoned);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomSaveNames);
  TDUnitX.RegisterTestFixture(TTestXcomPauseSave);

end.
