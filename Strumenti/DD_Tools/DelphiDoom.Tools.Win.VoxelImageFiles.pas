{******************************************************************************}
{                                                                              }
{  DD_Tools: the picture files of the voxel editor                              }
{  Copyright (C) 2013-2025 by Jim Valavanis (original DD_VOXEL)                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tools.Win.VoxelImageFiles;

interface

uses
  System.SysUtils,
  DelphiDoom.VoxelEditor.Types,
  DelphiDoom.VoxelEditor.Intf;

type
  /// <summary>
  ///   IVoxelEditorImageLoader on the picture classes of the VCL (BMP, JPEG, PNG, GIF, ICO, WMF...): the picture of a
  ///   file becomes the cells of a plane, a heightmap or a texture, stretched to the size of the voxel
  /// </summary>
  TVclVoxelImageLoader = class(TInterfacedObject, IVoxelEditorImageLoader)
  public
    function TryGetDimensions(const AFileName: string; out AWidth, AHeight: Integer): Boolean;
    function TryLoad(const AFileName: string; ASize: Integer; out AImage: TVoxelEditorImage): Boolean;
  end;

  /// <summary>IVoxelEditorImageExporter: PNG, JPEG or BMP by the extension of the name (BMP for any other)</summary>
  TVclVoxelImageExporter = class(TInterfacedObject, IVoxelEditorImageExporter)
  public
    function Export(const AFileName: string; const AImage: TVoxelEditorImage; ASize: Integer): Boolean;
  end;

implementation

uses
  System.Classes,
  Vcl.Graphics, Vcl.Imaging.pngimage, Vcl.Imaging.jpeg, Vcl.Imaging.GIFImg,
  DelphiDoom.Tools.Win.VoxelBitmaps;

{ TVclVoxelImageLoader }

function TVclVoxelImageLoader.TryGetDimensions(const AFileName: string; out AWidth, AHeight: Integer): Boolean;
var
  LPicture: TPicture;
begin
  AWidth := 0;
  AHeight := 0;
  LPicture := TPicture.Create;
  try
    try
      LPicture.LoadFromFile(AFileName);
      AWidth := LPicture.Width;
      AHeight := LPicture.Height;
      Result := (AWidth > 0) and (AHeight > 0);
    except
      on EInvalidGraphic do
        Result := False;
      on EFOpenError do
        Result := False;
    end;
  finally
    LPicture.Free;
  end;
end;

function TVclVoxelImageLoader.TryLoad(const AFileName: string; ASize: Integer; out AImage: TVoxelEditorImage): Boolean;
var
  LPicture: TPicture;
  LBitmap: TBitmap;
begin
  Result := False;
  LPicture := TPicture.Create;
  try
    try
      LPicture.LoadFromFile(AFileName);
      if (LPicture.Width <= 0) or (LPicture.Height <= 0) then
        Exit;
      LBitmap := TBitmap.Create;
      try
        LBitmap.PixelFormat := pf32bit;
        LBitmap.SetSize(LPicture.Width, LPicture.Height);
        LBitmap.Canvas.Draw(0, 0, LPicture.Graphic);
        AImage := TVoxelBitmaps.FromBitmap(LBitmap, ASize);
        Result := True;
      finally
        LBitmap.Free;
      end;
    except
      on EInvalidGraphic do
        Result := False;
      on EFOpenError do
        Result := False;
    end;
  finally
    LPicture.Free;
  end;
end;

{ TVclVoxelImageExporter }

function TVclVoxelImageExporter.Export(const AFileName: string; const AImage: TVoxelEditorImage; ASize: Integer): Boolean;
var
  LBitmap: TBitmap;
  LExtension: string;
  LPng: TPngImage;
  LJpeg: TJPEGImage;
begin
  Result := False;
  if (ASize < 1) or (Length(AImage) <> ASize * ASize) then
    Exit;
  LExtension := LowerCase(ExtractFileExt(AFileName));
  LBitmap := TVoxelBitmaps.ToBitmap(AImage, ASize);
  try
    try
      if (LExtension = '.jpg') or (LExtension = '.jpeg') then
      begin
        LJpeg := TJPEGImage.Create;
        try
          LJpeg.Assign(LBitmap);
          LJpeg.SaveToFile(AFileName);
        finally
          LJpeg.Free;
        end;
      end
      else if LExtension = '.png' then
      begin
        LPng := TPngImage.Create;
        try
          LPng.Assign(LBitmap);
          LPng.SaveToFile(AFileName);
        finally
          LPng.Free;
        end;
      end
      else
        LBitmap.SaveToFile(AFileName);
      Result := True;
    except
      on EInOutError do
        Result := False;
      on EFCreateError do
        Result := False;
      on EFOpenError do
        Result := False;
    end;
  finally
    LBitmap.Free;
  end;
end;

end.
