{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - the screen of the battle       }
{  (BattlescapeState: the map, the panel of the icons, the selected soldier,    }
{  the timers of the steps and of the animation)                                }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.BattlescapeState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomMod.MapBlock, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.Widget,
  DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Timer,
  DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.NumberText, DelphiDoom.XcomUi.Bar, DelphiDoom.XcomUi.BattlescapeButton,
  DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.SavedBattleGame, DelphiDoom.XcomBattle.View.Intf,
  DelphiDoom.XcomBattle.BattlescapeGame, DelphiDoom.XcomBattle.Options, DelphiDoom.XcomBattleStates.Session.Intf,
  DelphiDoom.XcomBattleStates.Screens.Intf, DelphiDoom.XcomBattleStates.MapWidget,
  DelphiDoom.XcomBattleStates.WarningMessage;

const
  /// <summary>BattlescapeState::VISIBLE_MAX: the buttons of the enemies in sight</summary>
  XCOM_VISIBLE_MAX = 10;

type
  /// <summary>
  ///   The screen of the battle. It owns the game in progress (TXcomBattlescapeGame) and is its view: the steps of
  ///   the battle ask it for warnings, sounds, the camera and the other screens. The session (the battle and its
  ///   engines) is shared with the screens it opens; the screens and the sounds come from interfaces (nil: the
  ///   button does nothing, no sound). An interface without count: the game holds it and is freed first.
  ///   Not ported: the scrolling by dragging, the second stage of a mission, the debug keys and the voxel dumps
  /// </summary>
  TXcomBattlescapeState = class(TXcomState, IXcomBattleView)
  strict private
    FSession: IXcomBattleSession;
    FScreens: IXcomBattleScreens;
    FAudio: IXcomBattleAudio;
    FSave: TXcomSavedBattleGame;
    FGame: TXcomBattlescapeGame;
    FMap: TXcomMapWidget;
    FIcons: TXcomInteractiveSurface;
    FRank: TXcomWidget;
    FBtnUnitUp, FBtnUnitDown, FBtnMapUp, FBtnMapDown, FBtnShowMap, FBtnKneel, FBtnInventory, FBtnCenter,
      FBtnNextSoldier, FBtnNextStop, FBtnShowLayers, FBtnHelp, FBtnEndTurn, FBtnAbort, FBtnReserveNone,
      FBtnReserveSnap, FBtnReserveAimed, FBtnReserveAuto, FBtnReserveKneel, FBtnZeroTUs, FBtnLaunch,
      FBtnPsi: TXcomBattlescapeButton;
    FBtnStats, FBtnLeftHandItem, FBtnRightHandItem: TXcomInteractiveSurface;
    FBtnVisibleUnit: array[0..XCOM_VISIBLE_MAX - 1] of TXcomInteractiveSurface;
    FNumVisibleUnit: array[0..XCOM_VISIBLE_MAX - 1] of TXcomNumberText;
    FVisibleUnit: array[0..XCOM_VISIBLE_MAX - 1] of TXcomBattleUnit;
    FNumLayers, FNumAmmoLeft, FNumAmmoRight, FNumTimeUnits, FNumEnergy, FNumHealth, FNumMorale: TXcomNumberText;
    FBarTimeUnits, FBarEnergy, FBarHealth, FBarMorale: TXcomBar;
    FTxtName, FTxtDebug, FTxtTooltip: TXcomText;
    FWarning: TXcomWarningMessage;
    FReserve: TXcomBattlescapeButtonGroup;
    FAnimTimer: TXcomTimer;
    FGameTimer: TXcomTimer;
    FPopups: TList<TXcomState>;
    FPopped: Boolean;
    FFirstInit: Boolean;
    FMouseOverIcons: Boolean;
    FCurrentTooltip: string;
    FBarHealthColor: Byte;
    FBlinkDelta: Integer;
    FBlinkColor: Integer;
    FHealthColor: Byte;
    FHealthStep: Byte;
    FFinished: Boolean;
    FAutosave: Boolean;
    procedure PushSave(AKind: TXcomBattleSaveKind);
    function IsIronman: Boolean;
    function Option(const AId: string): Integer;
    procedure AddIcon(ASurface: TXcomWidget; const AId: string);
    procedure SetupButton(AButton: TXcomInteractiveSurface; const AHandler: TXcomActionHandler; const AKeyOption,
      ATooltip: string; AMouseButton: Integer = XCOM_BUTTON_LEFT);
    function ReadOptions: TXcomBattleOptions;
    procedure Animate;
    procedure BlinkVisibleUnitButtons;
    procedure BlinkHealthBar;
    procedure ToggleKneelButton(const AUnit: TXcomBattleUnit);
    procedure DrawHandItem(const AItem: TXcomBattleItem; ASurface: TXcomInteractiveSurface; ANumber: TXcomNumberText);
    procedure HandleItemClick(const AItem: TXcomBattleItem);
    procedure RefreshPreview;
    procedure SelectReserve(AButton: TXcomBattlescapeButton);
    procedure PushScreen(AState: TXcomState);
    function UnitMessage(const AUnit: TXcomBattleUnit; const AMessage: string): string;
    // handlers
    procedure MapClick(AAction: TXcomAction);
    procedure BtnUnitUpClick(AAction: TXcomAction);
    procedure BtnUnitDownClick(AAction: TXcomAction);
    procedure BtnMapUpClick(AAction: TXcomAction);
    procedure BtnMapDownClick(AAction: TXcomAction);
    procedure BtnShowMapClick(AAction: TXcomAction);
    procedure BtnKneelClick(AAction: TXcomAction);
    procedure BtnInventoryClick(AAction: TXcomAction);
    procedure BtnCenterClick(AAction: TXcomAction);
    procedure BtnNextSoldierClick(AAction: TXcomAction);
    procedure BtnNextStopClick(AAction: TXcomAction);
    procedure BtnPrevSoldierClick(AAction: TXcomAction);
    procedure BtnShowLayersClick(AAction: TXcomAction);
    procedure BtnHelpClick(AAction: TXcomAction);
    procedure BtnEndTurnClick(AAction: TXcomAction);
    procedure BtnAbortClick(AAction: TXcomAction);
    procedure BtnStatsClick(AAction: TXcomAction);
    procedure BtnLeftHandItemClick(AAction: TXcomAction);
    procedure BtnRightHandItemClick(AAction: TXcomAction);
    procedure BtnVisibleUnitClick(AAction: TXcomAction);
    procedure BtnLaunchClick(AAction: TXcomAction);
    procedure BtnPsiClick(AAction: TXcomAction);
    procedure BtnReserveClick(AAction: TXcomAction);
    procedure BtnReserveKneelClick(AAction: TXcomAction);
    procedure BtnZeroTUsClick(AAction: TXcomAction);
    procedure BtnReloadClick(AAction: TXcomAction);
    procedure BtnPersonalLightingClick(AAction: TXcomAction);
    procedure TxtTooltipIn(AAction: TXcomAction);
    procedure TxtTooltipOut(AAction: TXcomAction);
  protected
    function QueryInterface(const AGuid: TGUID; out AObject): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    /// <param name="ASession">The battle to play, with its engines</param>
    /// <param name="AScreens">Makes the screens the buttons open; nil: they do nothing</param>
    /// <param name="AAudio">Plays the sounds of the battle; nil: none</param>
    constructor Create(AHost: TXcomStateHost; const ASession: IXcomBattleSession;
      const AScreens: IXcomBattleScreens; const AAudio: IXcomBattleAudio);
    destructor Destroy; override;
    procedure Init; override;
    procedure Think; override;
    procedure Handle(AAction: TXcomAction); override;
    /// <summary>autosave: the game is saved the next time the battlescape comes to the front (ironman or Options::autosave)</summary>
    procedure Autosave;
    /// <summary>popup: the state is pushed at the next think, one at a time (owned until then)</summary>
    procedure Popup(AState: TXcomState);
    /// <summary>selectNextPlayerUnit</summary>
    procedure SelectNextPlayerUnit(ACheckReselect: Boolean = False; ASetReselect: Boolean = False;
      ACheckInventory: Boolean = False; ACheckFov: Boolean = True);
    /// <summary>selectPreviousPlayerUnit</summary>
    procedure SelectPreviousPlayerUnit(ACheckReselect: Boolean = False; ASetReselect: Boolean = False;
      ACheckInventory: Boolean = False);
    /// <summary>btnCenterClick: the camera goes to the selected unit</summary>
    procedure CenterOnSelectedUnit;
    /// <summary>playableUnitSelected</summary>
    function PlayableUnitSelected: Boolean;
    /// <summary>allowButtons: not in the middle of a shot, of the alien turn or of a panic</summary>
    function AllowButtons(AAllowSaving: Boolean = False): Boolean;
    /// <summary>updateSoldierInfo with the choice of computing the field of view again</summary>
    procedure UpdateSoldierInfoWith(ACheckFov: Boolean);
    /// <summary>getLeftHandItem: the item of the left hand, or the built-in melee weapon when the right is taken</summary>
    function LeftHandItem(const AUnit: TXcomBattleUnit): TXcomBattleItem;
    /// <summary>getRightHandItem</summary>
    function RightHandItem(const AUnit: TXcomBattleUnit): TXcomBattleItem;
    property Session: IXcomBattleSession read FSession;
    property Screens: IXcomBattleScreens read FScreens;
    /// <summary>getBattleGame</summary>
    property Game: TXcomBattlescapeGame read FGame;
    /// <summary>getMap</summary>
    property Map: TXcomMapWidget read FMap;
    property Icons: TXcomInteractiveSurface read FIcons;
    property WarningMessage: TXcomWarningMessage read FWarning;
    /// <summary>finishBattle was called: the debriefing took the place of this screen</summary>
    property Finished: Boolean read FFinished;
    // IXcomBattleView
    procedure Warning(const AMessage: string);
    procedure Debug(const AMessage: string);
    procedure UpdateSoldierInfo;
    procedure CenterOnPosition(const APosition: TXcomPosition; AGraphic: Boolean = True);
    procedure SetViewLevel(ALevel: Integer);
    function IsOnScreen(const APosition: TXcomPosition; AUnitWalking: Boolean; AUnitSize: Integer;
      ABoundary: Boolean): Boolean;
    procedure CacheUnits;
    procedure CacheUnit(const AUnit: TXcomBattleUnit);
    procedure SetStateInterval(AMilliseconds: Integer);
    procedure ShowPsiButton(AShow: Boolean);
    procedure ShowLaunchButton(AShow: Boolean);
    procedure SetUnitDying(ADying: Boolean);
    procedure SetCursorType(ACursorType: Integer; ASize: Integer = 1);
    procedure PlaySound(ASound: Integer; const APosition: TXcomPosition);
    procedure AddExplosion(const ACenter: TXcomPosition; AStartFrame, AFrameDelay: Integer; ABig, AHit: Boolean);
    procedure SetProjectile(const AProjectile: TObject);
    procedure AddVaporCloud(const AVoxel: TXcomPosition; ADensity, AColor: Integer);
    procedure ResetObstacles;
    procedure EnableObstacles;
    procedure DisableObstacles;
    procedure SetBlastFlash(AFlash: Boolean);
    function BlastFlash: Boolean;
    function AnimateExplosions: Boolean;
    procedure SoldierKilled(const AUnit: TXcomBattleUnit);
    procedure ShowUnitMessage(const AUnit: TXcomBattleUnit; const AMessage: string; ANeedsConfirmation: Boolean);
    procedure FinishBattle(AAbort: Boolean; AInExitArea: Integer);
    procedure NextTurn;
    procedure ShowCursor(AVisible: Boolean);
    function CameraOffset: TXcomPosition;
    procedure SetCameraOffset(const AOffset: TXcomPosition);
    procedure AddWaypoint(const APosition: TXcomPosition);
    procedure RemoveLastWaypoint;
    procedure ClearWaypoints;
    procedure ShowUnitInfo(const AUnit: TXcomBattleUnit);
  end;

