{******************************************************************************}
{                                                                              }
{  DelphiDoom: launcher library - TLauncherEngines                             }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Launcher.Engines;

interface

uses
  System.SysUtils;

type
  /// <summary>Tells whether a file is there (the disk in the Launcher, a list in the tests)</summary>
  TLauncherFileExists = reference to function(const AFileName: string): Boolean;

  /// <summary>
  ///   What the Launcher knows of the games it starts: the name of each engine (the entries of
  ///   its radio group, in the order of gameengine_t), its programs, its folder of data, its
  ///   main data files. An engine is its index, 0 .. COUNT - 1; any other number is no engine
  /// </summary>
  TLauncherEngines = class
  public const
    DOOM = 0;
    HERETIC = 1;
    HEXEN = 2;
    STRIFE = 3;
    RADIX = 4;
    /// <summary>How many engines the Launcher knows</summary>
    COUNT = 5;
    /// <summary>No engine</summary>
    NONE = -1;
  public
    /// <summary>True for the index of an engine</summary>
    class function IsEngine(AEngine: Integer): Boolean; static;
    /// <summary>The name of an engine as the Launcher shows it ('Doom', 'Radix'); '' for no engine</summary>
    class function Name(AEngine: Integer): string; static;
    /// <summary>The engine with that name, whatever its case; NONE when there is none</summary>
    class function IndexOfName(const AName: string): Integer; static;
    /// <summary>The folder of the data of an engine below the folder of the games ('doom\'); '' for no engine</summary>
    class function Folder(AEngine: Integer): string; static;
    /// <summary>False for an engine without an OpenGL program (Radix)</summary>
    class function HasOpenGl(AEngine: Integer): Boolean; static;
    /// <summary>
    ///   The program of an engine: the OpenGL one when it is asked and the engine has it, the
    ///   software one otherwise; '' for no engine
    /// </summary>
    class function Executable(AEngine: Integer; AOpenGl: Boolean): string; static;
    /// <summary>
    ///   Where the program is. The games are built in a folder beside the Launcher that has the
    ///   name of their data folder, and they find their data from there; an old layout has them
    ///   in the data folder. The first that is there: the data folder, the folder of the engine
    ///   beside the Launcher, the folder of the Launcher. The bare name when none is (the system
    ///   then looks for it as it did before)
    /// </summary>
    /// <param name="ALauncherFolder">The folder of the Launcher program</param>
    /// <param name="ADataFolder">The folder of the data of the game</param>
    class function ExecutablePath(AEngine: Integer; AOpenGl: Boolean; const ALauncherFolder, ADataFolder: string;
      const AFileExists: TLauncherFileExists): string; static;
    /// <summary>The main data files of an engine, the one to prefer first (file names, lower case)</summary>
    class function MainDataFiles(AEngine: Integer): TArray<string>; static;
    /// <summary>The engine whose main data file has that name (a path is allowed); NONE when no engine has it</summary>
    class function EngineOfDataFile(const AFileName: string): Integer; static;
    /// <summary>The first main data file of an engine that is there; '' when none is</summary>
    class function DefaultDataFile(AEngine: Integer; const AFileExists: TLauncherFileExists): string; static;
    /// <summary>
    ///   The engine to start when nobody chose one: the first, in the order of the engines, that
    ///   has one of its main data files; Doom when none has
    /// </summary>
    class function DefaultEngine(const AFileExists: TLauncherFileExists): Integer; static;
    /// <summary>The mask of the files that can be the main data file of an engine ('*.wad', '*.dat')</summary>
    class function MainDataMask(AEngine: Integer): string; static;
    /// <summary>
    ///   True when the main data file of an engine is a WAD, that the Launcher can read for the
    ///   names of its maps and of its demos (RADIX.DAT is not one)
    /// </summary>
    class function MainDataIsWad(AEngine: Integer): Boolean; static;
    /// <summary>
    ///   The names of the maps of an engine whose main data file is not a WAD ('E1M1' ..
    ///   'E3M9' for Radix); none for the others, whose maps are read from the WAD
    /// </summary>
    class function BuiltInMapNames(AEngine: Integer): TArray<string>; static;
    /// <summary>The most players of a net game (8 for Hexen and Strife, 4 for the others)</summary>
    class function MaxPlayers(AEngine: Integer): Integer; static;
    /// <summary>The smallest zone, in MB, that the Launcher lets choose (8 for Hexen, 6 for the others)</summary>
    class function MinZoneSize(AEngine: Integer): Integer; static;
    /// <summary>The caption of the menu entry that starts the game ('&Run DelphiDoom'); '' for no engine</summary>
    class function RunCaption(AEngine: Integer): string; static;
    /// <summary>A file name as an argument of a command line: between quotes when it has a space</summary>
    class function Quoted(const AArgument: string): string; static;
  end;

