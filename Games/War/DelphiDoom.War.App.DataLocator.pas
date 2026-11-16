{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - where DATA.WAR and the fonts of the remake are    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.App.DataLocator;

interface

uses
  System.SysUtils;

type
  /// <summary>Whether a file exists (the disk of the program, or a fake in a test)</summary>
  TWarFileExists = reference to function(const APath: string): Boolean;

  /// <summary>
  ///   Looks for the files the program cannot start without. The game is a commercial one and its data are not in
  ///   the repository: the player gives the folder (-data) and the program says what is missing and where it looked
  /// </summary>
  TWarDataLocator = class
  strict private
    class function Combine(const AFolder, ARelative: string): string; static;
  public
    /// <summary>The path of DATA.WAR in the first folder that has it (the file itself or its folder DATA); empty if none</summary>
    class function FindDataWar(const AFolders: TArray<string>; const AExists: TWarFileExists): string; static;
    /// <summary>
    ///   The PNG of a font of the remake (AFont is 0 or 1): in the folder, in FONTS or assets of it, or in
    ///   Reference\war1\assets of a folder above it; empty if none
    /// </summary>
    class function FindFont(AFont: Integer; const AFolders: TArray<string>; const AExists: TWarFileExists): string;
      static;
    /// <summary>The paths that FindDataWar looks at, for the message when it finds nothing</summary>
    class function DataWarCandidates(const AFolders: TArray<string>): TArray<string>; static;
  end;

const
  /// <summary>The name of the data file of the game</summary>
  WAR_DATA_FILE_NAME = 'DATA.WAR';

implementation

const
  PARENT_LEVELS = 6;

{ TWarDataLocator }

class function TWarDataLocator.Combine(const AFolder, ARelative: string): string;
begin
  Result := IncludeTrailingPathDelimiter(AFolder) + ARelative;
end;

class function TWarDataLocator.DataWarCandidates(const AFolders: TArray<string>): TArray<string>;
var
  LFolder: string;
begin
  Result := nil;
  for LFolder in AFolders do
  begin
    Result := Result + [Combine(LFolder, WAR_DATA_FILE_NAME)];
    Result := Result + [Combine(LFolder, 'DATA\' + WAR_DATA_FILE_NAME)];
  end;
end;

class function TWarDataLocator.FindDataWar(const AFolders: TArray<string>; const AExists: TWarFileExists): string;
var
  LPath: string;
begin
  for LPath in DataWarCandidates(AFolders) do
    if AExists(LPath) then
      Exit(LPath);
  Result := '';
end;

class function TWarDataLocator.FindFont(AFont: Integer; const AFolders: TArray<string>;
  const AExists: TWarFileExists): string;
var
  LName: string;
  LFolder: string;
  LCurrent: string;
  LParent: string;
  LLevel: Integer;
  LPath: string;
begin
  LName := Format('war1_font_%d.png', [AFont + 1]);
  for LFolder in AFolders do
  begin
    for LPath in [Combine(LFolder, LName), Combine(LFolder, 'FONTS\' + LName), Combine(LFolder, 'assets\' + LName)] do
      if AExists(LPath) then
        Exit(LPath);
    LCurrent := ExcludeTrailingPathDelimiter(LFolder);
    for LLevel := 1 to PARENT_LEVELS do
    begin
      LPath := Combine(LCurrent, 'Reference\war1\assets\' + LName);
      if AExists(LPath) then
        Exit(LPath);
      LParent := ExtractFileDir(LCurrent);
      if (LParent = '') or (LParent = LCurrent) then
        Break;
      LCurrent := LParent;
    end;
  end;
  Result := '';
end;

end.
