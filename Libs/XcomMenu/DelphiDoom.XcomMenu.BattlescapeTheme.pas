{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - State::applyBattlescapeTheme of OpenXcom     }
{  (the colors of a menu that is opened over a battle)                          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.BattlescapeTheme;

interface

uses
  DelphiDoom.XcomEngine.State;

type
  /// <summary>
  ///   State::applyBattlescapeTheme: every surface of the state takes the color of the element battlescapeTheme of
  ///   the interface mainMenu and the high contrast, the windows take TAC00.SCR as background, the lists and the
  ///   combo boxes the border color for their arrows. The state engine cannot do it because it does not know the
  ///   widgets. Does not change the palette of the state (State.SetInterface with ABattle does)
  /// </summary>
  TXcomBattlescapeTheme = class
  public
    const
      INTERFACE_NAME = 'mainMenu';
      ELEMENT_NAME = 'battlescapeTheme';
      BACKGROUND_NAME = 'TAC00.SCR';
    /// <summary>Applies the theme; does nothing when the ruleset has no battlescapeTheme element</summary>
    class procedure Apply(AState: TXcomState); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Widget,
  DelphiDoom.XcomEngine.RuleInterface, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.TextList,
  DelphiDoom.XcomUi.ComboBox;

class procedure TXcomBattlescapeTheme.Apply(AState: TXcomState);
var
  LInterface: TXcomRuleInterface;
  LElement: TXcomInterfaceElement;
  LBackground: TXcomSurface;
begin
  LInterface := AState.Host.Resources.GetInterface(INTERFACE_NAME);
  if (LInterface = nil) or not LInterface.TryGetElement(ELEMENT_NAME, LElement) then
    Exit;
  LBackground := AState.Host.Resources.GetSurface(BACKGROUND_NAME);
  AState.VisitSurfaces(
    procedure(ASurface: TXcomWidget)
    begin
      ASurface.SetColor(Byte(LElement.Color));
      ASurface.SetHighContrast(True);
      if ASurface is TXcomWindow then
        TXcomWindow(ASurface).SetBackground(LBackground)
      else if ASurface is TXcomTextList then
        TXcomTextList(ASurface).SetArrowColor(Byte(LElement.Border))
      else if ASurface is TXcomComboBox then
        TXcomComboBox(ASurface).SetArrowColor(Byte(LElement.Border));
    end);
end;

end.