implementation

uses
  DelphiDoom.XcomSurface.Types, DelphiDoom.XcomSurface.SurfaceSet, DelphiDoom.XcomSurface.Shade, DelphiDoom.XcomEngine.RuleInterface,
  DelphiDoom.XcomMod.RuleItem, DelphiDoom.XcomBattle.Types, DelphiDoom.XcomBattle.Projectile;

const
  DEFAULT_ANIM_SPEED = 100;
  SCREEN_HEIGHT = 200;
  HAND_W = 2;
  HAND_H = 3;
  SLOT_W = 16;
  SLOT_H = 16;

function TXcomBattlescapeState.QueryInterface(const AGuid: TGUID; out AObject): HResult;
begin
  if GetInterface(AGuid, AObject) then
    Result := S_OK
  else
    Result := E_NOINTERFACE;
end;

function TXcomBattlescapeState._AddRef: Integer;
begin
  Result := -1;
end;

function TXcomBattlescapeState._Release: Integer;
begin
  Result := -1;
end;

function TXcomBattlescapeState.Option(const AId: string): Integer;
begin
  Result := Host.Options.GetValue(AId);
end;

function TXcomBattlescapeState.ReadOptions: TXcomBattleOptions;
begin
  Result := TXcomBattleOptions.Default;
  Result.WeaponSelfDestruction := Host.Options.GetBool('weaponSelfDestruction');
  Result.BattleNotifyDeath := Host.Options.GetBool('battleNotifyDeath');
  Result.BattleAutoEnd := Host.Options.GetBool('battleAutoEnd');
  Result.AllowPsionicCapture := Host.Options.GetBool('allowPsionicCapture');
  Result.AllowPsiStrengthImprovement := Host.Options.GetBool('allowPsiStrengthImprovement');
  Result.NoAlienPanicMessages := Host.Options.GetBool('noAlienPanicMessages');
  Result.BattleXcomSpeed := Option('battleXcomSpeed');
  Result.BattleAlienSpeed := Option('battleAlienSpeed');
  Result.BattleInstantGrenade := Host.Options.GetBool('battleInstantGrenade');
  Result.FireSpeed := Option('battleFireSpeed');
  Result.UfoExtenderAccuracy := Host.Options.GetBool('battleUFOExtenderAccuracy');
  Result.ForceFire := Host.Options.GetBool('forceFire');
  Result.PreviewPath := Option('battleNewPreviewPath');
  Result.ConfirmFireMode := Host.Options.GetBool('battleConfirmFireMode');
end;

procedure TXcomBattlescapeState.AddIcon(ASurface: TXcomWidget; const AId: string);
begin
  Add(ASurface, AId, 'battlescape', FIcons);
  // State::add: a battlescape button takes its picture from the panel under it
  if ASurface is TXcomBattlescapeButton then
  begin
    ASurface.Copy(FIcons);
    TXcomBattlescapeButton(ASurface).InitSurfaces;
  end;
end;

procedure TXcomBattlescapeState.SetupButton(AButton: TXcomInteractiveSurface; const AHandler: TXcomActionHandler;
  const AKeyOption, ATooltip: string; AMouseButton: Integer);
begin
  AButton.OnMouseClick(AHandler, AMouseButton);
  if AKeyOption <> '' then
    AButton.OnKeyboardPress(AHandler, Option(AKeyOption));
  AButton.Tooltip := ATooltip;
  AButton.OnMouseIn(TxtTooltipIn);
  AButton.OnMouseOut(TxtTooltipOut);
end;

constructor TXcomBattlescapeState.Create(AHost: TXcomStateHost; const ASession: IXcomBattleSession;
  const AScreens: IXcomBattleScreens; const AAudio: IXcomBattleAudio);
var
  LScreenWidth, LScreenHeight, LIconsWidth, LIconsHeight, LVisibleMapHeight, LX, LY, LIndex: Integer;
  LInterface: TXcomRuleInterface;
  LElement, LVisible, LWarning: TXcomInterfaceElement;
  LIconsSurface, LReserve: TXcomSurface;
  LTftd: Boolean;
  LSpecial: TXcomSurfaceSet;
  LFrame: TXcomSurface;
