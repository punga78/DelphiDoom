{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the names of the mods in a saved game      }
{  (SavedGame::sanitizeModName of OpenXcom)                                     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.ModNames;

interface

type
  /// <summary>The names of the mods as a saved game keeps them ("xcom2 ver: 1.0")</summary>
  TXcomModNames = class
  public
    /// <summary>The id without the version part: the text before " ver: " (the name as it is when there is none)</summary>
    class function Sanitize(const AName: string): string; static;
  end;

implementation

class function TXcomModNames.Sanitize(const AName: string): string;
var
  LBreak: Integer;
begin
  LBreak := Pos(' ver: ', AName);
  if LBreak = 0 then
    Result := AName
  else
    Result := Copy(AName, 1, LBreak - 1);
end;

end.
