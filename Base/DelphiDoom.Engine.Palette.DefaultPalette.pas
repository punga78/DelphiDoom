{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the default palette in 32 bits over Libs\Palette       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Palette.DefaultPalette;

{$I Doom32.inc}

interface

uses
  System.SysUtils,
  DelphiDoom.Palette.Intf,
  DelphiDoom.Engine.Palette.Intf;

type
  /// <summary>
  ///   R_DefaultPalette of the old r_palette.pas: the palette comes from V_ReadPalette, the
  ///   colors from the unpacker of Libs\Palette; it is read the first time and then kept
  /// </summary>
  TEngineDefaultPalette = class(TInterfacedObject, IEngineDefaultPalette)
  strict private
    FUnpacker: IPaletteUnpacker;
    FColors: TEnginePalette;
    FLoaded: Boolean;
  public
    /// <remarks>Raises EArgumentNilException if AUnpacker is nil</remarks>
    constructor Create(const AUnpacker: IPaletteUnpacker);
    function Colors: PEnginePalette;
  end;

implementation

uses
  d_delphi,
  v_data,
  z_zone;

const
  SUnpackerIsNil = 'TEngineDefaultPalette: the unpacker of the palette is nil';
  PALETTE_BYTES = 256 * 3;

{ TEngineDefaultPalette }

constructor TEngineDefaultPalette.Create(const AUnpacker: IPaletteUnpacker);
begin
  inherited Create;
  if not Assigned(AUnpacker) then
    raise EArgumentNilException.Create(SUnpackerIsNil);
  FUnpacker := AUnpacker;
end;

function TEngineDefaultPalette.Colors: PEnginePalette;
var
  LPalette: PByteArray;
  LSource: TBytes;
  LColors: TArray<Cardinal>;
begin
  if not FLoaded then
  begin
    LPalette := V_ReadPalette(PU_STATIC);
    SetLength(LSource, PALETTE_BYTES);
    Move(LPalette^, LSource[0], PALETTE_BYTES);
    Z_ChangeTag(LPalette, PU_CACHE);

    LColors := FUnpacker.Unpack(LSource);
    Move(LColors[0], FColors[0], SizeOf(TEnginePalette));
    FLoaded := True;
  end;
  Result := @FColors;
end;

end.
