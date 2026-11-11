{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape states library - the choice of the turns of     }
{  the fuse of a grenade (PrimeGrenadeState)                                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattleStates.PrimeGrenadeState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.Widget,
  DelphiDoom.XcomEngine.InteractiveSurface, DelphiDoom.XcomEngine.State, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.Frame, DelphiDoom.XcomBattle.Model, DelphiDoom.XcomBattle.Action,
  DelphiDoom.XcomBattleStates.Session.Intf, DelphiDoom.XcomBattleStates.BattlescapeState;

const
  /// <summary>The buttons of the window: the turns 0..23</summary>
  XCOM_PRIME_GRENADE_BUTTONS = 24;

type
  /// <summary>
  ///   The window "Set Timer" with the 24 numbered buttons. From the battle the number goes in the value of the
  ///   action (-1 when the player gives up) and the action menu under the window is closed too; from the inventory
  ///   it becomes the fuse of the grenade. The action and the grenade are not owned
  /// </summary>
  TXcomPrimeGrenadeState = class(TXcomState)
  strict private
    FAction: TXcomBattleAction;
    FInInventoryView: Boolean;
    FGrenadeInInventory: TXcomBattleItem;
    FNumber: array[0..XCOM_PRIME_GRENADE_BUTTONS - 1] of TXcomText;
    FButton: array[0..XCOM_PRIME_GRENADE_BUTTONS - 1] of TXcomInteractiveSurface;
    FTitle: TXcomText;
    FFrame: TXcomFrame;
    FBackground: TXcomWidget;
    procedure BtnClick(AAction: TXcomAction);
  public
    /// <param name="AParent">The battlescape the window is opened over: gives the battle (the palette of its depth)</param>
    /// <param name="AAction">The action that primes; not used (nil) from the inventory</param>
    /// <param name="AInInventoryView">Opened from the inventory, on AGrenade</param>
    constructor Create(AHost: TXcomStateHost; AParent: TXcomBattlescapeState; AAction: TXcomBattleAction;
      AInInventoryView: Boolean; AGrenade: TXcomBattleItem); overload;
    /// <summary>The same window on a session; the session is not used (nil) from the inventory</summary>
    constructor Create(AHost: TXcomStateHost; const ASession: IXcomBattleSession; AAction: TXcomBattleAction;
      AInInventoryView: Boolean; AGrenade: TXcomBattleItem); overload;
    /// <summary>handle: the right button gives up</summary>
    procedure Handle(AAction: TXcomAction); override;
    /// <summary>The button of a number of turns</summary>
    function Button(AIndex: Integer): TXcomInteractiveSurface;
  end;

implementation

uses
  DelphiDoom.XcomSurface.Types, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.RuleInterface,
  DelphiDoom.XcomUi.Types;

const
  SNoGrenadeBackgroundElement = 'The interface of the battlescape has no element "grenadeBackground"';

constructor TXcomPrimeGrenadeState.Create(AHost: TXcomStateHost; AParent: TXcomBattlescapeState;
  AAction: TXcomBattleAction; AInInventoryView: Boolean; AGrenade: TXcomBattleItem);
begin
  Create(AHost, AParent.Session, AAction, AInInventoryView, AGrenade);
end;

constructor TXcomPrimeGrenadeState.Create(AHost: TXcomStateHost; const ASession: IXcomBattleSession;
  AAction: TXcomBattleAction; AInInventoryView: Boolean; AGrenade: TXcomBattleItem);
const
  LEFT = 67;
  TOP = 68;
var
  LInterface: TXcomRuleInterface;
  LBackground: TXcomInterfaceElement;
  LIndex: Integer;
  LSquare: TXcomRect;
begin
  inherited Create(AHost);
  FAction := AAction;
  FInInventoryView := AInInventoryView;
  FGrenadeInInventory := AGrenade;
  ToggleScreen;

  // set palette
  SetPalette('PAL_BATTLESCAPE', -1);
  // SavedBattleGame::setPaletteByDepth
  if not AInInventoryView then
    SetPalette(ASession.Graphics.Palette(ASession.Battle.Depth), 0, 256);

  LInterface := Host.Resources.GetInterface('battlescape');
  if (not Assigned(LInterface)) or (not LInterface.TryGetElement('grenadeBackground', LBackground)) then
    raise EXcomEngineException.Create(SNoGrenadeBackgroundElement);

  // set up objects
  FBackground := TXcomWidget.Create(192, 93, 65, 45);
  Add(FBackground);
  FBackground.DrawRect(0, 0, FBackground.Width, FBackground.Height, Byte(LBackground.Color and $FF));

  FFrame := TXcomFrame.Create(192, 27, 65, 37);
  Add(FFrame, 'grenadeMenu', 'battlescape');
  FFrame.SetThickness(3);
  FFrame.SetHighContrast(True);

  FTitle := TXcomText.Create(192, 24, 65, 44);
  Add(FTitle, 'grenadeMenu', 'battlescape');
  FTitle.SetAlign(haCenter);
  FTitle.SetBig;
  FTitle.SetText(Tr('STR_SET_TIMER').Text);
  FTitle.SetHighContrast(True);

  for LIndex := 0 to High(FButton) do
  begin
    FButton[LIndex] := TXcomInteractiveSurface.Create(22, 22, LEFT - 1 + ((LIndex mod 8) * 24),
      TOP - 4 + ((LIndex div 8) * 25));
    Add(FButton[LIndex]);
    FButton[LIndex].OnMouseClick(BtnClick);
    LSquare := TXcomRect.Make(0, 0, FButton[LIndex].Width, FButton[LIndex].Height);
    FButton[LIndex].DrawRect(LSquare, Byte(LBackground.Border and $FF));
    LSquare := TXcomRect.Make(1, 1, FButton[LIndex].Width - 2, FButton[LIndex].Height - 2);
    FButton[LIndex].DrawRect(LSquare, Byte(LBackground.Color2 and $FF));

    FNumber[LIndex] := TXcomText.Create(20, 20, LEFT + ((LIndex mod 8) * 24), TOP - 1 + ((LIndex div 8) * 25));
    Add(FNumber[LIndex], 'grenadeMenu', 'battlescape');
    FNumber[LIndex].SetBig;
    FNumber[LIndex].SetText(IntToStr(LIndex));
    FNumber[LIndex].SetHighContrast(True);
    FNumber[LIndex].SetAlign(haCenter);
    FNumber[LIndex].SetVerticalAlign(vaMiddle);
  end;

  CenterAllSurfaces;
  LowerAllSurfaces;
end;

procedure TXcomPrimeGrenadeState.Handle(AAction: TXcomAction);
begin
  inherited Handle(AAction);
  if (AAction.Details.Kind = ekMouseDown) and (AAction.Details.Button = XCOM_BUTTON_RIGHT) then
  begin
    if not FInInventoryView then
      FAction.Value := -1;
    Host.PopState;
  end;
end;

procedure TXcomPrimeGrenadeState.BtnClick(AAction: TXcomAction);
var
  LButton, LIndex: Integer;
begin
  LButton := -1;
  if AAction.Details.Button = XCOM_BUTTON_RIGHT then
  begin
    if not FInInventoryView then
      FAction.Value := LButton;
    Host.PopState;
    Exit;
  end;
  // got to find out which button was pressed
  for LIndex := 0 to High(FButton) do
    if AAction.Sender = FButton[LIndex] then
    begin
      LButton := LIndex;
      Break;
    end;
  if LButton = -1 then
    Exit;
  if FInInventoryView then
    FGrenadeInInventory.FuseTimer := LButton
  else
    FAction.Value := LButton;
  Host.PopState;
  // the action menu under the window
  if not FInInventoryView then
    Host.PopState;
end;

function TXcomPrimeGrenadeState.Button(AIndex: Integer): TXcomInteractiveSurface;
begin
  Result := FButton[AIndex];
end;

end.
