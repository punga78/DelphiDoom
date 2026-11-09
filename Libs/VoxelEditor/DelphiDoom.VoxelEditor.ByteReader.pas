{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel editor - a reader of the bytes of a file                   }
{  Copyright (C) 2013-2025 by Jim Valavanis (original DD_VOXEL)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.VoxelEditor.ByteReader;

interface

uses
  System.SysUtils;

type
  /// <summary>
  ///   Reads little endian numbers from the bytes of a file. A read beyond the end is an EVoxelEditorException: the
  ///   old loaders read what the stream gave, and a short file left the rest of their variables as they were
  /// </summary>
  TVoxelEditorByteReader = class
  strict private
    FBytes: TBytes;
    FPosition: Integer;
    procedure Need(ACount: Integer);
  public
    constructor Create(const ABytes: TBytes);
    function ReadByte: Byte;
    function ReadWord: Word;
    function ReadInteger: Integer;
    function ReadCardinal: Cardinal;
    procedure Seek(APosition: Integer);
    function Remaining: Integer;
    property Position: Integer read FPosition;
    property Bytes: TBytes read FBytes;
  end;

implementation

uses
  DelphiDoom.VoxelEditor.Types;

resourcestring
  SByteReaderShort = 'the file ends too soon';

{ TVoxelEditorByteReader }

constructor TVoxelEditorByteReader.Create(const ABytes: TBytes);
begin
  inherited Create;
  FBytes := ABytes;
end;

procedure TVoxelEditorByteReader.Need(ACount: Integer);
begin
  if (ACount < 0) or (FPosition < 0) or (FPosition + ACount > Length(FBytes)) then
    raise EVoxelEditorException.CreateFmt(SVoxelEditorBadFile, [SByteReaderShort]);
end;

function TVoxelEditorByteReader.ReadByte: Byte;
begin
  Need(1);
  Result := FBytes[FPosition];
  Inc(FPosition);
end;

function TVoxelEditorByteReader.ReadWord: Word;
begin
  Need(2);
  Result := PWord(@FBytes[FPosition])^;
  Inc(FPosition, 2);
end;

function TVoxelEditorByteReader.ReadInteger: Integer;
begin
  Need(4);
  Result := PInteger(@FBytes[FPosition])^;
  Inc(FPosition, 4);
end;

function TVoxelEditorByteReader.ReadCardinal: Cardinal;
begin
  Need(4);
  Result := PCardinal(@FBytes[FPosition])^;
  Inc(FPosition, 4);
end;

procedure TVoxelEditorByteReader.Seek(APosition: Integer);
begin
  FPosition := APosition;
end;

function TVoxelEditorByteReader.Remaining: Integer;
begin
  Result := Length(FBytes) - FPosition;
end;

end.
