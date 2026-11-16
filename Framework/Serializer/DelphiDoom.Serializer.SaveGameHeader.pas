{******************************************************************************}
{                                                                              }
{  DelphiDoom: serializer library - the header of a saved game                 }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Serializer.SaveGameHeader;

interface

type
  /// <summary>
  ///   The 8 bit fields at the beginning of the file of a saved game: the description, the text
  ///   of the version and the time of the level in three bytes (G_DoSaveGameInFile and
  ///   G_DoLoadGame of g_game)
  /// </summary>
  TSaveGameHeader = class sealed
  public
    /// <summary>
    ///   Writes the description as 8 bit text: cut at ASize bytes and padded
    /// </summary>
    /// <param name="ADestination">Where it goes (ASize bytes are written)</param>
    /// <param name="ASize">The size of the field (24 in every game)</param>
    /// <param name="ADescription">The text of the player</param>
    /// <param name="APadding">The byte after the text: 0 in Doom and Heretic, a space in Strife</param>
    class procedure WriteDescription(const ADestination: PByte; const ASize: Integer;
      const ADescription: string; const APadding: Byte); static;

    /// <summary>
    ///   The text of the version of the engine ("version 206") as written in the file
    /// </summary>
    /// <param name="AVersion">The number of the version</param>
    /// <param name="ASize">The size of the field: the text is padded with spaces</param>
    /// <param name="APrefix">The word before the number ("version" or "heretic")</param>
    class function VersionText(const AVersion: Integer; const ASize: Integer;
      const APrefix: string = 'version'): AnsiString; static;

    /// <summary>Writes the field of the version (ASize bytes)</summary>
    class procedure WriteVersion(const ADestination: PByte; const AVersion: Integer;
      const ASize: Integer; const APrefix: string = 'version'); static;

    /// <summary>Writes the tics of the level in three bytes, the most significant first</summary>
    class procedure WriteLevelTime(const ADestination: PByte; const ALevelTime: Integer); static;

    /// <summary>Reads the tics of the level written by WriteLevelTime</summary>
    class function ReadLevelTime(const ASource: PByte): Integer; static;
  end;

implementation

uses
  System.SysUtils;

{ TSaveGameHeader }

class procedure TSaveGameHeader.WriteDescription(const ADestination: PByte;
  const ASize: Integer; const ADescription: string; const APadding: Byte);
var
  LText: AnsiString;
begin
  FillChar(ADestination^, ASize, APadding);
  LText := AnsiString(ADescription);
  if Length(LText) > ASize then
    SetLength(LText, ASize);
  if Length(LText) > 0 then
    Move(LText[1], ADestination^, Length(LText));
end;

class function TSaveGameHeader.VersionText(const AVersion: Integer; const ASize: Integer;
  const APrefix: string): AnsiString;
begin
  Result := AnsiString(APrefix + ' ' + IntToStr(AVersion));
  while Length(Result) < ASize do
    Result := Result + ' ';
end;

class procedure TSaveGameHeader.WriteVersion(const ADestination: PByte;
  const AVersion: Integer; const ASize: Integer; const APrefix: string);
var
  LText: AnsiString;
begin
  LText := VersionText(AVersion, ASize, APrefix);
  Move(LText[1], ADestination^, ASize);
end;

class procedure TSaveGameHeader.WriteLevelTime(const ADestination: PByte;
  const ALevelTime: Integer);
begin
  // the three bytes keep the low 8 bits of each part: the wraparound is wanted
  ADestination[0] := Byte(ALevelTime shr 16);
  ADestination[1] := Byte(ALevelTime shr 8);
  ADestination[2] := Byte(ALevelTime);
end;

class function TSaveGameHeader.ReadLevelTime(const ASource: PByte): Integer;
begin
  Result := (Integer(ASource[0]) shl 16) + (Integer(ASource[1]) shl 8) + ASource[2];
end;

end.
