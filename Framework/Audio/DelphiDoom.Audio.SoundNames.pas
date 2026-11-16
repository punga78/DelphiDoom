{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - the rules on the names of sounds and songs      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.SoundNames;

interface

type
  /// <summary>
  ///   The small rules that sounds.pas applied to names, with the same results: the upper
  ///   case touches only a-z, a number is a number only if it is written as the engine
  ///   would write it. The matchers are static so that the table of the engine can call them
  ///   in its loop without a call to an interface per slot
  /// </summary>
  TSoundNames = class sealed
  public
    /// <summary>
    ///   True if AName is a decimal number written in the canonical form (the old
    ///   itoa(atoi(name, -1)) = name); ANumber is atoi(name, -1) in any case
    /// </summary>
    class function IsNumber(const AName: string; out ANumber: Integer): Boolean; static;
    /// <summary>True if AText starts with APrefix (the old Pos1)</summary>
    class function HasPrefix(const APrefix, AText: string): Boolean; static;
    /// <summary>The upper case of a-z only (the old strupper)</summary>
    class function Upper(const AText: string): string; static;
    /// <summary>
    ///   True if the song in the slot is the one asked for: its upper case name, or the
    ///   name with the "D_" prefix of the lump; AUpperName is already in upper case
    /// </summary>
    class function MusicMatches(const ASlotName, AUpperName: string): Boolean; static;
    /// <summary>
    ///   True if the sound in the slot is the one asked for: its upper case name, or the name
    ///   with the "DS" prefix of the lump; AUpperName is already in upper case
    /// </summary>
    class function SfxMatches(const ASlotName, AUpperName: string): Boolean; static;
    /// <summary>
    ///   As SfxMatches, and the tag name of the slot counts too (Hexen: the name of the
    ///   sounds of SNDINFO)
    /// </summary>
    class function SfxMatchesTagged(const ASlotTagName, ASlotName, AUpperName: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Scanner.Strings;

{ TSoundNames }

class function TSoundNames.IsNumber(const AName: string; out ANumber: Integer): Boolean;
begin
  ANumber := TScannerStrings.ToInteger(AName, -1);
  Result := IntToStr(ANumber) = AName;
end;

class function TSoundNames.HasPrefix(const APrefix, AText: string): Boolean;
begin
  Result := Copy(AText, 1, Length(APrefix)) = APrefix;
end;

class function TSoundNames.Upper(const AText: string): string;
begin
  Result := TScannerStrings.UpperAscii(AText);
end;

class function TSoundNames.MusicMatches(const ASlotName, AUpperName: string): Boolean;
var
  LCheck: string;
begin
  LCheck := Upper(ASlotName);
  Result := (LCheck = AUpperName) or ('D_' + LCheck = AUpperName);
end;

class function TSoundNames.SfxMatches(const ASlotName, AUpperName: string): Boolean;
var
  LCheck: string;
begin
  LCheck := Upper(ASlotName);
  Result := (LCheck = AUpperName) or ('DS' + LCheck = AUpperName);
end;

class function TSoundNames.SfxMatchesTagged(const ASlotTagName, ASlotName,
  AUpperName: string): Boolean;
begin
  Result := (Upper(ASlotTagName) = AUpperName) or (Upper(ASlotName) = AUpperName) or
    ('DS' + Upper(ASlotName) = AUpperName);
end;

end.
