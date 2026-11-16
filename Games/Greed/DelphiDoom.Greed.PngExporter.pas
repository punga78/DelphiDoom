{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - saves a map or an image of the archive as PNG    }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): a way to look at the data   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.PngExporter;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf, DelphiDoom.Platform.Intf;

type
  /// <summary>
  ///   Reads the map or the lump, makes the image, encodes it with the palette of the archive and writes the
  ///   file. The color 0 of a sprite or of a masked picture is transparent in the file; in a flat, a wall, a
  ///   map and in the pictures that have no 0 it makes no difference
  /// </summary>
  TGreedPngExporter = class(TInterfacedObject, IGreedPngExporter)
  strict private
    FArchive: IGreedArchive;
    FMaps: IGreedMapLoader;
    FRenderer: IGreedMapRenderer;
    FClassifier: IGreedLumpClassifier;
    FEncoder: IGreedImageEncoder;
    FFiles: IFileStore;
    function Palette: TBytes;
    procedure Write(const APath: string; const ABytes: TBytes);
  public
    constructor Create(const AArchive: IGreedArchive; const AMaps: IGreedMapLoader;
      const ARenderer: IGreedMapRenderer; const AClassifier: IGreedLumpClassifier;
      const AEncoder: IGreedImageEncoder; const AFiles: IFileStore);
    procedure SaveMap(AMapNumber: Integer; const APath: string);
    procedure SaveLump(AIndex: Integer; const APath: string);
  end;

implementation

uses
  DelphiDoom.Greed.Palette;

{ TGreedPngExporter }

constructor TGreedPngExporter.Create(const AArchive: IGreedArchive; const AMaps: IGreedMapLoader;
  const ARenderer: IGreedMapRenderer; const AClassifier: IGreedLumpClassifier;
  const AEncoder: IGreedImageEncoder; const AFiles: IFileStore);
begin
  inherited Create;
  if not Assigned(AArchive) then
    raise EArgumentNilException.Create('AArchive');
  if not Assigned(AMaps) then
    raise EArgumentNilException.Create('AMaps');
  if not Assigned(ARenderer) then
    raise EArgumentNilException.Create('ARenderer');
  if not Assigned(AClassifier) then
    raise EArgumentNilException.Create('AClassifier');
  if not Assigned(AEncoder) then
    raise EArgumentNilException.Create('AEncoder');
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  FArchive := AArchive;
  FMaps := AMaps;
  FRenderer := ARenderer;
  FClassifier := AClassifier;
  FEncoder := AEncoder;
  FFiles := AFiles;
end;

function TGreedPngExporter.Palette: TBytes;
begin
  Result := TGreedPalette.FromLump(FArchive.ReadLump(FArchive.RequireIndexOf(GREED_LUMP_PALETTE)));
end;

procedure TGreedPngExporter.Write(const APath: string; const ABytes: TBytes);
begin
  if not FFiles.Write(APath, @ABytes[0], Length(ABytes)) then
    raise EGreedException.CreateFmt(SGreedFileNotWritten, [APath]);
end;

procedure TGreedPngExporter.SaveMap(AMapNumber: Integer; const APath: string);
begin
  Write(APath, FEncoder.Encode(FRenderer.Render(FMaps.Load(AMapNumber)), Palette, False));
end;

procedure TGreedPngExporter.SaveLump(AIndex: Integer; const APath: string);
var
  LKind: TGreedLumpKind;
  LDecoder: IGreedImageDecoder;
begin
  LKind := FClassifier.Classify(AIndex);
  LDecoder := FClassifier.DecoderOf(LKind);
  if not Assigned(LDecoder) then
    raise EGreedDataException.CreateFmt(SGreedImageKind, [AIndex, FArchive.GetLumpName(AIndex)]);
  Write(APath, FEncoder.Encode(LDecoder.Decode(FArchive.ReadLump(AIndex)), Palette,
    LKind in [glkSprite, glkPicture]));
end;

end.
