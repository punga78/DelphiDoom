{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the bytes of the records                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.BinaryWriter;

interface

uses
  System.SysUtils, DelphiDoom.Udmf.Types;

type
  /// <summary>Numbers as the engine reads them from the lumps: little endian, one after the other</summary>
  TUdmfBinaryWriter = class
  private
    FBytes: TBytes;
    FSize: Integer;
    procedure Grow(AAdd: Integer);
  public
    procedure WriteByte(AValue: Integer);
    /// <summary>The low 16 bits of the value</summary>
    procedure WriteInt16(AValue: Integer);
    procedure WriteInt32(AValue: Integer);
    procedure WriteCardinal(AValue: Cardinal);
    procedure WriteSingle(AValue: Single);
    procedure WriteName8(const AName: TUdmfName8);
    /// <summary>A set of 256 elements: 32 bytes, the element n is the bit n mod 8 of the byte n div 8</summary>
    procedure WriteMoreIds(const AIds: TUdmfMoreIds);
    property Size: Integer read FSize;
    function ToBytes: TBytes;
  end;

implementation

{ TUdmfBinaryWriter }

procedure TUdmfBinaryWriter.Grow(AAdd: Integer);
begin
  if FSize + AAdd > Length(FBytes) then
    SetLength(FBytes, (FSize + AAdd) * 2 + 64);
end;

procedure TUdmfBinaryWriter.WriteByte(AValue: Integer);
begin
  Grow(1);
  FBytes[FSize] := Byte(AValue);
  Inc(FSize);
end;

procedure TUdmfBinaryWriter.WriteInt16(AValue: Integer);
begin
  Grow(2);
  FBytes[FSize] := Byte(AValue);
  FBytes[FSize + 1] := Byte(AValue shr 8);
  Inc(FSize, 2);
end;

procedure TUdmfBinaryWriter.WriteInt32(AValue: Integer);
begin
  WriteCardinal(Cardinal(AValue));
end;

procedure TUdmfBinaryWriter.WriteCardinal(AValue: Cardinal);
begin
  Grow(4);
  FBytes[FSize] := Byte(AValue);
  FBytes[FSize + 1] := Byte(AValue shr 8);
  FBytes[FSize + 2] := Byte(AValue shr 16);
  FBytes[FSize + 3] := Byte(AValue shr 24);
  Inc(FSize, 4);
end;

procedure TUdmfBinaryWriter.WriteSingle(AValue: Single);
begin
  WriteCardinal(PCardinal(@AValue)^);
end;

procedure TUdmfBinaryWriter.WriteName8(const AName: TUdmfName8);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 7 do
    WriteByte(Ord(AName[LIndex]));
end;

procedure TUdmfBinaryWriter.WriteMoreIds(const AIds: TUdmfMoreIds);
var
  LIndex: Integer;
  LBit: Integer;
  LValue: Integer;
begin
  for LIndex := 0 to 31 do
  begin
    LValue := 0;
    for LBit := 0 to 7 do
      if (LIndex * 8 + LBit) in AIds then
        LValue := LValue or (1 shl LBit);
    WriteByte(LValue);
  end;
end;

function TUdmfBinaryWriter.ToBytes: TBytes;
begin
  Result := Copy(FBytes, 0, FSize);
end;

end.