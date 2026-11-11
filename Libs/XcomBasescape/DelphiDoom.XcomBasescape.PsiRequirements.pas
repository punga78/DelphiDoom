{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - Mod::getPsiRequirements of OpenXcom     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.PsiRequirements;

interface

uses
  DelphiDoom.XcomMod.Ruleset;

type
  /// <summary>What must be researched to know the psionic strength of the soldiers</summary>
  TXcomPsiRequirements = class
  public
    /// <summary>
    ///   Mod::getPsiRequirements: the requirements of the first facility (in the order of the ruleset) that has
    ///   psionic laboratories; empty if none has
    /// </summary>
    class function Resolve(ARuleset: TXcomRuleset): TArray<string>; static;
  end;

implementation

{ TXcomPsiRequirements }

class function TXcomPsiRequirements.Resolve(ARuleset: TXcomRuleset): TArray<string>;
var
  LName: string;
begin
  Result := nil;
  for LName in ARuleset.Facilities.Index do
    if ARuleset.Facilities.Find(LName).PsiLaboratories > 0 then
      Exit(ARuleset.Facilities.Find(LName).Requirements);
end;

end.
