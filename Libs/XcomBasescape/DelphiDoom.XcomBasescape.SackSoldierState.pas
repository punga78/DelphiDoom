{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - SackSoldierState of OpenXcom (the       }
{  question before a soldier is sacked)                                         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.SackSoldierState;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.State,
  DelphiDoom.XcomUi.Types, DelphiDoom.XcomUi.Window, DelphiDoom.XcomUi.Text, DelphiDoom.XcomUi.TextButton,
  DelphiDoom.XcomSave.Base;

type
  /// <summary>Sacks a soldier of a base after a confirmation: the armor goes back to the stores</summary>
  TXcomSackSoldierState = class(TXcomState)
  strict private
    FBase: TXcomBase;
    FSoldierId: Integer;
    FWindow: TXcomWindow;
    FBtnOk: TXcomTextButton;
    FBtnCancel: TXcomTextButton;
    FTxtTitle: TXcomText;
    FTxtSoldier: TXcomText;
    procedure OkClick(AAction: TXcomAction);
    procedure CancelClick(AAction: TXcomAction);
  public
    /// <param name="ABase">The base (not owned)</param>
    /// <param name="ASoldierId">The index of the soldier in the list of the base</param>
    constructor Create(AHost: TXcomStateHost; ABase: TXcomBase; ASoldierId: Integer);
  end;

implementation

uses
  DelphiDoom.XcomSave.Soldier, DelphiDoom.XcomMod.Armor;

{ TXcomSackSoldierState }

constructor TXcomSackSoldierState.Create(AHost: TXcomStateHost; ABase: TXcomBase; ASoldierId: Integer);
begin
  inherited Create(AHost);
  FBase := ABase;
  FSoldierId := ASoldierId;
  ToggleScreen;
  FWindow := TXcomWindow.Create(Self, 152, 80, 84, 60);
  FBtnOk := TXcomTextButton.Create(44, 16, 100, 115);
  FBtnCancel := TXcomTextButton.Create(44, 16, 176, 115);
  FTxtTitle := TXcomText.Create(142, 9, 89, 75);
  FTxtSoldier := TXcomText.Create(142, 9, 89, 85);
  SetInterface('sackSoldier');
  Add(FWindow, 'window', 'sackSoldier');
  Add(FBtnOk, 'button', 'sackSoldier');
  Add(FBtnCancel, 'button', 'sackSoldier');
  Add(FTxtTitle, 'text', 'sackSoldier');
  Add(FTxtSoldier, 'text', 'sackSoldier');
  CenterAllSurfaces;
  FWindow.SetBackground(Host.Resources.GetSurface('BACK13.SCR'));
  FBtnOk.SetText(Tr('STR_OK'));
  FBtnOk.OnMouseClick(OkClick);
  FBtnOk.OnKeyboardPress(OkClick, Host.Options.KeyOk);
  FBtnCancel.SetText(Tr('STR_CANCEL_UC'));
  FBtnCancel.OnMouseClick(CancelClick);
  FBtnCancel.OnKeyboardPress(CancelClick, Host.Options.KeyCancel);
  FTxtTitle.SetAlign(haCenter);
  FTxtTitle.SetText(Tr('STR_SACK'));
  FTxtSoldier.SetAlign(haCenter);
  FTxtSoldier.SetText(FBase.Soldiers[FSoldierId].Name + '?');
end;

procedure TXcomSackSoldierState.OkClick(AAction: TXcomAction);
var
  LSoldier: TXcomSoldier;
begin
  LSoldier := FBase.Soldiers[FSoldierId];
  if LSoldier.Armor.StoreItem <> TXcomArmor.NONE then
    FBase.StorageItems.AddItem(LSoldier.Armor.StoreItem);
  // the list owns the soldier: deleting it from the list frees it
  FBase.Soldiers.Delete(FSoldierId);
  Host.PopState;
end;

procedure TXcomSackSoldierState.CancelClick(AAction: TXcomAction);
begin
  Host.PopState;
end;

end.
