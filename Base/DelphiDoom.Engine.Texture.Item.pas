//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - an external texture as the renderers use it
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit DelphiDoom.Engine.Texture.Item;

interface

uses
  d_delphi,
  DelphiDoom.Texture.Image;

type
  TPalette = array[0..255] of integer;
  PPalette = ^TPalette;

  PTexture = ^TTexture;

  /// <summary>
  ///   An external texture (the old object of t_main): a TTextureImage of Libs\Texture with the
  ///   methods that the renderers call. The files are read by IEngineTextureFiles
  /// </summary>
  TTexture = object
  private
    FImage: TTextureImage;
  public
    constructor Create;
    destructor Destroy;
    procedure Empty;
    /// <summary>Takes the image (the texture owns it from now on); the old one is freed</summary>
    procedure SetImage(const AImage: TTextureImage);
    function GetImage: pointer;
    function GetPalette: PPalette;
    function GetTransformedPalette: PPalette;
    function GetWidth: integer;
    function GetHeight: integer;
    function HasPalette: boolean;
    procedure GetColumn32(col: integer; size: integer; dest: pointer);
    procedure SetColumn32(col: integer; data: PLongWordArray);
    function GetPalettedColumn32(col: integer; size: integer; dest: pointer; APalColor: LongWord): boolean;
    procedure GetRow32(row: integer; size: integer; dest: pointer);
    procedure SetRow32(row: integer; data: PLongWordArray);
    function GetPalettedRow32(row: integer; size: integer; dest: pointer; APalColor: LongWord): boolean;
    procedure ScaleTo(AWidth, AHeight: word);
    procedure SetWidth(Value: word);
    procedure SetHeight(Value: word);
    procedure SetBytesPerPixel(Value: word);
    procedure SwapRGB;
    procedure SetAlphaChannel(Value: byte);
    procedure SetAlphaChannelFromImage(tex: PTexture);
    procedure SetDefaultAlphaChannel;
    procedure RemoveTransparency;
    function ExternalAlphaPresent: boolean;
    procedure SetExternalAlphaPresent(Value: boolean);
    procedure ConvertTo32bit;
    procedure ConvertToGrayScale;
    function GetBytesPerPixel: word;
    procedure SetPalColor(AColor: LongWord);
    procedure Adjust32bitTransparency;
    procedure Mirror;
    function GetLeftOffset: integer;
    procedure SetLeftOffset(const offs: integer);
    function GetTopOffset: integer;
    procedure SetTopOffset(const offs: integer);
    function GetHasOffsets: boolean;
    property LeftOffset: integer read GetLeftOffset write SetLeftOffset;
    property TopOffset: integer read GetTopOffset write SetTopOffset;
    property HasOffsets: boolean read GetHasOffsets;
  end;

implementation

uses
  DelphiDoom.Texture.Alpha;
//==============================================================================
//
// TTexture.Create
//
//==============================================================================
constructor TTexture.Create;
begin
  FImage := TTextureImage.Create;
end;

//==============================================================================
//
// TTexture.Destroy
//
//==============================================================================
destructor TTexture.Destroy;
begin
  FImage.Free;
  FImage := nil;
end;

//==============================================================================
//
// TTexture.Empty
//
//==============================================================================
procedure TTexture.Empty;
begin
  FImage.Clear;
end;

//==============================================================================
//
// TTexture.SetImage
//
//==============================================================================
procedure TTexture.SetImage(const AImage: TTextureImage);
begin
  if AImage <> FImage then
  begin
    FImage.Free;
    FImage := AImage;
  end;
end;

//==============================================================================
//
// TTexture.GetImage
//
//==============================================================================
function TTexture.GetImage: pointer;
begin
  result := FImage.PixelsPointer;
end;

//==============================================================================
//
// TTexture.GetPalette
//
//==============================================================================
function TTexture.GetPalette: PPalette;
begin
  result := PPalette(FImage.PalettePointer);
end;

//==============================================================================
//
// TTexture.GetTransformedPalette
//
//==============================================================================
function TTexture.GetTransformedPalette: PPalette;
begin
  result := PPalette(FImage.TransformedPalettePointer);
end;

//==============================================================================
//
// TTexture.GetWidth
//
//==============================================================================
function TTexture.GetWidth: integer;
begin
  result := FImage.Width;
end;

//==============================================================================
//
// TTexture.GetHeight
//
//==============================================================================
function TTexture.GetHeight: integer;
begin
  result := FImage.Height;
end;

//==============================================================================
//
// TTexture.HasPalette
//
//==============================================================================
function TTexture.HasPalette: boolean;
begin
  result := FImage.HasPalette;
end;

//==============================================================================
//
// TTexture.GetColumn32
//
//==============================================================================
procedure TTexture.GetColumn32(col: integer; size: integer; dest: pointer);
begin
  FImage.GetColumn32(col, size, dest);
end;

//==============================================================================
//
// TTexture.SetColumn32
//
//==============================================================================
procedure TTexture.SetColumn32(col: integer; data: PLongWordArray);
begin
  FImage.SetColumn32(col, PCardinal(data));
end;

//==============================================================================
//
// TTexture.GetPalettedColumn32
//
//==============================================================================
function TTexture.GetPalettedColumn32(col: integer; size: integer; dest: pointer; APalColor: LongWord): boolean;
begin
  result := FImage.GetPalettedColumn32(col, size, dest, APalColor);
