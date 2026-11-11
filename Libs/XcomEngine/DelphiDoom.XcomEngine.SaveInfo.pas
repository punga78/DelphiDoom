{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the brief info of a save (SaveInfo))
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}unit DelphiDoom.XcomEngine.SaveInfo;

interface

type
  /// <summary>SaveInfo: what the lists of saved games show of a save file, read from its first YAML document</summary>
  TXcomSaveInfo = record
    FileName: string;
    DisplayName: string;
    /// <summary>The date of the last change of the file (local time)</summary>
    Timestamp: TDateTime;
    /// <summary>YYYY-MM-DD</summary>
    IsoDate: string;
    /// <summary>HH:MM</summary>
    IsoTime: string;
    Details: string;
    /// <summary>The quick save and the autosaves: listed first and with the color of the headings</summary>
    Reserved: Boolean;
    Mods: TArray<string>;
  end;

implementation

end.