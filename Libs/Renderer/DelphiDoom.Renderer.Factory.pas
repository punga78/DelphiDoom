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
  DelphiDoom.Renderer.Intf, DelphiDoom.Logging.Intf;

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
  DelphiDoom.Renderer.SpriteTable;

{ TRendererFactory }

class function TRendererFactory.CreateSubsectorGridBuilder: IRendererSubsectorGridBuilder;
begin
  Result := TRendererSubsectorGridBuilder.Create;
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
