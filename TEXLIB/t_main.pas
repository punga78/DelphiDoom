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
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

{
  The external textures of the game (hi-resolution textures and sprites in the PAK
  files and the folders). The old classes of Gertjan Schouten (1998) are now the
  classes of Libs\Texture: this unit keeps the API that the renderers use (PTexture,
  T_LoadHiResTexture) and finds the files through the PAK file system.
}

unit t_main;

interface

uses
  d_delphi,
  DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Intf;

type
  TPalette = array[0..255] of integer;
  PPalette = ^TPalette;

  PTexture = ^TTexture;

  TTexture = object
  private
    FImage: TTextureImage;
  public
    constructor Create;
    destructor Destroy;
    procedure Empty;
    /// <summary>Decodes the stream with the decoder of the extension of alias ('.PNG' ...)</summary>
    function LoadFromStream(stream: TDStream; const alias: string): boolean;
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

//==============================================================================
//
// T_ConfigureTextures
//
//==============================================================================
procedure T_ConfigureTextures(const AFormats: ITextureFormats);

//==============================================================================
//
// T_LoadHiResImage
// JVAL
// Load external texture using the PAKFileSystem; the caller owns the image
//
//==============================================================================
function T_LoadHiResImage(const FileName: string; const silent: boolean = False): TTextureImage;

//==============================================================================
//
// T_LoadHiResTexture
//
//==============================================================================
function T_LoadHiResTexture(const FileName: string; const silent: boolean = False): PTexture;

//==============================================================================
//
// T_IsTextureExtension
// True for the extensions of the texture decoders ('.PNG', '.BMP'...)
//
//==============================================================================
function T_IsTextureExtension(const ext: string): boolean;

//==============================================================================
//
// T_Init
//
//==============================================================================
procedure T_Init;

//==============================================================================
//
// T_ShutDown
//
//==============================================================================
procedure T_ShutDown;

var
  preferetexturesnamesingamedirectory: boolean;

implementation

uses
  doomdef,
  i_system,
  DelphiDoom.Texture.Alpha,
  t_draw,
  w_folders,
  w_pak;

var
  textureformats: ITextureFormats = nil;

//==============================================================================
//
// T_ConfigureTextures
//
//==============================================================================
procedure T_ConfigureTextures(const AFormats: ITextureFormats);
begin
  textureformats := AFormats;
end;

//==============================================================================
//
// T_Formats
//
//==============================================================================
function T_Formats: ITextureFormats;
begin
  if textureformats = nil then
    I_Error('T_Formats(): the textures are not configured (ComposeEngine was not called)');
  result := textureformats;
end;

//==============================================================================
//
// T_ReadStream
//
//==============================================================================
function T_ReadStream(const strm: TDStream): TArray<Byte>;
var
  size: integer;
begin
  strm.Seek(0, sFromBeginning);
  size := strm.Size;
  SetLength(result, size);
  if size > 0 then
    strm.Read(result[0], size);
end;

//==============================================================================
// T_LoadHiResImage
//
// JVAL
// Load external texture using the PAKFileSystem
//
//==============================================================================
function T_LoadHiResImage(const FileName: string; const silent: boolean = False): TTextureImage;
var
  i: integer;
  ext: string;
  exts: TArray<string>;
  done: boolean;
  strm: TPakStream;
  tname: string;
  image: TTextureImage;
  formats: ITextureFormats;
begin
  formats := T_Formats;
  exts := formats.Extensions;
  done := false;
  result := nil;
  for i := 0 to Length(exts) - 1 do
  begin
    if done then
      break;
    ext := exts[i];
    if formats.FindDecoder(ext) <> nil then
    begin
      tname := strupper(FileName);
      if Copy(tname, Length(tname) - Length(ext) + 1, Length(ext)) <> ext then
        tname := tname + ext;
      if preferetexturesnamesingamedirectory then
        strm := TPakStream.Create(tname, pm_prefered, gamedirectories)
      else
        strm := TPakStream.Create(tname, pm_short, '', FOLDER_TEXTURES);
      strm.OnBeginBusy := I_BeginDiskBusy;
      if strm.IOResult = 0 then
      begin
        // every decoder starts from an empty image
        image := TTextureImage.Create;
        if formats.Decode(ext, T_ReadStream(strm), image) then
        begin
          if not silent then
            printf('  Found external texture %s'#13#10, [tname]);
          result := image;
          done := true;
        end
        else
          image.Free;
      end;
      strm.Free;
    end;
  end;
end;

//==============================================================================
//
// T_LoadHiResTexture
//
//==============================================================================
function T_LoadHiResTexture(const FileName: string; const silent: boolean = False): PTexture;
var
  image: TTextureImage;
begin
  image := T_LoadHiResImage(FileName, silent);
  if image = nil then
    result := nil
  else
  begin
    result := new(PTexture, Create);
    result.SetImage(image);
  end;
end;

//==============================================================================
//
// T_IsTextureExtension
//
//==============================================================================
function T_IsTextureExtension(const ext: string): boolean;
begin
  result := T_Formats.IsKnownExtension(ext);
end;

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
// TTexture.LoadFromStream
//
//==============================================================================
function TTexture.LoadFromStream(stream: TDStream; const alias: string): boolean;
var
  i: integer;
  image: TTextureImage;
begin
  result := false;
  i := length(alias);
  while (i > 0) and (alias[i] <> '.') do
    dec(i);
  if i = 0 then
    exit;
  image := TTextureImage.Create;
  result := T_Formats.Decode(Copy(alias, i, Length(alias)), T_ReadStream(stream), image);
  SetImage(image);
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

//==============================================================================
//
// T_Init
//
//==============================================================================
procedure T_Init;
begin
  T_InitDrawTextures;
end;

//==============================================================================
//
// T_ShutDown
//
//==============================================================================
procedure T_ShutDown;
begin
  T_ShutDownDrawTextures;
  textureformats := nil;
end;

end.
