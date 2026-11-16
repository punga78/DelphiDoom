{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the images of a PK3 for the renderer library           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Renderer.Pk3Catalog;

{$I Doom32.inc}

interface

uses
  DelphiDoom.Renderer.Intf, DelphiDoom.Engine.Texture.Intf;

type
  /// <summary>
  ///   What the selector of the images of a PK3 asks: the extensions that the decoders read
  ///   (IEngineTextureFiles), the lumps of the WAD (W_CheckNumForName) and the textures that are
  ///   already there (R_CheckTextureNumForName)
  /// </summary>
  TEngineRendererPk3Catalog = class(TInterfacedObject, IRendererPk3Catalog)
  strict private
    FFiles: IEngineTextureFiles;
  public
    constructor Create(const AFiles: IEngineTextureFiles);
    function IsTextureExtension(const AExtension: string): Boolean;
    function HasLump(const AName: string): Boolean;
    function TextureNumber(const AName: string): Integer;
  end;

implementation

uses
  System.SysUtils,
  r_data,
  w_wad;

{ TEngineRendererPk3Catalog }

constructor TEngineRendererPk3Catalog.Create(const AFiles: IEngineTextureFiles);
begin
  inherited Create;
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  FFiles := AFiles;
end;

function TEngineRendererPk3Catalog.IsTextureExtension(const AExtension: string): Boolean;
begin
  Result := FFiles.IsTextureExtension(AExtension);
end;

function TEngineRendererPk3Catalog.HasLump(const AName: string): Boolean;
begin
  Result := W_CheckNumForName(AName) >= 0;
end;

function TEngineRendererPk3Catalog.TextureNumber(const AName: string): Integer;
begin
  Result := R_CheckTextureNumForName(AName);
end;

end.
