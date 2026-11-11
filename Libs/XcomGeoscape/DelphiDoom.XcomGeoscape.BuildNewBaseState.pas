{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - BuildNewBaseState of OpenXcom (the       }
{  choice of the site of a new base on the globe)                               }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.BuildNewBaseState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomEngine.Timer, DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomSave.Base,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomGeoscape.Globe, DelphiDoom.XcomGeoscape.Control.Intf;

type
  /// <summary>
  ///   The window over the globe where the site of the base is chosen: the radars of the facilities follow the mouse
  ///   and a click on land puts the base there. For the first base there is no Cancel and the name is asked next;
  ///   the globe belongs to the geoscape, and the base is owned by the saved game (when it is not the first one and
  ///   is cancelled the caller frees it: not ported with ConfirmNewBaseState)
  /// </summary>
  TXcomBuildNewBaseState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FGlobe: TXcomGlobe;
    FFirst: Boolean;
    FControl: IXcomGeoscapeControl;
    FOldShowRadar: Boolean;
    FOldLat: Double;
    FOldLon: Double;
    FMouseX: Integer;
    FMouseY: Integer;
    FRotateLeft: TXcomInteractiveSurface;
    FRotateRight: TXcomInteractiveSurface;
    FRotateUp: TXcomInteractiveSurface;
    FRotateDown: TXcomInteractiveSurface;
    FZoomIn: TXcomInteractiveSurface;
    FZoomOut: TXcomInteractiveSurface;
    FWindow: TXcomWindow;
    FCancel: TXcomTextButton;
    FTitle: TXcomText;
    FHoverTimer: TXcomTimer;
    procedure GlobeHover(AAction: TXcomAction);
    procedure GlobeClick(AAction: TXcomAction);
    procedure HoverRedraw;
    procedure CancelClick(AAction: TXcomAction);
    procedure ConfigureHold(ASurface: TXcomInteractiveSurface; AKey: Integer; const APress,
      ARelease: TXcomActionHandler);
  public
    /// <param name="AControl">The geoscape, for the confirmation and the lift of a base after the first (nil: none)</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; AGlobe: TXcomGlobe; AFirst: Boolean;
      const AControl: IXcomGeoscapeControl = nil);
    destructor Destroy; override;
    procedure Init; override;
    procedure Think; override;
    procedure Handle(AAction: TXcomAction); override;
  end;

implementation

uses
  System.Math, DelphiDoom.XcomEngine.Screen, DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomSave.Craft,
  DelphiDoom.XcomMenu.ErrorMessageState, DelphiDoom.XcomGeoscape.Keys, DelphiDoom.XcomGeoscape.BaseNameState,
  DelphiDoom.XcomGeoscape.ConfirmNewBaseState;

constructor TXcomBuildNewBaseState.Create(AHost: TXcomStateHost; ABase: TXcomBase; AGlobe: TXcomGlobe;
  AFirst: Boolean; const AControl: IXcomGeoscapeControl);
var
  LDX, LDY: Integer;
