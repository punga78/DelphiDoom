{******************************************************************************}
{                                                                              }
{  DelphiDoom: speed library - TSpeedIs2Decoder                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Copyright (C) 1995 by Noriaworks (Speed Haste)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of TSpeedBitmap.AttachIS2 (speed_bitmap.pas)                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.Is2Decoder;

interface

uses
  System.SysUtils,
  DelphiDoom.Speed.Types, DelphiDoom.Speed.Intf;

type
  /// <summary>
  ///   Reads an .IS2 picture: a header of 24 bytes and then, for every column (or every row when
  ///   the flag says so), the first position and runs of pixels with the gaps between them. The
  ///   pixels that no run covers are 255, the hole of the patches
  /// </summary>
  TSpeedIs2Decoder = class(TInterfacedObject, ISpeedBitmapDecoder)
  public
    function DecodeIs2(const AData: TBytes; out ABitmap: TSpeedBitmap): Boolean;
  end;

implementation

const
  /// <summary>A picture bigger than this is not a picture of the game</summary>
  MAX_SIDE = 8192;

{ TSpeedIs2Decoder }

function TSpeedIs2Decoder.DecodeIs2(const AData: TBytes; out ABitmap: TSpeedBitmap): Boolean;
var
  LHeader: TSpeedIs2Header;
  LHorizontal: Boolean;
  LLines: Integer;
  LLineStarts: TArray<Integer>;
  LPosition: Integer;
  LLine: Integer;
  LX: Integer;
  LY: Integer;
  LRuns: Integer;
  LRun: Integer;
  LPixel: Byte;

  // the data that follow the header; what lies after the end of the buffer reads as 0
  function RawAt(AIndex: Integer): Byte;
  begin
    if (AIndex >= 0) and (SizeOf(TSpeedIs2Header) + AIndex < Length(AData)) then
      Result := AData[SizeOf(TSpeedIs2Header) + AIndex]
    else
      Result := 0;
  end;

  function ReadByte: Byte;
  begin
    if LPosition >= LHeader.Length then
      Result := 0
    else
    begin
      Result := RawAt(LPosition);
      Inc(LPosition);
    end;
  end;

  procedure SetPixel(AColumn, ARow: Integer; AValue: Byte);
  begin
    if (AColumn >= 0) and (AColumn < ABitmap.Width) and (ARow >= 0) and (ARow < ABitmap.Height) then
      ABitmap.Pixels[AColumn * ABitmap.Height + ARow] := AValue;
  end;

begin
  ABitmap.Width := 0;
  ABitmap.Height := 0;
  ABitmap.Pixels := nil;
  Result := False;
  if Length(AData) < SizeOf(TSpeedIs2Header) then
    Exit;
  Move(AData[0], LHeader, SizeOf(TSpeedIs2Header));
  if (LHeader.Sign <> SPEED_IS2_MAGIC) or (LHeader.Width > MAX_SIDE) or (LHeader.Height > MAX_SIDE) then
    Exit;

  ABitmap.Width := LHeader.Width;
  ABitmap.Height := LHeader.Height;
  SetLength(ABitmap.Pixels, ABitmap.Width * ABitmap.Height);
  if Length(ABitmap.Pixels) > 0 then
    FillChar(ABitmap.Pixels[0], Length(ABitmap.Pixels), 255);

  LHorizontal := (LHeader.Flags and SPEED_IS2_HORIZONTAL) <> 0;
  if LHorizontal then
    LLines := LHeader.Height
  else
    LLines := LHeader.Width;

  // where every line (a column, or a row) starts
  SetLength(LLineStarts, LLines + 1);
  for LLine := 0 to LLines do
    LLineStarts[LLine] := LHeader.Length;
  LPosition := 0;
  LLine := 0;
  while LLine < LLines do
  begin
    LLineStarts[LLine] := LPosition;
    Inc(LPosition);
    while RawAt(LPosition) <> 0 do
    begin
      LPosition := LPosition + RawAt(LPosition) + 1;
      if LPosition >= LHeader.Length then
        Break;
      if RawAt(LPosition) = 0 then
        Break;
      Inc(LPosition);
    end;
    Inc(LLine);
    Inc(LPosition);
  end;

  for LLine := 0 to LLines - 1 do
  begin
    LPosition := LLineStarts[LLine];
    LX := ReadByte;
    LY := LLine;
    while True do
    begin
      LRuns := ReadByte;
      for LRun := 0 to LRuns - 1 do
      begin
        LPixel := ReadByte;
        if LHorizontal then
          SetPixel(LX, LY, LPixel)
        else
          SetPixel(LY, LX, LPixel);
        // the original forgot the begin and end around the if: the step is for every pixel
        Inc(LX);
      end;
      if RawAt(LPosition) = 0 then
      begin
        Inc(LPosition);
        Break;
      end;
      if LPosition >= LLineStarts[LLine + 1] then
        Break;
      LX := LX + ReadByte;
      if LPosition >= LHeader.Length then
        Break;
    end;
  end;
  Result := True;
end;

end.
