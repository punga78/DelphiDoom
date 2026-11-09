{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - where the real data of the game are  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.RealData;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   The shareware 1.13 files (KDREAMS.EGA, .MAP, .AUD) are not in the repository. They are looked for in the
  ///   folder of the environment variable DELPHIDOOM_KEEN_DATA, or in Reference\_dati\keen_build\riferimento of
  ///   a folder above the program: dati (the three files), golden (MAPHEAD.KDR and MAPDICT.KDR of the 1.13, that
  ///   an unpacker took from the program) and Reference\keen\static (the other headers and dictionaries,
  ///   the same in the 1.13 and in the 1.93 of the source code). A test that needs them is skipped if they are not there
  /// </summary>
  TKeenRealData = class
  public
    /// <summary>The files of the real game; nil if they are not on this machine</summary>
    class function OpenFiles: IKeenDataFiles; static;
    /// <summary>The golden file of the original program, Tests\Data\Keen\KDGOLD.TXT</summary>
    class function GoldenPath: string; static;
    /// <summary>
    ///   Tests\Data\Keen\KDGOLD_EXTRA.TXT: the first bytes of the tile chunks that the C expands with what the buffer
    ///   had after the data (taken from the -raw dump of kdgold.exe)
    /// </summary>
    class function GoldenExtraPath: string; static;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Keen.Factory;

{ TKeenRealData }

class function TKeenRealData.GoldenPath: string;
begin
  Result := TPath.GetFullPath(ExtractFilePath(ParamStr(0)) + '..\..\Tests\Data\Keen\KDGOLD.TXT');
end;

class function TKeenRealData.GoldenExtraPath: string;
begin
  Result := TPath.GetFullPath(ExtractFilePath(ParamStr(0)) + '..\..\Tests\Data\Keen\KDGOLD_EXTRA.TXT');
end;

class function TKeenRealData.OpenFiles: IKeenDataFiles;
var
  LFolder: string;
  LCurrent: string;
  LRoot: string;
  LParent: string;
  LFiles: IKeenDataFiles;
begin
  Result := nil;
  LFolder := GetEnvironmentVariable('DELPHIDOOM_KEEN_DATA');
  if (LFolder <> '') and TDirectory.Exists(LFolder) then
  begin
    LFiles := TKeenFactory.CreateFolderFiles([LFolder]);
    if LFiles.Exists('KDREAMS.EGA') then
      Exit(LFiles);
  end;
  LCurrent := ExtractFilePath(ParamStr(0));
  while LCurrent <> '' do
  begin
    LRoot := TPath.Combine(LCurrent, 'Reference');
    if TDirectory.Exists(TPath.Combine(LRoot, '_dati\keen_build\riferimento\dati')) then
    begin
      LFiles := TKeenFactory.CreateFolderFiles([
        TPath.Combine(LRoot, '_dati\keen_build\riferimento\dati'),
        TPath.Combine(LRoot, '_dati\keen_build\riferimento\golden'),
        TPath.Combine(LRoot, 'keen\static')]);
      if LFiles.Exists('KDREAMS.EGA') and LFiles.Exists('MAPHEAD.KDR') and LFiles.Exists('EGAHEAD.KDR') then
        Exit(LFiles);
    end;
    LParent := ExtractFileDir(ExcludeTrailingPathDelimiter(LCurrent));
    if (LParent = '') or (LParent = ExcludeTrailingPathDelimiter(LCurrent)) then
      Break;
    LCurrent := IncludeTrailingPathDelimiter(LParent);
  end;
end;

end.
