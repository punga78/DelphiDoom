{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - a view of a map as the game shows it              }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.ViewExporter;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf, DelphiDoom.Platform.Intf;

type
  /// <summary>
  ///   Makes the 320x200 screen of the game for a map and a position, with the video manager and the tile
  ///   refresh manager (not the whole map at once like the map renderer does), and saves it as an image
  /// </summary>
  TKeenViewExporter = class(TInterfacedObject, IKeenViewExporter)
  strict private
    FData: IKeenGameData;
    FEncoder: IKeenImageEncoder;
    FFiles: IFileStore;
  public
    constructor Create(const AData: IKeenGameData; const AEncoder: IKeenImageEncoder; const AFiles: IFileStore);
    procedure SaveViewPicture(AMapNumber, AGlobalX, AGlobalY: Integer; const ASprites: array of TKeenViewSprite;
      const APath: string);
  end;

implementation

uses
  DelphiDoom.Keen.EgaMemory, DelphiDoom.Keen.SpriteCache, DelphiDoom.Keen.Video, DelphiDoom.Keen.WorkingMap,
  DelphiDoom.Keen.Refresh, DelphiDoom.Keen.ManualClock, DelphiDoom.Keen.DisplayCapture;

{ TKeenViewExporter }

constructor TKeenViewExporter.Create(const AData: IKeenGameData; const AEncoder: IKeenImageEncoder;
  const AFiles: IFileStore);
begin
  inherited Create;
  if not Assigned(AData) then
    raise EArgumentNilException.Create('AData');
  if not Assigned(AEncoder) then
    raise EArgumentNilException.Create('AEncoder');
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  FData := AData;
  FEncoder := AEncoder;
  FFiles := AFiles;
end;

procedure TKeenViewExporter.SaveViewPicture(AMapNumber, AGlobalX, AGlobalY: Integer;
  const ASprites: array of TKeenViewSprite; const APath: string);
var
  LSprites: IKeenSpriteCache;
  LVideo: IKeenVideo;
  LRefresh: IKeenRefresh;
  LHandles: TArray<TKeenSpriteHandle>;
  LIndex: Integer;
  LBytes: TBytes;
begin
  LSprites := TKeenSpriteCache.Create(FData.Graphics);
  LVideo := TKeenVideo.Create(TKeenEgaMemory.Create, FData.Graphics, LSprites);
  LRefresh := TKeenRefresh.Create(LVideo, FData.Graphics, FData.Maps.TileInfo, LSprites, TKeenManualClock.Create);
  LRefresh.NewMap(TKeenWorkingMap.Create(FData.Maps.LoadMap(AMapNumber)));
  LRefresh.MarkTileGraphics;
  LRefresh.NewPosition(AGlobalX, AGlobalY);
  SetLength(LHandles, Length(ASprites));
  for LIndex := 0 to High(ASprites) do
    LRefresh.PlaceSprite(LHandles[LIndex], ASprites[LIndex].GlobalX, ASprites[LIndex].GlobalY,
      ASprites[LIndex].SpriteChunk, kdtSpriteDraw, ASprites[LIndex].Priority);
  // two refreshes: both pages have the whole view
  LRefresh.Refresh;
  LRefresh.Refresh;
  LBytes := FEncoder.Encode(TKeenDisplayCapture.CaptureVideo(LVideo));
  if not FFiles.Write(APath, @LBytes[0], Length(LBytes)) then
    raise EKeenException.CreateFmt(SKeenFileNotWritten, [APath]);
end;

end.
