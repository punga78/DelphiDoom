{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - the names of the mp3 files tried for a song     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.ExternalMusicNames;

interface

type
  /// <summary>
  ///   The list of S_DoChangeMusic of s_sound.pas ("Create a list with external mp3 filenames
  ///   to check") and its S_GetListFromAlias, without the song record of the engine: the
  ///   engine opens the files of the list in order and plays the first that exists
  /// </summary>
  TExternalMusicNames = class sealed
  public
    /// <summary>
    ///   The names inside AAlias (separated by spaces or commas), in upper case, without the
    ///   empty ones
    /// </summary>
    class function AliasList(const AAlias: string): TArray<string>; static;
    /// <summary>
    ///   The file names to try, in order: the name of the map (if any) and the name of the
    ///   song, each one plain and with ALumpPrefix ("d_" or "MUS_"); with AWithAliases (the
    ///   games that have aliases: not Heretic and Hexen) the same for each alias
    /// </summary>
    class function Candidates(const AMapName, AName, AAlias, ALumpPrefix: string;
      AWithAliases: Boolean): TArray<string>; static;
  end;

implementation

const
  MP3_EXTENSION = '.mp3';

{ TExternalMusicNames }

class function TExternalMusicNames.AliasList(const AAlias: string): TArray<string>;
var
  LIndex: Integer;
  LCount: Integer;
  LName: string;
  LChar: Char;

  procedure Flush;
  begin
    if LName <> '' then
    begin
      Result[LCount] := LName;
      Inc(LCount);
      LName := '';
    end;
  end;

begin
  SetLength(Result, Length(AAlias));
  LCount := 0;
  LName := '';
  for LIndex := 1 to Length(AAlias) do
  begin
    LChar := AAlias[LIndex];
    case LChar of
      // the old list was filled as text: a zero character ended it
      #0:
        Break;
      // and a line break inside the alias ended a name too
      ' ', ',', #13, #10:
        Flush;
      'a'..'z':
        LName := LName + Char(Ord(LChar) - 32);
    else
      LName := LName + LChar;
    end;
  end;
  Flush;
  SetLength(Result, LCount);
end;

class function TExternalMusicNames.Candidates(const AMapName, AName, AAlias,
  ALumpPrefix: string; AWithAliases: Boolean): TArray<string>;
var
  LAliases: TArray<string>;
  LCount: Integer;
  LAlias: string;

  procedure Add(const AFileName: string);
  begin
    Result[LCount] := AFileName;
    Inc(LCount);
  end;

begin
  LAliases := nil;
  if AWithAliases then
    LAliases := AliasList(AAlias);
  SetLength(Result, 4 + 2 * Length(LAliases));
  LCount := 0;

  if AMapName <> '' then
  begin
    Add(AMapName + MP3_EXTENSION);
    Add(ALumpPrefix + AMapName + MP3_EXTENSION);
  end;
  Add(AName + MP3_EXTENSION);
  Add(ALumpPrefix + AName + MP3_EXTENSION);
  for LAlias in LAliases do
  begin
    Add(LAlias + MP3_EXTENSION);
    Add(ALumpPrefix + LAlias + MP3_EXTENSION);
  end;
  SetLength(Result, LCount);
end;

end.
