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
  DelphiDoom.Scanner.Preprocessor.Intf,
  DelphiDoom.Zone.Intf,
  DelphiDoom.Engine.Wad.Lumps.Intf,
  DelphiDoom.Engine.Shutdown.Intf;

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
    FLumps: IEngineLumps;
    FZone: IZoneAllocator;
    FShutdown: IEngineShutdown;
  public
    /// <param name="ABuilder">Makes the palettes of the game (profile Doom or Hexen)</param>
    /// <param name="AWithFogmap">False in Hexen, which has no FOGMAP</param>
    /// <param name="ALumps">The palette lump, and the WAD that is loaded at runtime</param>
    /// <param name="AZone">Gives back the cached copy of the palette lump</param>
    /// <param name="AShutdown">Stops the game when the palettes can not be built (I_Error)</param>
    constructor Create(const ABuilder: IPaletteBuilder; AWithFogmap: Boolean;
      const ALumps: IEngineLumps; const AZone: IZoneAllocator; const AShutdown: IEngineShutdown);
    /// <param name="AArgument">The palette lump (empty: PLAYPAL)</param>
    procedure Generate(const AArgument: string);
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Palette.Types,
  d_delphi,
  i_tmp,
  w_wadwriter,
  DelphiDoom.Zone.Types;

const
  AUTO_PALETTE_WAD = 'auto_palette.wad';

{ TEnginePaletteGenerator }

constructor TEnginePaletteGenerator.Create(const ABuilder: IPaletteBuilder; AWithFogmap: Boolean;
  const ALumps: IEngineLumps; const AZone: IZoneAllocator; const AShutdown: IEngineShutdown);
begin
  inherited Create;
  if not Assigned(AShutdown) then
    raise EArgumentNilException.Create('AShutdown');
  FShutdown := AShutdown;
  if not Assigned(ABuilder) then
    raise EArgumentNilException.Create('ABuilder');
  if not Assigned(ALumps) then
    raise EArgumentNilException.Create('ALumps');
  if not Assigned(AZone) then
    raise EArgumentNilException.Create('AZone');
  FLumps := ALumps;
  FZone := AZone;
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
    LLump := FLumps.Cache(FLumps.GetNumForName('PLAYPAL'), ZONE_TAG_STATIC)
  else
    LLump := FLumps.Cache(FLumps.GetNumForName(AArgument), ZONE_TAG_STATIC);
  SetLength(LBase, PALETTE_BYTE_COUNT);
  Move(LLump^, LBase[0], PALETTE_BYTE_COUNT);
  FZone.FreeBlock(LLump);

  try
    LPalettes := FBuilder.Build(LBase, True, FWithFogmap);
  except
    on E: EPaletteException do
      FShutdown.Fail('TEnginePaletteGenerator.Generate(): ' + E.Message);
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

  FLumps.RuntimeLoadFile(LFileName);
end;

end.
