{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the sprite headers for the renderer library            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Renderer.SpriteHeaders;

{$I Doom32.inc}

interface

uses
  DelphiDoom.Renderer.Intf;

type
  /// <summary>
  ///   Reads the header of a sprite lump through the cache of the engine (W_CacheSpriteNum:
  ///   the images of the PK3 count as sprites): static while it is read, then back to the cache
  /// </summary>
  TEngineRendererSpriteHeaders = class(TInterfacedObject, IRendererSpriteHeaders)
  public
    procedure Header(ALump: Integer; out AWidth, ALeftOffset, ATopOffset: Integer);
  end;

implementation

uses
  r_defs,
  w_sprite,
  z_zone;

{ TEngineRendererSpriteHeaders }

procedure TEngineRendererSpriteHeaders.Header(ALump: Integer; out AWidth, ALeftOffset,
  ATopOffset: Integer);
var
  LPatch: Ppatch_t;
begin
  LPatch := W_CacheSpriteNum(ALump, nil, PU_STATIC);
  AWidth := LPatch.width;
  ALeftOffset := LPatch.leftoffset;
  ATopOffset := LPatch.topoffset;
  Z_ChangeTag(LPatch, PU_CACHE);
end;

end.
