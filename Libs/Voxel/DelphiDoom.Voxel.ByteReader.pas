{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel library - the cursor over the bytes of a file             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Voxel.ByteReader;

interface

uses
  System.SysUtils,
  DelphiDoom.Voxel.Types;

type
  /// <summary>
  ///   Reads numbers of the voxel files (little endian) from the bytes: a read beyond the end is
  ///   an EVoxelException, never a read of memory that is not there
  /// </summary>
  TVoxelByteReader = class
  strict private
    FBytes: TBytes;
    FPosition: Integer;
    procedure Need(const ACount: Integer);
  public
    constructor Create(const ABytes: TBytes);
    function ReadByte: Byte;
    function ReadWord: Word;
    function ReadInteger: Integer;
    function ReadCardinal: Cardinal;
    procedure Seek(const APosition: Integer);
    property Position: Integer read FPosition;
    function Remaining: Integer;
  end;

implementation

{ TVoxelByteReader }

constructor TVoxelByteReader.Create(const ABytes: TBytes);
begin
  inherited Create;
  FBytes := ABytes;
  FPosition := 0;
end;

procedure TVoxelByteReader.Need(const ACount: Integer);
begin
  if (ACount < 0) or (FPosition < 0) or (FPosition + ACount > Length(FBytes)) then
    raise EVoxelException.CreateFmt(SVoxelTruncated, [Length(FBytes), ACount, FPosition]);
end;

function TVoxelByteReader.ReadByte: Byte;
begin
  Need(1);
  Result := FBytes[FPosition];
  Inc(FPosition);
end;

function TVoxelByteReader.ReadWord: Word;
begin
  Need(2);
  Result := FBytes[FPosition] or (FBytes[FPosition + 1] shl 8);
  Inc(FPosition, 2);
end;

function TVoxelByteReader.ReadCardinal: Cardinal;
begin
  Need(4);
  Result := Cardinal(FBytes[FPosition]) or (Cardinal(FBytes[FPosition + 1]) shl 8) or
    (Cardinal(FBytes[FPosition + 2]) shl 16) or (Cardinal(FBytes[FPosition + 3]) shl 24);
  Inc(FPosition, 4);
end;

function TVoxelByteReader.ReadInteger: Integer;
begin
  Result := Integer(ReadCardinal);
end;

procedure TVoxelByteReader.Seek(const APosition: Integer);
begin
  FPosition := APosition;
end;

function TVoxelByteReader.Remaining: Integer;
begin
  Result := Length(FBytes) - FPosition;
end;

end.
