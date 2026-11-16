{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - the coordinates of the I3D models           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.I3d.Coordinates;

interface

uses
  DelphiDoom.Models.I3d.Types,
  DelphiDoom.Models.Types;

type
  /// <summary>
  ///   From the numbers of the file to the ones of the renderer. The expressions are the old ones
  ///   (the compiler computes them in the widest type of the platform) and the renderer gets a
  ///   Single, as OpenGL did.
  /// </summary>
  TI3dCoordinates = class
  public
    /// <summary>The x of a vertex in the placement (the axes of the file and of the renderer are the same)</summary>
    class function WorldX(const AHeader: TI3dHeader; const APlacement: TModelPlacement;
      const AX: Integer): Single; static;
    /// <summary>The y of a vertex in the placement</summary>
    class function WorldY(const AHeader: TI3dHeader; const APlacement: TModelPlacement;
      const AY: Integer): Single; static;
    /// <summary>The z of a vertex in the placement: the file looks the other way, so it changes sign</summary>
    class function WorldZ(const AHeader: TI3dHeader; const APlacement: TModelPlacement;
      const AZ: Integer): Single; static;
    /// <summary>The texture point of the file (the old UVtoGL): u changes sign</summary>
    class procedure TextureToGl(const ATextureX, ATextureY: Integer; out AU, AV: Single); static;
    /// <summary>The way back (the old GLtoUV)</summary>
    class procedure GlToTexture(const AU, AV: Single; out ATextureX, ATextureY: Integer); static;
  end;

implementation

{ TI3dCoordinates }

class function TI3dCoordinates.WorldX(const AHeader: TI3dHeader; const APlacement: TModelPlacement;
  const AX: Integer): Single;
begin
  Result := (1.0 * AX - AHeader.CenterX) * AHeader.ScaleX / I3D_DEFAULT_SCALE * APlacement.ScaleX +
    APlacement.OffsetX;
end;

class function TI3dCoordinates.WorldY(const AHeader: TI3dHeader; const APlacement: TModelPlacement;
  const AY: Integer): Single;
begin
  Result := (1.0 * AY - AHeader.CenterY) * AHeader.ScaleY / I3D_DEFAULT_SCALE * APlacement.ScaleY +
    APlacement.OffsetY;
end;

class function TI3dCoordinates.WorldZ(const AHeader: TI3dHeader; const APlacement: TModelPlacement;
  const AZ: Integer): Single;
begin
  Result := -(1.0 * AZ - AHeader.CenterZ) * AHeader.ScaleZ / I3D_DEFAULT_SCALE * APlacement.ScaleZ +
    APlacement.OffsetZ;
end;

class procedure TI3dCoordinates.TextureToGl(const ATextureX, ATextureY: Integer; out AU, AV: Single);
begin
  AU := -ATextureX / I3D_UV_CONSTANT;
  AV := ATextureY / I3D_UV_CONSTANT;
end;

class procedure TI3dCoordinates.GlToTexture(const AU, AV: Single; out ATextureX, ATextureY: Integer);
begin
  ATextureX := -Round(AU * I3D_UV_CONSTANT);
  ATextureY := Round(AV * I3D_UV_CONSTANT);
end;

end.
