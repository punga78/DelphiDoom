{******************************************************************************}
{                                                                              }
{  DelphiDoom: blockmap - reader of the BLOCKMAP lump                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Blockmap.LumpReader;

interface

uses
  System.SysUtils,
  DelphiDoom.Blockmap.Intf,
  DelphiDoom.Blockmap.Types;

type
  /// <summary>
  ///   Reads a BLOCKMAP lump: little endian 16 bit values, the header is signed and the
  ///   offsets and line numbers are unsigned except the -1 that ends each list
  /// </summary>
  TBlockmapLumpReader = class(TInterfacedObject, IBlockmapLumpReader)
  strict private
    class function ReadWord(const ALump: TBytes; const AIndex: Integer): Word; static;
    class function ReadSmallInt(const ALump: TBytes; const AIndex: Integer): SmallInt; static;
  public
    function IsUsable(const ALump: TBytes): Boolean;
    function Read(const ALump: TBytes): TBlockmapData;
  end;

implementation

{ TBlockmapLumpReader }

class function TBlockmapLumpReader.ReadWord(const ALump: TBytes; const AIndex: Integer): Word;
begin
  Result := Word(ALump[AIndex * 2]) or (Word(ALump[AIndex * 2 + 1]) shl 8);
end;

class function TBlockmapLumpReader.ReadSmallInt(const ALump: TBytes;
  const AIndex: Integer): SmallInt;
begin
  Result := SmallInt(ReadWord(ALump, AIndex));
end;

function TBlockmapLumpReader.IsUsable(const ALump: TBytes): Boolean;
var
  LCount: Integer;
begin
  LCount := Length(ALump) div 2; // number of 16 bit values
  Result := (LCount >= BLOCKMAP_HEADER_SIZE) and (LCount < BLOCKMAP_MAX_LUMP_WORDS);
  if Result then
    // the offsets of the blocks must be inside the lump
    Result := (ReadSmallInt(ALump, 2) >= 0) and (ReadSmallInt(ALump, 3) >= 0) and
      (Int64(ReadSmallInt(ALump, 2)) * ReadSmallInt(ALump, 3) <= LCount - BLOCKMAP_HEADER_SIZE);
end;

function TBlockmapLumpReader.Read(const ALump: TBytes): TBlockmapData;
var
  LIndex, LCount: Integer;
  LValue: SmallInt;
begin
  LCount := Length(ALump) div 2;
  SetLength(Result.Lump, LCount);
  for LIndex := 0 to BLOCKMAP_HEADER_SIZE - 1 do
    Result.Lump[LIndex] := ReadSmallInt(ALump, LIndex);
  for LIndex := BLOCKMAP_HEADER_SIZE to LCount - 1 do
  begin
    LValue := ReadSmallInt(ALump, LIndex);
    if LValue = -1 then
      Result.Lump[LIndex] := -1
    else if LValue < 0 then
      Result.Lump[LIndex] := $10000 + LValue
    else
      Result.Lump[LIndex] := LValue;
  end;
  Result.OriginX := Result.Lump[0];
  Result.OriginY := Result.Lump[1];
  Result.Columns := Result.Lump[2];
  Result.Rows := Result.Lump[3];
  Result.NegX := BLOCKMAP_NEG_DISABLED;
  Result.NegY := BLOCKMAP_NEG_DISABLED;
  Result.Built := False;
end;

end.