end;

//==============================================================================
//
// TTexture.GetRow32
//
//==============================================================================
procedure TTexture.GetRow32(row: integer; size: integer; dest: pointer);
begin
  FImage.GetRow32(row, size, dest);
end;

//==============================================================================
//
// TTexture.SetRow32
//
//==============================================================================
procedure TTexture.SetRow32(row: integer; data: PLongWordArray);
begin
  FImage.SetRow32(row, PCardinal(data));
end;

//==============================================================================
//
// TTexture.GetPalettedRow32
//
//==============================================================================
function TTexture.GetPalettedRow32(row: integer; size: integer; dest: pointer; APalColor: LongWord): boolean;
begin
  result := FImage.GetPalettedRow32(row, size, dest, APalColor);
end;

//==============================================================================
//
// TTexture.ScaleTo
//
//==============================================================================
procedure TTexture.ScaleTo(AWidth, AHeight: word);
begin
  FImage.ScaleTo(AWidth, AHeight);
end;

//==============================================================================
//
// TTexture.SetWidth
//
//==============================================================================
procedure TTexture.SetWidth(Value: word);
begin
  FImage.SetWidth(Value);
end;

//==============================================================================
//
// TTexture.SetHeight
//
//==============================================================================
procedure TTexture.SetHeight(Value: word);
begin
  FImage.SetHeight(Value);
end;

//==============================================================================
//
// TTexture.SetBytesPerPixel
//
//==============================================================================
procedure TTexture.SetBytesPerPixel(Value: word);
begin
  FImage.SetBytesPerPixel(Value);
end;

//==============================================================================
//
// TTexture.SwapRGB
//
//==============================================================================
procedure TTexture.SwapRGB;
begin
  FImage.SwapRGB;
end;

//==============================================================================
//
// TTexture.SetAlphaChannel
//
//==============================================================================
procedure TTexture.SetAlphaChannel(Value: byte);
begin
  TTextureAlpha.SetChannel(FImage, Value);
end;

//==============================================================================
//
// TTexture.SetAlphaChannelFromImage
//
//==============================================================================
procedure TTexture.SetAlphaChannelFromImage(tex: PTexture);
begin
  TTextureAlpha.SetChannelFromImage(FImage, tex.FImage);
end;

//==============================================================================
//
// TTexture.SetDefaultAlphaChannel
//
//==============================================================================
procedure TTexture.SetDefaultAlphaChannel;
begin
  TTextureAlpha.SetDefaultChannel(FImage);
end;

//==============================================================================
//
// TTexture.RemoveTransparency
//
//==============================================================================
procedure TTexture.RemoveTransparency;
begin
  TTextureAlpha.RemoveTransparency(FImage);
end;

//==============================================================================
//
// TTexture.ExternalAlphaPresent
//
//==============================================================================
function TTexture.ExternalAlphaPresent: boolean;
begin
  result := FImage.ExternalAlphaPresent;
end;

//==============================================================================
//
// TTexture.SetExternalAlphaPresent
//
//==============================================================================
procedure TTexture.SetExternalAlphaPresent(Value: boolean);
begin
  FImage.ExternalAlphaPresent := Value;
end;

//==============================================================================
//
// TTexture.ConvertTo32bit
//
//==============================================================================
procedure TTexture.ConvertTo32bit;
begin
  FImage.ConvertTo32bit;
end;

//==============================================================================
//
// TTexture.ConvertToGrayScale
//
//==============================================================================
procedure TTexture.ConvertToGrayScale;
begin
  FImage.ConvertToGrayScale;
end;

//==============================================================================
//
// TTexture.GetBytesPerPixel
//
//==============================================================================
function TTexture.GetBytesPerPixel: word;
begin
  result := FImage.BytesPerPixel;
end;

//==============================================================================
//
// TTexture.SetPalColor
//
//==============================================================================
procedure TTexture.SetPalColor(AColor: LongWord);
begin
  FImage.SetPaletteColor(AColor);
end;

//==============================================================================
// TTexture.Adjust32bitTransparency
//
// JVAL: Adjust custom transparent color
//
//==============================================================================
procedure TTexture.Adjust32bitTransparency;
begin
  TTextureAlpha.AdjustTransparency(FImage);
end;

//==============================================================================
//
// TTexture.Mirror
//
//==============================================================================
procedure TTexture.Mirror;
begin
  FImage.Mirror;
end;

//==============================================================================
//
// TTexture.GetLeftOffset
//
//==============================================================================
function TTexture.GetLeftOffset: integer;
begin
  result := FImage.LeftOffset;
end;

//==============================================================================
//
// TTexture.SetLeftOffset
//
//==============================================================================
procedure TTexture.SetLeftOffset(const offs: integer);
begin
  FImage.LeftOffset := offs;
end;

//==============================================================================
//
// TTexture.GetTopOffset
//
//==============================================================================
function TTexture.GetTopOffset: integer;
begin
  result := FImage.TopOffset;
end;

//==============================================================================
//
// TTexture.SetTopOffset
//
//==============================================================================
procedure TTexture.SetTopOffset(const offs: integer);
begin
  FImage.TopOffset := offs;
end;

//==============================================================================
//
// TTexture.GetHasOffsets
//
//==============================================================================
function TTexture.GetHasOffsets: boolean;
begin
  result := FImage.HasOffsets;
end;

end.
