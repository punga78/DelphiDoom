//------------------------------------------------------------------------------
//
//  DelphiDoom is a source port of the game Doom and it is
//  based on original Linux Doom as published by "id Software"
//  Copyright (C) 1993-1996 by id Software, Inc.
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, inc., 59 Temple Place - Suite 330, Boston, MA
//  02111-1307, USA.
//
// DESCRIPTION:
//  PNG image format.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit t_png;

interface

uses
  d_delphi,
  t_main,
  DelphiDoom.Png.Intf;

var
  // Colors (in the byte order of a Windows COLORREF) that the PNG textures
  // treat as transparent, besides the one of the tRNS chunk
  pngtransparentcolor: integer = $FF00FF;
  pngtransparentcolor2: integer = $FFFF;
  // Also treat as transparent the colors made only of 00 and FF bytes
  // with at least two FF (magenta, cyan, yellow, white...)
  assumecommontranspantcolors: boolean = True;

type
  TPNGBaseTextureManager = object(TTextureManager)
  private
    // The image decoded by LoadHeader and used by LoadImage
    FInfo: TPngInfo;
    FPixels: TArray<Byte>;
    FPalette: TArray<Byte>;
    FIndexed: boolean;
  protected
    function RGBSwap(buffer: LongWord): LongWord;
    function PixelAt(const x, y: integer): LongWord;
    function PaletteColorAt(const index: integer): LongWord;
    function PaletteAlphaAt(const index: integer): byte;
    function TransparentColorOfFile: LongWord;
  public
    constructor Create(ext: string);
    function Decode(stream: TDStream): boolean;
    destructor Destroy; virtual;
  end;

  TPNGTextureManager = object(TPNGBaseTextureManager)
  public
    constructor Create;
    function LoadHeader(stream: TDStream): boolean; virtual;
    function LoadImage(stream: TDStream): boolean; virtual;
  end;

  TPNGSpriteTextureManager = object(TPNGBaseTextureManager)
  private
    ftransparentcolor: Cardinal;
  public
    constructor Create;
    function LoadHeader(stream: TDStream): boolean; virtual;
    function LoadImage(stream: TDStream): boolean; virtual;
  end;

const
  PNGEXT = '.PNG';
  PNGSPRITEEXT = '.PNGSPRITE';

implementation

uses
  i_system,
  DelphiDoom.Png.Client,
  DelphiDoom.Png.Provider;

//==============================================================================
//
// T_IsCommonTransparentColor
//
//==============================================================================
function T_IsCommonTransparentColor(c: LongWord): Boolean;
var
  ca: array[0..2] of byte;
  x00, xFF: integer;
  i: integer;
begin
  for i := 0 to 2 do
  begin
    ca[i] := c;
    c := c shr 8;
  end;

  x00 := 0;
  xFF := 0;

  for i := 0 to 2 do
  begin
    if ca[i] = 0 then
      inc(x00)
    else if ca[i] = $FF then
      inc(xFF)
  end;
  Result := ((x00 + xFF) = 3) and (xFF > 1);
end;

////////////////////////////////////////////////////////////////////////////////
// TPNGBaseTextureManager
////////////////////////////////////////////////////////////////////////////////

//==============================================================================
//
// TPNGBaseTextureManager.Create
//
//==============================================================================
constructor TPNGBaseTextureManager.Create(ext: string);
begin
  inherited Create;
  SetFileExt(ext);
  FPixels := nil;
  FPalette := nil;
  FIndexed := False;
end;

//==============================================================================
//
// TPNGBaseTextureManager.RGBSwap
//
//==============================================================================
function TPNGBaseTextureManager.RGBSwap(buffer: LongWord): LongWord;
var
  r, g, b: LongWord;
begin
  Result := buffer;
  b := Result and $FF;
  Result := Result shr 8;
  g := Result and $FF;
  Result := Result shr 8;
  r := Result and $FF;
  Result := r + g shl 8 + b shl 16;
end;

//==============================================================================
//
// TPNGBaseTextureManager.PixelAt
//
// A decoded pixel as $00RRGGBB (memory order B, G, R)
//
//==============================================================================
function TPNGBaseTextureManager.PixelAt(const x, y: integer): LongWord;
begin
  Result := PLongWordArray(FPixels)[y * FInfo.Width + x] and $FFFFFF;
end;

//==============================================================================
//
// TPNGBaseTextureManager.PaletteColorAt
//
//==============================================================================
function TPNGBaseTextureManager.PaletteColorAt(const index: integer): LongWord;
begin
  Result := PLongWordArray(FPalette)[index] and $FFFFFF;
end;

//==============================================================================
//
// TPNGBaseTextureManager.PaletteAlphaAt
//
//==============================================================================
function TPNGBaseTextureManager.PaletteAlphaAt(const index: integer): byte;
begin
  Result := FPalette[index * 4 + 3];
end;

