{******************************************************************************}
{                                                                              }
{  DelphiDoom: audio library - the sounds of a random group                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Audio.SfxRandomGroup;

interface

uses
  DelphiDoom.Audio.Sound.Intf;

type
  /// <summary>A sound of a random group: the name to register and the number of its lump</summary>
  TSfxRandomMember = record
    Name: string;
    LumpNumber: Integer;
  end;

  /// <summary>
  ///   The rule of S_GetRandomSoundList of sounds.pas: the name of a sound that ends with a
  ///   digit ("dsxxx0", "dsxxx3", "dsxxx9") stands for the lumps of the same name that end
  ///   with any digit; not all the digits are required. The list of numbers belongs to the
  ///   table of the engine (it is shared by the sounds of the group): the engine registers
  ///   the members in the order given here
  /// </summary>
  TSfxRandomGroup = class sealed
  public
    /// <summary>True if the name ends with a digit '0'..'9' (a name without it is a group of one)</summary>
    class function IsGroupName(const AUpperName: string): Boolean; static;
    /// <summary>
    ///   The members, in the order of the digits: for each digit the lump with the "DS" name,
    ///   else the one without (names cut to 8 characters, the last character is the digit)
    /// </summary>
    class function Members(const AUpperName: string;
      const AFinder: TSoundLumpFinder): TArray<TSfxRandomMember>; static;
  end;

implementation

uses
  DelphiDoom.Audio.SoundNames;

{ TSfxRandomGroup }

class function TSfxRandomGroup.IsGroupName(const AUpperName: string): Boolean;
begin
  Result := (AUpperName <> '') and (AUpperName[Length(AUpperName)] >= '0') and
    (AUpperName[Length(AUpperName)] <= '9');
end;

class function TSfxRandomGroup.Members(const AUpperName: string;
  const AFinder: TSoundLumpFinder): TArray<TSfxRandomMember>;
var
  LName1: string;
  LName2: string;
  LName3: string;
  LDigit: Char;
  LLump: Integer;
  LCount: Integer;
begin
  // look first for 'ds....' sound names
  if TSoundNames.HasPrefix('DS', AUpperName) then
  begin
    LName1 := AUpperName;
    LName2 := Copy(AUpperName, 3, Length(AUpperName) - 2);
  end
  else
  begin
    LName1 := 'DS' + AUpperName;
    LName2 := AUpperName;
  end;
  LName3 := '';
  if Length(LName1) > 8 then
    SetLength(LName1, 8);
  if Length(LName2) > 8 then
    SetLength(LName2, 8);

  SetLength(Result, 10);
  LCount := 0;
  for LDigit := '0' to '9' do
  begin
    LName1[Length(LName1)] := LDigit;
    LLump := AFinder(LName1);
    if LLump = -1 then
    begin
      LName2[Length(LName2)] := LDigit;
      LLump := AFinder(LName2);
      if LLump >= 0 then
        LName3 := LName2;
    end
    else
      LName3 := LName1;

    if LLump >= 0 then
    begin
      Result[LCount].Name := LName3;
      Result[LCount].LumpNumber := LLump;
      Inc(LCount);
    end;
  end;
  SetLength(Result, LCount);
end;

end.
