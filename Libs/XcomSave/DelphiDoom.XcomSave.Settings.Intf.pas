{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom saved game library - the options that the saved game reads  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSave.Settings.Intf;

interface

type
  /// <summary>
  ///   The few options of the game that change what is saved or how the soldiers train (Options::...): the C++
  ///   reads them from a global, here they are injected
  /// </summary>
  IXcomSaveSettings = interface
    ['{3C0B7F1A-5D52-4E0C-9A31-176000000010}']
    /// <summary>Options::soldierDiaries</summary>
    function SoldierDiaries: Boolean;
    /// <summary>Options::allowPsiStrengthImprovement</summary>
    function AllowPsiStrengthImprovement: Boolean;
    /// <summary>Options::psiStrengthEval</summary>
    function PsiStrengthEval: Boolean;
  end;

implementation

end.
