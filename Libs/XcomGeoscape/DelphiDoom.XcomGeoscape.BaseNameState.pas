{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - BaseNameState of OpenXcom (the window    }
{  where the name of a new base is typed)                                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.BaseNameState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text,
  DelphiDoom.XcomUi.TextButton, DelphiDoom.XcomUi.TextEdit, DelphiDoom.XcomGeoscape.Globe, DelphiDoom.XcomGeoscape.Control.Intf;

type
  /// <summary>
  ///   The name of the new base: a window with a line to edit and OK, that appears when the name is not empty. OK
  ///   closes this window and the one that chose the site. The base is not owned. Not ported: PlaceLiftState (the
  ///   option customInitialBase, off by default, and the bases built after the first)
  /// </summary>
  TXcomBaseNameState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FGlobe: TXcomGlobe;
    FFirst: Boolean;
    FControl: IXcomGeoscapeControl;
    FWindow: TXcomWindow;
    FOk: TXcomTextButton;
    FTitle: TXcomText;
    FName: TXcomTextEdit;
    procedure NameChange(AAction: TXcomAction);
    procedure OkClick(AAction: TXcomAction);
  public
    /// <param name="AControl">Opens the screen that places the access lift after the name (nil: it does not)</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; AGlobe: TXcomGlobe; AFirst: Boolean;
      const AControl: IXcomGeoscapeControl = nil);
  end;

implementation

constructor TXcomBaseNameState.Create(AHost: TXcomStateHost; ABase: TXcomBase; AGlobe: TXcomGlobe; AFirst: Boolean;
  const AControl: IXcomGeoscapeControl);
begin
  inherited Create(AHost);
  FControl := AControl;
  FBase := ABase;
  FGlobe := AGlobe;
  FFirst := AFirst;
  FGlobe.OnMouseOver(nil);
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 192, 80, 32, 60, wpBoth);
  FOk := TXcomTextButton.Create(162, 12, 47, 118);
  FTitle := TXcomText.Create(182, 17, 37, 70);
  FName := TXcomTextEdit.Create(Self, 127, 16, 59, 94);
  SetInterface('baseNaming');
  Add(FWindow, 'window', 'baseNaming');
  Add(FOk, 'button', 'baseNaming');
  Add(FTitle, 'text', 'baseNaming');
  Add(FName, 'text', 'baseNaming');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK01.SCR'));
  FOk.SetText(Tr('STR_OK'));
  FOk.OnMouseClick(OkClick);
  FOk.OnKeyboardPress(OkClick, Host.Options.KeyCancel);
  FOk.Visible := False;
  FTitle.SetAlign(haCenter);
  FTitle.SetBig;
  FTitle.SetText(Tr('STR_BASE_NAME'));
  FName.SetBig;
  FName.SetFocus(True, False);
  FName.OnChange(NameChange);
end;

procedure TXcomBaseNameState.NameChange(AAction: TXcomAction);
begin
  FBase.Name := FName.GetText;
  if (AAction.Details^.Key = XCOM_KEY_RETURN) or (AAction.Details^.Key = XCOM_KEY_KP_ENTER) then
  begin
    if FName.GetText <> '' then
      OkClick(AAction);
  end
  else
    FOk.Visible := FName.GetText <> '';
end;

procedure TXcomBaseNameState.OkClick(AAction: TXcomAction);
begin
  if FName.GetText <> '' then
  begin
    Host.PopState;
    Host.PopState;
    if not FFirst or Host.Options.GetBool('customInitialBase') then
    begin
      // a base built after the first closes also the confirmation of its cost
      if not FFirst then
        Host.PopState;
      if Assigned(FControl) then
        FControl.PlaceLift(FBase, FFirst);
    end;
  end;
end;

end.