implementation

type
  TLauncherEngineRow = record
    Name: string;
    Folder: string;
    Executable: string;
    OpenGlExecutable: string;
    RunCaption: string;
    DataMask: string;
    MaxPlayers: Integer;
    MinZoneSize: Integer;
  end;

const
  ENGINE_ROWS: array[0..TLauncherEngines.COUNT - 1] of TLauncherEngineRow = (
    (Name: 'Doom'; Folder: 'doom\'; Executable: 'doom32.exe'; OpenGlExecutable: 'gldoom32.exe';
     RunCaption: '&Run DelphiDoom'; DataMask: '*.wad'; MaxPlayers: 4; MinZoneSize: 6),
    (Name: 'Heretic'; Folder: 'heretic\'; Executable: 'heretic32.exe'; OpenGlExecutable: 'glheretic32.exe';
     RunCaption: '&Run DelphiHeretic'; DataMask: '*.wad'; MaxPlayers: 4; MinZoneSize: 6),
    (Name: 'Hexen'; Folder: 'hexen\'; Executable: 'hexen32.exe'; OpenGlExecutable: 'glhexen32.exe';
     RunCaption: '&Run DelphiHexen'; DataMask: '*.wad'; MaxPlayers: 8; MinZoneSize: 8),
    (Name: 'Strife'; Folder: 'strife\'; Executable: 'strife32.exe'; OpenGlExecutable: 'glstrife32.exe';
     RunCaption: '&Run DelphiStrife'; DataMask: '*.wad'; MaxPlayers: 8; MinZoneSize: 6),
    (Name: 'Radix'; Folder: 'radix\'; Executable: 'radix32.exe'; OpenGlExecutable: '';
     RunCaption: '&Run Radix'; DataMask: '*.dat'; MaxPlayers: 4; MinZoneSize: 6));

  // in the order the Launcher has always looked for them
  DOOM_DATA_FILES: array[0..6] of string = (
    'doom2f.wad', 'doom2.wad', 'plutonia.wad', 'tnt.wad', 'doomu.wad', 'doom.wad', 'doom1.wad');
  HERETIC_DATA_FILES: array[0..1] of string = ('heretic.wad', 'heretic1.wad');
  HEXEN_DATA_FILES: array[0..1] of string = ('hexen.wad', 'hexen1.wad');
  STRIFE_DATA_FILES: array[0..1] of string = ('strife1.wad', 'strife0.wad');
  RADIX_DATA_FILES: array[0..0] of string = ('radix.dat');

function CopyOf(const AFiles: array of string): TArray<string>;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(AFiles));
  for LIndex := 0 to High(AFiles) do
    Result[LIndex] := AFiles[LIndex];
end;

{ TLauncherEngines }

class function TLauncherEngines.IsEngine(AEngine: Integer): Boolean;
begin
  Result := (AEngine >= 0) and (AEngine < COUNT);
end;

class function TLauncherEngines.Name(AEngine: Integer): string;
begin
  if IsEngine(AEngine) then
    Result := ENGINE_ROWS[AEngine].Name
  else
    Result := '';
end;

class function TLauncherEngines.IndexOfName(const AName: string): Integer;
var
  LEngine: Integer;
begin
  for LEngine := 0 to COUNT - 1 do
    if SameText(ENGINE_ROWS[LEngine].Name, Trim(AName)) then
      Exit(LEngine);
  Result := NONE;
end;

class function TLauncherEngines.Folder(AEngine: Integer): string;
begin
  if IsEngine(AEngine) then
    Result := ENGINE_ROWS[AEngine].Folder
  else
    Result := '';
end;

class function TLauncherEngines.HasOpenGl(AEngine: Integer): Boolean;
begin
  Result := IsEngine(AEngine) and (ENGINE_ROWS[AEngine].OpenGlExecutable <> '');
end;

class function TLauncherEngines.Executable(AEngine: Integer; AOpenGl: Boolean): string;
begin
  if not IsEngine(AEngine) then
    Result := ''
  else if AOpenGl and HasOpenGl(AEngine) then
    Result := ENGINE_ROWS[AEngine].OpenGlExecutable
  else
    Result := ENGINE_ROWS[AEngine].Executable;
end;

class function TLauncherEngines.ExecutablePath(AEngine: Integer; AOpenGl: Boolean; const ALauncherFolder,
  ADataFolder: string; const AFileExists: TLauncherFileExists): string;
