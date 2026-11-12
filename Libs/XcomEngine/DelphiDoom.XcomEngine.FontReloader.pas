{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - lays the fonts chosen in the options over  }
{  the fonts of the game while the game runs (issue 184)                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.FontReloader;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomEngine.FontReloader.Intf,
  DelphiDoom.XcomEngine.FontSettingsSource.Intf, DelphiDoom.XcomSurface.Glyph.Types,
  DelphiDoom.XcomSurface.FontOverlay.Intf;

type
  /// <summary>Makes the overlay for a list of entries; nil for an empty list (the pictures of the game alone)</summary>
  TXcomFontOverlayFactory = reference to function(const ASettings: TArray<TXcomFontOverlaySettings>): IXcomFontOverlay;

  /// <summary>
  ///   IXcomFontReloader: keeps the choice of the source, makes the overlay for it with the factory (the composition
  ///   root, which knows the rasterizer and the composer of the screen) and has the resources lay it over their
  ///   fonts. Resources that cannot change their fonts are left alone
  /// </summary>
  TXcomFontReloader = class(TInterfacedObject, IXcomFontReloader)
  strict private
    FSource: IXcomFontSettingsSource;
    FFactory: TXcomFontOverlayFactory;
  public
    constructor Create(const ASource: IXcomFontSettingsSource; const AFactory: TXcomFontOverlayFactory);
    function Reload(const AResources: IXcomResources): TArray<string>;
  end;

implementation

uses
  DelphiDoom.XcomEngine.FontReapplier.Intf;

constructor TXcomFontReloader.Create(const ASource: IXcomFontSettingsSource; const AFactory: TXcomFontOverlayFactory);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  if not Assigned(AFactory) then
    raise EArgumentNilException.Create('AFactory');
  FSource := ASource;
  FFactory := AFactory;
end;

function TXcomFontReloader.Reload(const AResources: IXcomResources): TArray<string>;
var
  LReapplier: IXcomFontReapplier;
  LOverlay: IXcomFontOverlay;
  LNotices: IXcomFontNotices;
begin
  Result := nil;
  FSource.Commit;
  if not Supports(AResources, IXcomFontReapplier, LReapplier) then
    Exit;
  LOverlay := FFactory(FSource.Settings);
  LReapplier.ReapplyFonts(LOverlay);
  if Supports(LOverlay, IXcomFontNotices, LNotices) then
    Result := LNotices.Notices;
end;

end.
