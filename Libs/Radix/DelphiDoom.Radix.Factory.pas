{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - the factory: the composition root               }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Factory;

interface

uses
  System.SysUtils,
  DelphiDoom.Radix.Intf;

type
  /// <summary>The only place that knows the classes behind the contracts of the library</summary>
  TRadixFactory = class
  public
    /// <summary>Opens RADIX.DAT; ERadixException when it is not a container of Radix</summary>
    class function OpenContainer(const APath: string): IRadixContainer; static;
    /// <summary>A container held in memory</summary>
    class function OpenContainerBytes(const ABytes: TBytes): IRadixContainer; static;
    class function CreatePaletteBuilder: IRadixPaletteBuilder; static;
    /// <summary>
    ///   The translator of the game with the steps that are ported, in the order of the old
    ///   converter, and the patch options of Rad-X
    /// </summary>
    class function CreateTranslator: IRadixTranslator; static;
  end;

implementation

uses
  System.Classes,
  DelphiDoom.Palette.Intf, DelphiDoom.Palette.Factory, DelphiDoom.GameData.Types,
  DelphiDoom.GameData.Intf, DelphiDoom.GameData.Factory,
  DelphiDoom.Radix.Context, DelphiDoom.Radix.Container, DelphiDoom.Radix.PaletteBuilder,
  DelphiDoom.Radix.PalettePart, DelphiDoom.Radix.TexturePart, DelphiDoom.Radix.FlatPart,
  DelphiDoom.Radix.GraphicsPart, DelphiDoom.Radix.SmallFontPart, DelphiDoom.Radix.LumpGroupPart,
  DelphiDoom.Radix.BigFontPart, DelphiDoom.Radix.DosFontPart, DelphiDoom.Radix.MenuTranslationPart,
  DelphiDoom.Radix.CockpitPart, DelphiDoom.Radix.SoundPart, DelphiDoom.Radix.SpritePart,
  DelphiDoom.Radix.SpriteCatalog, DelphiDoom.Radix.Translator;

{ TRadixFactory }

class function TRadixFactory.OpenContainer(const APath: string): IRadixContainer;
begin
  Result := TRadixContainer.Create(TFileStream.Create(APath, fmOpenRead or fmShareDenyNone), True);
end;

class function TRadixFactory.OpenContainerBytes(const ABytes: TBytes): IRadixContainer;
begin
  Result := TRadixContainer.Create(TBytesStream.Create(ABytes), True);
end;

class function TRadixFactory.CreatePaletteBuilder: IRadixPaletteBuilder;
begin
  Result := TRadixPaletteBuilder.Create(TPaletteFactory.CreateColorMatcher);
end;

class function TRadixFactory.CreateTranslator: IRadixTranslator;
var
  LMatcher: IColorMatcher;
begin
  LMatcher := TPaletteFactory.CreateColorMatcher;
  Result := TRadixTranslator.Create(
    [TRadixPalettePart.Create(CreatePaletteBuilder),
     TRadixTexturePart.Create('PNAMES0', 'TEXTURE0'),
     TRadixFlatPart.Create(LMatcher, True),
     TRadixGraphicsPart.Create,
     TRadixSmallFontPart.Create,
     TRadixBigFontPart.Create(LMatcher),
     TRadixDosFontPart.Create(LMatcher),
     TRadixMenuTranslationPart.Create,
     TRadixSpritePart.Create(TRadixSpriteCatalog.Fill),
     TRadixLumpGroupPart.Music,
     TRadixCockpitPart.Create,
     TRadixSoundPart.Create,
     TRadixLumpGroupPart.MissionText,
     TRadixLumpGroupPart.MissionBriefing,
     TRadixLumpGroupPart.EndText],
    TGameDataFactory.CreatePatchBuilder(TGamePatchOptions.Radix, LMatcher),
    function: IGameWadComposer
    begin
      Result := TGameDataFactory.CreateWadComposer;
    end);
end;

end.
