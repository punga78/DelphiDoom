{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - where the real data are              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.RealData;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   DATA.WAR of the game is not in the repository (a commercial game). It is looked for in the folder of the
  ///   environment variable DELPHIDOOM_WAR_DATA (the folder that has DATA\DATA.WAR, or the DATA.WAR itself), or
  ///   in Reference\_dati\warcraft of a folder above the program. A test that needs it is IGNORED (not green,
  ///   not red) if it is not there
  /// </summary>
  TWarRealData = class
  strict private
    class function Search: string; static;
  public
    /// <summary>The path of DATA.WAR; empty if it is not on this machine</summary>
    class function DataWarPath: string; static;
    /// <summary>A golden file of Tests\Data\War</summary>
    class function GoldenPath(const AName: string): string; static;
    /// <summary>Marks the running test as ignored (ETestIgnored) if DATA.WAR is not here; else returns its path</summary>
    class function RequireDataWar: string; static;
  end;

implementation

uses
  System.IOUtils, DUnitX.Exceptions;

{ TWarRealData }

class function TWarRealData.Search: string;
var
  LCurrent: string;
  LParent: string;
begin
  Result := GetEnvironmentVariable('DELPHIDOOM_WAR_DATA');
  if Result <> '' then
  begin
    if TFile.Exists(Result) then
      Exit;
    if TFile.Exists(TPath.Combine(Result, 'DATA\DATA.WAR')) then
      Exit(TPath.Combine(Result, 'DATA\DATA.WAR'));
  end;
  Result := '';
  LCurrent := ExtractFilePath(ParamStr(0));
  while LCurrent <> '' do
  begin
    if TFile.Exists(TPath.Combine(LCurrent, 'Reference\_dati\warcraft\DATA\DATA.WAR')) then
      Exit(TPath.Combine(LCurrent, 'Reference\_dati\warcraft\DATA\DATA.WAR'));
    LParent := ExtractFileDir(ExcludeTrailingPathDelimiter(LCurrent));
    if (LParent = '') or (LParent = ExcludeTrailingPathDelimiter(LCurrent)) then
      Break;
    LCurrent := IncludeTrailingPathDelimiter(LParent);
  end;
end;

class function TWarRealData.DataWarPath: string;
begin
  Result := Search;
end;

class function TWarRealData.GoldenPath(const AName: string): string;
begin
  Result := TPath.GetFullPath(ExtractFilePath(ParamStr(0)) + '..\..\..\..\Tests\Data\War\' + AName);
end;

class function TWarRealData.RequireDataWar: string;
begin
  Result := Search;
  if Result = '' then
    raise ETestIgnored.Create('DATA.WAR di Warcraft non c''e'' su questo PC (DELPHIDOOM_WAR_DATA o Reference\_dati\warcraft): prova ignorata');
end;

end.