var
  LExecutable: string;
  LCandidates: TArray<string>;
  LCandidate: string;
begin
  if not Assigned(AFileExists) then
    raise EArgumentNilException.Create('AFileExists');
  LExecutable := Executable(AEngine, AOpenGl);
  Result := LExecutable;
  if LExecutable = '' then
    Exit;

  LCandidates := nil;
  if ADataFolder <> '' then
    LCandidates := LCandidates + [IncludeTrailingPathDelimiter(ADataFolder) + LExecutable];
  if ALauncherFolder <> '' then
    LCandidates := LCandidates + [
      IncludeTrailingPathDelimiter(ALauncherFolder) + Folder(AEngine) + LExecutable,
      IncludeTrailingPathDelimiter(ALauncherFolder) + LExecutable];
  for LCandidate in LCandidates do
    if AFileExists(LCandidate) then
      Exit(LCandidate);
end;

class function TLauncherEngines.MainDataFiles(AEngine: Integer): TArray<string>;
begin
  case AEngine of
    DOOM: Result := CopyOf(DOOM_DATA_FILES);
    HERETIC: Result := CopyOf(HERETIC_DATA_FILES);
    HEXEN: Result := CopyOf(HEXEN_DATA_FILES);
    STRIFE: Result := CopyOf(STRIFE_DATA_FILES);
    RADIX: Result := CopyOf(RADIX_DATA_FILES);
  else
    Result := nil;
  end;
end;

class function TLauncherEngines.EngineOfDataFile(const AFileName: string): Integer;
var
  LName: string;
  LEngine: Integer;
  LFile: string;
begin
  LName := ExtractFileName(Trim(AFileName));
  for LEngine := 0 to COUNT - 1 do
    for LFile in MainDataFiles(LEngine) do
      if SameText(LFile, LName) then
        Exit(LEngine);
  Result := NONE;
end;

class function TLauncherEngines.DefaultDataFile(AEngine: Integer; const AFileExists: TLauncherFileExists): string;
var
  LFile: string;
begin
  if not Assigned(AFileExists) then
    raise EArgumentNilException.Create('AFileExists');
  for LFile in MainDataFiles(AEngine) do
    if AFileExists(LFile) then
      Exit(LFile);
  Result := '';
end;

class function TLauncherEngines.DefaultEngine(const AFileExists: TLauncherFileExists): Integer;
var
  LEngine: Integer;
begin
  for LEngine := 0 to COUNT - 1 do
    if DefaultDataFile(LEngine, AFileExists) <> '' then
      Exit(LEngine);
  Result := DOOM;
end;

class function TLauncherEngines.MainDataMask(AEngine: Integer): string;
begin
  if IsEngine(AEngine) then
    Result := ENGINE_ROWS[AEngine].DataMask
  else
    Result := ENGINE_ROWS[DOOM].DataMask;
end;

class function TLauncherEngines.MainDataIsWad(AEngine: Integer): Boolean;
begin
  Result := AEngine <> RADIX;
end;

class function TLauncherEngines.BuiltInMapNames(AEngine: Integer): TArray<string>;
const
  RADIX_EPISODES = 3;
  RADIX_MAPS = 9;
var
  LEpisode: Integer;
  LMap: Integer;
begin
  Result := nil;
  if AEngine <> RADIX then
    Exit;
  SetLength(Result, RADIX_EPISODES * RADIX_MAPS);
  for LEpisode := 1 to RADIX_EPISODES do
    for LMap := 1 to RADIX_MAPS do
      Result[(LEpisode - 1) * RADIX_MAPS + LMap - 1] := Format('E%dM%d', [LEpisode, LMap]);
end;

class function TLauncherEngines.MaxPlayers(AEngine: Integer): Integer;
begin
  if IsEngine(AEngine) then
    Result := ENGINE_ROWS[AEngine].MaxPlayers
  else
    Result := ENGINE_ROWS[DOOM].MaxPlayers;
end;

class function TLauncherEngines.MinZoneSize(AEngine: Integer): Integer;
begin
  if IsEngine(AEngine) then
    Result := ENGINE_ROWS[AEngine].MinZoneSize
  else
    Result := ENGINE_ROWS[DOOM].MinZoneSize;
end;

class function TLauncherEngines.RunCaption(AEngine: Integer): string;
begin
  if IsEngine(AEngine) then
    Result := ENGINE_ROWS[AEngine].RunCaption
  else
    Result := '';
end;

class function TLauncherEngines.Quoted(const AArgument: string): string;
begin
  if Pos(' ', AArgument) = 0 then
    Result := AArgument
  else
    Result := '"' + AArgument + '"';
end;

end.
