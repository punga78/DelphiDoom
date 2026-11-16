{******************************************************************************}
{                                                                              }
{  DelphiDoom: texture definitions library - the factory: the composition root }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.TextureDefs.Factory;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.TextureDefs.Intf, DelphiDoom.TextureDefs.Types;

type
  /// <summary>The only place that knows the classes behind the contracts of the texture definitions</summary>
  TTextureDefsFactory = class
  public
    class function CreatePatchNamesReader: ITextureDefsPatchNamesReader; static;
    class function CreateTextureLumpReader(AFormat: TTextureDefsFormat): ITextureDefsTextureLumpReader; static;
    class function CreatePk3Reader(AFormat: TTextureDefsFormat): ITextureDefsPk3Reader; static;
    /// <param name="ALog">May be nil</param>
    class function CreateFlatInfoParser(const ALog: ILog): ITextureDefsFlatInfoParser; static;
    /// <summary>PNAMES, TEXTURE1..3 and TEXTURE0 with the layout of the game</summary>
    class function CreateLoader(const ASource: ITextureDefsLumpSource;
      AFormat: TTextureDefsFormat): ITextureDefsLoader; static;
  end;

implementation

uses
  DelphiDoom.TextureDefs.PatchNamesReader, DelphiDoom.TextureDefs.TextureLumpReader,
  DelphiDoom.TextureDefs.Pk3Reader, DelphiDoom.TextureDefs.FlatInfoParser,
  DelphiDoom.TextureDefs.Loader;

{ TTextureDefsFactory }

class function TTextureDefsFactory.CreatePatchNamesReader: ITextureDefsPatchNamesReader;
begin
  Result := TTextureDefsPatchNamesReader.Create;
end;

class function TTextureDefsFactory.CreateTextureLumpReader(
  AFormat: TTextureDefsFormat): ITextureDefsTextureLumpReader;
begin
  Result := TTextureDefsTextureLumpReader.Create(AFormat);
end;

class function TTextureDefsFactory.CreatePk3Reader(AFormat: TTextureDefsFormat): ITextureDefsPk3Reader;
begin
  Result := TTextureDefsPk3Reader.Create(AFormat);
end;

class function TTextureDefsFactory.CreateFlatInfoParser(const ALog: ILog): ITextureDefsFlatInfoParser;
begin
  Result := TTextureDefsFlatInfoParser.Create(ALog);
end;

class function TTextureDefsFactory.CreateLoader(const ASource: ITextureDefsLumpSource;
  AFormat: TTextureDefsFormat): ITextureDefsLoader;
begin
  Result := TTextureDefsLoader.Create(ASource, CreatePatchNamesReader,
    CreateTextureLumpReader(AFormat), CreatePk3Reader(AFormat));
end;

end.
