{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL scene - the light of a sector                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Port of gld_CalcLightLevel of OPENGL\gl_render.pas                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlScene.Light;

interface

uses
  DelphiDoom.GlScene.Types;

type
  /// <summary>The brightness OpenGL gets for a light level of the map</summary>
  TGlSceneLight = class
  public
    /// <summary>The entry of the table for the gamma of the user; the level is brought into 0..255</summary>
    /// <remarks>AGamma has to be a row of the table: it is not checked (one call per wall, flat and sprite)</remarks>
    class function Level(const ATable: PGlSceneLightTable; const AGamma, ALight: Integer): Single; static; inline;
  end;

implementation

{ TGlSceneLight }

class function TGlSceneLight.Level(const ATable: PGlSceneLightTable; const AGamma, ALight: Integer): Single;
var
  LLight: Integer;
begin
  LLight := ALight;
  if LLight > 255 then
    LLight := 255;
  if LLight < 0 then
    LLight := 0;
  Result := ATable[AGamma][LLight];
end;

end.
