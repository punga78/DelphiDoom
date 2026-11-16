{******************************************************************************}
{                                                                              }
{  DelphiDoom: definitions library - the reader of the SWITCHES lump           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Definitions.SwitchLumpReader;

interface

uses
  System.SysUtils, DelphiDoom.Definitions.Types, DelphiDoom.Definitions.Intf;

type
  /// <summary>
  ///   The lump SWITCHES of BOOM: entries of two names of 9 bytes (zero ended) and the
  ///   episode in a little endian smallint, 20 bytes each; the Strife version adds a
  ///   little endian integer with the sound (24 bytes). A last part shorter than an entry
  ///   is dropped, as the old integer division did
  /// </summary>
  TSwitchLumpReader = class(TInterfacedObject, IDefSwitchLumpReader)
  private
    FHasSound: Boolean;
    function NameAt(const ABytes: TBytes; AOffset: Integer): string;
  public
    /// <param name="AHasSound">True for the lump of Strife</param>
    constructor Create(AHasSound: Boolean);
    function Read(const ABytes: TBytes): TArray<TDefSwitchPair>;
  end;

implementation

const
  NAME_FIELD_SIZE = 9;

{ TSwitchLumpReader }

constructor TSwitchLumpReader.Create(AHasSound: Boolean);
begin
  inherited Create;
  FHasSound := AHasSound;
end;

function ReadUnsigned(const ABytes: TBytes; AOffset, ASize: Integer): Cardinal;
var
  LIndex: Integer;
begin
  // little endian
  Result := 0;
  for LIndex := ASize - 1 downto 0 do
    Result := (Result shl 8) or Cardinal(ABytes[AOffset + LIndex]);
end;

function TSwitchLumpReader.NameAt(const ABytes: TBytes; AOffset: Integer): string;
var
  LIndex: Integer;
  LName: AnsiString;
begin
  // the name ends at the first zero and has at most 8 characters; the bytes are 8 bit
  // characters, converted as the old assignment of the character array to a string did
  LName := '';
  for LIndex := 0 to DEFINITIONS_NAME_LENGTH - 1 do
  begin
    if ABytes[AOffset + LIndex] = 0 then
      Break;
    LName := LName + AnsiChar(ABytes[AOffset + LIndex]);
  end;
  Result := string(LName);
end;

function TSwitchLumpReader.Read(const ABytes: TBytes): TArray<TDefSwitchPair>;
var
  LEntrySize: Integer;
  LCount: Integer;
  LIndex: Integer;
  LBase: Integer;
begin
  LEntrySize := 2 * NAME_FIELD_SIZE + SizeOf(SmallInt);
  if FHasSound then
    Inc(LEntrySize, SizeOf(Integer));
  LCount := Length(ABytes) div LEntrySize;
  SetLength(Result, LCount);
  for LIndex := 0 to LCount - 1 do
  begin
    LBase := LIndex * LEntrySize;
    Result[LIndex].Name1 := NameAt(ABytes, LBase);
    Result[LIndex].Name2 := NameAt(ABytes, LBase + NAME_FIELD_SIZE);
    Result[LIndex].Episode := SmallInt(Word(ReadUnsigned(ABytes, LBase + 2 * NAME_FIELD_SIZE, 2)));
    Result[LIndex].Sound := 0;
    if FHasSound then
      Result[LIndex].Sound := Integer(ReadUnsigned(ABytes, LBase + 2 * NAME_FIELD_SIZE + 2, 4));
    Result[LIndex].SoundName := '';
  end;
end;

end.
