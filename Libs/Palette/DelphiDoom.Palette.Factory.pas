{******************************************************************************}
{                                                                              }
{  DelphiDoom: palette library - the factory: the composition root              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Palette.Factory;

interface

uses
  DelphiDoom.Palette.Types, DelphiDoom.Palette.Intf, DelphiDoom.Video.Intf;

type
  /// <summary>The only place that knows the classes behind the contracts of the palette library</summary>
  TPaletteFactory = class
  public
    class function CreateColorMatcher: IColorMatcher; static;
    /// <param name="AProfile">TPaletteProfiles.Doom (Doom, Heretic, Strife) or .Hexen</param>
    class function CreatePaletteBuilder(const AMatcher: IColorMatcher;
      const AProfile: TPaletteProfile): IPaletteBuilder; static;
    class function CreateTranslationBuilder(const AMatcher: IColorMatcher): ITranslationBuilder; static;
    class function CreateDoomPlayerTranslations: IPlayerTranslations; static;
    class function CreateHereticPlayerTranslations: IPlayerTranslations; static;
    class function CreateStrifePlayerTranslations: IPlayerTranslations; static;
    class function CreateGammaTables: IGammaTables; static;
    class function CreateColormapPreparer: IColormapPreparer; static;
    class function CreateLightTableCalculator: ILightTableCalculator; static;
    class function CreateTranslationNames: ITranslationNames; static;
    class function CreatePrecalcTables: IPrecalcTables; static;
    class function CreateBufferFixer: IPaletteBufferFixer; static;
    /// <param name="AConverter">The converter of Libs\Video (TVideoFactory)</param>
    class function CreatePaletteUnpacker(const AConverter: IPaletteConverter): IPaletteUnpacker; static;
  end;

implementation

uses
  DelphiDoom.Palette.ColorMatcher, DelphiDoom.Palette.Builder, DelphiDoom.Palette.TranslationBuilder,
  DelphiDoom.Palette.PlayerTranslations.Doom, DelphiDoom.Palette.PlayerTranslations.Heretic,
  DelphiDoom.Palette.PlayerTranslations.Strife, DelphiDoom.Palette.GammaTables,
  DelphiDoom.Palette.ColormapPreparer, DelphiDoom.Palette.LightTables,
  DelphiDoom.Palette.TranslationNames, DelphiDoom.Palette.PrecalcTables,
  DelphiDoom.Palette.BufferFixer, DelphiDoom.Palette.Unpacker;

{ TPaletteFactory }

class function TPaletteFactory.CreateColorMatcher: IColorMatcher;
begin
  Result := TColorMatcher.Create;
end;

class function TPaletteFactory.CreatePaletteBuilder(const AMatcher: IColorMatcher;
  const AProfile: TPaletteProfile): IPaletteBuilder;
begin
  Result := TPaletteBuilder.Create(AMatcher, AProfile);
end;

class function TPaletteFactory.CreateTranslationBuilder(const AMatcher: IColorMatcher): ITranslationBuilder;
begin
  Result := TTranslationBuilder.Create(AMatcher);
end;

class function TPaletteFactory.CreateDoomPlayerTranslations: IPlayerTranslations;
begin
  Result := TDoomPlayerTranslations.Create;
end;

class function TPaletteFactory.CreateHereticPlayerTranslations: IPlayerTranslations;
begin
  Result := THereticPlayerTranslations.Create;
end;

class function TPaletteFactory.CreateStrifePlayerTranslations: IPlayerTranslations;
begin
  Result := TStrifePlayerTranslations.Create;
end;

class function TPaletteFactory.CreateGammaTables: IGammaTables;
begin
  Result := TGammaTables.Create;
end;

class function TPaletteFactory.CreateColormapPreparer: IColormapPreparer;
begin
  Result := TColormapPreparer.Create;
end;

class function TPaletteFactory.CreateLightTableCalculator: ILightTableCalculator;
begin
  Result := TLightTableCalculator.Create;
end;

class function TPaletteFactory.CreateTranslationNames: ITranslationNames;
begin
  Result := TTranslationNames.Create;
end;

class function TPaletteFactory.CreatePrecalcTables: IPrecalcTables;
begin
  Result := TPrecalcTables.Create;
end;

class function TPaletteFactory.CreateBufferFixer: IPaletteBufferFixer;
begin
  Result := TPaletteBufferFixer.Create;
end;

class function TPaletteFactory.CreatePaletteUnpacker(const AConverter: IPaletteConverter): IPaletteUnpacker;
begin
  Result := TPaletteUnpacker.Create(AConverter);
end;

end.
