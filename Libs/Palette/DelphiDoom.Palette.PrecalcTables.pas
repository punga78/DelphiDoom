{******************************************************************************}
{                                                                              }
{  DelphiDoom: palette library - the precalculated color tables                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Palette.PrecalcTables;

interface

uses
  System.SysUtils, DelphiDoom.Palette.Types, DelphiDoom.Palette.Intf;

type
  /// <summary>The tables of R_InitPrecalc, computed on request, each in one flat array</summary>
  TPrecalcTables = class(TInterfacedObject, IPrecalcTables)
  strict private
    const
      FRAC_BITS = 16;
    class procedure CheckChannel(AChannel, AMaximum: Integer); static;
    class function MultiplyRed(ALight, AColor: Integer): Integer; static;
    class function FogRed(ALight, AColor: Integer): Integer; static;
  public
    function Multiply(AChannel: Integer): TArray<Integer>;
    function Fog(AChannel: Integer): TArray<Integer>;
    function LightIndex(ALight: Integer): Integer;
    function ByteToLong: TArray<Cardinal>;
    function ByteToWord: TArray<Cardinal>;
    function InverseColor: TArray<Cardinal>;
    function Average(AChannel: Integer): TArray<Cardinal>;
    function AddClamp: TBytes;
  end;

implementation

{ TPrecalcTables }

class procedure TPrecalcTables.CheckChannel(AChannel, AMaximum: Integer);
begin
  if (AChannel < 0) or (AChannel > AMaximum) then
    raise EPaletteException.CreateFmt(SChannelInvalid, [AChannel]);
end;

class function TPrecalcTables.MultiplyRed(ALight, AColor: Integer): Integer;
begin
  Result := (ALight * AColor * 256) shr FRAC_BITS;
end;

class function TPrecalcTables.FogRed(ALight, AColor: Integer): Integer;
begin
  Result := 255 - (ALight * (255 - AColor)) shr 8;
  Result := (Result * (256 - ALight) + MultiplyRed(ALight, AColor) * ALight) shr 8;
end;

function TPrecalcTables.Multiply(AChannel: Integer): TArray<Integer>;
var
  LLight: Integer;
  LColor: Integer;
begin
  CheckChannel(AChannel, 2);
  SetLength(Result, 256 * 256);
  for LLight := 0 to 255 do
    for LColor := 0 to 255 do
      case AChannel of
        0: Result[LLight * 256 + LColor] := MultiplyRed(LLight, LColor);
        1: Result[LLight * 256 + LColor] := (MultiplyRed(LLight, LColor) shl 8) and $FF00;
      else
        Result[LLight * 256 + LColor] := (LLight * LColor * 256) and $FF0000;
      end;
end;

function TPrecalcTables.Fog(AChannel: Integer): TArray<Integer>;
var
  LLight: Integer;
  LColor: Integer;
begin
  CheckChannel(AChannel, 2);
  SetLength(Result, 256 * 256);
  for LLight := 0 to 255 do
    for LColor := 0 to 255 do
      Result[LLight * 256 + LColor] := FogRed(LLight, LColor) shl (8 * AChannel);
end;

function TPrecalcTables.LightIndex(ALight: Integer): Integer;
begin
  Result := ALight shr 8;
  if Result > 255 then
    Result := 255;
end;

function TPrecalcTables.ByteToLong: TArray<Cardinal>;
var
  LIndex: Integer;
begin
  SetLength(Result, 256);
  for LIndex := 0 to 255 do
    Result[LIndex] := Cardinal(LIndex) * $01010101;
end;

function TPrecalcTables.ByteToWord: TArray<Cardinal>;
var
  LIndex: Integer;
begin
  SetLength(Result, 256);
  for LIndex := 0 to 255 do
    Result[LIndex] := Cardinal(LIndex) * $0101;
end;

function TPrecalcTables.InverseColor: TArray<Cardinal>;
var
  LIndex: Integer;
  LLevel: Cardinal;
begin
  SetLength(Result, 768);
  for LIndex := 0 to 767 do
  begin
    LLevel := Cardinal(255 - LIndex div 6);
    Result[LIndex] := LLevel + (LLevel shl 8) + (LLevel shl 16);
  end;
end;

function TPrecalcTables.Average(AChannel: Integer): TArray<Cardinal>;
var
  LIndex: Integer;
begin
  CheckChannel(AChannel, 3);
  SetLength(Result, 512);
  for LIndex := 0 to 511 do
    case AChannel of
      0, 1: Result[LIndex] := Cardinal(LIndex div 2);
      2: Result[LIndex] := Cardinal(LIndex div 2) shl 8;
    else
      Result[LIndex] := Cardinal(LIndex div 2) shl 16;
    end;
end;

function TPrecalcTables.AddClamp: TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, 512);
  for LIndex := 0 to 511 do
    if LIndex > 255 then
      Result[LIndex] := 255
    else
      Result[LIndex] := Byte(LIndex);
end;

end.
