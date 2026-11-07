{******************************************************************************}
{                                                                              }
{  DelphiDoom: serializer library - a stream on memory that is not its own     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Serializer.MemoryStream;

interface

uses
  System.Classes;

type
  /// <summary>
  ///   A stream on a block of memory of the caller (the save buffer of the engine): it neither
  ///   allocates nor frees it, and does not grow. A write past the end writes what fits and
  ///   gives the smaller count, so WriteBuffer raises an error
  /// </summary>
  TSerializerMemoryStream = class(TCustomMemoryStream)
  public
    constructor Create(const AMemory: Pointer; ASize: Integer);
    function Write(const Buffer; Count: Longint): Longint; override;
  end;

implementation

{ TSerializerMemoryStream }

constructor TSerializerMemoryStream.Create(const AMemory: Pointer; ASize: Integer);
begin
  inherited Create;
  SetPointer(AMemory, ASize);
end;

function TSerializerMemoryStream.Write(const Buffer; Count: Longint): Longint;
var
  LPosition: Int64;
begin
  LPosition := Position;
  Result := Count;
  if LPosition + Result > Size then
    Result := Size - LPosition;
  if Result <= 0 then
    Exit(0);
  Move(Buffer, (PByte(Memory) + LPosition)^, Result);
  Seek(Result, soCurrent);
end;

end.
