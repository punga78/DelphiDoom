{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the graphic resources of DATA.WAR                 }
{                                                                              }
{  Port of war1 (acoto87/war1), wres_loadResource and the graphic loaders of   }
{  war_resources.c, (c) 2019 Alejandro Coto Gutierrez, zlib License (see       }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Graphics;

interface

uses
  System.SysUtils, DelphiDoom.War.Types, DelphiDoom.War.Intf, DelphiDoom.War.Graphics.Types,
  DelphiDoom.War.Graphics.Intf;

type
  /// <summary>
  ///   Decodes the graphic records of an archive with what the catalog says of each (its type and the palettes
  ///   it names). The original loaded all the records in the order of the table, so a record could only use a
  ///   palette that came before it; every palette of DATA.WAR does, and here any palette of the catalog can be
  ///   used. A palette that is not a palette of the catalog is EWarException (the original read the bytes of
  ///   whatever the record was)
  /// </summary>
  TWarGraphics = class(TInterfacedObject, IWarGraphics)
  strict private
    FArchive: IWarArchive;
    FCatalog: IWarCatalog;
    function Require(AIndex: Integer; AType: TWarRecordType; const ATypeName: string): TWarCatalogEntry;
    function PaletteOf(AIndex: Integer): TBytes;
    function LookupFor(const AEntry: TWarCatalogEntry): TWarColorLookup;
  public
    constructor Create(const AArchive: IWarArchive; const ACatalog: IWarCatalog);
    function GetPalette(AIndex: Integer): TBytes;
    function ComposePalette(AIndex1, AIndex2: Integer): TBytes;
    function GetImage(AIndex: Integer): TWarImage;
    function GetSprite(AIndex: Integer): TWarSprite;
    function GetCursor(AIndex: Integer): TWarCursor;
    function GetTiles(AIndex: Integer): TWarTiles;
    function GetTileset(AIndex: Integer): TWarTileset;
  end;

implementation

uses
  DelphiDoom.War.Graphics.PaletteDecoder, DelphiDoom.War.Graphics.PaletteComposer,
  DelphiDoom.War.Graphics.ColorLookup, DelphiDoom.War.Graphics.ImageDecoder,
  DelphiDoom.War.Graphics.SpriteDecoder, DelphiDoom.War.Graphics.CursorDecoder,
  DelphiDoom.War.Graphics.TilesetDecoder;

{ TWarGraphics }

constructor TWarGraphics.Create(const AArchive: IWarArchive; const ACatalog: IWarCatalog);
begin
  inherited Create;
  if not Assigned(AArchive) then
    raise EArgumentNilException.Create(SWarGraphicsNoArchive);
  if not Assigned(ACatalog) then
    raise EArgumentNilException.Create(SWarGraphicsNoCatalog);
  FArchive := AArchive;
  FCatalog := ACatalog;
end;

function TWarGraphics.Require(AIndex: Integer; AType: TWarRecordType; const ATypeName: string): TWarCatalogEntry;
begin
  if not FCatalog.TryFind(AIndex, Result) then
    raise EWarException.CreateFmt(SWarGraphicsNotListed, [AIndex]);
  if Result.RecordType <> AType then
    raise EWarException.CreateFmt(SWarGraphicsWrongType, [AIndex, ATypeName]);
end;

function TWarGraphics.PaletteOf(AIndex: Integer): TBytes;
var
  LEntry: TWarCatalogEntry;
begin
  if AIndex = 0 then
    Exit(nil);
  if (not FCatalog.TryFind(AIndex, LEntry)) or (LEntry.RecordType <> wrtPalette) then
    raise EWarException.CreateFmt(SWarGraphicsPaletteIndex, [AIndex]);
  Result := GetPalette(AIndex);
end;

function TWarGraphics.LookupFor(const AEntry: TWarCatalogEntry): TWarColorLookup;
begin
  Result := TWarColorLookupBuilder.Build(ComposePalette(AEntry.Param1, AEntry.Param2));
end;

function TWarGraphics.GetPalette(AIndex: Integer): TBytes;
begin
  Require(AIndex, wrtPalette, 'palette');
  Result := TWarPaletteDecoder.Decode(AIndex, FArchive.ReadRecord(AIndex));
end;

function TWarGraphics.ComposePalette(AIndex1, AIndex2: Integer): TBytes;
begin
  Result := TWarPaletteComposer.Compose(PaletteOf(AIndex1), PaletteOf(AIndex2));
end;

function TWarGraphics.GetImage(AIndex: Integer): TWarImage;
begin
  Result := TWarImageDecoder.Decode(AIndex, FArchive.ReadRecord(AIndex), LookupFor(Require(AIndex, wrtImage, 'image')));
end;

function TWarGraphics.GetSprite(AIndex: Integer): TWarSprite;
begin
  Result := TWarSpriteDecoder.Decode(AIndex, FArchive.ReadRecord(AIndex), LookupFor(Require(AIndex, wrtSprite, 'sprite')));
end;

function TWarGraphics.GetCursor(AIndex: Integer): TWarCursor;
begin
  Result := TWarCursorDecoder.Decode(AIndex, FArchive.ReadRecord(AIndex), LookupFor(Require(AIndex, wrtCursor, 'cursor')));
end;

function TWarGraphics.GetTiles(AIndex: Integer): TWarTiles;
var
  LEntry: TWarCatalogEntry;
begin
  LEntry := Require(AIndex, wrtTiles, 'tiles');
  Result.Palette1 := LEntry.Param1;
  Result.Palette2 := LEntry.Param2;
  Result.Data := FArchive.ReadRecord(AIndex);
end;

function TWarGraphics.GetTileset(AIndex: Integer): TWarTileset;
var
  LEntry: TWarCatalogEntry;
  LTiles: TWarTiles;
begin
  LEntry := Require(AIndex, wrtTileset, 'tileset');
  // Param1 of a tileset is the record of its tiles
  LTiles := GetTiles(LEntry.Param1);
  Result := TWarTilesetDecoder.Decode(FArchive.ReadRecord(AIndex), LTiles.Data,
    TWarColorLookupBuilder.Build(ComposePalette(LTiles.Palette1, LTiles.Palette2)));
end;

end.
