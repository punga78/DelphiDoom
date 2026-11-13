{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the lightmaps of a BSP as images             }
{                                                                              }
{  Port of R_LoadLightmaps (tr_bsp.c), Quake III Arena GPL Source Code.        }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. GPL v2 or later.                                }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Bsp.LightmapLoader;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.MapFile.Bsp.Intf;

type
  /// <summary>
  ///   Expands the 24 bit lightmaps of the file to 32 bit images (R_ColorShiftLightingBytes on
  ///   every texel, alpha 255), without creating any texture. Not ported: the debug display of
  ///   <c>r_lightmap 2</c> (colours by intensity) and the vertex light mode (no images at all:
  ///   the caller just does not ask for them)
  /// </summary>
  TBspLightmapLoader = class(TInterfacedObject, IBspLightmapLoader)
  public
    function LightmapCount(const ALumpLength: Integer): Integer;
    function Load(const ALightmaps: TBytes; const AShift: Integer): TArray<TBytes>;
  end;

implementation

uses
  DelphiDoom.MapFile.Bsp.Types, DelphiDoom.MapFile.Bsp.ColorShift;

const
  LIGHTMAP_SIZE = 128;
  TEXELS = LIGHTMAP_SIZE * LIGHTMAP_SIZE;

{ TBspLightmapLoader }

function TBspLightmapLoader.LightmapCount(const ALumpLength: Integer): Integer;
begin
  if ALumpLength <= 0 then
    Exit(0);
  Result := ALumpLength div BSP_LIGHTMAP_BYTES;
  // maps with only one lightmap turn up fullbright for some reason: the original adds one
  if Result = 1 then
    Inc(Result);
end;

function TBspLightmapLoader.Load(const ALightmaps: TBytes; const AShift: Integer): TArray<TBytes>;
var
  LCount, LImage, LTexel, LSource: Integer;
  LColor, LShifted: TBspColor;
begin
  LCount := LightmapCount(Length(ALightmaps));
  SetLength(Result, LCount);
  for LImage := 0 to LCount - 1 do
  begin
    SetLength(Result[LImage], TEXELS * 4);
    for LTexel := 0 to TEXELS - 1 do
    begin
      LSource := LImage * BSP_LIGHTMAP_BYTES + LTexel * 3;
      // past the lump (the second image of the one-lightmap hack): zero
      if LSource + 2 < Length(ALightmaps) then
      begin
        LColor[0] := ALightmaps[LSource];
        LColor[1] := ALightmaps[LSource + 1];
        LColor[2] := ALightmaps[LSource + 2];
      end
      else
      begin
        LColor[0] := 0;
        LColor[1] := 0;
        LColor[2] := 0;
      end;
      LColor[3] := 0;
      TBspColorShift.Apply(AShift, LColor, LShifted);
      Result[LImage][LTexel * 4] := LShifted[0];
      Result[LImage][LTexel * 4 + 1] := LShifted[1];
      Result[LImage][LTexel * 4 + 2] := LShifted[2];
      Result[LImage][LTexel * 4 + 3] := 255;
    end;
  end;
end;

end.
