{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the factory                                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Factory;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.War.Intf, DelphiDoom.War.Graphics.Intf, DelphiDoom.War.Font.Intf;

type
  /// <summary>The only place that knows the concrete classes of the library</summary>
  TWarFactory = class
  public
    /// <summary>The table of the records of the original (579 entries)</summary>
    class function CreateCatalog: IWarCatalog; static;
    /// <summary>An archive on a stream; the stream is freed with the archive if AOwnsStream</summary>
    class function OpenStream(AStream: TStream; AOwnsStream: Boolean; const ACatalog: IWarCatalog): IWarArchive; static;
    /// <summary>An archive on a file, opened for reading; EWarException if it is not a DATA.WAR</summary>
    class function OpenFile(const APath: string; const ACatalog: IWarCatalog): IWarArchive; static;
    /// <summary>The decoder of the graphic records (palettes, images, sprites, cursors, tiles, tilesets) of an archive</summary>
    class function CreateGraphics(const AArchive: IWarArchive; const ACatalog: IWarCatalog): IWarGraphics; static;
    /// <summary>The glyph tables of the two fonts of the game</summary>
    class function CreateFontMetrics: IWarFontMetrics; static;
  end;

implementation

uses
  DelphiDoom.War.Archive, DelphiDoom.War.Catalog, DelphiDoom.War.Catalog.Data, DelphiDoom.War.StreamSource,
  DelphiDoom.War.Graphics, DelphiDoom.War.Font.Types, DelphiDoom.War.Font.Data, DelphiDoom.War.Font.Metrics;

{ TWarFactory }

class function TWarFactory.CreateCatalog: IWarCatalog;
begin
  Result := TWarCatalog.Create(WarDefaultCatalogEntries);
end;

class function TWarFactory.OpenStream(AStream: TStream; AOwnsStream: Boolean; const ACatalog: IWarCatalog): IWarArchive;
begin
  // the source takes the stream first: if the archive refuses the data the stream is freed with it
  Result := TWarArchive.Create(TWarStreamSource.Create(AStream, AOwnsStream), ACatalog);
end;

class function TWarFactory.OpenFile(const APath: string; const ACatalog: IWarCatalog): IWarArchive;
begin
  Result := OpenStream(TFileStream.Create(APath, fmOpenRead or fmShareDenyNone), True, ACatalog);
end;

class function TWarFactory.CreateGraphics(const AArchive: IWarArchive; const ACatalog: IWarCatalog): IWarGraphics;
begin
  Result := TWarGraphics.Create(AArchive, ACatalog);
end;

class function TWarFactory.CreateFontMetrics: IWarFontMetrics;
var
  LFonts: TArray<TWarFontData>;
  LFont: Integer;
begin
  SetLength(LFonts, WAR_FONT_COUNT);
  for LFont := 0 to WAR_FONT_COUNT - 1 do
    LFonts[LFont] := WarDefaultFontData(LFont);
  Result := TWarFontMetrics.Create(LFonts);
end;

end.
