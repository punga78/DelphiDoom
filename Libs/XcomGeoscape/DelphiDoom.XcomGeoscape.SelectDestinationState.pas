{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - SelectDestinationState of OpenXcom (the  }
{  globe where the destination of a craft is chosen)                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.SelectDestinationState;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Target,
  DelphiDoom.XcomGeoscape.Globe, DelphiDoom.XcomGeoscape.GlobeControls;

type
  /// <summary>
  ///   The globe with a small window on top: a click on a target (or a point of the globe, which becomes a new
  ///   waypoint) chooses the destination of the craft. For a craft that is in its base the range is drawn on the globe.
  ///   The Cydonia button (the last mission of X-COM: Enemy Unknown) is not shown: it needs the final research
  /// </summary>
  TXcomSelectDestinationState = class(TXcomState)
  strict private
    FCraft: TXcomCraft;
    FGlobe: TXcomGlobe;
    FOnTargets: TProc<TList<TXcomTarget>, TXcomCraft>;
    FControls: TXcomGlobeControls;
    FWindow: TXcomWindow;
    FBtnCancel: TXcomTextButton;
    FTxtTitle: TXcomText;
    procedure GlobeClick(AAction: TXcomAction);
    procedure CancelClick(AAction: TXcomAction);
  public
    /// <param name="ACraft">The craft to send (not owned)</param>
    /// <param name="AGlobe">The globe (not owned)</param>
    /// <param name="AOnTargets">Shows the choice among the targets that were clicked (the callee takes the list)</param>
    constructor Create(AHost: TXcomStateHost; ACraft: TXcomCraft; AGlobe: TXcomGlobe;
      const AOnTargets: TProc<TList<TXcomTarget>, TXcomCraft>);
    destructor Destroy; override;
    procedure Init; override;
    procedure Think; override;
    procedure Handle(AAction: TXcomAction); override;
  end;

implementation

uses
  System.Math, DelphiDoom.XcomEngine.Screen, DelphiDoom.XcomSave.Waypoint;

{ TXcomSelectDestinationState }

constructor TXcomSelectDestinationState.Create(AHost: TXcomStateHost; ACraft: TXcomCraft; AGlobe: TXcomGlobe;
  const AOnTargets: TProc<TList<TXcomTarget>, TXcomCraft>);
var
  LDX, LDY: Integer;
begin
  inherited Create(AHost);
  FCraft := ACraft;
  FGlobe := AGlobe;
  FOnTargets := AOnTargets;
  LDX := Host.Screen.DX;
  LDY := Host.Screen.DY;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 256, 28, 0, 0, wpNone);
  FWindow.X := LDX;
  FWindow.SetDY(0);
  FBtnCancel := TXcomTextButton.Create(60, 12, 110 + LDX, 8);
  FTxtTitle := TXcomText.Create(100, 16, 10 + LDX, 6);
  SetInterface('geoscape');
  FControls := TXcomGlobeControls.Create(Self, FGlobe, LDX, LDY);
  Add(FWindow, 'genericWindow', 'geoscape');
  Add(FBtnCancel, 'genericButton1', 'geoscape');
  Add(FTxtTitle, 'genericText', 'geoscape');
  FGlobe.OnMouseClick(GlobeClick);
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FBtnCancel.SetText(Tr('STR_CANCEL_UC'));
  FBtnCancel.OnMouseClick(CancelClick);
  FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  FTxtTitle.SetText(Tr('STR_SELECT_DESTINATION'));
  FTxtTitle.SetVerticalAlign(vaMiddle);
  FTxtTitle.SetWordWrap(True);
  if FCraft.Status <> 'STR_OUT' then
  begin
    FGlobe.SetCraftRange(FCraft.Longitude, FCraft.Latitude, FCraft.BaseRange);
    FGlobe.Invalidate;
  end;
end;

destructor TXcomSelectDestinationState.Destroy;
begin
  FGlobe.SetCraftRange(0.0, 0.0, 0.0);
  inherited Destroy;
  FControls.Free;
end;

procedure TXcomSelectDestinationState.Init;
begin
  inherited Init;
  FGlobe.RotateStop;
end;

procedure TXcomSelectDestinationState.Think;
begin
  inherited Think;
  FGlobe.Think;
end;

procedure TXcomSelectDestinationState.Handle(AAction: TXcomAction);
begin
  inherited Handle(AAction);
  FGlobe.Handle(AAction);
end;

procedure TXcomSelectDestinationState.GlobeClick(AAction: TXcomAction);
var
  LLon, LLat: Double;
  LMouseX, LMouseY: Integer;
  LTargets: TList<TXcomTarget>;
  LWaypoint: TXcomWaypoint;
begin
  LMouseX := Floor(AAction.AbsoluteXMouse);
  LMouseY := Floor(AAction.AbsoluteYMouse);
  FGlobe.CartToPolar(SmallInt(LMouseX), SmallInt(LMouseY), LLon, LLat);
  // ignore the clicks on the window
  if LMouseY < 28 then
    Exit;
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
  begin
    LTargets := FGlobe.GetTargets(LMouseX, LMouseY, True);
    if LTargets.Count = 0 then
    begin
      LWaypoint := TXcomWaypoint.Create;
      LWaypoint.SetLongitude(LLon);
      LWaypoint.SetLatitude(LLat);
      LTargets.Add(LWaypoint);
    end;
    if Assigned(FOnTargets) then
      FOnTargets(LTargets, FCraft)
    else
    begin
      // nobody takes the list: a new waypoint is freed with it
      if (LTargets.Count = 1) and (LTargets[0] is TXcomWaypoint) and (LTargets[0].Id = 0) then
        LTargets[0].Free;
      LTargets.Free;
    end;
  end;
end;

procedure TXcomSelectDestinationState.CancelClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
