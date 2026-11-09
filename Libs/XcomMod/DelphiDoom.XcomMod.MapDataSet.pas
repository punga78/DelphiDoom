{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a map data file (MapDataSet)              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.MapDataSet;

interface

type
  /// <summary>
  ///   A MCD file of tile parts that a terrain refers to by name. While the ruleset loads it is only a name
  ///   (MapDataSet::loadData reads the file when a battle needs it; the parts are read by Libs\XcomFormats)
  /// </summary>
  TXcomMapDataSet = class
  strict private
    FName: string;
    FLoaded: Boolean;
  public
    constructor Create(const AName: string);
    property Name: string read FName;
    /// <summary>Whether the data of the file are in memory (always False here: the file is not read)</summary>
    property Loaded: Boolean read FLoaded;
  end;

implementation

{ TXcomMapDataSet }

constructor TXcomMapDataSet.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
end;

end.
