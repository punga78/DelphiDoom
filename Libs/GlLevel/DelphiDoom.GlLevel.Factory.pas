{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL level geometry - the factory: the composition root       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlLevel.Factory;

interface

uses
  DelphiDoom.GlLevel.Intf;

type
  /// <summary>The only place that knows the classes behind the interfaces of the level geometry</summary>
  TGlLevelFactory = class
  public
    /// <summary>The carver of the flats over a BSP and a place for the polygons</summary>
    class function CreateFlatCarver(const AWorld: IGlFlatWorld; const ASink: IGlFlatLoopSink): IGlFlatCarver; static;
    /// <summary>The checks on the sectors of a level (special effects and isolated lines)</summary>
    class function CreateSectorPreprocessor(const AWorld: IGlSectorWorld): IGlSectorPreprocessor; static;
  end;

implementation

uses
  DelphiDoom.GlLevel.FlatCarver,
  DelphiDoom.GlLevel.SectorPreprocessor;

{ TGlLevelFactory }

class function TGlLevelFactory.CreateFlatCarver(const AWorld: IGlFlatWorld;
  const ASink: IGlFlatLoopSink): IGlFlatCarver;
begin
  Result := TGlFlatCarver.Create(AWorld, ASink);
end;

class function TGlLevelFactory.CreateSectorPreprocessor(const AWorld: IGlSectorWorld): IGlSectorPreprocessor;
begin
  Result := TGlSectorPreprocessor.Create(AWorld);
end;

end.
