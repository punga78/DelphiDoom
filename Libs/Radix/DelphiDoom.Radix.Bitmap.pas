{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixBitmap                                    }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of TRadixBitmap of radix_bitmap.pas (pixels stored by columns)         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Bitmap;

interface

uses
  System.SysUtils;

type
  /// <summary>An 8 bit image whose pixels are stored by columns (x * height + y)</summary>
  TRadixBitmap = class
  strict private
    FWidth: Integer;
    FHeight: Integer;
    FImage: TBytes;
    function Index(AX, AY: Integer): Integer;
    procedure Resize(AWidth, AHeight: Integer);
    procedure SetWidth(AValue: Integer);
    procedure SetHeight(AValue: Integer);
    function GetPixel(AX, AY: Integer): Byte;
    procedure SetPixel(AX, AY: Integer; AValue: Byte);
  public
    procedure ApplyTranslationTable(const ATable: TBytes);
    /// <summary>Takes the size and the pixels of a buffer</summary>
    procedure AttachImage(const ABuffer: TBytes; AWidth, AHeight: Integer);
    procedure Clear(AColor: Byte);
    procedure Crop(ANewWidth, ANewHeight: Integer);
    /// <summary>Removes the last row when it is all 254 (a hole); false when it is not</summary>
    function BottomCrop: Boolean;
    property Width: Integer read FWidth write SetWidth;
    property Height: Integer read FHeight write SetHeight;
    /// <summary>A pixel outside of the image reads 0 and is not written</summary>
    property Pixels[AX, AY: Integer]: Byte read GetPixel write SetPixel; default;
    property Image: TBytes read FImage;
  end;

implementation

{ TRadixBitmap }

function TRadixBitmap.Index(AX, AY: Integer): Integer;
begin
  Result := AX * FHeight + AY;
end;

procedure TRadixBitmap.Resize(AWidth, AHeight: Integer);
begin
  FWidth := AWidth;
  FHeight := AHeight;
  // the new bytes are zero (the old code left what the heap had)
  SetLength(FImage, FWidth * FHeight);
end;

procedure TRadixBitmap.SetWidth(AValue: Integer);
begin
  if AValue <> FWidth then
    Resize(AValue, FHeight);
end;

procedure TRadixBitmap.SetHeight(AValue: Integer);
begin
  if AValue <> FHeight then
    Resize(FWidth, AValue);
end;

function TRadixBitmap.GetPixel(AX, AY: Integer): Byte;
begin
  if (AX < 0) or (AX >= FWidth) or (AY < 0) or (AY >= FHeight) then
    Exit(0);
  Result := FImage[Index(AX, AY)];
end;

procedure TRadixBitmap.SetPixel(AX, AY: Integer; AValue: Byte);
begin
  if (AX < 0) or (AX >= FWidth) or (AY < 0) or (AY >= FHeight) then
    Exit;
  FImage[Index(AX, AY)] := AValue;
end;

procedure TRadixBitmap.ApplyTranslationTable(const ATable: TBytes);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FWidth * FHeight - 1 do
    FImage[LIndex] := ATable[FImage[LIndex]];
end;

procedure TRadixBitmap.AttachImage(const ABuffer: TBytes; AWidth, AHeight: Integer);
begin
  Resize(AWidth, AHeight);
  if FWidth * FHeight > 0 then
    Move(ABuffer[0], FImage[0], FWidth * FHeight);
end;

procedure TRadixBitmap.Clear(AColor: Byte);
begin
  if Length(FImage) > 0 then
    FillChar(FImage[0], Length(FImage), AColor);
end;

procedure TRadixBitmap.Crop(ANewWidth, ANewHeight: Integer);
var
  LOld: TBytes;
  LOldHeight: Integer;
  LColumns: Integer;
  LRows: Integer;
  LX: Integer;
  LY: Integer;
begin
  LOld := Copy(FImage);
  LOldHeight := FHeight;
  LColumns := FWidth;
  Resize(ANewWidth, ANewHeight);
  if ANewWidth < LColumns then
    LColumns := ANewWidth;
  LRows := LOldHeight;
  if ANewHeight < LRows then
    LRows := ANewHeight;
  for LX := 0 to LColumns - 1 do
    for LY := 0 to LRows - 1 do
      FImage[Index(LX, LY)] := LOld[LX * LOldHeight + LY];
end;

function TRadixBitmap.BottomCrop: Boolean;
var
  LX: Integer;
begin
  if FHeight < 2 then
    Exit(False);
  for LX := 0 to FWidth - 1 do
    if FImage[Index(LX, FHeight - 1)] <> 254 then
      Exit(False);
  Crop(FWidth, FHeight - 1);
  Result := True;
end;

end.
