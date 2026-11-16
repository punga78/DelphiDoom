{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - the factory: the composition root            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.Factory;

interface

uses
  DelphiDoom.Renderer.Intf, DelphiDoom.Logging.Intf, DelphiDoom.Video.Intf;

type
  /// <summary>The only place that knows the classes behind the interfaces of the renderer library</summary>
  TRendererFactory = class
  public
    /// <param name="APatchSource">The patches of the WAD</param>
    /// <param name="ALog">Where the warnings go (only in developer mode)</param>
    class function CreateTextureLookup(const APatchSource: IRendererPatchSource;
      const ALog: ILog): IRendererTextureLookup; static;
    class function CreateLevelPrecalc: IRendererLevelPrecalc; static;
    class function CreateSubsectorGridBuilder: IRendererSubsectorGridBuilder; static;
    class function CreateTextureMappingBuilder: IRendererTextureMappingBuilder; static;
    class function CreatePrecachePlanner: IRendererPrecachePlanner; static;
    /// <param name="ASource">The screen modes of the system, in its order</param>
    class function CreateMonitorAspect(const ASource: IDisplayModeSource): IRendererMonitorAspect; static;
    class function CreateFake3DAngles: IRendererFake3DAngles; static;
    class function CreateViewTables: IRendererViewTables; static;
    /// <summary>The four sorters of the sprites and the rule that chooses between them</summary>
    class function CreateSpriteSortPolicy: IRendererSpriteSortPolicy; static;
    class function CreateSelectionSorter: IRendererSpriteSorter; static;
    class function CreateQuickSorter: IRendererSpriteSorter; static;
    class function CreateMergeSorter: IRendererSpriteSorter; static;
    class function CreateRadixSorter: IRendererSpriteSorter; static;
    class function CreatePk3NameSelector: IRendererPk3NameSelector; static;
    class function CreatePk3TextHash: IRendererPk3TextHash; static;
    /// <param name="ADirectory">The lumps of the WAD</param>
    /// <param name="ALog">Where the warnings go</param>
    class function CreateLumpRanges(const ADirectory: IRendererLumpDirectory;
      const ALog: ILog): IRendererLumpRanges; static;
    /// <param name="ADirectory">The lumps of the WAD</param>
    /// <param name="AHeaders">The headers of the sprite lumps</param>
    class function CreateSpriteTableBuilder(const ADirectory: IRendererLumpDirectory;
      const AHeaders: IRendererSpriteHeaders): IRendererSpriteTableBuilder; static;
    /// <param name="ASource">The sprite lumps of the WAD</param>
    /// <param name="ALog">Where the warnings go</param>
    class function CreateSpriteDefs(const ASource: IRendererSpriteSource;
      const ALog: ILog): IRendererSpriteDefs; static;
  end;

implementation

uses
  DelphiDoom.Renderer.TextureLookup, DelphiDoom.Renderer.LevelPrecalc,
  DelphiDoom.Renderer.SpriteDefs, DelphiDoom.Renderer.SubsectorGrid, DelphiDoom.Renderer.LumpRanges,
  DelphiDoom.Renderer.SpriteTable, DelphiDoom.Renderer.TextureMapping,
  DelphiDoom.Renderer.PrecachePlan, DelphiDoom.Renderer.Pk3NameSelector,
  DelphiDoom.Renderer.Pk3TextHash, DelphiDoom.Renderer.MonitorAspect,
  DelphiDoom.Renderer.Fake3DAngles, DelphiDoom.Renderer.ViewTables,
  DelphiDoom.Renderer.SelectionSorter, DelphiDoom.Renderer.QuickSorter,
  DelphiDoom.Renderer.MergeSorter, DelphiDoom.Renderer.RadixSorter,
  DelphiDoom.Renderer.SpriteSortPolicy;

{ TRendererFactory }

class function TRendererFactory.CreateSubsectorGridBuilder: IRendererSubsectorGridBuilder;
begin
  Result := TRendererSubsectorGridBuilder.Create;
end;

class function TRendererFactory.CreateMonitorAspect(
  const ASource: IDisplayModeSource): IRendererMonitorAspect;
begin
  Result := TRendererMonitorAspect.Create(ASource);
end;

class function TRendererFactory.CreateSelectionSorter: IRendererSpriteSorter;
begin
  Result := TRendererSelectionSorter.Create;
end;

class function TRendererFactory.CreateQuickSorter: IRendererSpriteSorter;
begin
  Result := TRendererQuickSorter.Create;
end;

class function TRendererFactory.CreateMergeSorter: IRendererSpriteSorter;
begin
  Result := TRendererMergeSorter.Create;
end;

class function TRendererFactory.CreateRadixSorter: IRendererSpriteSorter;
begin
  Result := TRendererRadixSorter.Create;
end;

class function TRendererFactory.CreateSpriteSortPolicy: IRendererSpriteSortPolicy;
begin
  Result := TRendererSpriteSortPolicy.Create(CreateSelectionSorter, CreateQuickSorter,
    CreateMergeSorter, CreateRadixSorter);
end;

class function TRendererFactory.CreateViewTables: IRendererViewTables;
begin
  Result := TRendererViewTables.Create;
end;

class function TRendererFactory.CreateFake3DAngles: IRendererFake3DAngles;
begin
  Result := TRendererFake3DAngles.Create;
end;

class function TRendererFactory.CreatePk3NameSelector: IRendererPk3NameSelector;
begin
  Result := TRendererPk3NameSelector.Create;
end;

class function TRendererFactory.CreatePk3TextHash: IRendererPk3TextHash;
begin
  Result := TRendererPk3TextHash.Create;
end;

class function TRendererFactory.CreatePrecachePlanner: IRendererPrecachePlanner;
begin
  Result := TRendererPrecachePlanner.Create;
end;

class function TRendererFactory.CreateTextureMappingBuilder: IRendererTextureMappingBuilder;
begin
  Result := TRendererTextureMappingBuilder.Create;
end;

class function TRendererFactory.CreateLumpRanges(const ADirectory: IRendererLumpDirectory;
  const ALog: ILog): IRendererLumpRanges;
begin
  Result := TRendererLumpRanges.Create(ADirectory, ALog);
end;

class function TRendererFactory.CreateSpriteTableBuilder(
  const ADirectory: IRendererLumpDirectory;
  const AHeaders: IRendererSpriteHeaders): IRendererSpriteTableBuilder;
begin
  Result := TRendererSpriteTableBuilder.Create(ADirectory, AHeaders);
end;

class function TRendererFactory.CreateSpriteDefs(const ASource: IRendererSpriteSource;
  const ALog: ILog): IRendererSpriteDefs;
begin
  Result := TRendererSpriteDefs.Create(ASource, ALog);
end;

class function TRendererFactory.CreateTextureLookup(const APatchSource: IRendererPatchSource;
  const ALog: ILog): IRendererTextureLookup;
begin
  Result := TRendererTextureLookup.Create(APatchSource, ALog);
end;

class function TRendererFactory.CreateLevelPrecalc: IRendererLevelPrecalc;
begin
  Result := TRendererLevelPrecalc.Create;
end;

end.
