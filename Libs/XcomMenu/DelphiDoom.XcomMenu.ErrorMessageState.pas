{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - ErrorMessageState of OpenXcom (a popup with a message)
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}unit DelphiDoom.XcomMenu.ErrorMessageState;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.RuleInterface,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomMenu.OptionsTypes;

type
  /// <summary>
  ///   A window with a message in big letters and an OK button (Esc and Enter close it too). It takes the palette of
  ///   the state below it; the colors and the background are the ones of the interface "errorMessages" (see ForOrigin)
  /// </summary>
  TXcomErrorMessageState = class(TXcomState)
  strict private
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FTxtMessage: TXcomText;
    procedure OkClick(AAction: TXcomAction);
  public
    /// <summary>
    ///   AParentPalette is the palette of the state below; ABackgroundColor is the block of BACKPALS.DAT of the
    ///   background (-1 for the battlescape, which draws in high contrast)
    /// </summary>
    constructor Create(AHost: TXcomStateHost; const AMessage: string; AParentPalette: PXcomColors; AColor: Byte;
      const ABackground: string; ABackgroundColor: Integer);
    /// <summary>The error window of the geoscape or of the battlescape, with the colors of the interface "errorMessages"</summary>
    class function ForOrigin(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin; const AMessage: string;
      AParentPalette: PXcomColors): TXcomErrorMessageState; static;
  end;

implementation

const
  BACK_POSITION = 224;
  BLOCK_SIZE = 16;

constructor TXcomErrorMessageState.Create(AHost: TXcomStateHost; const AMessage: string; AParentPalette: PXcomColors;
  AColor: Byte; const ABackground: string; ABackgroundColor: Integer);
begin
  inherited Create(AHost);
  FWindow := TXcomWindow.Create(Self, 256, 160, 32, 20, wpBoth);
  FBtnOk := TXcomTextButton.Create(120, 18, 100, 154);
  FTxtMessage := TXcomText.Create(246, 80, 37, 50);
  SetPalette(PXcomColor(AParentPalette), 0, 256);
  if ABackgroundColor <> -1 then
    SetPalette(PXcomColor(PByte(Host.Resources.GetPalette('BACKPALS.DAT')) +
      ABackgroundColor * BLOCK_SIZE * SizeOf(TXcomColor)), BACK_POSITION, BLOCK_SIZE);
  Add(FWindow);
  Add(FBtnOk);
  Add(FTxtMessage);
  CenterAllSurfaces;
  FWindow.SetColor(AColor);
  FWindow.SetBackground(Host.Resources.GetSurface(ABackground));
  FBtnOk.SetColor(AColor);
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FTxtMessage.SetColor(AColor);
  FTxtMessage.SetAlign(haCenter);
  FTxtMessage.SetVerticalAlign(vaMiddle);
  FTxtMessage.SetBig;
  FTxtMessage.SetWordWrap(True);
  FTxtMessage.SetText(AMessage);
  if ABackgroundColor = -1 then
  begin
    FWindow.SetHighContrast(True);
    FBtnOk.SetHighContrast(True);
    FTxtMessage.SetHighContrast(True);
  end;
end;

class function TXcomErrorMessageState.ForOrigin(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin;
  const AMessage: string; AParentPalette: PXcomColors): TXcomErrorMessageState;
var
  LInterface: TXcomRuleInterface;
  LColor: TXcomInterfaceElement;
  LPalette: TXcomInterfaceElement;
begin
  LColor := Default(TXcomInterfaceElement);
  LPalette := Default(TXcomInterfaceElement);
  LInterface := AHost.Resources.GetInterface('errorMessages');
  // a ruleset without the interface gives the plain colors
  if LInterface = nil then
  begin
    LColor.Color := 0;
    LPalette.Color := 0;
    if AOrigin <> ooBattlescape then
      Exit(TXcomErrorMessageState.Create(AHost, AMessage, AParentPalette, 0, 'BACK01.SCR', 0))
    else
      Exit(TXcomErrorMessageState.Create(AHost, AMessage, AParentPalette, 0, 'TAC00.SCR', 0));
  end;
  if AOrigin <> ooBattlescape then
  begin
    LInterface.TryGetElement('geoscapeColor', LColor);
    LInterface.TryGetElement('geoscapePalette', LPalette);
    Result := TXcomErrorMessageState.Create(AHost, AMessage, AParentPalette, Byte(LColor.Color), 'BACK01.SCR',
      LPalette.Color);
  end
  else
  begin
    LInterface.TryGetElement('battlescapeColor', LColor);
    LInterface.TryGetElement('battlescapePalette', LPalette);
    Result := TXcomErrorMessageState.Create(AHost, AMessage, AParentPalette, Byte(LColor.Color), 'TAC00.SCR',
      LPalette.Color);
  end;
end;

procedure TXcomErrorMessageState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.