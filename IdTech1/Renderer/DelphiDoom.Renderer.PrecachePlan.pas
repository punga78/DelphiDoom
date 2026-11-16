{******************************************************************************}
{                                                                              }
{  DelphiDoom: renderer library - what a level needs to be loaded              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of the tables of what is present of R_PrecacheLevel of r_data.pas      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Renderer.PrecachePlan;

interface

uses
  System.SysUtils, DelphiDoom.Renderer.Types, DelphiDoom.Renderer.Intf;

type
  /// <summary>
  ///   Marks the flats, textures and sprites that a level uses: the renderer loads those and
  ///   only those before the first frame. It is done once for each level
  /// </summary>
  TRendererPrecachePlanner = class(TInterfacedObject, IRendererPrecachePlanner)
  strict private
    class procedure Mark(const ATable: TArray<Boolean>; AIndex: Integer); static;
  public
    function Plan(const AInput: TRendererPrecacheInput): TRendererPrecachePlan;
  end;

implementation

{ TRendererPrecachePlanner }

class procedure TRendererPrecachePlanner.Mark(const ATable: TArray<Boolean>; AIndex: Integer);
begin
  // the old code wrote the byte whatever the index (a texture of a side of Heretic or Hexen can be
  // -1, which wrote before the table): what is outside the game has nothing to load
  if (AIndex >= 0) and (AIndex < Length(ATable)) then
    ATable[AIndex] := True;
end;

function TRendererPrecachePlanner.Plan(const AInput: TRendererPrecacheInput): TRendererPrecachePlan;
var
  LIndex: Integer;
begin
  SetLength(Result.FlatPresent, AInput.FlatCount);
  SetLength(Result.TexturePresent, AInput.TextureCount);
  SetLength(Result.SpritePresent, AInput.SpriteCount);

  for LIndex := 0 to High(AInput.SectorFlats) do
    Mark(Result.FlatPresent, AInput.SectorFlats[LIndex]);
  for LIndex := 0 to High(AInput.ExtraFlats) do
    Mark(Result.FlatPresent, AInput.ExtraFlats[LIndex]);
  for LIndex := 0 to High(AInput.SideTextures) do
    Mark(Result.TexturePresent, AInput.SideTextures[LIndex]);
  for LIndex := 0 to High(AInput.ExtraTextures) do
    Mark(Result.TexturePresent, AInput.ExtraTextures[LIndex]);
  for LIndex := 0 to High(AInput.ObjectSprites) do
    Mark(Result.SpritePresent, AInput.ObjectSprites[LIndex]);
end;

end.