begin
  inherited Create(AHost);
  FSession := ASession;
  FScreens := AScreens;
  FAudio := AAudio;
  FSave := ASession.Battle;
  FFirstInit := True;
  FBlinkDelta := 1;
  FBlinkColor := 32;
  FPopups := TList<TXcomState>.Create;
  FReserve := TXcomBattlescapeButtonGroup.Create;
  LScreenWidth := Host.Options.BaseXResolution;
  LScreenHeight := Host.Options.BaseYResolution;
  LIconsWidth := 320;
  LIconsHeight := 56;
  LTftd := False;
  FillChar(LVisible, SizeOf(LVisible), 0);
  FillChar(LWarning, SizeOf(LWarning), 0);
  LInterface := Host.Resources.GetInterface('battlescape');
  if Assigned(LInterface) then
  begin
    if LInterface.TryGetElement('icons', LElement) then
    begin
      LIconsWidth := LElement.W;
      LIconsHeight := LElement.H;
      LTftd := LElement.TftdMode;
    end;
    LInterface.TryGetElement('visibleUnits', LVisible);
    LInterface.TryGetElement('warning', LWarning);
    if LInterface.TryGetElement('pathfinding', LElement) then
    begin
      ASession.Pathfinding.PreviewGreen := LElement.Color;
      ASession.Pathfinding.PreviewYellow := LElement.Color2;
      ASession.Pathfinding.PreviewRed := LElement.Border;
    end;
  end;
  LVisibleMapHeight := LScreenHeight - LIconsHeight;
  LX := LScreenWidth div 2 - LIconsWidth div 2;
  LY := LScreenHeight - LIconsHeight;
  // the button bar, on the center bottom of the screen, and the map under it
  FIcons := TXcomInteractiveSurface.Create(LIconsWidth, LIconsHeight, LX, LY);
  FMap := TXcomMapWidget.Create(Self, ASession, LScreenWidth, LScreenHeight, 0, 0, LVisibleMapHeight);
  FNumLayers := TXcomNumberText.Create(3, 5, LX + 232, LY + 6);
  FRank := TXcomWidget.Create(26, 23, LX + 107, LY + 33);
  FBtnUnitUp := TXcomBattlescapeButton.Create(32, 16, LX + 48, LY);
  FBtnUnitDown := TXcomBattlescapeButton.Create(32, 16, LX + 48, LY + 16);
  FBtnMapUp := TXcomBattlescapeButton.Create(32, 16, LX + 80, LY);
  FBtnMapDown := TXcomBattlescapeButton.Create(32, 16, LX + 80, LY + 16);
  FBtnShowMap := TXcomBattlescapeButton.Create(32, 16, LX + 112, LY);
  FBtnKneel := TXcomBattlescapeButton.Create(32, 16, LX + 112, LY + 16);
  FBtnInventory := TXcomBattlescapeButton.Create(32, 16, LX + 144, LY);
  FBtnCenter := TXcomBattlescapeButton.Create(32, 16, LX + 144, LY + 16);
  FBtnNextSoldier := TXcomBattlescapeButton.Create(32, 16, LX + 176, LY);
  FBtnNextStop := TXcomBattlescapeButton.Create(32, 16, LX + 176, LY + 16);
  FBtnShowLayers := TXcomBattlescapeButton.Create(32, 16, LX + 208, LY);
  FBtnHelp := TXcomBattlescapeButton.Create(32, 16, LX + 208, LY + 16);
  FBtnEndTurn := TXcomBattlescapeButton.Create(32, 16, LX + 240, LY);
  FBtnAbort := TXcomBattlescapeButton.Create(32, 16, LX + 240, LY + 16);
  FBtnStats := TXcomInteractiveSurface.Create(164, 23, LX + 107, LY + 33);
  FBtnReserveNone := TXcomBattlescapeButton.Create(17, 11, LX + 60, LY + 33);
  FBtnReserveSnap := TXcomBattlescapeButton.Create(17, 11, LX + 78, LY + 33);
  FBtnReserveAimed := TXcomBattlescapeButton.Create(17, 11, LX + 60, LY + 45);
  FBtnReserveAuto := TXcomBattlescapeButton.Create(17, 11, LX + 78, LY + 45);
  FBtnReserveKneel := TXcomBattlescapeButton.Create(10, 23, LX + 96, LY + 33);
  FBtnZeroTUs := TXcomBattlescapeButton.Create(10, 23, LX + 49, LY + 33);
  FBtnLeftHandItem := TXcomInteractiveSurface.Create(32, 48, LX + 8, LY + 4);
  FNumAmmoLeft := TXcomNumberText.Create(30, 5, LX + 8, LY + 4);
  FBtnRightHandItem := TXcomInteractiveSurface.Create(32, 48, LX + 280, LY + 4);
  FNumAmmoRight := TXcomNumberText.Create(30, 5, LX + 280, LY + 4);
  for LIndex := 0 to XCOM_VISIBLE_MAX - 1 do
  begin
    FBtnVisibleUnit[LIndex] := TXcomInteractiveSurface.Create(15, 12, LX + LVisible.X, LY + LVisible.Y - LIndex * 13);
    FNumVisibleUnit[LIndex] := TXcomNumberText.Create(15, 12, FBtnVisibleUnit[LIndex].X + 6,
      FBtnVisibleUnit[LIndex].Y + 4);
  end;
  // center number 10
  FNumVisibleUnit[9].X := FNumVisibleUnit[9].X - 2;
  FWarning := TXcomWarningMessage.Create(Host.Clock, 224, 24, LX + 48, LY + 32);
  // the screen width, because that is independent of the black bars on the screen
  FBtnLaunch := TXcomBattlescapeButton.Create(32, 24, LScreenWidth - 32, 0);
  FBtnLaunch.Visible := False;
  FBtnPsi := TXcomBattlescapeButton.Create(32, 24, LScreenWidth - 32, 25);
  FBtnPsi.Visible := False;
  FTxtName := TXcomText.Create(136, 10, LX + 135, LY + 32);
  FNumTimeUnits := TXcomNumberText.Create(15, 5, LX + 136, LY + 42);
  FBarTimeUnits := TXcomBar.Create(102, 3, LX + 170, LY + 41);
  FNumEnergy := TXcomNumberText.Create(15, 5, LX + 154, LY + 42);
  FBarEnergy := TXcomBar.Create(102, 3, LX + 170, LY + 45);
  FNumHealth := TXcomNumberText.Create(15, 5, LX + 136, LY + 50);
  FBarHealth := TXcomBar.Create(102, 3, LX + 170, LY + 49);
  FNumMorale := TXcomNumberText.Create(15, 5, LX + 154, LY + 50);
  FBarMorale := TXcomBar.Create(102, 3, LX + 170, LY + 53);
  FTxtDebug := TXcomText.Create(300, 10, 20, 0);
  FTxtTooltip := TXcomText.Create(300, 10, LX + 2, LY - 10);
  // SavedBattleGame::setPaletteByDepth
  // the cursor color of the battlescape, then the colors of the depth
  SetPalette('PAL_BATTLESCAPE', -1);
  SetPalette(ASession.Graphics.Palette(FSave.Depth), 0, 256);
  ASession.Graphics.SetPalette(@Palette^[0]);
  // the menus opened over the battle take these colors (State.SetInterface with ABattle)
  Host.SetBattlePalette(Self, @Palette^[0]);
  Add(FMap);
  Add(FIcons);
  // the icons image is 320x200 and only its bottom is needed
  LIconsSurface := ASession.Graphics.Surface('ICONS.PCK');
  if Assigned(LIconsSurface) then
  begin
    LReserve := ASession.Graphics.Surface('TFTDReserve');
    if Assigned(LReserve) then
    begin
      LReserve.X := 48;
      LReserve.Y := 176;
      LReserve.Blit(LIconsSurface);
    end;
    LIconsSurface.X := 0;
    LIconsSurface.Y := 0;
    LIconsSurface.Crop := TXcomRect.Make(0, SCREEN_HEIGHT - LIconsHeight, LIconsWidth, LIconsHeight);
    // the icons are blitted before the buttons are added, as they copy the underlying parent surface
    LIconsSurface.Blit(FIcons);
    LIconsSurface.ResetCrop;
  end;
  // a hack to fix the single transparent pixel on TFTD's icon panel
  if LTftd then
    FIcons.SetPixel(46, 44, 8);
  AddIcon(FRank, 'rank');
  AddIcon(FBtnUnitUp, 'buttonUnitUp');
  AddIcon(FBtnUnitDown, 'buttonUnitDown');
  AddIcon(FBtnMapUp, 'buttonMapUp');
  AddIcon(FBtnMapDown, 'buttonMapDown');
  AddIcon(FBtnShowMap, 'buttonShowMap');
  AddIcon(FBtnKneel, 'buttonKneel');
  AddIcon(FBtnInventory, 'buttonInventory');
  AddIcon(FBtnCenter, 'buttonCenter');
  AddIcon(FBtnNextSoldier, 'buttonNextSoldier');
  AddIcon(FBtnNextStop, 'buttonNextStop');
  AddIcon(FBtnShowLayers, 'buttonShowLayers');
  AddIcon(FNumLayers, 'numLayers');
  AddIcon(FBtnHelp, 'buttonHelp');
  AddIcon(FBtnEndTurn, 'buttonEndTurn');
  AddIcon(FBtnAbort, 'buttonAbort');
  AddIcon(FBtnStats, 'buttonStats');
  AddIcon(FTxtName, 'textName');
  AddIcon(FNumTimeUnits, 'numTUs');
  AddIcon(FNumEnergy, 'numEnergy');
  AddIcon(FNumHealth, 'numHealth');
  AddIcon(FNumMorale, 'numMorale');
  AddIcon(FBarTimeUnits, 'barTUs');
  AddIcon(FBarEnergy, 'barEnergy');
  AddIcon(FBarHealth, 'barHealth');
  AddIcon(FBarMorale, 'barMorale');
  AddIcon(FBtnReserveNone, 'buttonReserveNone');
  AddIcon(FBtnReserveSnap, 'buttonReserveSnap');
  AddIcon(FBtnReserveAimed, 'buttonReserveAimed');
  AddIcon(FBtnReserveAuto, 'buttonReserveAuto');
  AddIcon(FBtnReserveKneel, 'buttonReserveKneel');
  AddIcon(FBtnZeroTUs, 'buttonZeroTUs');
  AddIcon(FBtnLeftHandItem, 'buttonLeftHand');
  AddIcon(FNumAmmoLeft, 'numAmmoLeft');
  AddIcon(FBtnRightHandItem, 'buttonRightHand');
  AddIcon(FNumAmmoRight, 'numAmmoRight');
  for LIndex := 0 to XCOM_VISIBLE_MAX - 1 do
  begin
    Add(FBtnVisibleUnit[LIndex]);
    Add(FNumVisibleUnit[LIndex]);
  end;
  AddIcon(FWarning, 'warning');
  Add(FTxtDebug);
  AddIcon(FTxtTooltip, 'textTooltip');
  Add(FBtnLaunch);
  Add(FBtnPsi);
  LSpecial := ASession.Graphics.SurfaceSet('SPICONS.DAT');
  if Assigned(LSpecial) then
  begin
    LFrame := LSpecial.GetFrame(0);
    if Assigned(LFrame) then
      TXcomSurfaceShader.Blit(LFrame, FBtnLaunch, FBtnLaunch.X, FBtnLaunch.Y, 0);
    LFrame := LSpecial.GetFrame(1);
    if Assigned(LFrame) then
      TXcomSurfaceShader.Blit(LFrame, FBtnPsi, FBtnPsi.X, FBtnPsi.Y, 0);
  end;
  FMap.OnMouseClick(MapClick, 0);
  FMap.OnMouseIn(
    procedure(AAction: TXcomAction)
    begin
      FMap.SetButtonPressed(Option('battleDragScrollButton'), False);
    end);
  FMap.IsLaunchAction :=
    function: Boolean
    begin
      Result := Assigned(FGame) and (FGame.CurrentAction.ActionType = BA_LAUNCH);
    end;
  // Palette::blockOffset(1) - 2
  FNumLayers.SetColor(14);
  FNumLayers.SetValue(1);
  FNumAmmoLeft.SetValue(999);
  FNumAmmoRight.SetValue(999);
  FIcons.OnMouseIn(
    procedure(AAction: TXcomAction)
    begin
      FMouseOverIcons := True;
      FMap.Map.MouseOverIcons := True;
    end);
  FIcons.OnMouseOut(
    procedure(AAction: TXcomAction)
    begin
      FMouseOverIcons := False;
      FMap.Map.MouseOverIcons := False;
    end);
  SetupButton(FBtnUnitUp, BtnUnitUpClick, '', 'STR_UNIT_LEVEL_ABOVE');
  SetupButton(FBtnUnitDown, BtnUnitDownClick, '', 'STR_UNIT_LEVEL_BELOW');
  SetupButton(FBtnMapUp, BtnMapUpClick, 'keyBattleLevelUp', 'STR_VIEW_LEVEL_ABOVE');
  SetupButton(FBtnMapDown, BtnMapDownClick, 'keyBattleLevelDown', 'STR_VIEW_LEVEL_BELOW');
  SetupButton(FBtnShowMap, BtnShowMapClick, 'keyBattleMap', 'STR_MINIMAP');
  SetupButton(FBtnKneel, BtnKneelClick, 'keyBattleKneel', 'STR_KNEEL');
  FBtnKneel.AllowToggleInversion;
  SetupButton(FBtnInventory, BtnInventoryClick, 'keyBattleInventory', 'STR_INVENTORY');
  SetupButton(FBtnCenter, BtnCenterClick, 'keyBattleCenterUnit', 'STR_CENTER_SELECTED_UNIT');
  SetupButton(FBtnNextSoldier, BtnNextSoldierClick, 'keyBattleNextUnit', 'STR_NEXT_UNIT');
  FBtnNextSoldier.OnKeyboardPress(BtnPrevSoldierClick, Option('keyBattlePrevUnit'));
  SetupButton(FBtnNextStop, BtnNextStopClick, 'keyBattleDeselectUnit', 'STR_DESELECT_UNIT');
  SetupButton(FBtnShowLayers, BtnShowLayersClick, '', 'STR_MULTI_LEVEL_VIEW');
  SetupButton(FBtnHelp, BtnHelpClick, 'keyBattleOptions', 'STR_OPTIONS');
  SetupButton(FBtnEndTurn, BtnEndTurnClick, 'keyBattleEndTurn', 'STR_END_TURN');
  SetupButton(FBtnAbort, BtnAbortClick, 'keyBattleAbort', 'STR_ABORT_MISSION');
  SetupButton(FBtnStats, BtnStatsClick, 'keyBattleStats', 'STR_UNIT_STATS');
  SetupButton(FBtnLeftHandItem, BtnLeftHandItemClick, 'keyBattleUseLeftHand', 'STR_USE_LEFT_HAND');
  SetupButton(FBtnRightHandItem, BtnRightHandItemClick, 'keyBattleUseRightHand', 'STR_USE_RIGHT_HAND');
  SetupButton(FBtnReserveNone, BtnReserveClick, 'keyBattleReserveNone', 'STR_DONT_RESERVE_TIME_UNITS');
  SetupButton(FBtnReserveSnap, BtnReserveClick, 'keyBattleReserveSnap', 'STR_RESERVE_TIME_UNITS_FOR_SNAP_SHOT');
  SetupButton(FBtnReserveAimed, BtnReserveClick, 'keyBattleReserveAimed', 'STR_RESERVE_TIME_UNITS_FOR_AIMED_SHOT');
  SetupButton(FBtnReserveAuto, BtnReserveClick, 'keyBattleReserveAuto', 'STR_RESERVE_TIME_UNITS_FOR_AUTO_SHOT');
  SetupButton(FBtnReserveKneel, BtnReserveKneelClick, 'keyBattleReserveKneel', 'STR_RESERVE_TIME_UNITS_FOR_KNEEL');
  FBtnReserveKneel.AllowToggleInversion;
  SetupButton(FBtnZeroTUs, BtnZeroTUsClick, 'keyBattleZeroTUs', 'STR_EXPEND_ALL_TIME_UNITS', XCOM_BUTTON_RIGHT);
  FBtnZeroTUs.AllowClickInversion;
  // shortcuts without a specific button
  FBtnStats.OnKeyboardPress(BtnReloadClick, Option('keyBattleReload'));
  FBtnStats.OnKeyboardPress(BtnPersonalLightingClick, Option('keyBattlePersonalLighting'));
  for LIndex := 0 to XCOM_VISIBLE_MAX - 1 do
  begin
    // the tenth enemy is the key 0
    SetupButton(FBtnVisibleUnit[LIndex], BtnVisibleUnitClick, Format('keyBattleCenterEnemy%d', [LIndex + 1]),
      Format('STR_CENTER_ON_ENEMY_%d', [LIndex + 1]));
    FNumVisibleUnit[LIndex].SetColor(Byte(LVisible.Color));
    FNumVisibleUnit[LIndex].SetValue(Cardinal(LIndex + 1));
  end;
  FWarning.SetColor(Byte(LWarning.Color2));
  FWarning.SetTextColor(Byte(LWarning.Color));
  FBtnLaunch.OnMouseClick(BtnLaunchClick);
  FBtnPsi.OnMouseClick(BtnPsiClick);
  FTxtName.SetHighContrast(True);
  FBarTimeUnits.SetScale(1.0);
  FBarEnergy.SetScale(1.0);
  FBarHealth.SetScale(1.0);
  FBarMorale.SetScale(1.0);
  // Palette::blockOffset(8)
  FTxtDebug.SetColor(128);
  FTxtDebug.SetHighContrast(True);
  FTxtTooltip.SetHighContrast(True);
  FReserve.Selected := FBtnReserveNone;
  FBtnReserveNone.SetGroup(FReserve);
  FBtnReserveSnap.SetGroup(FReserve);
  FBtnReserveAimed.SetGroup(FReserve);
  FBtnReserveAuto.SetGroup(FReserve);
  if FSave.Music = '' then
    Host.PlayMusic('GMTACTIC')
  else
    Host.PlayMusic(FSave.Music);
  FAnimTimer := TXcomTimer.Create(Host.Clock, DEFAULT_ANIM_SPEED, True, Option('maxFrameSkip'));
  FAnimTimer.OnTimerState(Animate);
  FGameTimer := TXcomTimer.Create(Host.Clock, DEFAULT_ANIM_SPEED, True, Option('maxFrameSkip'));
  FGameTimer.OnTimerState(
    procedure
    begin
      FGame.HandleState;
    end);
  FGame := ASession.CreateGame(Self, ReadOptions);
  FBarHealthColor := FBarHealth.GetColor;
