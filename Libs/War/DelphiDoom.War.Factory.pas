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
  System.SysUtils, System.Classes, DelphiDoom.War.Intf;

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
  end;

implementation

uses
  DelphiDoom.War.Archive, DelphiDoom.War.Catalog, DelphiDoom.War.Catalog.Data, DelphiDoom.War.StreamSource;

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

end.
