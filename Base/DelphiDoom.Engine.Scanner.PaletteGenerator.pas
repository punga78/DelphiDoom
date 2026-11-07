{******************************************************************************}
{                                                                              }
{  DelphiDoom: the palettes that #CREATEPALETTE asks for                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Scanner.PaletteGenerator;

interface

uses
  DelphiDoom.Palette.Intf,
  DelphiDoom.Scanner.Preprocessor.Intf;

type
  /// <summary>
  ///   #CREATEPALETTE: builds PLAYPAL, COLORMAP and (not in Hexen) FOGMAP from a palette lump
  ///   with the IPaletteBuilder of Libs\Palette, writes them in a temporary WAD and loads it
  ///   (it was V_AutoGeneratePalettes of v_palettes.pas)
  /// </summary>
  TEnginePaletteGenerator = class(TInterfacedObject, IPaletteGenerator)
  strict private
    FBuilder: IPaletteBuilder;
    FWithFogmap: Boolean;
  public
    /// <param name="ABuilder">Makes the palettes of the game (profile Doom or Hexen)</param>
    /// <param name="AWithFogmap">False in Hexen, which has no FOGMAP</param>
    constructor Create(const ABuilder: IPaletteBuilder; AWithFogmap: Boolean);
    /// <param name="AArgument">The palette lump (empty: PLAYPAL)</param>
    procedure Generate(const AArgument: string);
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Palette.Types,
  d_delphi,
  i_system,
  i_tmp,
  w_wad,
  w_wadwriter,
  z_zone;

const
  AUTO_PALETTE_WAD = 'auto_palette.wad';

{ TEnginePaletteGenerator }

constructor TEnginePaletteGenerator.Create(const ABuilder: IPaletteBuilder; AWithFogmap: Boolean);
begin
  inherited Create;
  if not Assigned(ABuilder) then
    raise EArgumentNilException.Create('ABuilder');
  FBuilder := ABuilder;
  FWithFogmap := AWithFogmap;
end;

procedure TEnginePaletteGenerator.Generate(const AArgument: string);
var
  LLump: PByteArray;
  LBase: TBytes;
  LPalettes: TPaletteSet;
  LWad: TWadWriter;
  LFileName: string;
begin
  if AArgument = '' then
    LLump := W_CacheLumpName('PLAYPAL', PU_STATIC)
  else
    LLump := W_CacheLumpName(AArgument, PU_STATIC);
  SetLength(LBase, PALETTE_BYTE_COUNT);
  Move(LLump^, LBase[0], PALETTE_BYTE_COUNT);
  Z_Free(LLump);

  try
    LPalettes := FBuilder.Build(LBase, True, FWithFogmap);
  except
    on E: EPaletteException do
      I_Error('TEnginePaletteGenerator.Generate(): %s', [E.Message]);
  end;

  LFileName := I_NewTempFile(AUTO_PALETTE_WAD);

  LWad := TWadWriter.Create;
  try
    LWad.AddData('PLAYPAL', @LPalettes.Playpal[0], Length(LPalettes.Playpal));
    LWad.AddData('COLORMAP', @LPalettes.Colormap[0], Length(LPalettes.Colormap));
    if FWithFogmap then
      LWad.AddData('FOGMAP', @LPalettes.Fogmap[0], Length(LPalettes.Fogmap));
    LWad.SaveToFile(LFileName);
  finally
    LWad.Free;
  end;

  W_RuntimeLoad(LFileName, F_ORIGIN_WAD);
end;

end.
