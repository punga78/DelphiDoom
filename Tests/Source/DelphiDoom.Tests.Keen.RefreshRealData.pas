{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the refresh manager with the data    }
{  of the real game (shareware 1.13): the screen has to be the map             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.RefreshRealData;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenRefreshRealData = class(TObject)
  strict private
    FData: IKeenGameData;
    FVideo: IKeenVideo;
    FRefresh: IKeenRefresh;
    FMap: IKeenWorkingMap;
    FFirstX: Integer;
    FFirstY: Integer;
    function OpenGame: Boolean;
    procedure Start(AMapNumber: Integer);
    function Differences: Integer;
    procedure ExpectNoDifferences(const AWhat: string);
  public
    [Test]
    procedure DovrebbeMostrareLaMappaDelMondo;
    [Test]
    procedure DovrebbeScorrereLaMappaDelMondoComeLaMappaIntera;
    [Test]
    procedure DovrebbeMostrareOgniLivelloDelloShareware;
  end;

implementation

uses
  DelphiDoom.Keen.EgaMemory, DelphiDoom.Keen.Video, DelphiDoom.Keen.SpriteCache, DelphiDoom.Keen.WorkingMap,
  DelphiDoom.Keen.Refresh, DelphiDoom.Keen.Map, DelphiDoom.Keen.MapRenderer, DelphiDoom.Keen.DisplayCapture,
  DelphiDoom.Keen.ManualClock, DelphiDoom.Keen.Factory, DelphiDoom.Tests.Keen.RealData;

{ TTestKeenRefreshRealData }

function TTestKeenRefreshRealData.OpenGame: Boolean;
var
  LFiles: IKeenDataFiles;
begin
  LFiles := TKeenRealData.OpenFiles;
  Result := Assigned(LFiles);
  if Result then
    FData := TKeenFactory.OpenGameData(LFiles);
end;

procedure TTestKeenRefreshRealData.Start(AMapNumber: Integer);
var
  LSprites: IKeenSpriteCache;
begin
  LSprites := TKeenSpriteCache.Create(FData.Graphics);
  FVideo := TKeenVideo.Create(TKeenEgaMemory.Create, FData.Graphics, LSprites);
  FRefresh := TKeenRefresh.Create(FVideo, FData.Graphics, FData.Maps.TileInfo, LSprites, TKeenManualClock.Create);
  FMap := TKeenWorkingMap.Create(FData.Maps.LoadMap(AMapNumber));
  FRefresh.NewMap(FMap);
  FRefresh.MarkTileGraphics;
end;

function TTestKeenRefreshRealData.Differences: Integer;
var
  LHeader: TKeenMapHeader;
  LFile: IKeenMap;
  LFull: TKeenChunkyImage;
  LActual: TKeenChunkyImage;
  LStartX: Integer;
  LStartY: Integer;
  LX: Integer;
  LY: Integer;
begin
  FillChar(LHeader, SizeOf(LHeader), 0);
  LHeader.Width := FMap.Width;
  LHeader.Height := FMap.Height;
  LFile := TKeenMap.Create(0, LHeader, [Copy(FMap.Planes[0]), Copy(FMap.Planes[1]), Copy(FMap.Planes[2])]);
  LFull := TKeenMapRenderer.Create.Render(LFile, FData.Graphics);
  LActual := TKeenDisplayCapture.CaptureVideo(FVideo);
  LStartX := FRefresh.OriginXTile * 16 + (FVideo.PanX and 14);
  LStartY := FRefresh.OriginYTile * 16 + FVideo.PanY;
  Result := 0;
  for LY := 0 to KEEN_DISPLAY_HEIGHT - 1 do
    for LX := 0 to KEEN_DISPLAY_WIDTH - 1 do
      if LActual.Pixels[LY * KEEN_DISPLAY_WIDTH + LX] <> LFull.Pixels[(LStartY + LY) * LFull.Width + LStartX + LX] then
      begin
        if Result = 0 then
        begin
          FFirstX := LX;
          FFirstY := LY;
        end;
        Inc(Result);
      end;
end;

procedure TTestKeenRefreshRealData.ExpectNoDifferences(const AWhat: string);
var
  LCount: Integer;
  LTileX: Integer;
  LTileY: Integer;
begin
  LCount := Differences;
  if LCount <> 0 then
  begin
    LTileX := FRefresh.OriginXTile + (FFirstX + (FVideo.PanX and 14)) div 16;
    LTileY := FRefresh.OriginYTile + (FFirstY + FVideo.PanY) div 16;
    Assert.Fail(Format('%s: %d pixels differ, the first at (%d, %d), tile (%d, %d) back %d front %d, origin (%d, %d) pan (%d, %d)',
      [AWhat, LCount, FFirstX, FFirstY, LTileX, LTileY, FMap.Planes[0][LTileY * FMap.Width + LTileX],
       FMap.Planes[1][LTileY * FMap.Width + LTileX], FRefresh.OriginXTile, FRefresh.OriginYTile, FVideo.PanX,
       FVideo.PanY]));
  end;
end;

procedure TTestKeenRefreshRealData.DovrebbeMostrareLaMappaDelMondo;
begin
  if not OpenGame then
  begin
    Assert.Pass('I dati di Keen Dreams 1.13 non ci sono su questo PC: prova saltata');
    Exit;
  end;
  Start(0);
  FRefresh.NewPosition(2 * 256, 2 * 256);
  FRefresh.Refresh;
  ExpectNoDifferences('the world map');
end;

procedure TTestKeenRefreshRealData.DovrebbeScorrereLaMappaDelMondoComeLaMappaIntera;
var
  LStep: Integer;
  LDeltaX: Integer;
  LDeltaY: Integer;
begin
  if not OpenGame then
  begin
    Assert.Pass('I dati di Keen Dreams 1.13 non ci sono su questo PC: prova saltata');
    Exit;
  end;
  Start(0);
  FRefresh.NewPosition(8 * 256, 10 * 256);
  FRefresh.Refresh;
  LDeltaX := 23;
  LDeltaY := 11;
  for LStep := 1 to 500 do
  begin
    if LStep mod 50 = 0 then
    begin
      LDeltaX := -LDeltaX;
      LDeltaY := -LDeltaY + 7;
    end;
    FRefresh.Scroll(LDeltaX, LDeltaY);
    FRefresh.Refresh;
    if LStep mod 5 = 0 then
      ExpectNoDifferences('step ' + IntToStr(LStep));
  end;
end;

procedure TTestKeenRefreshRealData.DovrebbeMostrareOgniLivelloDelloShareware;
var
  LNumber: Integer;
  LCount: Integer;
begin
  if not OpenGame then
  begin
    Assert.Pass('I dati di Keen Dreams 1.13 non ci sono su questo PC: prova saltata');
    Exit;
  end;
  LCount := 0;
  for LNumber in FData.Maps.MapNumbers do
  begin
    Start(LNumber);
    FRefresh.NewPosition(0, 0);
    FRefresh.Refresh;
    // the top left corner, then the middle and the bottom right
    ExpectNoDifferences('map ' + IntToStr(LNumber) + ' at the corner');
    FRefresh.Scroll((FMap.Width div 2) * 256 - FRefresh.OriginXGlobal, (FMap.Height div 2) * 256 - FRefresh.OriginYGlobal);
    FRefresh.Refresh;
    ExpectNoDifferences('map ' + IntToStr(LNumber) + ' at the middle');
    FRefresh.NewPosition(FMap.Width * 256, FMap.Height * 256);
    FRefresh.Refresh;
    ExpectNoDifferences('map ' + IntToStr(LNumber) + ' at the end');
    Inc(LCount);
  end;
  Assert.AreEqual(18, LCount);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenRefreshRealData);

end.
