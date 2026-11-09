{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - the default values of the options      }
{  that the saved game reads (Options::soldierDiaries and the psi ones)         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.DefaultSettings;

interface

uses
  System.SysUtils, DelphiDoom.XcomSave.Settings.Intf;

type
  /// <summary>The defaults of Options.cpp: diaries on, no psi strength improvement and no evaluation</summary>
  TXcomDefaultSaveSettings = class(TInterfacedObject, IXcomSaveSettings)
  public
    function SoldierDiaries: Boolean;
    function AllowPsiStrengthImprovement: Boolean;
    function PsiStrengthEval: Boolean;
  end;

implementation

function TXcomDefaultSaveSettings.SoldierDiaries: Boolean;
begin
  Result := True;
end;

function TXcomDefaultSaveSettings.AllowPsiStrengthImprovement: Boolean;
begin
  Result := False;
end;

function TXcomDefaultSaveSettings.PsiStrengthEval: Boolean;
begin
  Result := False;
end;

end.
