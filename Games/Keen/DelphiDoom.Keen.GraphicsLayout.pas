{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - sizes of the chunks of the graphics file          }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  the start of CAL_ExpandGrChunk of id_ca.c                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.GraphicsLayout;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   In the graphics file the chunks before STARTTILE8 (tables, font, pictures, sprites) start with the
  ///   expanded length; the tiles do not, because every tile of a kind has the same size: all the 8x8
  ///   tiles are one chunk, then the masked 8x8 tiles, then one chunk for every 16x16 tile and every
  ///   masked 16x16 tile (EGA: 32, 40, 128, 160 bytes for each tile)
  /// </summary>
  TKeenGraphicsLayout = class(TInterfacedObject, IKeenChunkLayout)
  public
    function ImplicitLength(AIndex: Integer): Integer;
    /// <summary>The 8x8 tiles and the masked ones: their chunk has fewer tiles than NUMTILE8 and NUMTILE8M</summary>
    function IsLenient(AIndex: Integer): Boolean;
  end;

implementation

{ TKeenGraphicsLayout }

function TKeenGraphicsLayout.IsLenient(AIndex: Integer): Boolean;
begin
  Result := (AIndex = KEEN_STARTTILE8) or (AIndex = KEEN_STARTTILE8M);
end;

function TKeenGraphicsLayout.ImplicitLength(AIndex: Integer): Integer;
begin
  if AIndex < KEEN_STARTTILE8 then
    Result := -1
  else if AIndex < KEEN_STARTTILE8M then
    Result := KEEN_TILE8_BYTES * KEEN_NUMTILE8
  else if AIndex < KEEN_STARTTILE16 then
    Result := KEEN_TILE8M_BYTES * KEEN_NUMTILE8M
  else if AIndex < KEEN_STARTTILE16M then
    Result := KEEN_TILE16_BYTES
  else
    Result := KEEN_TILE16M_BYTES;
end;

end.
