{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom menu library - the file names of the saved games            }
{  (CrossPlatform::sanitizeFilename and the reserved names of SavedGame)        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMenu.SaveNames;

interface

type
  /// <summary>How a saved game is named on disk</summary>
  TXcomSaveNames = class
  public
    const
      QUICKSAVE = '_quick_.asav';
      AUTOSAVE_GEOSCAPE = '_autogeo_.asav';
      AUTOSAVE_BATTLESCAPE = '_autobattle_.asav';
    /// <summary>sanitizeFilename: the characters that a file system does not allow (&lt; &gt; : " / ? \) become _</summary>
    class function Sanitize(const AName: string): string; static;
  end;

implementation

class function TXcomSaveNames.Sanitize(const AName: string): string;
var
  LIndex: Integer;
begin
  Result := AName;
  for LIndex := 1 to Length(Result) do
    case Result[LIndex] of
      '<', '>', ':', '"', '/', '?', '\':
        Result[LIndex] := '_';
    end;
end;

end.
