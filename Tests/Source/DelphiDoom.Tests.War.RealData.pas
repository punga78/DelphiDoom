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
    /// <summary>A file of the repository (a path from its root), found from the folder of the program</summary>
    class function RepoPath(const ARelative: string): string; static;
    /// <summary>
    ///   The PNG of a font of the remake (war1_font_1.png, war1_font_2.png: Reference\war1\assets, not in the repository);
    ///   empty if it is not on this machine
    /// </summary>
    class function FontPath(AFont: Integer): string; static;
    /// <summary>Marks the running test as ignored if the PNG of a font is not here; else returns its path</summary>
    class function RequireFont(AFont: Integer): string; static;
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

class function TWarRealData.RepoPath(const ARelative: string): string;
begin
  Result := TPath.GetFullPath(ExtractFilePath(ParamStr(0)) + '..\..\..\..\' + ARelative);
end;

class function TWarRealData.FontPath(AFont: Integer): string;
var
  LName: string;
  LCurrent: string;
  LParent: string;
  LData: string;
begin
  LName := Format('war1_font_%d.png', [AFont + 1]);
  // beside DATA.WAR: Reference\_dati\warcraft\DATA\DATA.WAR and Reference\war1\assets
  LData := Search;
  if LData <> '' then
  begin
    Result := TPath.GetFullPath(ExtractFilePath(LData) + '..\..\..\war1\assets\' + LName);
    if TFile.Exists(Result) then
      Exit;
  end;
  Result := '';
  LCurrent := ExtractFilePath(ParamStr(0));
  while LCurrent <> '' do
  begin
    if TFile.Exists(TPath.Combine(LCurrent, 'Reference\war1\assets\' + LName)) then
      Exit(TPath.Combine(LCurrent, 'Reference\war1\assets\' + LName));
    LParent := ExtractFileDir(ExcludeTrailingPathDelimiter(LCurrent));
    if (LParent = '') or (LParent = ExcludeTrailingPathDelimiter(LCurrent)) then
      Break;
    LCurrent := IncludeTrailingPathDelimiter(LParent);
  end;
end;

class function TWarRealData.RequireFont(AFont: Integer): string;
begin
  Result := FontPath(AFont);
  if Result = '' then
    raise ETestIgnored.Create('I PNG dei font del remake (Reference\war1\assets) non ci sono su questo PC: prova ignorata');
end;

class function TWarRealData.RequireDataWar: string;
begin
  Result := Search;
  if Result = '' then
    raise ETestIgnored.Create('DATA.WAR di Warcraft non c''e'' su questo PC (DELPHIDOOM_WAR_DATA o Reference\_dati\warcraft): prova ignorata');
end;

end.
