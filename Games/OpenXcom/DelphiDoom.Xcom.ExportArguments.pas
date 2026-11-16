{******************************************************************************}
{                                                                              }
{  DelphiDoom: Xcom32 - the arguments of the export of the data files          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.ExportArguments;

interface

uses
  System.SysUtils;

type
  /// <summary>An argument of the export without its value</summary>
  EXcomExportArgumentException = class(Exception);

  /// <summary>What the export decodes</summary>
  TXcomExportMode = (xmNone, xmPck, xmDat, xmScr, xmMap);

  /// <summary>
  ///   The command line of Xcom32 when it exports a data file as a PNG instead of opening the game. The program is
  ///   in this mode when, and only when, the command line names what to export: -pck, -dat, -scr or -map
  ///   (IsExport). In this mode -data is a folder of the game (the one with GEODATA\PALETTES.DAT) and can be
  ///   repeated; -game is the same thing. In the mode of the game -data is the folder with common\ and standard\
  ///   and -game the folder of the game: -game means the same in both modes, -data does not
  /// </summary>
  TXcomExportArguments = record
  public
    /// <summary>The folders of the game, in the order of the command line; empty when none was given</summary>
    Folders: TArray<string>;
    Mode: TXcomExportMode;
    InputFile: string;
    TabFile: string;
    RouteFile: string;
    PngFile: string;
    PaletteIndex: Integer;
    /// <summary>0: the default of the mode</summary>
    Width: Integer;
    /// <summary>0: the default of the mode</summary>
    Height: Integer;
    Columns: Integer;
    Layer: Integer;
    /// <summary>True when the command line names what to export (-pck, -dat, -scr or -map)</summary>
    class function IsExport(const AArguments: array of string): Boolean; static;
    /// <summary>
    ///   Reads the command line of the export. False when an argument is not one of the export (the ones of the
    ///   game too) or nothing to export is named; an argument without its value raises
    /// </summary>
    class function TryParse(const AArguments: array of string; out AResult: TXcomExportArguments): Boolean; static;
  end;

implementation

const
  SXcomExportNeedsValue = '%s needs a value';
  DEFAULT_PNG_FILE = 'xcom.png';
  DEFAULT_COLUMNS = 16;

function ModeOf(const AName: string): TXcomExportMode;
begin
  if AName = '-pck' then
    Result := xmPck
  else if AName = '-dat' then
    Result := xmDat
  else if AName = '-scr' then
    Result := xmScr
  else if AName = '-map' then
    Result := xmMap
  else
    Result := xmNone;
end;

{ TXcomExportArguments }

class function TXcomExportArguments.IsExport(const AArguments: array of string): Boolean;
var
  LArgument: string;
begin
  for LArgument in AArguments do
    if ModeOf(LArgument.ToLowerInvariant) <> xmNone then
      Exit(True);
  Result := False;
end;

class function TXcomExportArguments.TryParse(const AArguments: array of string;
  out AResult: TXcomExportArguments): Boolean;
var
  LIndex: Integer;
  LName: string;

  function NextValue: string;
  begin
    if LIndex >= High(AArguments) then
      raise EXcomExportArgumentException.CreateFmt(SXcomExportNeedsValue, [LName]);
    Inc(LIndex);
    Result := AArguments[LIndex];
  end;

begin
  AResult := Default(TXcomExportArguments);
  AResult.Columns := DEFAULT_COLUMNS;
  AResult.PngFile := DEFAULT_PNG_FILE;
  LIndex := 0;
  while LIndex <= High(AArguments) do
  begin
    LName := AArguments[LIndex].ToLowerInvariant;
    if (LName = '-data') or (LName = '-game') then
      AResult.Folders := AResult.Folders + [NextValue]
    else if LName = '-pal' then
      AResult.PaletteIndex := StrToInt(NextValue)
    else if LName = '-png' then
      AResult.PngFile := NextValue
    else if LName = '-tab' then
      AResult.TabFile := NextValue
    else if LName = '-rmp' then
      AResult.RouteFile := NextValue
    else if LName = '-w' then
      AResult.Width := StrToInt(NextValue)
    else if LName = '-h' then
      AResult.Height := StrToInt(NextValue)
    else if LName = '-columns' then
      AResult.Columns := StrToInt(NextValue)
    else if LName = '-z' then
      AResult.Layer := StrToInt(NextValue)
    else if ModeOf(LName) <> xmNone then
    begin
      AResult.Mode := ModeOf(LName);
      AResult.InputFile := NextValue;
    end
    else
      Exit(False);
    Inc(LIndex);
  end;
  Result := AResult.Mode <> xmNone;
end;

end.
