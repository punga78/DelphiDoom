{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel library - the factory: the composition root               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Voxel.Factory;

interface

uses
  DelphiDoom.Logging.Intf,
  DelphiDoom.Voxel.Intf;

type
  /// <summary>The only place that knows the classes behind the interfaces of the voxel library</summary>
  TVoxelFactory = class
  public
    /// <summary>The readers of the four formats: DDVOX, DDMESH, KVX and VOX</summary>
    class function CreateFormats(const ALog: ILog): TArray<IVoxelFormat>; static;
    /// <summary>A loader of the four formats that takes the files from ASource</summary>
    class function CreateLoader(const ASource: IVoxelFileSource; const ALog: ILog): IVoxelLoader; static;
    /// <summary>The placement of a model in a cube</summary>
    class function CreateCubeBuilder: IVoxelCubeBuilder; static;
    /// <summary>The maker of the patch of a sprite; AMapper finds the colors of the palette</summary>
    class function CreatePatchBuilder(const AMapper: IVoxelColorMapper): IVoxelPatchBuilder; static;
    /// <summary>The parser of the VOXELDEF lump; ALookup knows the states and the sprites of the game</summary>
    class function CreateDefinitionParser(const ALookup: IVoxelDefinitionLookup;
      const ALog: ILog): IVoxelDefinitionParser; static;
    /// <summary>An empty list of the voxel files that become sprites; ALumps are the lumps of the game</summary>
    class function CreateSpriteNames(const ALumps: IVoxelLumpNames): IVoxelSpriteNames; static;
  end;

implementation

uses
  DelphiDoom.Voxel.Format.Ddvox,
  DelphiDoom.Voxel.Format.Ddmesh,
  DelphiDoom.Voxel.Format.Kvx,
  DelphiDoom.Voxel.Format.Slab6,
  DelphiDoom.Voxel.Loader,
  DelphiDoom.Voxel.CubeBuilder,
  DelphiDoom.Voxel.PatchBuilder,
  DelphiDoom.Voxel.DefinitionParser,
  DelphiDoom.Voxel.SpriteNames;

{ TVoxelFactory }

class function TVoxelFactory.CreateFormats(const ALog: ILog): TArray<IVoxelFormat>;
begin
  SetLength(Result, 4);
  Result[0] := TVoxelDdmeshFormat.Create;
  Result[1] := TVoxelDdvoxFormat.Create(ALog);
  Result[2] := TVoxelKvxFormat.Create;
  Result[3] := TVoxelSlab6Format.Create;
end;

class function TVoxelFactory.CreateLoader(const ASource: IVoxelFileSource; const ALog: ILog): IVoxelLoader;
begin
  Result := TVoxelLoader.Create(CreateFormats(ALog), ASource, ALog);
end;

class function TVoxelFactory.CreateCubeBuilder: IVoxelCubeBuilder;
begin
  Result := TVoxelCubeBuilder.Create;
end;

class function TVoxelFactory.CreatePatchBuilder(const AMapper: IVoxelColorMapper): IVoxelPatchBuilder;
begin
  Result := TVoxelPatchBuilder.Create(AMapper);
end;

class function TVoxelFactory.CreateDefinitionParser(const ALookup: IVoxelDefinitionLookup;
  const ALog: ILog): IVoxelDefinitionParser;
begin
  Result := TVoxelDefinitionParser.Create(ALookup, ALog);
end;

class function TVoxelFactory.CreateSpriteNames(const ALumps: IVoxelLumpNames): IVoxelSpriteNames;
begin
  Result := TVoxelSpriteNames.Create(ALumps);
end;

end.
