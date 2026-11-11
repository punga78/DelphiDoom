{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the menus opened over a battle: the palette of the }
{  battle that the game keeps, State.SetInterface with a battle and the         }
{  battlescape theme (State::applyBattlescapeTheme)                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomEngine.BattlescapeTheme;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Widget, DelphiDoom.XcomMenu.OptionsTypes, DelphiDoom.XcomMenu.OptionsNavigator.Intf,
  DelphiDoom.Tests.XcomEngine.World;

type
  /// <summary>The navigator of the options that records the category it is asked</summary>
  TFakeOptionsNavigator = class(TInterfacedObject, IXcomOptionsNavigator)
  public
    Asked: Integer;
    Category: TXcomOptionsCategory;
    Origin: TXcomOptionsOrigin;
    function CreateCategory(ACategory: TXcomOptionsCategory; AOrigin: TXcomOptionsOrigin;
      AHost: TXcomStateHost): TXcomState;
    procedure Restart(AOrigin: TXcomOptionsOrigin; AHost: TXcomStateHost);
  end;

  [TestFixture]
  [Category('XcomMenu')]
  TTestXcomBattlescapeTheme = class
  strict private
    FWorld: TTestWorld;
    FBattleColors: TXcomColors;
    FOwner: TObject;
    procedure StartBattle;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure IlGiocoSenzaBattagliaNonHaLaPaletteDellaBattaglia;
    [Test]
    procedure SoloChiHaDatoLaPaletteLaPuoTogliere;
    [Test]
    procedure LaPausaDallaBattagliaPrendeIColoriDellaBattaglia;
    [Test]
    procedure LaPausaDalGeoscapeTieneLaPaletteDellInterfacciaAncheConUnaBattaglia;
    [Test]
    procedure IlTemaDaIlColoreElAltoContrastoAOgniSuperficie;
    [Test]
    procedure SenzaLElementoDelTemaIColoriRestano;
    [Test]
    procedure LeOpzioniDellaPausaInBattagliaSonoQuelleDelBattlescape;
    [Test]
    procedure LeOpzioniDellaPausaDelGeoscapeSonoQuelleDelGeoscape;
    [Test]
    procedure AbbandonaDallaBattagliaHaIlTema;
  end;

implementation

uses
  DelphiDoom.XcomMenu.PauseState, DelphiDoom.XcomMenu.AbandonGameState, DelphiDoom.XcomMenu.BattlescapeTheme;

const
  THEME_COLOR = 5;
  MENU_COLOR = 9;

{ TFakeOptionsNavigator }

function TFakeOptionsNavigator.CreateCategory(ACategory: TXcomOptionsCategory; AOrigin: TXcomOptionsOrigin;
  AHost: TXcomStateHost): TXcomState;
begin
  Inc(Asked);
  Category := ACategory;
  Origin := AOrigin;
  Result := nil;
end;

procedure TFakeOptionsNavigator.Restart(AOrigin: TXcomOptionsOrigin; AHost: TXcomStateHost);
begin
end;

{ TTestXcomBattlescapeTheme }

procedure TTestXcomBattlescapeTheme.Setup;
var
  LIndex: Integer;
begin
  FWorld := TTestWorld.Create;
  FOwner := TObject.Create;
  for LIndex := 0 to 255 do
  begin
    FBattleColors[LIndex].Red := 7;
    FBattleColors[LIndex].Green := Byte(LIndex);
    FBattleColors[LIndex].Blue := 11;
    FBattleColors[LIndex].Alpha := 255;
  end;
  FWorld.Resources.AddInterface('mainMenu',
    'elements:'#10'  - id: battlescapeTheme'#10'    color: 5'#10'    border: 3'#10);
  FWorld.Resources.AddInterface('pauseMenu',
    'elements:'#10'  - id: window'#10'    color: 9'#10'  - id: button'#10'    color: 9'#10'  - id: text'#10 +
    '    color: 9'#10);
  FWorld.Resources.AddSurface('TAC00.SCR', 77);
end;

procedure TTestXcomBattlescapeTheme.TearDown;
begin
  FWorld.Free;
  FOwner.Free;
end;

procedure TTestXcomBattlescapeTheme.StartBattle;
begin
  FWorld.Game.SetBattlePalette(FOwner, @FBattleColors[0]);
end;

procedure TTestXcomBattlescapeTheme.IlGiocoSenzaBattagliaNonHaLaPaletteDellaBattaglia;
begin
  Assert.IsTrue(FWorld.Game.BattlePalette = nil);
end;

procedure TTestXcomBattlescapeTheme.SoloChiHaDatoLaPaletteLaPuoTogliere;
var
  LOther: TObject;
begin
  LOther := TObject.Create;
  try
    StartBattle;
    // a battle that replaces another is made before the old one is freed
    FWorld.Game.SetBattlePalette(LOther, @FBattleColors[0]);
    FWorld.Game.SetBattlePalette(FOwner, nil);
    Assert.IsTrue(FWorld.Game.BattlePalette <> nil, 'the old battle cannot take back the colors of the new one');
    FWorld.Game.SetBattlePalette(LOther, nil);
    Assert.IsTrue(FWorld.Game.BattlePalette = nil);
  finally
    LOther.Free;
  end;
end;

procedure TTestXcomBattlescapeTheme.LaPausaDallaBattagliaPrendeIColoriDellaBattaglia;
var
  LState: TXcomPauseState;
begin
  StartBattle;
  // the game keeps a copy: the battle may change its array afterwards
  FBattleColors[100].Red := 200;
  LState := TXcomPauseState.Create(FWorld.Game, ooBattlescape, nil);
  FWorld.Game.PushState(LState);
  Assert.AreEqual(7, Integer(LState.Palette^[100].Red));
  Assert.AreEqual(100, Integer(LState.Palette^[100].Green));
  Assert.AreEqual(11, Integer(LState.Palette^[100].Blue));
  Assert.AreEqual(THEME_COLOR, Integer(LState.CancelButton.GetColor));
  FWorld.Wait(400);
  // the cursor color of the battlescape
  Assert.AreEqual(144, Integer(FWorld.Game.Cursor.GetColor));
end;

procedure TTestXcomBattlescapeTheme.LaPausaDalGeoscapeTieneLaPaletteDellInterfacciaAncheConUnaBattaglia;
var
  LState: TXcomPauseState;
begin
  LState := TXcomPauseState.Create(FWorld.Game, ooGeoscape, nil);
  FWorld.Game.PushState(LState);
  // the palette of the fake resources: red is the index
  Assert.AreEqual(100, Integer(LState.Palette^[100].Red));
  Assert.AreEqual(MENU_COLOR, Integer(LState.CancelButton.GetColor));
end;

procedure TTestXcomBattlescapeTheme.IlTemaDaIlColoreElAltoContrastoAOgniSuperficie;
var
  LState: TXcomPauseState;
  LCount: Integer;
begin
  LState := TXcomPauseState.Create(FWorld.Game, ooGeoscape, nil);
  FWorld.Game.PushState(LState);
  TXcomBattlescapeTheme.Apply(LState);
  Assert.AreEqual(THEME_COLOR, Integer(LState.LoadButton.GetColor));
  Assert.AreEqual(THEME_COLOR, Integer(LState.SaveButton.GetColor));
  Assert.AreEqual(THEME_COLOR, Integer(LState.AbandonButton.GetColor));
  Assert.AreEqual(THEME_COLOR, Integer(LState.OptionsButton.GetColor));
  LCount := 0;
  LState.VisitSurfaces(
    procedure(ASurface: TXcomWidget)
    begin
      Inc(LCount);
    end);
  // window, five buttons and the title
  Assert.AreEqual(7, LCount);
end;

procedure TTestXcomBattlescapeTheme.SenzaLElementoDelTemaIColoriRestano;
var
  LState: TXcomPauseState;
begin
  FWorld.Resources.AddInterface('mainMenu', 'elements:'#10'  - id: window'#10'    color: 1'#10);
  StartBattle;
  LState := TXcomPauseState.Create(FWorld.Game, ooBattlescape, nil);
  FWorld.Game.PushState(LState);
  Assert.AreEqual(MENU_COLOR, Integer(LState.CancelButton.GetColor));
end;

procedure TTestXcomBattlescapeTheme.LeOpzioniDellaPausaInBattagliaSonoQuelleDelBattlescape;
var
  LNavigator: TFakeOptionsNavigator;
  LNavigatorRef: IXcomOptionsNavigator;
  LState: TXcomPauseState;
begin
  LNavigator := TFakeOptionsNavigator.Create;
  LNavigatorRef := LNavigator;
  StartBattle;
  LState := TXcomPauseState.Create(FWorld.Game, ooBattlescape, LNavigatorRef);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  FWorld.Click(Round((LState.OptionsButton.X + 5) * FWorld.Game.Screen.XScale),
    Round((LState.OptionsButton.Y + 5) * FWorld.Game.Screen.YScale));
  Assert.AreEqual(1, LNavigator.Asked);
  Assert.IsTrue(LNavigator.Category = ocBattlescape);
  Assert.IsTrue(LNavigator.Origin = ooBattlescape);
end;

procedure TTestXcomBattlescapeTheme.LeOpzioniDellaPausaDelGeoscapeSonoQuelleDelGeoscape;
var
  LNavigator: TFakeOptionsNavigator;
  LNavigatorRef: IXcomOptionsNavigator;
  LState: TXcomPauseState;
begin
  LNavigator := TFakeOptionsNavigator.Create;
  LNavigatorRef := LNavigator;
  LState := TXcomPauseState.Create(FWorld.Game, ooGeoscape, LNavigatorRef);
  FWorld.Game.PushState(LState);
  FWorld.Wait(400);
  FWorld.Click(Round((LState.OptionsButton.X + 5) * FWorld.Game.Screen.XScale),
    Round((LState.OptionsButton.Y + 5) * FWorld.Game.Screen.YScale));
  Assert.AreEqual(1, LNavigator.Asked);
  Assert.IsTrue(LNavigator.Category = ocGeoscape);
end;

procedure TTestXcomBattlescapeTheme.AbbandonaDallaBattagliaHaIlTema;
var
  LState: TXcomAbandonGameState;
  LColors: string;
begin
  FWorld.Resources.AddInterface('geoscape',
    'elements:'#10'  - id: genericWindow'#10'    color: 9'#10'  - id: genericButton2'#10'    color: 9'#10 +
    '  - id: genericText'#10'    color: 9'#10);
  StartBattle;
  LState := TXcomAbandonGameState.Create(FWorld.Game, ooBattlescape);
  FWorld.Game.PushState(LState);
  Assert.AreEqual(100, Integer(LState.Palette^[100].Green));
  LColors := '';
  LState.VisitSurfaces(
    procedure(ASurface: TXcomWidget)
    begin
      LColors := LColors + IntToStr(ASurface.GetColor) + ' ';
    end);
  Assert.AreEqual('5 5 5 5 ', LColors);
end;

end.