end;

destructor TXcomBattlescapeState.Destroy;
var
  LState: TXcomState;
begin
  if Assigned(FAudio) then
    FAudio.StopAmbience;
  Host.SetBattlePalette(Self, nil);
  FAnimTimer.Free;
  FGameTimer.Free;
  // the steps of the game refer to the projectile and to the view: the game goes first
  FGame.Free;
  if Assigned(FPopups) then
    for LState in FPopups do
      LState.Free;
  FPopups.Free;
  FReserve.Free;
  inherited Destroy;
  FSession := nil;
end;

procedure TXcomBattlescapeState.Init;
begin
  if (FSave.Ambience <> -1) and Assigned(FAudio) then
    FAudio.LoopAmbience(FSave.Depth, FSave.Ambience);
  inherited Init;
  FSession.Graphics.SetPalette(@Palette^[0]);
  FAnimTimer.Start;
  FGameTimer.Start;
  FMap.SetFocus(True);
  FMap.Map.CacheUnits;
  FGame.Init;
  UpdateSoldierInfo;
  case FSave.TuReserved of
    BA_SNAPSHOT: SelectReserve(FBtnReserveSnap);
    BA_AIMEDSHOT: SelectReserve(FBtnReserveAimed);
    BA_AUTOSHOT: SelectReserve(FBtnReserveAuto);
  else
    SelectReserve(FBtnReserveNone);
  end;
  if FFirstInit then
  begin
    if not PlayableUnitSelected then
      SelectNextPlayerUnit;
    if PlayableUnitSelected then
    begin
      FGame.SetupCursor;
      FMap.Camera.CenterOnPosition(FSave.SelectedUnit.Position);
    end;
    FFirstInit := False;
  end;
  FTxtTooltip.SetText('');
  FBtnReserveKneel.Toggle(FSave.KneelReserved);
  FGame.SetKneelReserved(FSave.KneelReserved);
  if FAutosave then
  begin
    FAutosave := False;
    if IsIronman then
      PushSave(bskIronman)
    else if Option('autosave') <> 0 then
      PushSave(bskAuto);
  end;
