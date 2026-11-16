{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the BSP of Quake III Arena: flares           }
{                                                                              }
{  Port of ParseFlare (tr_bsp.c). Based on the Quake III Arena GPL Source Code }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is       }
{  derived from the Quake III Arena source code and is therefore available     }
{  under the GNU General Public License, version 2 or (at your option) any     }
{  later version.                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Bsp.FlareLoader;

interface

uses
  DelphiDoom.MapFile.Bsp.Intf, DelphiDoom.MapFile.Bsp.RenderTypes, DelphiDoom.MapFile.Bsp.Types;

type
  /// <summary>
  ///   ParseFlare: a flare has no vertices; its origin is the lightmap origin of the surface,
  ///   its colour the first lightmap vector and its normal the third
  /// </summary>
  TBspFlareLoader = class(TInterfacedObject, IBspFlareLoader)
  public
    function Parse(const ASurface: TBspSurface; const AShaderCount: Integer): TBspFlareSurface;
  end;

implementation

uses
  DelphiDoom.MapFile.Bsp.SurfaceGuard;

{ TBspFlareLoader }

function TBspFlareLoader.Parse(const ASurface: TBspSurface; const AShaderCount: Integer): TBspFlareSurface;
var
  LAxis: Integer;
begin
  TBspSurfaceGuard.CheckShaderNum(ASurface.ShaderNum, AShaderCount);
  // get fog volume
  Result.FogIndex := ASurface.FogNum + 1;
  Result.ShaderNum := ASurface.ShaderNum;
  for LAxis := 0 to 2 do
  begin
    Result.Origin[LAxis] := ASurface.LightmapOrigin[LAxis];
    Result.Color[LAxis] := ASurface.LightmapVecs[0, LAxis];
    Result.Normal[LAxis] := ASurface.LightmapVecs[2, LAxis];
  end;
end;

end.
