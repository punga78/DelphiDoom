{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - the screen of the minimap      }
{  (MiniMapState)                                                               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.MiniMapState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.Widget,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Timer, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.BattlescapeButton, DelphiDoom.XcomBattleStates.BattlescapeState,
  DelphiDoom.XcomBattleStates.MiniMapView;

type
  /// <summary>
  ///   The minimap of the battle: the frame SCANBORD.PCK, the map seen from above, the buttons of the level and
  ///   the level shown. The map blinks every 125 ms. The camera moved here is the one of the battlescape.
  ///   Not ported: Options::maximizeInfoScreens (the change of the resolution of the screen)
  /// </summary>
  TXcomMiniMapState = class(TXcomState)
  strict private
    FParent: TXcomBattlescapeState;
    FBackground: TXcomWidget;
    FMiniMapView: TXcomMiniMapView;
    FBtnLevelUp: TXcomBattlescapeButton;
    FBtnLevelDown: TXcomBattlescapeButton;
    FBtnOk: TXcomBattlescapeButton;
    FTxtLevel: TXcomText;
    FTimerAnimate: TXcomTimer;
    procedure AddButton(AButton: TXcomBattlescapeButton; const AId: string);
    procedure ShowLevel(ALevel: Integer);
    procedure BtnOkClick(AAction: TXcomAction);
    procedure BtnLevelUpClick(AAction: TXcomAction);
    procedure BtnLevelDownClick(AAction: TXcomAction);
    procedure Animate;
  public
    /// <param name="AParent">The battlescape that opens the minimap: its session and its camera are used</param>
    constructor Create(AHost: TXcomStateHost; AParent: TXcomBattlescapeState);
    destructor Destroy; override;
    procedure Init; override;
    procedure Think; override;
    /// <summary>handle: the wheel of the mouse changes the level</summary>
    procedure Handle(AAction: TXcomAction); override;
    property MiniMapView: TXcomMiniMapView read FMiniMapView;
    property BtnLevelUp: TXcomBattlescapeButton read FBtnLevelUp;
    property BtnLevelDown: TXcomBattlescapeButton read FBtnLevelDown;
    property BtnOk: TXcomBattlescapeButton read FBtnOk;
    property TxtLevel: TXcomText read FTxtLevel;
  end;

implementation

uses
  DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomBattleStates.Session.Intf;

const
  ANIMATION_INTERVAL = 125;
  // the screen is taller than the minimap by more than this: the battlescape stays visible around it
  TALL_SCREEN = 50;

constructor TXcomMiniMapState.Create(AHost: TXcomStateHost; AParent: TXcomBattlescapeState);
var
  LSession: IXcomBattleSession;
  LBorder: TXcomSurface;
  LDrag: TXcomMiniMapDragOptions;
begin
  inherited Create(AHost);
  FParent := AParent;
  LSession := AParent.Session;
  LDrag.Button := Host.Options.GetValue('battleDragScrollButton');
  LDrag.Invert := Host.Options.GetBool('battleDragScrollInvert');
  LDrag.TimeTolerance := Host.Options.GetValue('dragScrollTimeTolerance');
  LDrag.PixelTolerance := Host.Options.GetValue('dragScrollPixelTolerance');
  FBackground := TXcomWidget.Create(320, 200);
  FMiniMapView := TXcomMiniMapView.Create(221, 148, 48, 16, LSession.Graphics.SurfaceSet('SCANG.DAT'),
    AParent.Map.Camera, LSession.Battle, Host.Clock, LDrag, LSession.Pathfinding.PreviewRed);
  FBtnLevelUp := TXcomBattlescapeButton.Create(18, 20, 24, 62);
  FBtnLevelDown := TXcomBattlescapeButton.Create(18, 20, 24, 88);
  FBtnOk := TXcomBattlescapeButton.Create(32, 32, 275, 145);
  FTxtLevel := TXcomText.Create(28, 16, 281, 75);
  // SavedBattleGame::setPaletteByDepth
  SetPalette('PAL_BATTLESCAPE', -1);
  SetPalette(LSession.Graphics.Palette(LSession.Battle.Depth), 0, 256);
  LSession.Graphics.SetPalette(@Palette^[0]);
  Add(FBackground);
  LBorder := LSession.Graphics.Surface('SCANBORD.PCK');
  if Assigned(LBorder) then
    LBorder.Blit(FBackground);
  Add(FMiniMapView);
  AddButton(FBtnLevelUp, 'buttonUp');
  AddButton(FBtnLevelDown, 'buttonDown');
  AddButton(FBtnOk, 'buttonOK');
  Add(FTxtLevel, 'textLevel', 'minimap', FBackground);
  CenterAllSurfaces;
  if Host.Screen.DY > TALL_SCREEN then
  begin
    ToggleScreen;
    // Palette::blockOffset(15) + 15
    FBackground.DrawRect(46, 14, 223, 151, 255);
  end;
  FBtnLevelUp.OnMouseClick(BtnLevelUpClick);
  FBtnLevelDown.OnMouseClick(BtnLevelDownClick);
  FBtnOk.OnMouseClick(BtnOkClick);
  FBtnOk.OnKeyboardPress(BtnOkClick, Host.Options.KeyCancel);
  FBtnOk.OnKeyboardPress(BtnOkClick, Host.Options.GetValue('keyBattleMap'));
  FMiniMapView.OnClose := BtnOkClick;
  FTxtLevel.SetBig;
  FTxtLevel.SetHighContrast(True);
  ShowLevel(AParent.Map.Camera.ViewLevel);
  FTimerAnimate := TXcomTimer.Create(Host.Clock, ANIMATION_INTERVAL);
  FTimerAnimate.OnTimerState(Animate);
  FTimerAnimate.Start;
  FMiniMapView.Draw;
end;

destructor TXcomMiniMapState.Destroy;
begin
  FTimerAnimate.Free;
  inherited Destroy;
end;

procedure TXcomMiniMapState.AddButton(AButton: TXcomBattlescapeButton; const AId: string);
begin
  Add(AButton, AId, 'minimap', FBackground);
  // State::add: a battlescape button takes its picture from the surface under it
  AButton.Copy(FBackground);
  AButton.InitSurfaces;
end;

procedure TXcomMiniMapState.Init;
begin
  inherited Init;
  // State::init, Mod::setPalette: the pictures of the battle follow the palette of the state on screen
  FParent.Session.Graphics.SetPalette(@Palette^[0]);
end;

procedure TXcomMiniMapState.ShowLevel(ALevel: Integer);
begin
  FTxtLevel.SetText(Tr('STR_LEVEL_SHORT').Arg(ALevel));
end;

procedure TXcomMiniMapState.Handle(AAction: TXcomAction);
begin
  inherited Handle(AAction);
  if AAction.Details.Kind = ekMouseDown then
  begin
    if AAction.Details.Button = XCOM_BUTTON_WHEELUP then
      BtnLevelUpClick(AAction)
    else if AAction.Details.Button = XCOM_BUTTON_WHEELDOWN then
      BtnLevelDownClick(AAction);
  end;
end;

procedure TXcomMiniMapState.BtnOkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

procedure TXcomMiniMapState.BtnLevelUpClick(AAction: TXcomAction);
begin
  ShowLevel(FMiniMapView.Up);
end;

procedure TXcomMiniMapState.BtnLevelDownClick(AAction: TXcomAction);
begin
  ShowLevel(FMiniMapView.Down);
end;

procedure TXcomMiniMapState.Animate;
begin
  FMiniMapView.Animate;
end;

procedure TXcomMiniMapState.Think;
begin
  inherited Think;
  FTimerAnimate.Think(True, False);
end;

end.