end;

procedure TXcomBattlescapeState.Autosave;
begin
  FAutosave := True;
end;

function TXcomBattlescapeState.IsIronman: Boolean;
begin
  Result := (Host.SavedGameSaver <> nil) and Host.SavedGameSaver.IsIronman;
end;

procedure TXcomBattlescapeState.PushSave(AKind: TXcomBattleSaveKind);
begin
  if not Assigned(FScreens) then
    Exit;
  // the saved game takes the battle as it is now
  FSession.StoreInSavedGame;
  PushScreen(FScreens.SaveGame(Self, AKind));
end;

procedure TXcomBattlescapeState.Think;
var
  LState: TXcomState;
begin
  if not FGameTimer.IsRunning then
    Exit;
  if FPopups.Count = 0 then
  begin
    inherited Think;
    FGame.Think;
    if FFinished then
      Exit;
    FAnimTimer.Think(True, False,
      function: Boolean
      begin
        Result := Host.IsState(Self);
      end);
    FGameTimer.Think(True, False,
      function: Boolean
      begin
        Result := Host.IsState(Self);
      end);
    if FPopped and (not FFinished) then
    begin
      FGame.HandleNonTargetAction;
      FPopped := False;
    end;
  end
  else
  begin
    // handle popups, one at a time
    LState := FPopups.First;
    FPopups.Delete(0);
    Host.PushState(LState);
    FPopped := True;
  end;
end;

procedure TXcomBattlescapeState.Handle(AAction: TXcomAction);
begin
  if FFirstInit then
    Exit;
  if Host.Cursor.Visible or (((AAction.Details.Kind = ekMouseDown) or (AAction.Details.Kind = ekMouseUp)) and
    (AAction.Details.Button = XCOM_BUTTON_RIGHT)) then
  begin
    inherited Handle(AAction);
    // quick save and quick load
    if (AAction.Details.Kind = ekKeyDown) and Assigned(FScreens) and (not FFinished) and (not IsIronman) then
    begin
      if AAction.Details.Key = Option('keyQuickSave') then
        PushSave(bskQuick)
      else if AAction.Details.Key = Option('keyQuickLoad') then
        PushScreen(FScreens.QuickLoad(Self));
    end;
  end;
end;

procedure TXcomBattlescapeState.Popup(AState: TXcomState);
begin
  if Assigned(AState) then
    FPopups.Add(AState);
end;

procedure TXcomBattlescapeState.PushScreen(AState: TXcomState);
begin
  if Assigned(AState) then
    Host.PushState(AState);
end;

procedure TXcomBattlescapeState.Animate;
begin
  FMap.Map.Animate(not FGame.IsBusy);
  BlinkVisibleUnitButtons;
  BlinkHealthBar;
end;

procedure TXcomBattlescapeState.BlinkVisibleUnitButtons;
var
  LIndex: Integer;
begin
  for LIndex := 0 to XCOM_VISIBLE_MAX - 1 do
    if FBtnVisibleUnit[LIndex].Visible then
    begin
      FBtnVisibleUnit[LIndex].DrawRect(0, 0, 15, 12, 15);
      FBtnVisibleUnit[LIndex].DrawRect(1, 1, 13, 10, Byte(FBlinkColor));
    end;
  if FBlinkColor = 44 then
    FBlinkDelta := -2;
  if FBlinkColor = 32 then
    FBlinkDelta := 1;
  Inc(FBlinkColor, FBlinkDelta);
end;

procedure TXcomBattlescapeState.BlinkHealthBar;
const
  MAX_COLOR = 3;
var
  LUnit: TXcomBattleUnit;
  LIndex: Integer;
begin
  FHealthStep := 1 - FHealthStep;
  LUnit := FSave.SelectedUnit;
  if (FHealthStep = 0) or (not Assigned(LUnit)) or (not FBarHealth.Visible) then
    Exit;
  Inc(FHealthColor);
  if FHealthColor > MAX_COLOR then
    FHealthColor := MAX_COLOR - 3;
  for LIndex := 0 to 5 do
    if LUnit.GetFatalWound(LIndex) > 0 then
    begin
      FBarHealth.SetColor(Byte(FBarHealthColor + FHealthColor));
      Exit;
    end;
  // avoid redrawing if we don't have to
  if FBarHealth.GetColor <> FBarHealthColor then
    FBarHealth.SetColor(FBarHealthColor);
end;

function TXcomBattlescapeState.PlayableUnitSelected: Boolean;
begin
  Result := Assigned(FSave.SelectedUnit) and AllowButtons;
end;

function TXcomBattlescapeState.AllowButtons(AAllowSaving: Boolean): Boolean;
begin
  Result := (AAllowSaving or (FSave.Side = FACTION_PLAYER) or FSave.DebugMode) and
    (FGame.PanicHandled or FFirstInit) and (AAllowSaving or (not FGame.IsBusy) or FFirstInit) and
    (not Assigned(FMap.Map.Projectile));
end;

function TXcomBattlescapeState.LeftHandItem(const AUnit: TXcomBattleUnit): TXcomBattleItem;
var
  LMelee: TXcomBattleItem;
begin
  LMelee := AUnit.GetSpecialWeapon(TXcomRuleItem.BT_MELEE);
  Result := AUnit.GetItem('STR_LEFT_HAND');
  if Assigned(LMelee) and Assigned(AUnit.GetItem('STR_RIGHT_HAND')) and (not Assigned(Result)) then
    Result := LMelee;
end;

function TXcomBattlescapeState.RightHandItem(const AUnit: TXcomBattleUnit): TXcomBattleItem;
var
  LMelee: TXcomBattleItem;
begin
  LMelee := AUnit.GetSpecialWeapon(TXcomRuleItem.BT_MELEE);
  Result := AUnit.GetItem('STR_RIGHT_HAND');
  if Assigned(LMelee) and (not Assigned(Result)) then
    Result := LMelee;
end;

procedure TXcomBattlescapeState.ToggleKneelButton(const AUnit: TXcomBattleUnit);
var
  LSet: TXcomSurfaceSet;
  LFrame: TXcomSurface;
  LKneeled: Boolean;
begin
  LKneeled := Assigned(AUnit) and AUnit.IsKneeled;
  if FBtnKneel.TftdMode then
    FBtnKneel.Toggle(LKneeled)
  else
  begin
    LSet := FSession.Graphics.SurfaceSet('KneelButton');
    if Assigned(LSet) then
    begin
      LFrame := LSet.GetFrame(Ord(LKneeled));
      if Assigned(LFrame) then
        TXcomSurfaceShader.Blit(LFrame, FBtnKneel, FBtnKneel.X, FBtnKneel.Y, 0);
    end;
  end;
end;

procedure TXcomBattlescapeState.DrawHandItem(const AItem: TXcomBattleItem; ASurface: TXcomInteractiveSurface;
  ANumber: TXcomNumberText);
var
  LFrame: TXcomSurface;
