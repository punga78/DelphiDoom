{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the BSP of Quake III Arena: the checks the   }
{  surface loaders share                                                       }
{                                                                              }
{  Port of the test of ShaderForShaderNum (tr_bsp.c) plus the range checks the }
{  original does not make. Based on the Quake III Arena GPL Source Code (id    }
{  Software). Copyright (C) 1999-2005 Id Software, Inc. GPL v2 or later.       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Bsp.SurfaceGuard;

interface

type
  /// <summary>
  ///   What ParseFace, ParseTriSurf and ParseFlare check before they read: the shader number
  ///   (ShaderForShaderNum: ri.Error ERR_DROP in the original) and, where the original reads
  ///   outside the lumps, that the vertices and indexes of a surface are inside them
  /// </summary>
  TBspSurfaceGuard = class
  public
    /// <summary>ShaderForShaderNum: "bad num" for a number outside the shader lump</summary>
    class procedure CheckShaderNum(const AShaderNum, AShaderCount: Integer); static;
    /// <summary>
    ///   The range [AFirst, AFirst + ACount) must be inside AAvailable elements of the lump
    ///   AName (a difference from the original, which reads outside the lump)
    /// </summary>
    class procedure CheckRange(const AName: string; const AFirst, ACount, AAvailable: Integer); static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MapFile.Bsp.Types;

resourcestring
  SBspBadShaderNum = 'ShaderForShaderNum: bad num %d';
  SBspSurfaceRange = 'surface needs %s %d to %d of %d';

class procedure TBspSurfaceGuard.CheckShaderNum(const AShaderNum, AShaderCount: Integer);
begin
  if (AShaderNum < 0) or (AShaderNum >= AShaderCount) then
    raise EBspFileException.CreateFmt(SBspBadShaderNum, [AShaderNum]);
end;

class procedure TBspSurfaceGuard.CheckRange(const AName: string; const AFirst, ACount, AAvailable: Integer);
begin
  if ACount = 0 then
    Exit;
  if (AFirst < 0) or (ACount < 0) or (Int64(AFirst) + ACount > AAvailable) then
    raise EBspFileException.CreateFmt(SBspSurfaceRange, [AName, AFirst, Int64(AFirst) + ACount, AAvailable]);
end;

end.
