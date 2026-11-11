{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - ScannerState of OpenXcom (the  }
{  motion scanner)                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.ScannerState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.Widget,
  DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.Timer,
  DelphiDoom.XcomBattle.Action, DelphiDoom.XcomBattleStates.Session.Intf, DelphiDoom.XcomBattleStates.ScannerView;

type
  /// <summary>
  ///   The motion scanner of an action: the screen DETBORD2.PCK, the blips over it and the frame DETBORD.PCK on
  ///   top. The blips blink every 125 ms; a click, the right button or the cancel key close it. The time units are
  ///   spent by who opens the screen. Not ported: Options::maximizeInfoScreens
  /// </summary>
  TXcomScannerState = class(TXcomState)
  strict private
    FSession: IXcomBattleSession;
    FBackground: TXcomInteractiveSurface;
    FScan: TXcomWidget;
    FScannerView: TXcomScannerView;
    FTimerAnimate: TXcomTimer;
    procedure Animate;
  public
    /// <param name="ASession">The battle: its pictures, its depth and its map</param>
    /// <param name="AAction">The action of the scanner: its actor is the unit that scans</param>
    constructor Create(AHost: TXcomStateHost; const ASession: IXcomBattleSession; AAction: TXcomBattleAction);
    destructor Destroy; override;
    procedure Init; override;
    procedure Think; override;
    /// <summary>handle: the right button closes the screen</summary>
    procedure Handle(AAction: TXcomAction); override;
    procedure ExitClick(AAction: TXcomAction);
    property ScannerView: TXcomScannerView read FScannerView;
    property Background: TXcomInteractiveSurface read FBackground;
  end;

implementation

uses
  DelphiDoom.XcomSurface.Surface;

const
  ANIMATION_INTERVAL = 125;
  // the screen is taller than the scanner by more than this: the battlescape stays visible around it
  TALL_SCREEN = 50;

constructor TXcomScannerState.Create(AHost: TXcomStateHost; const ASession: IXcomBattleSession;
  AAction: TXcomBattleAction);
var
  LSurface: TXcomSurface;
begin
  inherited Create(AHost);
  FSession := ASession;
  FBackground := TXcomInteractiveSurface.Create(320, 200);
  FScan := TXcomWidget.Create(320, 200);
  FScannerView := TXcomScannerView.Create(152, 152, 56, 24, ASession.Graphics.SurfaceSet('DETBLOB.DAT'),
    ASession.Battle, AAction.Actor);
  if Host.Screen.DY > TALL_SCREEN then
    ToggleScreen;
  // SavedBattleGame::setPaletteByDepth
  SetPalette('PAL_BATTLESCAPE', -1);
  SetPalette(ASession.Graphics.Palette(ASession.Battle.Depth), 0, 256);
  ASession.Graphics.SetPalette(@Palette^[0]);
  Add(FScan);
  Add(FScannerView);
  Add(FBackground);
  CenterAllSurfaces;
  LSurface := ASession.Graphics.Surface('DETBORD.PCK');
  if Assigned(LSurface) then
    LSurface.Blit(FBackground);
  LSurface := ASession.Graphics.Surface('DETBORD2.PCK');
  if Assigned(LSurface) then
    LSurface.Blit(FScan);
  FBackground.OnMouseClick(ExitClick);
  FBackground.OnKeyboardPress(ExitClick, Host.Options.KeyCancel);
  FTimerAnimate := TXcomTimer.Create(Host.Clock, ANIMATION_INTERVAL);
  FTimerAnimate.OnTimerState(Animate);
  FTimerAnimate.Start;
end;

destructor TXcomScannerState.Destroy;
begin
  FTimerAnimate.Free;
  inherited Destroy;
end;

procedure TXcomScannerState.Init;
begin
  inherited Init;
  // State::init, Mod::setPalette: the pictures of the battle follow the palette of the state on screen
  FSession.Graphics.SetPalette(@Palette^[0]);
end;

procedure TXcomScannerState.Handle(AAction: TXcomAction);
begin
  inherited Handle(AAction);
  if (AAction.Details.Kind = ekMouseDown) and (AAction.Details.Button = XCOM_BUTTON_RIGHT) then
    ExitClick(AAction);
end;

procedure TXcomScannerState.Animate;
begin
  FScannerView.Animate;
end;

procedure TXcomScannerState.Think;
begin
  inherited Think;
  FTimerAnimate.Think(True, False);
end;

procedure TXcomScannerState.ExitClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.