begin
  ASurface.Clear;
  ANumber.Visible := False;
  if not Assigned(AItem) then
    Exit;
  // RuleItem::drawHandSprite: the big sprite in the middle of the hand
  LFrame := FSession.Graphics.SurfaceSet('BIGOBS.PCK').GetFrame(AItem.Rules.BigSprite);
  // the shaded blit takes the position of the target into account and copies the pixels as they are
  if Assigned(LFrame) then
    TXcomSurfaceShader.Blit(LFrame, ASurface, ASurface.X + (HAND_W - AItem.Rules.InventoryWidth) * SLOT_W div 2,
      ASurface.Y + (HAND_H - AItem.Rules.InventoryHeight) * SLOT_H div 2, 0);
  if (AItem.Rules.BattleType = TXcomRuleItem.BT_FIREARM) and (AItem.NeedsAmmo or (AItem.Rules.ClipSize > 0)) then
  begin
    ANumber.Visible := True;
    if Assigned(AItem.AmmoItem) then
      ANumber.SetValue(Cardinal(AItem.AmmoItem.AmmoQuantity))
    else
      ANumber.SetValue(0);
  end;
end;

procedure TXcomBattlescapeState.UpdateSoldierInfo;
begin
  UpdateSoldierInfoWith(True);
end;

procedure TXcomBattlescapeState.UpdateSoldierInfoWith(ACheckFov: Boolean);
var
  LUnit: TXcomBattleUnit;
  LIndex: Integer;
  LPlayable: Boolean;
  LFrame: TXcomSurface;
  LOther: TXcomBattleUnit;
begin
  LUnit := FSave.SelectedUnit;
  for LIndex := 0 to XCOM_VISIBLE_MAX - 1 do
  begin
    FBtnVisibleUnit[LIndex].Visible := False;
    FNumVisibleUnit[LIndex].Visible := False;
    FVisibleUnit[LIndex] := nil;
  end;
  LPlayable := FGame.PlayableUnitSelected;
  FRank.Visible := LPlayable;
  FNumTimeUnits.Visible := LPlayable;
  FBarTimeUnits.Visible := LPlayable;
  FNumEnergy.Visible := LPlayable;
  FBarEnergy.Visible := LPlayable;
  FNumHealth.Visible := LPlayable;
  FBarHealth.Visible := LPlayable;
  FNumMorale.Visible := LPlayable;
  FBarMorale.Visible := LPlayable;
  FBtnLeftHandItem.Visible := LPlayable;
  FBtnRightHandItem.Visible := LPlayable;
  FNumAmmoLeft.Visible := LPlayable;
  FNumAmmoRight.Visible := LPlayable;
  if not LPlayable then
  begin
    FTxtName.SetText('');
    ShowPsiButton(False);
    ToggleKneelButton(nil);
    Exit;
  end;
  FTxtName.SetText(LUnit.DisplayName(
    function(AId: string): string
    begin
      Result := Tr(AId).Text;
    end, False));
  FRank.Clear;
  if Assigned(LUnit.GeoscapeSoldier) then
  begin
    LFrame := FSession.Graphics.SurfaceSet('SMOKE.PCK').GetFrame(20 + LUnit.GeoscapeSoldier.Rank);
    if Assigned(LFrame) then
      TXcomSurfaceShader.Blit(LFrame, FRank, FRank.X, FRank.Y, 0);
  end;
  FNumTimeUnits.SetValue(Cardinal(LUnit.TimeUnits));
  FBarTimeUnits.SetMax(LUnit.Stats.TimeUnits);
  FBarTimeUnits.SetValue(LUnit.TimeUnits);
  FNumEnergy.SetValue(Cardinal(LUnit.Energy));
  FBarEnergy.SetMax(LUnit.Stats.Stamina);
  FBarEnergy.SetValue(LUnit.Energy);
  FNumHealth.SetValue(Cardinal(LUnit.Health));
  FBarHealth.SetMax(LUnit.Stats.Health);
  FBarHealth.SetValue(LUnit.Health);
  FBarHealth.SetValue2(LUnit.StunLevel);
  FNumMorale.SetValue(Cardinal(LUnit.Morale));
  FBarMorale.SetMax(100);
  FBarMorale.SetValue(LUnit.Morale);
  ToggleKneelButton(LUnit);
  DrawHandItem(LeftHandItem(LUnit), FBtnLeftHandItem, FNumAmmoLeft);
  DrawHandItem(RightHandItem(LUnit), FBtnRightHandItem, FNumAmmoRight);
  if ACheckFov then
    FSession.TileEngine.CalculateFov(LUnit);
  LIndex := 0;
  for LOther in LUnit.VisibleUnits do
  begin
    if LIndex >= XCOM_VISIBLE_MAX then
      Break;
    FBtnVisibleUnit[LIndex].Visible := True;
    FNumVisibleUnit[LIndex].Visible := True;
    FVisibleUnit[LIndex] := LOther;
    Inc(LIndex);
  end;
  ShowPsiButton(Assigned(LUnit.GetSpecialWeapon(TXcomRuleItem.BT_PSIAMP)));
end;

procedure TXcomBattlescapeState.SelectNextPlayerUnit(ACheckReselect, ASetReselect, ACheckInventory,
  ACheckFov: Boolean);
var
  LUnit: TXcomBattleUnit;
begin
  if not AllowButtons then
    Exit;
  LUnit := FSave.SelectNextPlayerUnit(ACheckReselect, ASetReselect, ACheckInventory);
  UpdateSoldierInfoWith(ACheckFov);
  if Assigned(LUnit) then
    FMap.Camera.CenterOnPosition(LUnit.Position);
  FGame.CancelAllActions;
  FGame.CurrentAction.Actor := LUnit;
  FGame.SetupCursor;
end;

procedure TXcomBattlescapeState.SelectPreviousPlayerUnit(ACheckReselect, ASetReselect, ACheckInventory: Boolean);
var
  LUnit: TXcomBattleUnit;
begin
  if not AllowButtons then
    Exit;
  LUnit := FSave.SelectPreviousPlayerUnit(ACheckReselect, ASetReselect, ACheckInventory);
  UpdateSoldierInfo;
  if Assigned(LUnit) then
    FMap.Camera.CenterOnPosition(LUnit.Position);
  FGame.CancelAllActions;
  FGame.CurrentAction.Actor := LUnit;
  FGame.SetupCursor;
end;

procedure TXcomBattlescapeState.RefreshPreview;
begin
  // update any path preview
  if FSession.Pathfinding.PathPreviewed then
  begin
    FSession.Pathfinding.RemovePreview;
    FSession.Pathfinding.PreviewPath;
  end;
end;

procedure TXcomBattlescapeState.SelectReserve(AButton: TXcomBattlescapeButton);
begin
  if Assigned(FReserve.Selected) and (FReserve.Selected <> AButton) then
    FReserve.Selected.Toggle(False);
  FReserve.Selected := AButton;
  // the button of the group shows itself pressed
  AButton.SetGroup(FReserve);
end;

procedure TXcomBattlescapeState.MapClick(AAction: TXcomAction);
var
  LPosition: TXcomPosition;
  LButton: Integer;
begin
  LButton := AAction.Details.Button;
  // right-click aborts walking state
  if (LButton = XCOM_BUTTON_RIGHT) and FGame.CancelCurrentAction then
    Exit;
  // don't handle mouseclicks over the buttons (it overlaps with map surface)
  if FMouseOverIcons then
    Exit;
  // don't accept leftclicks if there is no cursor or there is an action busy
  if (FMap.Map.CursorType = CT_NONE) or FGame.IsBusy then
    Exit;
  LPosition := FMap.Map.SelectorPosition;
  // don't allow to click into void
  if not Assigned(FSave.TileAt(LPosition)) then
    Exit;
  if ((LButton = XCOM_BUTTON_RIGHT) or ((LButton = XCOM_BUTTON_LEFT) and
    ((AAction.Details.Modifiers and XCOM_KMOD_ALT) <> 0))) and PlayableUnitSelected then
    FGame.SecondaryAction(LPosition)
  else if LButton = XCOM_BUTTON_LEFT then
    FGame.PrimaryAction(LPosition);
end;

procedure TXcomBattlescapeState.BtnUnitUpClick(AAction: TXcomAction);
begin
  if PlayableUnitSelected and FSession.Pathfinding.ValidateUpDown(FSave.SelectedUnit, FSave.SelectedUnit.Position,
    DIR_UP) then
  begin
    FGame.CancelAllActions;
    FGame.MoveUpDown(FSave.SelectedUnit, DIR_UP);
  end;
end;

procedure TXcomBattlescapeState.BtnUnitDownClick(AAction: TXcomAction);
begin
  if PlayableUnitSelected and FSession.Pathfinding.ValidateUpDown(FSave.SelectedUnit, FSave.SelectedUnit.Position,
    DIR_DOWN) then
  begin
    FGame.CancelAllActions;
    FGame.MoveUpDown(FSave.SelectedUnit, DIR_DOWN);
  end;
end;