begin
  inherited Create(AHost);
  FControl := AControl;
  FBase := ABase;
  FGlobe := AGlobe;
  FFirst := AFirst;
  LDX := Host.Screen.DX;
  LDY := Host.Screen.DY;
  ToggleScreen;
  FOldShowRadar := FGlobe.RadarLines;
  if not FOldShowRadar then
    FGlobe.RadarLines := True;
  FRotateLeft := TXcomInteractiveSurface.Create(12, 10, 259 + LDX * 2, 176 + LDY);
  FRotateRight := TXcomInteractiveSurface.Create(12, 10, 283 + LDX * 2, 176 + LDY);
  FRotateUp := TXcomInteractiveSurface.Create(13, 12, 271 + LDX * 2, 162 + LDY);
  FRotateDown := TXcomInteractiveSurface.Create(13, 12, 271 + LDX * 2, 187 + LDY);
  FZoomIn := TXcomInteractiveSurface.Create(23, 23, 295 + LDX * 2, 156 + LDY);
  FZoomOut := TXcomInteractiveSurface.Create(13, 17, 300 + LDX * 2, 182 + LDY);
  FWindow := TXcomWindow.Create(Self, 256, 28, 0, 0);
  FWindow.X := LDX;
  FWindow.SetDY(0);
  FCancel := TXcomTextButton.Create(54, 12, 186 + LDX, 8);
  FTitle := TXcomText.Create(180, 16, 8 + LDX, 6);
  FHoverTimer := TXcomTimer.Create(Host.Clock, 50);
  FHoverTimer.OnTimerState(HoverRedraw);
  FHoverTimer.Start;
  SetInterface('geoscape');
  Add(FRotateLeft);
  Add(FRotateRight);
  Add(FRotateUp);
  Add(FRotateDown);
  Add(FZoomIn);
  Add(FZoomOut);
  Add(FWindow, 'genericWindow', 'geoscape');
  Add(FCancel, 'genericButton2', 'geoscape');
  Add(FTitle, 'genericText', 'geoscape');
  FGlobe.OnMouseClick(GlobeClick);
  ConfigureHold(FRotateLeft, KEY_GEO_LEFT,
    procedure(AAction: TXcomAction)
    begin
      FGlobe.RotateLeft;
    end,
    procedure(AAction: TXcomAction)
    begin
      FGlobe.RotateStopLon;
    end);
  ConfigureHold(FRotateRight, KEY_GEO_RIGHT,
    procedure(AAction: TXcomAction)
    begin
      FGlobe.RotateRight;
    end,
    procedure(AAction: TXcomAction)
    begin
      FGlobe.RotateStopLon;
    end);
  ConfigureHold(FRotateUp, KEY_GEO_UP,
    procedure(AAction: TXcomAction)
    begin
      FGlobe.RotateUp;
    end,
    procedure(AAction: TXcomAction)
    begin
      FGlobe.RotateStopLat;
    end);
  ConfigureHold(FRotateDown, KEY_GEO_DOWN,
    procedure(AAction: TXcomAction)
    begin
      FGlobe.RotateDown;
    end,
    procedure(AAction: TXcomAction)
    begin
      FGlobe.RotateStopLat;
    end);
  FZoomIn.OnMouseClick(
    procedure(AAction: TXcomAction)
    begin
      FGlobe.ZoomIn;
    end, XCOM_BUTTON_LEFT);
  FZoomIn.OnMouseClick(
    procedure(AAction: TXcomAction)
    begin
      FGlobe.ZoomMax;
    end, XCOM_BUTTON_RIGHT);
  FZoomIn.OnKeyboardPress(
    procedure(AAction: TXcomAction)
    begin
      FGlobe.ZoomIn;
    end, KEY_GEO_ZOOM_IN);
  FZoomOut.OnMouseClick(
    procedure(AAction: TXcomAction)
    begin
      FGlobe.ZoomOut;
    end, XCOM_BUTTON_LEFT);
  FZoomOut.OnMouseClick(
    procedure(AAction: TXcomAction)
    begin
      FGlobe.ZoomMin;
    end, XCOM_BUTTON_RIGHT);
  FZoomOut.OnKeyboardPress(
    procedure(AAction: TXcomAction)
    begin
      FGlobe.ZoomOut;
    end, KEY_GEO_ZOOM_OUT);
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FCancel.SetText(Tr('STR_CANCEL_UC'));
  FCancel.OnMouseClick(CancelClick);
  FCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  FTitle.SetText(Tr('STR_SELECT_SITE_FOR_NEW_BASE'));
  FTitle.SetVerticalAlign(vaMiddle);
  FTitle.SetWordWrap(True);
  if FFirst then
    FCancel.Visible := False;
end;

destructor TXcomBuildNewBaseState.Destroy;
begin
  if FGlobe.RadarLines <> FOldShowRadar then
    FGlobe.RadarLines := False;
  inherited Destroy;
  FHoverTimer.Free;
end;

procedure TXcomBuildNewBaseState.ConfigureHold(ASurface: TXcomInteractiveSurface; AKey: Integer; const APress,
  ARelease: TXcomActionHandler);
