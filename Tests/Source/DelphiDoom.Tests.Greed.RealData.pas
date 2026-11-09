{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - where the real data are             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.RealData;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Intf;

type
  /// <summary>
  ///   The demos of the game (GREED.BLO of the 1.016 and of the 2.0) are not in the repository. They are looked
  ///   for in the folder of the environment variable DELPHIDOOM_GREED_DATA, or in Reference\_dati\greed of a
  ///   folder above the program: demo1016\GREED.BLO and demo20gus\GREEDEMO.20\GREED.BLO (with the LEVEL*.LAY
  ///   maps). A test that needs them is skipped if they are not there
  /// </summary>
  TGreedRealData = class
  strict private
    class function Root: string; static;
  public
    /// <summary>The folder of GREED.BLO of the demo 1.016; empty if it is not on this machine</summary>
    class function Demo1016Folder: string; static;
    /// <summary>The folder of GREED.BLO and of the .LAY files of the demo 2.0; empty if it is not here</summary>
    class function Demo20Folder: string; static;
    /// <summary>The folder of GREED.BLO of the full game; empty if it is not on this machine (it is not in the repository)</summary>
    class function FullFolder: string; static;
    /// <summary>A golden file of Tests\Data\Greed</summary>
    class function GoldenPath(const AName: string): string; static;
    /// <summary>The archive of the folder (with the corrections of the original)</summary>
    class function OpenArchive(const AFolder: string): IGreedArchive; static;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Greed.Factory;

{ TGreedRealData }

class function TGreedRealData.Root: string;
var
  LCurrent: string;
  LParent: string;
begin
  Result := GetEnvironmentVariable('DELPHIDOOM_GREED_DATA');
  if (Result <> '') and TDirectory.Exists(Result) then
    Exit;
  Result := '';
  LCurrent := ExtractFilePath(ParamStr(0));
  while LCurrent <> '' do
  begin
    if TDirectory.Exists(TPath.Combine(LCurrent, 'Reference\_dati\greed')) then
      Exit(TPath.Combine(LCurrent, 'Reference\_dati\greed'));
    LParent := ExtractFileDir(ExcludeTrailingPathDelimiter(LCurrent));
    if (LParent = '') or (LParent = ExcludeTrailingPathDelimiter(LCurrent)) then
      Break;
    LCurrent := IncludeTrailingPathDelimiter(LParent);
  end;
end;

class function TGreedRealData.Demo1016Folder: string;
begin
  Result := TPath.Combine(Root, 'demo1016');
  if (Root = '') or not TFile.Exists(TPath.Combine(Result, 'GREED.BLO')) then
    Result := '';
end;

class function TGreedRealData.Demo20Folder: string;
begin
  Result := TPath.Combine(Root, 'demo20gus\GREEDEMO.20');
  if (Root = '') or not TFile.Exists(TPath.Combine(Result, 'GREED.BLO')) then
    Result := '';
end;

class function TGreedRealData.FullFolder: string;
begin
  Result := TPath.Combine(Root, 'full');
  if (Root = '') or not TFile.Exists(TPath.Combine(Result, 'GREED.BLO')) then
    Result := '';
end;

class function TGreedRealData.GoldenPath(const AName: string): string;
begin
  Result := TPath.GetFullPath(ExtractFilePath(ParamStr(0)) + '..\..\Tests\Data\Greed\' + AName);
end;

class function TGreedRealData.OpenArchive(const AFolder: string): IGreedArchive;
begin
  Result := TGreedFactory.OpenArchiveFile(TPath.Combine(AFolder, 'GREED.BLO'));
end;

end.
