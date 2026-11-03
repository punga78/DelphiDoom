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
//  JPEG image format.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit t_jpeg;

interface

uses
  d_delphi,
  t_main,
  t_bmp;

type
  TJPGTextureManager = object(TBMPTextureManager)
  private
    bmpstream: TDStream;
  public
    constructor Create(const ext: string);
    destructor Destroy; virtual;
    function LoadHeader(stream: TDStream): boolean; virtual;
    function LoadImage(stream: TDStream): boolean; virtual;
  end;

implementation

uses
  i_system,
  DelphiDoom.Jpeg.Intf,
  DelphiDoom.Jpeg.Client,
  DelphiDoom.Jpeg.Provider,
  DelphiDoom.Texture.JpegBitmap;

{ ------------------------------------------------------------------------ }
{   load JPEG stream and save as BITMAP stream                             }
{ ------------------------------------------------------------------------ }

//==============================================================================
//
// LoadJPEG
//
//==============================================================================
procedure LoadJPEG(const infile, outfile: TDStream);
var
  size: integer;
  buffer: pointer;
  image: TJpegImage;
  bitmap: TArray<Byte>;
begin
  size := infile.Size - infile.Position;
  buffer := malloc(size);
  try
    infile.Read(buffer^, size);
    try
      image := TJpegProvider.Client.Decode(buffer, size);
      bitmap := TJpegBitmapBuilder.Build(image);
    except
      on E: EJpegException do
        I_Error('TJPGTextureManager(): %s', [E.Message]);
    end;
    outfile.Write(bitmap[0], Length(bitmap));
  finally
    memfree(buffer, size);
  end;
end;

//==============================================================================
//
// TJPGTextureManager.Create
//
//==============================================================================
constructor TJPGTextureManager.Create(const ext: string);
begin
  TTextureManager.Create;
  bmpstream := TDMemoryStream.Create;
  SetFileExt(ext);
end;

//==============================================================================
//
// TJPGTextureManager.Destroy
//
//==============================================================================
destructor TJPGTextureManager.Destroy;
begin
  bmpstream.Free;
  Inherited Destroy;
end;

//==============================================================================
//
// TJPGTextureManager.LoadHeader
//
//==============================================================================
function TJPGTextureManager.LoadHeader(stream: TDStream): boolean;
begin
  bmpstream.Seek(0, sFromBeginning);
  LoadJPEG(stream, bmpstream);
  bmpstream.Seek(0, sFromBeginning);
  LoadHeader := Inherited LoadHeader(bmpstream);
end;

//==============================================================================
//
// TJPGTextureManager.LoadImage
//
//==============================================================================
function TJPGTextureManager.LoadImage(stream: TDStream): boolean;
begin
  result := Inherited LoadImage(bmpstream);
  if result then
    FBitmap.Mirror;
end;

end.

