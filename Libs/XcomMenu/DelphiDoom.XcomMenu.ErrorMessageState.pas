{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - ErrorMessageState of OpenXcom (a window with }
{  a message and OK)                                                            }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.ErrorMessageState;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action,
  DelphiDoom.XcomEngine.State, DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomMenu.OptionsTypes, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextButton;

type
  /// <summary>
  ///   A pop-up with a message (the text of the language, already looked up) and an OK button that closes it. It uses
  ///   the palette of the state that opens it, and the block of colors of a background palette for the window when one is
  ///   given
  /// </summary>
  TXcomErrorMessageState = class(TXcomState)
  strict private
    FWindow: TXcomWindow;
    FOk: TXcomTextButton;
    FMessage: TXcomText;
    procedure OkClick(AAction: TXcomAction);
  public
    /// <param name="APalette">The 256 colors of the state that opens this one</param>
    /// <param name="AColor">The color of the window, the button and the text</param>
    /// <param name="ABackground">The full screen picture of the window (BACK01.SCR)</param>
    /// <param name="ABackgroundColor">The block of BACKPALS.DAT for the background colors, -1 for none</param>
    constructor Create(AHost: TXcomStateHost; const AMessage: string; APalette: PXcomColors; AColor: Byte;
      const ABackground: string; ABackgroundColor: Integer);
    /// <summary>The error window of the geoscape or of the battlescape, with the colors of the interface "errorMessages" (plain colors when the ruleset has none)</summary>
    class function ForOrigin(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin; const AMessage: string;
      AParentPalette: PXcomColors): TXcomErrorMessageState; static;
  end;

implementation

const
  BACK_POSITION = 224;
  BLOCK_COLORS = 16;

constructor TXcomErrorMessageState.Create(AHost: TXcomStateHost; const AMessage: string; APalette: PXcomColors;
  AColor: Byte; const ABackground: string; ABackgroundColor: Integer);
begin
  inherited Create(AHost);
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 256, 160, 32, 20, wpBoth);
  FOk := TXcomTextButton.Create(120, 18, 100, 154);
  FMessage := TXcomText.Create(246, 80, 37, 50);
  SetPalette(@APalette^[0], 0, 256);
  if ABackgroundColor <> -1 then
    SetPalette(PXcomColor(PByte(Host.Resources.GetPalette('BACKPALS.DAT')) +
      ABackgroundColor * BLOCK_COLORS * SizeOf(TXcomColor)), BACK_POSITION, BLOCK_COLORS);
  Add(FWindow);
  Add(FOk);
  Add(FMessage);
  CenterAllSurfaces;
  FWindow.SetColor(AColor);
  FWindow.SetBackground(Host.Resources.GetSurface(ABackground));
  FOk.SetColor(AColor);
  FOk.SetText(Tr('STR_OK'));
  FOk.OnMouseClick(OkClick);
  FOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FMessage.SetColor(AColor);
  FMessage.SetAlign(haCenter);
  FMessage.SetVerticalAlign(vaMiddle);
  FMessage.SetBig;
  FMessage.SetWordWrap(True);
  FMessage.SetText(AMessage);
  if ABackgroundColor = -1 then
  begin
    FWindow.SetHighContrast(True);
    FOk.SetHighContrast(True);
    FMessage.SetHighContrast(True);
  end;
end;

class function TXcomErrorMessageState.ForOrigin(AHost: TXcomStateHost; AOrigin: TXcomOptionsOrigin;
  const AMessage: string; AParentPalette: PXcomColors): TXcomErrorMessageState;
var
  LInterface: TXcomRuleInterface;
  LColor: TXcomInterfaceElement;
  LPalette: TXcomInterfaceElement;
  LPrefix: string;
  LBackground: string;
begin
  LColor := Default(TXcomInterfaceElement);
  LPalette := Default(TXcomInterfaceElement);
  if AOrigin <> ooBattlescape then
  begin
    LPrefix := 'geoscape';
    LBackground := 'BACK01.SCR';
  end
  else
  begin
    LPrefix := 'battlescape';
    LBackground := 'TAC00.SCR';
  end;
  LInterface := AHost.Resources.GetInterface('errorMessages');
  // a ruleset without the interface gives the plain colors
  if LInterface <> nil then
  begin
    LInterface.TryGetElement(LPrefix + 'Color', LColor);
    LInterface.TryGetElement(LPrefix + 'Palette', LPalette);
  end;
  Result := TXcomErrorMessageState.Create(AHost, AMessage, AParentPalette, Byte(LColor.Color), LBackground,
    LPalette.Color);
end;

procedure TXcomErrorMessageState.OkClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