procedure TXcomBattlescapeState.BtnMapUpClick(AAction: TXcomAction);
begin
  if (FSave.Side = FACTION_PLAYER) or FSave.DebugMode then
    FMap.Camera.Up;
end;

procedure TXcomBattlescapeState.BtnMapDownClick(AAction: TXcomAction);
begin
  if (FSave.Side = FACTION_PLAYER) or FSave.DebugMode then
    FMap.Camera.Down;
end;

procedure TXcomBattlescapeState.BtnShowMapClick(AAction: TXcomAction);
begin
  if AllowButtons and Assigned(FScreens) then
    PushScreen(FScreens.MiniMap(Self));
end;

procedure TXcomBattlescapeState.BtnKneelClick(AAction: TXcomAction);
var
  LUnit: TXcomBattleUnit;
begin
  if not AllowButtons then
    Exit;
  LUnit := FSave.SelectedUnit;
  if not Assigned(LUnit) then
    Exit;
  FGame.Kneel(LUnit);
  ToggleKneelButton(LUnit);
  // update any path preview when unit kneels
  if FSession.Pathfinding.PathPreviewed then
  begin
    FSession.Pathfinding.Calculate(FGame.CurrentAction.Actor, FGame.CurrentAction.Target);
    FSession.Pathfinding.RemovePreview;
    FSession.Pathfinding.PreviewPath;
  end;
end;

procedure TXcomBattlescapeState.BtnInventoryClick(AAction: TXcomAction);
begin
  if PlayableUnitSelected and (FSave.SelectedUnit.HasInventory or FSave.DebugMode) and Assigned(FScreens) then
  begin
    FGame.CancelAllActions;
    PushScreen(FScreens.Inventory(Self, not FSave.DebugMode));
  end;
end;

procedure TXcomBattlescapeState.CenterOnSelectedUnit;
begin
  if PlayableUnitSelected then
  begin
    FMap.Camera.CenterOnPosition(FSave.SelectedUnit.Position);
    FMap.RefreshSelectorPosition;
  end;
end;

procedure TXcomBattlescapeState.BtnCenterClick(AAction: TXcomAction);
begin
  CenterOnSelectedUnit;
end;

procedure TXcomBattlescapeState.BtnNextSoldierClick(AAction: TXcomAction);
begin
  if AllowButtons then
  begin
    SelectNextPlayerUnit(True, False);
    FMap.RefreshSelectorPosition;
  end;
end;

procedure TXcomBattlescapeState.BtnNextStopClick(AAction: TXcomAction);
begin
  if AllowButtons then
  begin
    SelectNextPlayerUnit(True, True);
    FMap.RefreshSelectorPosition;
  end;
end;

procedure TXcomBattlescapeState.BtnPrevSoldierClick(AAction: TXcomAction);
begin
  if AllowButtons then
  begin
    SelectPreviousPlayerUnit(True);
    FMap.RefreshSelectorPosition;
  end;
end;

procedure TXcomBattlescapeState.BtnShowLayersClick(AAction: TXcomAction);
begin
  FNumLayers.SetValue(Cardinal(FMap.Camera.ToggleShowAllLayers));
end;

procedure TXcomBattlescapeState.BtnHelpClick(AAction: TXcomAction);
begin
  if AllowButtons(True) and Assigned(FScreens) then
  begin
    // a game saved from the pause menu takes the battle as it is now
    FSession.StoreInSavedGame;
    PushScreen(FScreens.Options(Self));
  end;
end;

procedure TXcomBattlescapeState.BtnEndTurnClick(AAction: TXcomAction);
begin
  if AllowButtons then
  begin
    FTxtTooltip.SetText('');
    FGame.RequestEndTurn;
  end;
end;

procedure TXcomBattlescapeState.BtnAbortClick(AAction: TXcomAction);
begin
  if AllowButtons and Assigned(FScreens) then
    PushScreen(FScreens.AbortMission(Self));
end;

procedure TXcomBattlescapeState.BtnStatsClick(AAction: TXcomAction);
begin
  if PlayableUnitSelected and Assigned(FScreens) then
  begin
    FGame.CancelAllActions;
    Popup(FScreens.UnitInfo(Self, FSave.SelectedUnit, False, False));
  end;
end;

procedure TXcomBattlescapeState.HandleItemClick(const AItem: TXcomBattleItem);
begin
  // make sure there is an item, and the battlescape is in an idle state
  if Assigned(AItem) and (not FGame.IsBusy) and Assigned(FScreens) then
  begin
    FGame.CurrentAction.Weapon := AItem;
    Popup(FScreens.ActionMenu(Self, FGame.CurrentAction, FIcons.X, FIcons.Y + 16));
  end;
end;

procedure TXcomBattlescapeState.BtnLeftHandItemClick(AAction: TXcomAction);
var
  LUnit: TXcomBattleUnit;
  LItem: TXcomBattleItem;
begin
  if not PlayableUnitSelected then
    Exit;
  // a click on the item cancels the action that waits for a target
  if FGame.CurrentAction.Targeting then
  begin
    FGame.CancelCurrentAction;
    Exit;
  end;
  FGame.CancelCurrentAction;
  LUnit := FSave.SelectedUnit;
  LItem := LeftHandItem(LUnit);
  if LItem <> LUnit.GetSpecialWeapon(TXcomRuleItem.BT_MELEE) then
    LUnit.ActiveHandSlot := 'STR_LEFT_HAND';
  FMap.Map.CacheUnits;
  HandleItemClick(LItem);
end;

procedure TXcomBattlescapeState.BtnRightHandItemClick(AAction: TXcomAction);
var
  LUnit: TXcomBattleUnit;
  LItem: TXcomBattleItem;
begin
  if not PlayableUnitSelected then
    Exit;
  if FGame.CurrentAction.Targeting then
  begin
    FGame.CancelCurrentAction;
    Exit;
  end;
  FGame.CancelCurrentAction;
  LUnit := FSave.SelectedUnit;
  LItem := RightHandItem(LUnit);
  if LItem <> LUnit.GetSpecialWeapon(TXcomRuleItem.BT_MELEE) then
    LUnit.ActiveHandSlot := 'STR_RIGHT_HAND';
  FMap.Map.CacheUnits;
  HandleItemClick(LItem);
end;

procedure TXcomBattlescapeState.BtnVisibleUnitClick(AAction: TXcomAction);
var
  LIndex: Integer;
begin
  for LIndex := 0 to XCOM_VISIBLE_MAX - 1 do
    if (AAction.Sender = FBtnVisibleUnit[LIndex]) and Assigned(FVisibleUnit[LIndex]) then
    begin
      FMap.Camera.CenterOnPosition(FVisibleUnit[LIndex].Position);
      Break;
    end;
end;

procedure TXcomBattlescapeState.BtnLaunchClick(AAction: TXcomAction);
begin
  if FGame.CurrentAction.Waypoints.Count > 0 then
    FGame.LaunchAction;
end;

procedure TXcomBattlescapeState.BtnPsiClick(AAction: TXcomAction);
begin
  if Assigned(FSave.SelectedUnit) then
    FGame.PsiButtonAction;
end;

procedure TXcomBattlescapeState.BtnReserveClick(AAction: TXcomAction);
begin
  if not AllowButtons then
    Exit;
  if AAction.Sender is TXcomBattlescapeButton then
    SelectReserve(TXcomBattlescapeButton(AAction.Sender));
  if FReserve.Selected = FBtnReserveNone then
    FGame.SetTuReserved(BA_NONE)
  else if FReserve.Selected = FBtnReserveSnap then
    FGame.SetTuReserved(BA_SNAPSHOT)
  else if FReserve.Selected = FBtnReserveAimed then
    FGame.SetTuReserved(BA_AIMEDSHOT)
  else if FReserve.Selected = FBtnReserveAuto then
    FGame.SetTuReserved(BA_AUTOSHOT);
  RefreshPreview;
end;

procedure TXcomBattlescapeState.BtnReserveKneelClick(AAction: TXcomAction);
begin
  if not AllowButtons then
    Exit;
  FGame.SetKneelReserved(not FGame.GetKneelReserved);
  FBtnReserveKneel.Toggle(FGame.GetKneelReserved);
  RefreshPreview;
end;

procedure TXcomBattlescapeState.BtnZeroTUsClick(AAction: TXcomAction);
begin
  if AllowButtons and Assigned(FSave.SelectedUnit) then
  begin
    FSave.SelectedUnit.SetTimeUnits(0);
    UpdateSoldierInfo;
  end;
end;

procedure TXcomBattlescapeState.BtnReloadClick(AAction: TXcomAction);
begin
  if PlayableUnitSelected and FSave.SelectedUnit.CheckAmmo then
  begin
    PlaySound(FSession.Ruleset.Constants.ItemReload, FSave.SelectedUnit.Position);
    UpdateSoldierInfo;
  end;
end;

procedure TXcomBattlescapeState.BtnPersonalLightingClick(AAction: TXcomAction);
begin
  if AllowButtons then
    FSession.TileEngine.TogglePersonalLighting;
