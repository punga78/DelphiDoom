{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III program - the command line                            }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software): the "+" lines   }
{  of common.c (Com_ParseCommandLine, Com_AddStartupCommands). Copyright (C)   }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Quake3.CommandLine;

interface

uses
  System.SysUtils, DelphiDoom.Quake3.Types;

type
  /// <summary>
  ///   The command line as Quake III reads it: every word that starts with "+" begins a console command and the
  ///   words after it, up to the next "+", are its arguments ("+set fs_game baseoa +map oa_dm1 +addbot Sarge 3").
  ///   Added here: -frames N, -noclient, -help and the shortcuts -fs_basepath, -fs_homepath and -fs_game that
  ///   stand for "+set name value"
  /// </summary>
  TQ3CommandLine = class sealed
  strict private
    class function Quote(const AWord: string): string; static;
    class function IsShortcut(const AWord: string): Boolean; static;
  public
    /// <summary>
    ///   False (and the reason in AError) when a word is not understood; AOptions is complete when it is True
    /// </summary>
    class function Parse(const AArguments: array of string; out AOptions: TQ3ProgramOptions;
      out AError: string): Boolean; static;
    /// <summary>
    ///   True for the lines of the set family: they are executed before the server exists
    ///   (Com_StartupVariable), so that the latched variables take the value from the start
    /// </summary>
    class function IsSetCommand(const ALine: AnsiString): Boolean; static;
    /// <summary>The usage text, one line per entry</summary>
    class function Usage: TArray<string>; static;
  end;

implementation

resourcestring
  SMissingValue = 'The option %s needs a value';
  SBadFrames = 'The number of frames "%s" is not a number of zero or more';
  SUnknownWord = 'Unknown argument "%s" (the commands start with +)';

const
  SHORTCUTS: array[0..2] of string = ('fs_basepath', 'fs_homepath', 'fs_game');

{ TQ3CommandLine }

class function TQ3CommandLine.Quote(const AWord: string): string;
begin
  // the tokenizer of the console reads "text" as one token
  if (AWord = '') or (AWord.IndexOfAny([' ', #9, ';']) >= 0) then
    Result := '"' + AWord + '"'
  else
    Result := AWord;
end;

class function TQ3CommandLine.IsShortcut(const AWord: string): Boolean;
var
  LName: string;
begin
  for LName in SHORTCUTS do
    if SameText(AWord, '-' + LName) then
      Exit(True);
  Result := False;
end;

class function TQ3CommandLine.IsSetCommand(const ALine: AnsiString): Boolean;
var
  LName: string;
  LSpace: Integer;
begin
  LSpace := Pos(' ', string(ALine));
  if LSpace = 0 then
    LName := string(ALine)
  else
    LName := Copy(string(ALine), 1, LSpace - 1);
  Result := SameText(LName, 'set') or SameText(LName, 'seta') or SameText(LName, 'sets') or
    SameText(LName, 'setu');
end;

class function TQ3CommandLine.Parse(const AArguments: array of string; out AOptions: TQ3ProgramOptions;
  out AError: string): Boolean;
var
  LLines: TArray<AnsiString>;
  LCurrent: string;
  LHasCurrent: Boolean;
  LIndex, LFrames: Integer;
  LWord: string;

  procedure Flush;
  begin
    if LHasCurrent then
    begin
      SetLength(LLines, Length(LLines) + 1);
      LLines[High(LLines)] := AnsiString(LCurrent);
      LHasCurrent := False;
    end;
  end;

begin
  AOptions := Default(TQ3ProgramOptions);
  AOptions.Frames := Q3_FRAMES_UNLIMITED;
  AError := '';
  LHasCurrent := False;
  LCurrent := '';
  LIndex := 0;
  while LIndex <= High(AArguments) do
  begin
    LWord := AArguments[LIndex];
    if (Length(LWord) > 1) and (LWord[1] = '+') then
    begin
      Flush;
      LCurrent := Copy(LWord, 2, MaxInt);
      LHasCurrent := True;
    end
    else if SameText(LWord, '-noclient') then
      AOptions.NoClient := True
    else if SameText(LWord, '-help') or SameText(LWord, '-?') then
      AOptions.Help := True
    else if SameText(LWord, '-frames') or IsShortcut(LWord) then
    begin
      if LIndex = High(AArguments) then
      begin
        AError := Format(SMissingValue, [LWord]);
        Exit(False);
      end;
      Inc(LIndex);
      if SameText(LWord, '-frames') then
      begin
        if not TryStrToInt(AArguments[LIndex], LFrames) or (LFrames < 0) then
        begin
          AError := Format(SBadFrames, [AArguments[LIndex]]);
          Exit(False);
        end;
        AOptions.Frames := LFrames;
      end
      else
      begin
        Flush;
        SetLength(LLines, Length(LLines) + 1);
        LLines[High(LLines)] := AnsiString('set ' + Copy(LWord, 2, MaxInt) + ' ' + Quote(AArguments[LIndex]));
      end;
    end
    else if LHasCurrent then
      LCurrent := LCurrent + ' ' + Quote(LWord)
    else
    begin
      AError := Format(SUnknownWord, [LWord]);
      Exit(False);
    end;
    Inc(LIndex);
  end;
  Flush;
  AOptions.Commands := LLines;
  Result := True;
end;

class function TQ3CommandLine.Usage: TArray<string>;
begin
  Result := [
    'Quake3Server - dedicated server of Quake III Arena / OpenArena, console only',
    '',
    'Quake3Server.exe +set fs_basepath <folder> +set fs_game baseoa +map oa_dm1 +addbot Sarge 3 -frames 300',
    '',
    '  +<command> [arguments]   a console command (set, map, addbot, map_restart, status, quit ...)',
    '  -fs_basepath <folder>    the folder that holds baseoa (same as +set fs_basepath <folder>)',
    '  -fs_homepath <folder>    where the program may write (default: the temporary folder)',
    '  -fs_game <folder>        the game folder on top of baseoa (default baseoa)',
    '  -frames <n>              stop after n frames of the main loop (default: run until quit)',
    '  -noclient                no client in the process (without it a client joins and sends commands)',
    '  -help                    this text',
    '',
    'Exit code: 0 ok, 1 Com_Error of a module, 2 system call not served, 3 other failure, 4 bad command line'];
end;

end.