begin
  ASurface.OnMousePress(APress);
  ASurface.OnMouseRelease(ARelease);
  ASurface.OnKeyboardPress(APress, AKey);
  ASurface.OnKeyboardRelease(ARelease, AKey);
  ASurface.SetListButton;
end;

procedure TXcomBuildNewBaseState.Init;
begin
  inherited Init;
  FGlobe.OnMouseOver(GlobeHover);
  FGlobe.RotateStop;
  FGlobe.SetNewBaseHover(True);
end;

procedure TXcomBuildNewBaseState.Think;
begin
  inherited Think;
  FGlobe.Think;
  FHoverTimer.Think(True, False);
end;

procedure TXcomBuildNewBaseState.Handle(AAction: TXcomAction);
begin
  inherited Handle(AAction);
  FGlobe.Handle(AAction);
end;

procedure TXcomBuildNewBaseState.GlobeHover(AAction: TXcomAction);
begin
  FMouseX := Floor(AAction.AbsoluteXMouse);
  FMouseY := Floor(AAction.AbsoluteYMouse);
  if not FHoverTimer.IsRunning then
    FHoverTimer.Start;
end;

procedure TXcomBuildNewBaseState.HoverRedraw;
var
  LLon, LLat: Double;
  LValid: Boolean;
begin
  LValid := FGlobe.CartToPolar(SmallInt(FMouseX), SmallInt(FMouseY), LLon, LLat);
  if LValid then
  begin
    FGlobe.SetNewBaseHoverPos(LLon, LLat);
    FGlobe.SetNewBaseHover(True);
  end;
  if FGlobe.RadarLines and not (TXcomGlobe.AreSame(FOldLat, LLat) and TXcomGlobe.AreSame(FOldLon, LLon)) then
  begin
    FOldLat := LLat;
    FOldLon := LLon;
    FGlobe.Invalidate;
  end;
end;

procedure TXcomBuildNewBaseState.GlobeClick(AAction: TXcomAction);
var
  LLon, LLat: Double;
  LMouseX, LMouseY: Integer;
  LCraft: TXcomCraft;
  LElement: TXcomInterfaceElement;
  LColor, LPaletteColor: Integer;
begin
  LMouseX := Floor(AAction.AbsoluteXMouse);
  LMouseY := Floor(AAction.AbsoluteYMouse);
  FGlobe.CartToPolar(SmallInt(LMouseX), SmallInt(LMouseY), LLon, LLat);
  if LMouseY < 28 then
    Exit;
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
  begin
    if FGlobe.InsideLand(LLon, LLat) then
    begin
      FBase.SetLongitude(LLon);
      FBase.SetLatitude(LLat);
      for LCraft in FBase.Crafts do
      begin
        LCraft.SetLongitude(LLon);
        LCraft.SetLatitude(LLat);
      end;
      if FFirst then
        Host.PushState(TXcomBaseNameState.Create(Host, FBase, FGlobe, FFirst, FControl))
      else
        Host.PushState(TXcomConfirmNewBaseState.Create(Host, FBase, FGlobe, FControl));
    end
    else
    begin
      LColor := 0;
      LPaletteColor := -1;
      if Assigned(Host.Resources.GetInterface('geoscape')) then
      begin
        if Host.Resources.GetInterface('geoscape').TryGetElement('genericWindow', LElement) then
          LColor := LElement.Color;
        if Host.Resources.GetInterface('geoscape').TryGetElement('palette', LElement) then
          LPaletteColor := LElement.Color;
      end;
      Host.PushState(TXcomErrorMessageState.Create(Host, Tr('STR_XCOM_BASE_CANNOT_BE_BUILT'), Palette, Byte(LColor),
        'BACK01.SCR', LPaletteColor));
    end;
  end;
end;

procedure TXcomBuildNewBaseState.CancelClick(AAction: TXcomAction);
begin
  // BuildNewBaseState::btnCancelClick deletes the base (the one that is not in the game yet)
  if not FFirst then
    FreeAndNil(FBase);
  Host.PopState;
end;

end.
