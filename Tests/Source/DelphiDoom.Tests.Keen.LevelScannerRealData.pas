{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the actors of the levels of the      }
{  real game (shareware 1.13)                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.LevelScannerRealData;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenLevelScannerRealData = class(TObject)
  strict private
    FData: IKeenGameData;
    function OpenGame: Boolean;
    function CountCalls(const ACalls: TArray<string>; const APrefix: string): Integer;
  public
    [Test]
    procedure DovrebbeMettereUnSoloKeenInOgniLivello;
    [Test]
    procedure DovrebbeMettereUnSoloKeenDelMondoNellaMappaDelMondo;
    [Test]
    procedure DovrebbeStareNeiCentoAttoriInOgniLivello;
    [Test]
    procedure DovrebbeFarDormireTuttiGliAttoriTranneKeen;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.Factory, DelphiDoom.Keen.WorkingMap,
  DelphiDoom.Keen.ObjectList, DelphiDoom.Keen.Refresh, DelphiDoom.Keen.Video, DelphiDoom.Keen.EgaMemory,
  DelphiDoom.Keen.SpriteCache, DelphiDoom.Keen.ManualClock, DelphiDoom.Keen.LevelScanner, DelphiDoom.Tests.Keen.RealData,
  DelphiDoom.Tests.Keen.GameFakes;

{ TTestKeenLevelScannerRealData }

function TTestKeenLevelScannerRealData.OpenGame: Boolean;
var
  LFiles: IKeenDataFiles;
begin
  LFiles := TKeenRealData.OpenFiles;
  Result := Assigned(LFiles);
  if Result then
    FData := TKeenFactory.OpenGameData(LFiles);
end;

function TTestKeenLevelScannerRealData.CountCalls(const ACalls: TArray<string>; const APrefix: string): Integer;
var
  LCall: string;
begin
  Result := 0;
  for LCall in ACalls do
    if LCall.StartsWith(APrefix) then
      Inc(Result);
end;

procedure TTestKeenLevelScannerRealData.DovrebbeMettereUnSoloKeenInOgniLivello;
var
  LNumber: Integer;
  LSprites: IKeenSpriteCache;
  LRefresh: IKeenRefresh;
  LObjects: IKeenObjectList;
  LSpawner: TFakeKeenSpawner;
  LSpawnerIntf: IKeenActorSpawner;
  LScanner: TKeenLevelScanner;
begin
  if not OpenGame then
  begin
    Assert.Pass('I dati di Keen Dreams 1.13 non ci sono su questo PC: prova saltata');
    Exit;
  end;
  LSprites := TKeenSpriteCache.Create(FData.Graphics);
  LRefresh := TKeenRefresh.Create(TKeenVideo.Create(TKeenEgaMemory.Create, FData.Graphics, LSprites), FData.Graphics,
    FData.Maps.TileInfo, LSprites, TKeenManualClock.Create);
  LObjects := TKeenObjectList.Create(LRefresh);
  LSpawner := TFakeKeenSpawner.Create(LObjects);
  LSpawnerIntf := LSpawner;
  LScanner := TKeenLevelScanner.Create(LObjects, LSpawnerIntf);
  try
    for LNumber in FData.Maps.MapNumbers do
    begin
      if (LNumber = 0) or (LNumber = KEEN_TITLE_MAP) then
        Continue;
      LSpawner.Calls.Clear;
      LScanner.ScanInfoPlane(TKeenWorkingMap.Create(FData.Maps.LoadMap(LNumber)));
      // the number 1 or 2 of the info plane is where Keen starts: once
      Assert.AreEqual(1, CountCalls(LSpawner.Calls.ToArray, 'keen '), 'map ' + IntToStr(LNumber));
    end;
  finally
    LScanner.Free;
  end;
end;

procedure TTestKeenLevelScannerRealData.DovrebbeMettereUnSoloKeenDelMondoNellaMappaDelMondo;
var
  LSprites: IKeenSpriteCache;
  LRefresh: IKeenRefresh;
  LObjects: IKeenObjectList;
  LSpawner: TFakeKeenSpawner;
  LSpawnerIntf: IKeenActorSpawner;
  LScanner: TKeenLevelScanner;
begin
  if not OpenGame then
  begin
    Assert.Pass('I dati di Keen Dreams 1.13 non ci sono su questo PC: prova saltata');
    Exit;
  end;
  LSprites := TKeenSpriteCache.Create(FData.Graphics);
  LRefresh := TKeenRefresh.Create(TKeenVideo.Create(TKeenEgaMemory.Create, FData.Graphics, LSprites), FData.Graphics,
    FData.Maps.TileInfo, LSprites, TKeenManualClock.Create);
  LObjects := TKeenObjectList.Create(LRefresh);
  LSpawner := TFakeKeenSpawner.Create(LObjects);
  LSpawnerIntf := LSpawner;
  LScanner := TKeenLevelScanner.Create(LObjects, LSpawnerIntf);
  try
    LScanner.ScanInfoPlane(TKeenWorkingMap.Create(FData.Maps.LoadMap(0)));
    Assert.AreEqual(1, CountCalls(LSpawner.Calls.ToArray, 'worldkeen '));
    Assert.AreEqual(0, CountCalls(LSpawner.Calls.ToArray, 'keen '));
    Assert.IsTrue(LScanner.LumpNeeded(KEEN_LUMP_WORLDKEEN));
  finally
    LScanner.Free;
  end;
end;

procedure TTestKeenLevelScannerRealData.DovrebbeStareNeiCentoAttoriInOgniLivello;
var
  LNumber: Integer;
  LSprites: IKeenSpriteCache;
  LRefresh: IKeenRefresh;
  LObjects: IKeenObjectList;
  LSpawner: TFakeKeenSpawner;
  LSpawnerIntf: IKeenActorSpawner;
  LScanner: TKeenLevelScanner;
  LMost: Integer;
begin
  if not OpenGame then
  begin
    Assert.Pass('I dati di Keen Dreams 1.13 non ci sono su questo PC: prova saltata');
    Exit;
  end;
  LSprites := TKeenSpriteCache.Create(FData.Graphics);
  LRefresh := TKeenRefresh.Create(TKeenVideo.Create(TKeenEgaMemory.Create, FData.Graphics, LSprites), FData.Graphics,
    FData.Maps.TileInfo, LSprites, TKeenManualClock.Create);
  LObjects := TKeenObjectList.Create(LRefresh);
  LSpawner := TFakeKeenSpawner.Create(LObjects);
  LSpawnerIntf := LSpawner;
  LScanner := TKeenLevelScanner.Create(LObjects, LSpawnerIntf);
  try
    LMost := 0;
    for LNumber in FData.Maps.MapNumbers do
    begin
      if LNumber = KEEN_TITLE_MAP then
        Continue;
      // the list has room for 100 actors; a level that has more stops the game (the C: "No free spots")
      LScanner.ScanInfoPlane(TKeenWorkingMap.Create(FData.Maps.LoadMap(LNumber)));
      if LObjects.Count > LMost then
        LMost := LObjects.Count;
      Assert.IsTrue(LObjects.Count <= KEEN_MAXACTORS, 'map ' + IntToStr(LNumber));
    end;
    Assert.IsTrue(LMost > 20, 'the levels have actors');
  finally
    LScanner.Free;
  end;
end;

procedure TTestKeenLevelScannerRealData.DovrebbeFarDormireTuttiGliAttoriTranneKeen;
var
  LSprites: IKeenSpriteCache;
  LRefresh: IKeenRefresh;
  LObjects: IKeenObjectList;
  LSpawner: TFakeKeenSpawner;
  LSpawnerIntf: IKeenActorSpawner;
  LScanner: TKeenLevelScanner;
  LObject: PKeenObject;
  LAwake: Integer;
begin
  if not OpenGame then
  begin
    Assert.Pass('I dati di Keen Dreams 1.13 non ci sono su questo PC: prova saltata');
    Exit;
  end;
  LSprites := TKeenSpriteCache.Create(FData.Graphics);
  LRefresh := TKeenRefresh.Create(TKeenVideo.Create(TKeenEgaMemory.Create, FData.Graphics, LSprites), FData.Graphics,
    FData.Maps.TileInfo, LSprites, TKeenManualClock.Create);
  LObjects := TKeenObjectList.Create(LRefresh);
  LSpawner := TFakeKeenSpawner.Create(LObjects);
  LSpawnerIntf := LSpawner;
  LScanner := TKeenLevelScanner.Create(LObjects, LSpawnerIntf);
  try
    // the fake spawner gives "yes": the scanner makes them all asleep
    LScanner.ScanInfoPlane(TKeenWorkingMap.Create(FData.Maps.LoadMap(1)));
    LAwake := 0;
    LObject := LObjects.First;
    while Assigned(LObject) do
    begin
      if LObject^.Active <> kaNo then
        Inc(LAwake);
      LObject := LObjects.NextOf(LObject);
    end;
    // the player and the score box are made by the list before the scan, awake (SpawnKeen and SpawnScore take them)
    Assert.AreEqual(2, LAwake);
  finally
    LScanner.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenLevelScannerRealData);

end.