end;

procedure TXcomBattlescapeState.TxtTooltipIn(AAction: TXcomAction);
begin
  if AllowButtons and Host.Options.GetBool('battleTooltips') and (AAction.Sender is TXcomWidget) then
  begin
    FCurrentTooltip := TXcomWidget(AAction.Sender).Tooltip;
    FTxtTooltip.SetText(Tr(FCurrentTooltip).Text);
  end;
end;

procedure TXcomBattlescapeState.TxtTooltipOut(AAction: TXcomAction);
begin
  if AllowButtons and Host.Options.GetBool('battleTooltips') and (AAction.Sender is TXcomWidget) and
    (FCurrentTooltip = TXcomWidget(AAction.Sender).Tooltip) then
    FTxtTooltip.SetText('');
end;

{ IXcomBattleView }

procedure TXcomBattlescapeState.Warning(const AMessage: string);
begin
  FWarning.ShowMessage(Tr(AMessage).Text);
end;

procedure TXcomBattlescapeState.Debug(const AMessage: string);
begin
  if FSave.DebugMode then
    FTxtDebug.SetText(AMessage);
end;

procedure TXcomBattlescapeState.CenterOnPosition(const APosition: TXcomPosition; AGraphic: Boolean);
begin
  FMap.Camera.CenterOnPosition(APosition, AGraphic);
end;

procedure TXcomBattlescapeState.SetViewLevel(ALevel: Integer);
begin
  FMap.Camera.SetViewLevel(ALevel);
end;

function TXcomBattlescapeState.IsOnScreen(const APosition: TXcomPosition; AUnitWalking: Boolean; AUnitSize: Integer;
  ABoundary: Boolean): Boolean;
begin
  Result := FMap.Camera.IsOnScreen(APosition, AUnitWalking, AUnitSize, ABoundary);
end;

procedure TXcomBattlescapeState.CacheUnits;
begin
  FMap.Map.CacheUnits;
end;

procedure TXcomBattlescapeState.CacheUnit(const AUnit: TXcomBattleUnit);
begin
  FMap.Map.CacheUnit(AUnit);
end;

procedure TXcomBattlescapeState.SetStateInterval(AMilliseconds: Integer);
begin
  FGameTimer.SetInterval(Cardinal(AMilliseconds));
end;

procedure TXcomBattlescapeState.ShowPsiButton(AShow: Boolean);
begin
  FBtnPsi.Visible := AShow;
end;

procedure TXcomBattlescapeState.ShowLaunchButton(AShow: Boolean);
begin
  FBtnLaunch.Visible := AShow;
end;

procedure TXcomBattlescapeState.SetUnitDying(ADying: Boolean);
begin
  FMap.Map.UnitDying := ADying;
end;

procedure TXcomBattlescapeState.SetCursorType(ACursorType, ASize: Integer);
begin
  FMap.Map.SetCursorType(ACursorType, ASize);
end;

procedure TXcomBattlescapeState.PlaySound(ASound: Integer; const APosition: TXcomPosition);
var
  LAngle: Integer;
begin
  if (ASound < 0) or (not Assigned(FAudio)) then
    Exit;
  // a sound without a place is not panned
  if APosition.Z < 0 then
    LAngle := 0
  else
    LAngle := FMap.Map.SoundAngle(APosition);
  FAudio.PlaySound(FSave.Depth, ASound, LAngle);
end;

procedure TXcomBattlescapeState.AddExplosion(const ACenter: TXcomPosition; AStartFrame, AFrameDelay: Integer; ABig,
  AHit: Boolean);
begin
  FMap.Map.AddExplosion(ACenter, AStartFrame, AFrameDelay, ABig, AHit);
end;

procedure TXcomBattlescapeState.SetProjectile(const AProjectile: TObject);
begin
  FMap.Map.Projectile := AProjectile as TXcomProjectile;
  if Assigned(AProjectile) then
    FMap.StopMouseScrolling;
end;

procedure TXcomBattlescapeState.AddVaporCloud(const AVoxel: TXcomPosition; ADensity, AColor: Integer);
begin
  FMap.Map.AddVaporCloud(AVoxel, ADensity, AColor);
end;

procedure TXcomBattlescapeState.ResetObstacles;
begin
  FMap.Map.ResetObstacles;
end;

procedure TXcomBattlescapeState.EnableObstacles;
begin
  FMap.EnableObstacles;
end;

procedure TXcomBattlescapeState.DisableObstacles;
begin
  FMap.DisableObstacles;
end;

procedure TXcomBattlescapeState.SetBlastFlash(AFlash: Boolean);
begin
  FMap.Map.FlashScreen := AFlash;
end;

function TXcomBattlescapeState.BlastFlash: Boolean;
begin
  Result := FMap.Map.FlashScreen;
end;

function TXcomBattlescapeState.AnimateExplosions: Boolean;
begin
  // true when nothing is left to animate: the explosion then has its effect
  if FMap.Map.Explosions.Count = 0 then
    Result := True
  else
    Result := not FMap.Map.AnimateExplosions;
end;

procedure TXcomBattlescapeState.SoldierKilled(const AUnit: TXcomBattleUnit);
begin
  // the debriefing moves the dead soldiers to the memorial (the cause of death is not recorded here)
end;

function TXcomBattlescapeState.UnitMessage(const AUnit: TXcomBattleUnit; const AMessage: string): string;
var
  LGendered: string;
  LText: string;
begin
  if not Assigned(AUnit) then
    Exit(Tr(AMessage).Text);
  // Language::getString(id, gender): the text of the gender when the language has one
  if AUnit.Gender = GENDER_FEMALE then
    LGendered := AMessage + '_FEMALE'
  else
    LGendered := AMessage + '_MALE';
  LText := Tr(LGendered).Text;
  if LText = LGendered then
    Result := Tr(AMessage).Arg(AUnit.DisplayName(
      function(AId: string): string
      begin
        Result := Tr(AId).Text;
      end)).Text
  else
    Result := Tr(LGendered).Arg(AUnit.DisplayName(
      function(AId: string): string
      begin
        Result := Tr(AId).Text;
      end)).Text;
end;

procedure TXcomBattlescapeState.ShowUnitMessage(const AUnit: TXcomBattleUnit; const AMessage: string;
  ANeedsConfirmation: Boolean);
begin
  if not Assigned(FScreens) then
    Exit;
  if ANeedsConfirmation then
    PushScreen(FScreens.InfoboxOk(Self, UnitMessage(AUnit, AMessage)))
  else
    PushScreen(FScreens.Infobox(Self, UnitMessage(AUnit, AMessage)));
end;

procedure TXcomBattlescapeState.FinishBattle(AAbort: Boolean; AInExitArea: Integer);
var
  LState: TXcomState;
  LDebriefing: TXcomState;
begin
  if FFinished then
    Exit;
  FFinished := True;
  while not Host.IsState(Self) do
    Host.PopState;
  Host.Cursor.Visible := True;
  if Assigned(FAudio) then
    FAudio.StopAmbience;
  for LState in FPopups do
    LState.Free;
  FPopups.Clear;
  FAnimTimer.Stop;
  FGameTimer.Stop;
  // the debriefing reads the battle before this screen (and with it the battle) is freed
  LDebriefing := nil;
  if Assigned(FScreens) then
    LDebriefing := FScreens.Debriefing(Self);
  Host.PopState;
  if Assigned(LDebriefing) then
    Host.PushState(LDebriefing);
end;

procedure TXcomBattlescapeState.NextTurn;
begin
  if Assigned(FScreens) then
    PushScreen(FScreens.NextTurn(Self));
end;

procedure TXcomBattlescapeState.ShowCursor(AVisible: Boolean);
begin
  Host.Cursor.Visible := AVisible;
end;

function TXcomBattlescapeState.CameraOffset: TXcomPosition;
begin
  Result := FMap.Camera.MapOffset;
end;

procedure TXcomBattlescapeState.SetCameraOffset(const AOffset: TXcomPosition);
begin
  FMap.Camera.MapOffset := AOffset;
end;

procedure TXcomBattlescapeState.AddWaypoint(const APosition: TXcomPosition);
begin
  FMap.Map.Waypoints.Add(APosition);
end;

procedure TXcomBattlescapeState.RemoveLastWaypoint;
begin
  if FMap.Map.Waypoints.Count > 0 then
    FMap.Map.Waypoints.Delete(FMap.Map.Waypoints.Count - 1);
end;

procedure TXcomBattlescapeState.ClearWaypoints;
begin
  FMap.Map.Waypoints.Clear;
end;

procedure TXcomBattlescapeState.ShowUnitInfo(const AUnit: TXcomBattleUnit);
begin
  if Assigned(FScreens) then
    PushScreen(FScreens.UnitInfo(Self, AUnit, False, True));
end;

end.