//==============================================================================
//
// TPNGBaseTextureManager.TransparentColorOfFile
//
// The color of the tRNS chunk as $00RRGGBB, 0 if there is none
//
//==============================================================================
function TPNGBaseTextureManager.TransparentColorOfFile: LongWord;
begin
  if FInfo.HasTransparentColor <> 0 then
    Result := FInfo.TransparentColor and $FFFFFF
  else
    Result := 0;
end;

//==============================================================================
//
// TPNGBaseTextureManager.Decode
//
// Reads the whole stream and decodes it: palette images are kept as indices
//
//==============================================================================
function TPNGBaseTextureManager.Decode(stream: TDStream): boolean;
var
  size: integer;
  buffer: pointer;
  image: TPngImage;
  indexed: TPngIndexedImage;
begin
  Result := False;
  FPixels := nil;
  FPalette := nil;
  FIndexed := False;

  size := stream.Size - stream.Position;
  buffer := malloc(size);
  try
    stream.Read(buffer^, size);
    try
      FInfo := TPngProvider.Client.GetInfo(buffer, size);
      if FInfo.ColorType = DDPNG_COLOR_PALETTE then
      begin
        indexed := TPngProvider.Client.DecodeIndexed(buffer, size);
        FInfo := indexed.Info;
        FPixels := indexed.Pixels;
        FPalette := indexed.Palette;
        FIndexed := True;
      end
      else
      begin
        image := TPngProvider.Client.Decode(buffer, size);
        FInfo := image.Info;
        FPixels := image.Pixels;
      end;
      Result := True;
    except
      on E: EPngException do
        I_Warning('TPNGTextureManager(): ' + E.Message + #13#10);
    end;
  finally
    memfree(buffer, size);
  end;
end;

//==============================================================================
//
// TPNGBaseTextureManager.Destroy
//
//==============================================================================
destructor TPNGBaseTextureManager.Destroy;
begin
  FPixels := nil;
  FPalette := nil;
  inherited;
end;

////////////////////////////////////////////////////////////////////////////////
// TPNGTextureManager
////////////////////////////////////////////////////////////////////////////////

//==============================================================================
//
// TPNGTextureManager.Create
//
//==============================================================================
constructor TPNGTextureManager.Create;
begin
  inherited Create(PNGEXT);
end;

//==============================================================================
//
// TPNGTextureManager.LoadHeader
//
//==============================================================================
function TPNGTextureManager.LoadHeader(stream: TDStream): boolean;
begin
  Result := Decode(stream);
  if not Result then
    Exit;

  FBitmap.SetTransparentColor(TransparentColorOfFile);
  FBitmap.SetTransparentColor2(RGBSwap(pngtransparentcolor));
  FBitmap.SetTransparentColor3(RGBSwap(pngtransparentcolor2));
  FBitmap.ScaleTo(FInfo.Width, FInfo.Height);
  // JVAL: Support for offsets
  FBitmap.LeftOffset := FInfo.OffsetX;
  FBitmap.TopOffset := FInfo.OffsetY;
end;

//==============================================================================
//
// TPNGTextureManager.LoadImage
//
//==============================================================================
function TPNGTextureManager.LoadImage(stream: TDStream): boolean;
var
  x, y: integer;
  buffer: LongWord;
  trcolor: LongWord;
  trcolor2: LongWord;
  trcolor3: LongWord;
  row: pointer;
  i: integer;
  pal: TPalette;
begin
  Result := FPixels <> nil;
  if not Result then
    Exit;

  trcolor := FBitmap.GetTransparentColor;
  trcolor2 := FBitmap.GetTransparentColor2;
  trcolor3 := FBitmap.GetTransparentColor3;
  if FIndexed then
  begin
    FBitmap^.SetBytesPerPixel(1);
    for i := 0 to 255 do
    begin
      buffer := PaletteColorAt(i);
      if (buffer = trcolor) or (buffer = trcolor2) or (buffer = trcolor3) or (assumecommontranspantcolors and T_IsCommonTransparentColor(buffer)) then
        pal[i] := 0
      else
        pal[i] := buffer;
    end;
    FBitmap.SetPalette(@pal, 256, 0, 0);
    row := FBitmap.GetImage;
    for i := 0 to FInfo.Height - 1 do
    begin
      memcpy(row, @FPixels[i * FInfo.Width], FInfo.Width);
      row := pointer(integer(row) + FInfo.Width);
    end;
  end
  else
  begin
    FBitmap^.SetBytesPerPixel(4);
    for x := 0 to FInfo.Width - 1 do
      for y := 0 to FInfo.Height - 1 do
      begin
        buffer := PixelAt(x, y);
        if (buffer = trcolor) or (buffer = trcolor2) or (buffer = trcolor3) or (assumecommontranspantcolors and T_IsCommonTransparentColor(buffer)) then
          buffer := 0;
        FBitmap^.PutPixels(x, y, 1, @buffer, 32);
      end;
    FBitmap.SetTransparentColor(0);
    FBitmap.SetTransparentColor2(0);
    FBitmap.SetTransparentColor3(0);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// TPNGSpriteTextureManager
////////////////////////////////////////////////////////////////////////////////

//==============================================================================
//
// TPNGSpriteTextureManager.Create
//
//==============================================================================
constructor TPNGSpriteTextureManager.Create;
begin
  ftransparentcolor := 0;
  inherited Create(PNGSPRITEEXT);
end;

//==============================================================================
//
// TPNGSpriteTextureManager.LoadHeader
//
//==============================================================================
function TPNGSpriteTextureManager.LoadHeader(stream: TDStream): boolean;
begin
  Result := Decode(stream);
  if not Result then
    Exit;

  ftransparentcolor := TransparentColorOfFile;
  FBitmap.SetTransparentColor(0);
  FBitmap.SetTransparentColor2(0);
  FBitmap.SetTransparentColor3(0);
  FBitmap.ScaleTo(FInfo.Width, FInfo.Height);
  // JVAL: Support for offsets
  FBitmap.LeftOffset := FInfo.OffsetX;
  FBitmap.TopOffset := FInfo.OffsetY;
end;

//==============================================================================
//
// TPNGSpriteTextureManager.LoadImage
//
//==============================================================================
function TPNGSpriteTextureManager.LoadImage(stream: TDStream): boolean;
var
  x, y: integer;
  buffer: LongWord;
  row: pointer;
  pl: PLongWordArray;
  i: integer;
  pal: TPalette;
  nearblack: Cardinal;
  hasalphachannel: boolean;
begin
  Result := FPixels <> nil;
  if not Result then
    Exit;

  if ftransparentcolor = $010100 then
    nearblack := $000100
  else
    nearblack := $010100;

  if FIndexed then
  begin
    // JVAL: tRNS palette resolve in 8 bit color images
    if FInfo.HasAlpha <> 0 then
    begin
      for i := 0 to 255 do
      begin
        buffer := PaletteColorAt(i);
        if PaletteAlphaAt(i) = 0 then
          pal[i] := 0
        else if (buffer = ftransparentcolor) or (buffer = 0) then
          pal[i] := 0
        else
          pal[i] := buffer;
      end;

      FBitmap^.SetBytesPerPixel(4);
      pl := FBitmap.GetImage;
      for y := 0 to FInfo.Height - 1 do
      begin
        for i := 0 to FInfo.Width - 1 do
        begin
          if PaletteAlphaAt(FPixels[y * FInfo.Width + i]) = 0 then
            pl[i] := 0
          else
          begin
            pl[i] := pal[FPixels[y * FInfo.Width + i]];
            if (pl[i] = ftransparentcolor) or (pl[i] and $FFFFFF = 0) then
              pl[i] := nearblack;
          end;
        end;
        pl := @pl[FInfo.Width];
      end;
    end
    else
    begin
      FBitmap^.SetBytesPerPixel(1);
      for i := 0 to 255 do
      begin
        buffer := PaletteColorAt(i);
        if buffer = ftransparentcolor then
          pal[i] := 0
        else if buffer = 0 then
          pal[i] := nearblack
        else
          pal[i] := buffer;
      end;
      FBitmap.SetPalette(@pal, 256, 0, 0);
      row := FBitmap.GetImage;
      for i := 0 to FInfo.Height - 1 do
      begin
        memcpy(row, @FPixels[i * FInfo.Width], FInfo.Width);
        row := pointer(integer(row) + FInfo.Width);
      end;
    end;
  end
  else
  begin
    FBitmap^.SetBytesPerPixel(4);
    // Only the images with an alpha channel carry a per pixel alpha: the
    // others (also the ones with a tRNS color) are tested against the color
    hasalphachannel := (FInfo.ColorType = DDPNG_COLOR_RGBA) or
                       (FInfo.ColorType = DDPNG_COLOR_GRAY_ALPHA);
    for y := 0 to FInfo.Height - 1 do
    begin
      if hasalphachannel then
      begin
        for x := 0 to FInfo.Width - 1 do
        begin
          if (PLongWordArray(FPixels)[y * FInfo.Width + x] shr 24) = 0 then
            buffer := 0
          else
          begin
            buffer := PixelAt(x, y);
            if (buffer = ftransparentcolor) or (buffer and $FFFFFF = 0) then
              buffer := nearblack;
          end;
          FBitmap^.PutPixels(x, y, 1, @buffer, 32);
        end;
      end
      else
      begin
        for x := 0 to FInfo.Width - 1 do
        begin
          buffer := PixelAt(x, y);
          if buffer <> ftransparentcolor then
            if buffer and $FFFFFF = 0 then
              buffer := nearblack;
          FBitmap^.PutPixels(x, y, 1, @buffer, 32);
        end;
      end;
    end;
  end;
end;

end.
