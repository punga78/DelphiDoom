{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom geoscape library - the names of the targets of the globe    }
{  (Target::getName and getDefaultName, with the overrides of Ufo and Craft)    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomGeoscape.TargetNames;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Language, DelphiDoom.XcomSave.Target;

type
  /// <summary>
  ///   The text of a target in the language of the game: the custom name, or the default name of its kind
  ///   ("UFO-12", "Landing Site-3", "Triton-1")
  /// </summary>
  TXcomTargetNames = class
  public
    /// <summary>Target::getName: the custom name or the default one; a base has only the name it was given</summary>
    class function Name(const ATarget: TXcomTarget; const ALanguage: TXcomLanguage): string; static;
    /// <summary>Target::getDefaultName (Ufo and Craft override it: the id of a landed or crashed UFO, STR_CRAFTNAME)</summary>
    class function DefaultName(const ATarget: TXcomTarget; const ALanguage: TXcomLanguage): string; static;
  end;

implementation

uses
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.Craft, DelphiDoom.XcomSave.Ufo;

{ TXcomTargetNames }

class function TXcomTargetNames.Name(const ATarget: TXcomTarget; const ALanguage: TXcomLanguage): string;
begin
  if ATarget.Name <> '' then
    Result := ATarget.Name
  else if ATarget is TXcomBase then
    Result := ''
  else
    Result := DefaultName(ATarget, ALanguage);
end;

class function TXcomTargetNames.DefaultName(const ATarget: TXcomTarget; const ALanguage: TXcomLanguage): string;
begin
  if ATarget is TXcomCraft then
    Result := ALanguage.GetString('STR_CRAFTNAME').Arg(ALanguage.GetString(ATarget.TargetType).Text)
      .Arg(ATarget.Id).Text
  else if ATarget is TXcomUfo then
    Result := ALanguage.GetString(ATarget.MarkerName).Arg(ATarget.MarkerId).Text
  else
    Result := ALanguage.GetString(ATarget.MarkerName).Arg(ATarget.Id).Text;
end;

end.
