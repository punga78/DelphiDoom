{******************************************************************************}
{                                                                              }
{  DelphiDoom: texture definitions library - PNAMES and the lumps TEXTUREx     }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.TextureDefs.Loader;

interface

uses
  System.SysUtils, DelphiDoom.TextureDefs.Intf, DelphiDoom.TextureDefs.Types;

type
  /// <summary>
  ///   The order of the old R_InitTextures: PNAMES, TEXTURE1 (needed), TEXTURE2 and TEXTURE3
  ///   (if they exist) and then, if the engine made it, TEXTURE0. The textures are numbered in
  ///   this order. It does not look for the patches in the game: the engine does it when it
  ///   applies the model
  /// </summary>
  TTextureDefsLoader = class(TInterfacedObject, ITextureDefsLoader)
  strict private
    FSource: ITextureDefsLumpSource;
    FPatchNamesReader: ITextureDefsPatchNamesReader;
    FTextureReader: ITextureDefsTextureLumpReader;
    FPk3Reader: ITextureDefsPk3Reader;
    function ReadNeeded(const AName: string): TBytes;
  public
    constructor Create(const ASource: ITextureDefsLumpSource;
      const APatchNamesReader: ITextureDefsPatchNamesReader;
      const ATextureReader: ITextureDefsTextureLumpReader;
      const APk3Reader: ITextureDefsPk3Reader);
    function Load(AIncludePk3: Boolean): TTextureDefsSet;
  end;

implementation

const
  SMissingLump = 'The lump %s does not exist';

{ TTextureDefsLoader }

constructor TTextureDefsLoader.Create(const ASource: ITextureDefsLumpSource;
  const APatchNamesReader: ITextureDefsPatchNamesReader;
  const ATextureReader: ITextureDefsTextureLumpReader;
  const APk3Reader: ITextureDefsPk3Reader);
begin
  inherited Create;
  FSource := ASource;
  FPatchNamesReader := APatchNamesReader;
  FTextureReader := ATextureReader;
  FPk3Reader := APk3Reader;
end;

function TTextureDefsLoader.ReadNeeded(const AName: string): TBytes;
begin
  if not FSource.TryReadLump(AName, Result) then
    raise ETextureDefsException.Create(TTextureDefsError.MissingLump, Format(SMissingLump, [AName]));
end;

function TTextureDefsLoader.Load(AIncludePk3: Boolean): TTextureDefsSet;
const
  LOptionalNames: array[0..1] of string = ('TEXTURE2', 'TEXTURE3');
  LOptionalOrigins: array[0..1] of TTextureDefsOrigin =
    (TTextureDefsOrigin.Texture2, TTextureDefsOrigin.Texture3);
var
  LBytes: TBytes;
  LTextures: TArray<TTextureDefsTexture>;
  LIndex: Integer;
begin
  Result.PatchNames := FPatchNamesReader.Read(ReadNeeded('PNAMES'));
  Result.Textures := FTextureReader.Read(ReadNeeded('TEXTURE1'), TTextureDefsOrigin.Texture1,
    Result.PatchNames);

  for LIndex := Low(LOptionalNames) to High(LOptionalNames) do
    if FSource.TryReadLump(LOptionalNames[LIndex], LBytes) then
    begin
      LTextures := FTextureReader.Read(LBytes, LOptionalOrigins[LIndex], Result.PatchNames);
      Result.Textures := Result.Textures + LTextures;
    end;

  if AIncludePk3 then
  begin
    LTextures := FPk3Reader.Read(ReadNeeded('TEXTURE0'));
    Result.Textures := Result.Textures + LTextures;
  end;
end;

end.
