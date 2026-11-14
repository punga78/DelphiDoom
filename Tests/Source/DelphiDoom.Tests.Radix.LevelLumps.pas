{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixLevelLumpReader                                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.LevelLumps;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.Intf, DelphiDoom.Radix.Level.Types, DelphiDoom.Radix.LevelLogic.Types;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixLevelLumpReader = class(TObject)
  strict private
    FReader: IRadixLevelLumpReader;
    class function BytesOf(const ARecord; ASize: Integer): TBytes; static;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAvereIRecordDelleDimensioniDeiLump;
    [Test]
    procedure DovrebbeDareNessunaAzioneDaUnLumpVuoto;
    [Test]
    procedure DovrebbeLeggereLeAzioniConIParametri;
    [Test]
    procedure DovrebbeDareErroreSeLeAzioniNonSonoRecordInteri;
    [Test]
    procedure DovrebbeLeggereITriggerConLeLoroAzioni;
    [Test]
    procedure DovrebbeDareErroreSeUnTriggerHaTroppeAzioni;
    [Test]
    procedure DovrebbeDareUnaGrigliaSenzaTriggerDaUnLumpVuoto;
    [Test]
    procedure DovrebbeLeggereLaGrigliaELeSueDimensioni;
    [Test]
    procedure DovrebbeDareErroreSeLaGrigliaNonHaLeCelleGiuste;
    [Test]
    procedure DovrebbeDareErroreSeIlLumpDellaGrigliaECorto;
    [Test]
    procedure DovrebbeLeggereIPuntiDellaMappa;
    [Test]
    procedure DovrebbeDarePuntiAZeroDaUnLumpVuoto;
    [Test]
    procedure DovrebbeLeggereIDatiInPiuDelleCose;
    [Test]
    procedure DovrebbeDareErroreSeIDatiDelleCoseNonSonoRecordInteri;
  end;

  /// <summary>The lumps that the library writes for the levels of the real RADIX.DAT, read back</summary>
  [TestFixture]
  [Category('radix')]
  TTestRadixLevelLumpsRealData = class(TObject)
  strict private
    FWad: IInterface;
    FSkipReason: string;
    function FindData: string;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Test]
    procedure DovrebbeLeggereILumpDiOgniLivelloSenzaRiferimentiFuoriPosto;
    [Test]
    procedure DovrebbeTrovareLaFineDelLivelloInOgniLivello;
    [Test]
    procedure DovrebbeSvegliareLaFineDelPrimoLivelloDallaSuaCella;
  end;

implementation

uses
  System.IOUtils,
  DelphiDoom.GameData.Intf, DelphiDoom.Radix.Types, DelphiDoom.Radix.Factory,
  DelphiDoom.Radix.TriggerGrid, DelphiDoom.Radix.TriggerLogic, DelphiDoom.Tests.Shared.Skip;

const
  DOOM_THING_SIZE = 10;

{ TTestRadixLevelLumpReader }

class function TTestRadixLevelLumpReader.BytesOf(const ARecord; ASize: Integer): TBytes;
begin
  SetLength(Result, ASize);
  Move(ARecord, Result[0], ASize);
end;

procedure TTestRadixLevelLumpReader.Setup;
begin
  FReader := TRadixFactory.CreateLevelLumpReader;
end;

procedure TTestRadixLevelLumpReader.TearDown;
begin
  FReader := nil;
end;

procedure TTestRadixLevelLumpReader.DovrebbeAvereIRecordDelleDimensioniDeiLump;
begin
  Assert.AreEqual(168, Integer(SizeOf(TRadixLevelAction)));
  Assert.AreEqual(12, Integer(SizeOf(TRadixLevelTriggerAction)));
  Assert.AreEqual(1834, Integer(SizeOf(TRadixLevelTrigger)));
  Assert.AreEqual(8 + 2 * RADIX_GRID_SIZE, Integer(SizeOf(TRadixLevelGrid)));
  Assert.AreEqual(4 * RADIX_GRID_SIZE, Integer(SizeOf(TRadixLevelMapPoints)));
  Assert.AreEqual(10, Integer(SizeOf(TRadixDoomThingExtra)));
end;

procedure TTestRadixLevelLumpReader.DovrebbeDareNessunaAzioneDaUnLumpVuoto;
begin
  Assert.AreEqual(0, Integer(Length(FReader.ReadActions(nil))));
  Assert.AreEqual(0, Integer(Length(FReader.ReadTriggers(nil))));
  Assert.AreEqual(0, Integer(Length(FReader.ReadThingExtras(nil))));
end;

procedure TTestRadixLevelLumpReader.DovrebbeLeggereLeAzioniConIParametri;
var
  LSource: array[0..1] of TRadixLevelAction;
  LActions: TArray<TRadixLevelAction>;
begin
  FillChar(LSource, SizeOf(LSource), 0);
  LSource[0].Enabled := 1;
  LSource[0].ActionType := RADIX_ACTION_END_OF_LEVEL;
  LSource[0].Suspend := -1;
  LSource[0].Params[0] := 9;
  LSource[1].ActionType := RADIX_ACTION_PRINT_MESSAGE;
  LSource[1].NameId[0] := 'M';
  LSource[1].Params[63] := -7;
  LActions := FReader.ReadActions(BytesOf(LSource, SizeOf(LSource)));
  Assert.AreEqual(2, Integer(Length(LActions)));
  Assert.AreEqual(1, Integer(LActions[0].Enabled));
  Assert.AreEqual(RADIX_ACTION_END_OF_LEVEL, Integer(LActions[0].ActionType));
  Assert.AreEqual(-1, LActions[0].Suspend);
  Assert.AreEqual(9, Integer(LActions[0].Params[0]));
  Assert.AreEqual(RADIX_ACTION_PRINT_MESSAGE, Integer(LActions[1].ActionType));
  Assert.AreEqual(AnsiChar('M'), LActions[1].NameId[0]);
  Assert.AreEqual(-7, Integer(LActions[1].Params[63]));
end;

procedure TTestRadixLevelLumpReader.DovrebbeDareErroreSeLeAzioniNonSonoRecordInteri;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, SizeOf(TRadixLevelAction) + 1);
  Assert.WillRaise(
    procedure
    begin
      FReader.ReadActions(LBytes);
    end, ERadixException);
end;

procedure TTestRadixLevelLumpReader.DovrebbeLeggereITriggerConLeLoroAzioni;
var
  LSource: TRadixLevelTrigger;
  LTriggers: TArray<TRadixLevelTrigger>;
begin
  FillChar(LSource, SizeOf(LSource), 0);
  LSource.Suspended := 1;
  LSource.NumActions := 2;
  LSource.Actions[0].ActionId := 5;
  LSource.Actions[0].ActivationFlags := RADIX_TRIGGER_ACTIVATE;
  LSource.Actions[1].ActionId := 6;
  LSource.Actions[1].ActivationFlags := RADIX_TRIGGER_TOGGLE;
  LTriggers := FReader.ReadTriggers(BytesOf(LSource, SizeOf(LSource)));
  Assert.AreEqual(1, Integer(Length(LTriggers)));
  Assert.AreEqual(1, Integer(LTriggers[0].Suspended));
  Assert.AreEqual(2, LTriggers[0].NumActions);
  Assert.AreEqual(5, Integer(LTriggers[0].Actions[0].ActionId));
  Assert.AreEqual(6, Integer(LTriggers[0].Actions[1].ActionId));
  Assert.AreEqual(RADIX_TRIGGER_TOGGLE, Integer(LTriggers[0].Actions[1].ActivationFlags));
end;

procedure TTestRadixLevelLumpReader.DovrebbeDareErroreSeUnTriggerHaTroppeAzioni;
var
  LSource: TRadixLevelTrigger;
  LBytes: TBytes;
begin
  FillChar(LSource, SizeOf(LSource), 0);
  LSource.NumActions := RADIX_MAX_TRIGGER_ACTIONS + 1;
  LBytes := BytesOf(LSource, SizeOf(LSource));
  Assert.WillRaise(
    procedure
    begin
      FReader.ReadTriggers(LBytes);
    end, ERadixException);
end;

procedure TTestRadixLevelLumpReader.DovrebbeDareUnaGrigliaSenzaTriggerDaUnLumpVuoto;
var
  LGrid: TRadixTriggerGridData;
begin
  LGrid := FReader.ReadGrid(nil);
  Assert.AreEqual(0, LGrid.Width);
  Assert.AreEqual(0, LGrid.Height);
  Assert.AreEqual(RADIX_GRID_SIZE, Integer(Length(LGrid.Cells)));
  Assert.AreEqual(RADIX_NO_TRIGGER, Integer(LGrid.Cells[0]));
  Assert.AreEqual(RADIX_NO_TRIGGER, Integer(LGrid.Cells[RADIX_GRID_SIZE - 1]));
end;

procedure TTestRadixLevelLumpReader.DovrebbeLeggereLaGrigliaELeSueDimensioni;
var
  LBytes: TBytes;
  LSize: array[0..1] of Integer;
  LCell: SmallInt;
  LGrid: TRadixTriggerGridData;
begin
  SetLength(LBytes, SizeOf(TRadixLevelGrid));
  LSize[0] := 320;
  LSize[1] := 128;
  Move(LSize, LBytes[0], SizeOf(LSize));
  LCell := 17;
  Move(LCell, LBytes[8 + 2 * 321], SizeOf(LCell));
  LCell := -1;
  Move(LCell, LBytes[8], SizeOf(LCell));
  LGrid := FReader.ReadGrid(LBytes);
  Assert.AreEqual(320, LGrid.Width);
  Assert.AreEqual(128, LGrid.Height);
  Assert.AreEqual(-1, Integer(LGrid.Cells[0]));
  Assert.AreEqual(17, Integer(LGrid.Cells[321]));
  Assert.AreEqual(0, Integer(LGrid.Cells[322]));
end;

procedure TTestRadixLevelLumpReader.DovrebbeDareErroreSeLaGrigliaNonHaLeCelleGiuste;
var
  LBytes: TBytes;
  LSize: array[0..1] of Integer;
begin
  SetLength(LBytes, SizeOf(TRadixLevelGrid));
  LSize[0] := 100;
  LSize[1] := 100;
  Move(LSize, LBytes[0], SizeOf(LSize));
  Assert.WillRaise(
    procedure
    begin
      FReader.ReadGrid(LBytes);
    end, ERadixException);
end;

procedure TTestRadixLevelLumpReader.DovrebbeDareErroreSeIlLumpDellaGrigliaECorto;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, 100);
  Assert.WillRaise(
    procedure
    begin
      FReader.ReadGrid(LBytes);
    end, ERadixException);
  Assert.WillRaise(
    procedure
    begin
      FReader.ReadMapPoints(LBytes);
    end, ERadixException);
end;

procedure TTestRadixLevelLumpReader.DovrebbeLeggereIPuntiDellaMappa;
var
  LBytes: TBytes;
  LPoint: TRadixLevelMapPoint;
  LPoints: TArray<TRadixLevelMapPoint>;
begin
  SetLength(LBytes, SizeOf(TRadixLevelMapPoints));
  LPoint.X := -1200;
  LPoint.Y := 640;
  Move(LPoint, LBytes[4 * 7], SizeOf(LPoint));
  LPoints := FReader.ReadMapPoints(LBytes);
  Assert.AreEqual(RADIX_GRID_SIZE, Integer(Length(LPoints)));
  Assert.AreEqual(-1200, Integer(LPoints[7].X));
  Assert.AreEqual(640, Integer(LPoints[7].Y));
  Assert.AreEqual(0, Integer(LPoints[8].X));
end;

procedure TTestRadixLevelLumpReader.DovrebbeDarePuntiAZeroDaUnLumpVuoto;
var
  LPoints: TArray<TRadixLevelMapPoint>;
begin
  LPoints := FReader.ReadMapPoints(nil);
  Assert.AreEqual(RADIX_GRID_SIZE, Integer(Length(LPoints)));
  Assert.AreEqual(0, Integer(LPoints[0].X));
  Assert.AreEqual(0, Integer(LPoints[RADIX_GRID_SIZE - 1].Y));
end;

procedure TTestRadixLevelLumpReader.DovrebbeLeggereIDatiInPiuDelleCose;
var
  LSource: array[0..1] of TRadixDoomThingExtra;
  LExtras: TArray<TRadixDoomThingExtra>;
begin
  FillChar(LSource, SizeOf(LSource), 0);
  LSource[0].Z := 96;
  LSource[0].RadixId := 12;
  LSource[1].Speed := 3;
  LSource[1].HeightSpeed := -2;
  LSource[1].RadixSkill := 2;
  LExtras := FReader.ReadThingExtras(BytesOf(LSource, SizeOf(LSource)));
  Assert.AreEqual(2, Integer(Length(LExtras)));
  Assert.AreEqual(96, Integer(LExtras[0].Z));
  Assert.AreEqual(12, Integer(LExtras[0].RadixId));
  Assert.AreEqual(3, Integer(LExtras[1].Speed));
  Assert.AreEqual(-2, Integer(LExtras[1].HeightSpeed));
  Assert.AreEqual(2, Integer(LExtras[1].RadixSkill));
end;

procedure TTestRadixLevelLumpReader.DovrebbeDareErroreSeIDatiDelleCoseNonSonoRecordInteri;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, 15);
  Assert.WillRaise(
    procedure
    begin
      FReader.ReadThingExtras(LBytes);
    end, ERadixException);
end;

{ TTestRadixLevelLumpsRealData }

function TTestRadixLevelLumpsRealData.FindData: string;
const
  DATA_FILE = 'Reference\_dati\radix\v20\game\RADIX.DAT';
var
  LRoot: string;
  LCandidate: string;
begin
  LRoot := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), '..\..\..\..'));
  // the worktrees of the repository are under .claude\worktrees\<name>
  for LCandidate in TArray<string>.Create(TPath.Combine(LRoot, DATA_FILE),
    TPath.GetFullPath(TPath.Combine(LRoot, '..\..\..\' + DATA_FILE))) do
    if TFile.Exists(LCandidate) then
      Exit(LCandidate);
  Result := '';
end;

procedure TTestRadixLevelLumpsRealData.SetupFixture;
var
  LPath: string;
begin
  FWad := nil;
  LPath := FindData;
  if LPath = '' then
  begin
    FSkipReason := 'RADIX.DAT (2.0 shareware) non c''e'': i dati del gioco non stanno nel repository';
    Exit;
  end;
  FWad := TRadixFactory.CreateTranslator.Translate(TRadixFactory.OpenContainer(LPath));
end;

procedure TTestRadixLevelLumpsRealData.TearDownFixture;
begin
  FWad := nil;
end;

procedure TTestRadixLevelLumpsRealData.DovrebbeLeggereILumpDiOgniLivelloSenzaRiferimentiFuoriPosto;
var
  LWad: IGameWadComposer;
  LReader: IRadixLevelLumpReader;
  LIndex: Integer;
  LCell: Integer;
  LItem: Integer;
  LLevels: Integer;
  LThings: Integer;
  LName: string;
  LActions: TArray<TRadixLevelAction>;
  LTriggers: TArray<TRadixLevelTrigger>;
  LGrid: TRadixTriggerGridData;
  LPoints: TArray<TRadixLevelMapPoint>;
  LWhere: string;
begin
  if not Assigned(FWad) then
  begin
    TTestSkip.Ignore(FSkipReason);
    Exit;
  end;
  LWad := FWad as IGameWadComposer;
  LReader := TRadixFactory.CreateLevelLumpReader;
  LLevels := 0;
  LThings := -1;
  LActions := nil;
  LGrid.Width := 0;
  for LIndex := 0 to LWad.Count - 1 do
  begin
    LName := LWad.LumpNames[LIndex];
    LWhere := Format('%s of the level %d', [LName, LLevels + 1]);
    if LName = 'THINGS' then
      LThings := Length(LWad.LumpData[LIndex]) div DOOM_THING_SIZE
    else if LName = 'RTHINGS' then
      Assert.AreEqual(LThings, Integer(Length(LReader.ReadThingExtras(LWad.LumpData[LIndex]))), LWhere)
    else if LName = 'RGRID' then
    begin
      LGrid := LReader.ReadGrid(LWad.LumpData[LIndex]);
      Assert.AreEqual(RADIX_GRID_SIZE, LGrid.Width * LGrid.Height, LWhere);
    end
    else if LName = 'RMAPGRID' then
    begin
      LPoints := LReader.ReadMapPoints(LWad.LumpData[LIndex]);
      Assert.AreEqual(RADIX_GRID_SIZE, Integer(Length(LPoints)), LWhere);
    end
    else if LName = 'RACTION' then
    begin
      LActions := LReader.ReadActions(LWad.LumpData[LIndex]);
      Assert.IsTrue(Length(LActions) > 0, LWhere);
      for LItem := 0 to High(LActions) do
        Assert.IsTrue((LActions[LItem].ActionType >= 0) and (LActions[LItem].ActionType < RADIX_ACTION_KINDS),
          Format('%s: action %d of kind %d', [LWhere, LItem, LActions[LItem].ActionType]));
    end
    else if LName = 'RTRIGGER' then
    begin
      LTriggers := LReader.ReadTriggers(LWad.LumpData[LIndex]);
      Assert.IsTrue(Length(LTriggers) > 0, LWhere);
      for LItem := 0 to High(LTriggers) do
        for LCell := 0 to LTriggers[LItem].NumActions - 1 do
          Assert.IsTrue((LTriggers[LItem].Actions[LCell].ActionId >= 0) and
            (LTriggers[LItem].Actions[LCell].ActionId < Length(LActions)),
            Format('%s: trigger %d names the action %d', [LWhere, LItem, LTriggers[LItem].Actions[LCell].ActionId]));
      // RTRIGGER is the last lump of a level: the grid of the same level is already read
      for LCell := 0 to RADIX_GRID_SIZE - 1 do
        Assert.IsTrue((LGrid.Cells[LCell] >= RADIX_NO_TRIGGER) and (LGrid.Cells[LCell] < Length(LTriggers)),
          Format('%s: the cell %d names the trigger %d', [LWhere, LCell, LGrid.Cells[LCell]]));
      Inc(LLevels);
    end;
  end;
  // the shareware has the nine levels of the first episode
  Assert.AreEqual(9, LLevels);
end;

procedure TTestRadixLevelLumpsRealData.DovrebbeTrovareLaFineDelLivelloInOgniLivello;
var
  LWad: IGameWadComposer;
  LReader: IRadixLevelLumpReader;
  LIndex: Integer;
  LLevels: Integer;
  LActions: TArray<TRadixLevelAction>;
  LLogic: TRadixTriggerLogic;
begin
  if not Assigned(FWad) then
  begin
    TTestSkip.Ignore(FSkipReason);
    Exit;
  end;
  LWad := FWad as IGameWadComposer;
  LReader := TRadixFactory.CreateLevelLumpReader;
  LLevels := 0;
  LActions := nil;
  for LIndex := 0 to LWad.Count - 1 do
    if LWad.LumpNames[LIndex] = 'RACTION' then
      LActions := LReader.ReadActions(LWad.LumpData[LIndex])
    else if LWad.LumpNames[LIndex] = 'RTRIGGER' then
    begin
      LLogic := TRadixTriggerLogic.Create(LActions, LReader.ReadTriggers(LWad.LumpData[LIndex]), 1);
      try
        Inc(LLevels);
        Assert.IsTrue(LLogic.HasActionOfKind(RADIX_ACTION_END_OF_LEVEL),
          Format('the level %d has no end of level action', [LLevels]));
      finally
        LLogic.Free;
      end;
    end;
  Assert.AreEqual(9, LLevels);
end;

procedure TTestRadixLevelLumpsRealData.DovrebbeSvegliareLaFineDelPrimoLivelloDallaSuaCella;
var
  LWad: IGameWadComposer;
  LReader: IRadixLevelLumpReader;
  LIndex: Integer;
  LCell: Integer;
  LExitCell: Integer;
  LEmptyCell: Integer;
  LAction: Integer;
  LGridData: TRadixTriggerGridData;
  LActions: TArray<TRadixLevelAction>;
  LTriggers: TArray<TRadixLevelTrigger>;
  LGrid: TRadixTriggerGrid;
  LLogic: TRadixTriggerLogic;
  LCells: TRadixGridPositions;
  LRunning: Boolean;
begin
  if not Assigned(FWad) then
  begin
    TTestSkip.Ignore(FSkipReason);
    Exit;
  end;
  LWad := FWad as IGameWadComposer;
  LReader := TRadixFactory.CreateLevelLumpReader;
  // the lumps of the first level are the first ones of each name
  LTriggers := nil;
  for LIndex := 0 to LWad.Count - 1 do
    if LWad.LumpNames[LIndex] = 'RGRID' then
      LGridData := LReader.ReadGrid(LWad.LumpData[LIndex])
    else if LWad.LumpNames[LIndex] = 'RACTION' then
      LActions := LReader.ReadActions(LWad.LumpData[LIndex])
    else if LWad.LumpNames[LIndex] = 'RTRIGGER' then
    begin
      LTriggers := LReader.ReadTriggers(LWad.LumpData[LIndex]);
      Break;
    end;
  Assert.IsTrue(Length(LTriggers) > 0);

  LGrid := TRadixTriggerGrid.Create(LGridData, nil);
  LLogic := TRadixTriggerLogic.Create(LActions, LTriggers, 1);
  try
    // no end of level runs before the craft gets there
    LAction := LLogic.NextRunnable(0);
    while LAction < LLogic.ActionCount do
    begin
      Assert.AreNotEqual(RADIX_ACTION_END_OF_LEVEL, Integer(LLogic.Action(LAction).ActionType));
      LAction := LLogic.NextRunnable(LAction + 1);
    end;

    LExitCell := -1;
    LEmptyCell := -1;
    for LCell := 0 to RADIX_GRID_SIZE - 1 do
      if LGrid.TriggerAt(LCell) = RADIX_NO_TRIGGER then
        LEmptyCell := LCell
      else if (LExitCell < 0) and
        LLogic.TriggerHasActionOfKind(LGrid.TriggerAt(LCell), RADIX_ACTION_END_OF_LEVEL) then
        LExitCell := LCell;
    Assert.IsTrue(LExitCell >= 0, 'no cell of the grid ends the level');
    Assert.IsTrue(LEmptyCell >= 0);

    LCells := TRadixGridPositions.Empty;
    LCells.Add(LEmptyCell);
    LCells.Add(LExitCell);
    Assert.AreEqual(1, LLogic.PlayerCrosses(0, LGrid, LCells));

    LRunning := False;
    LAction := LLogic.NextRunnable(0);
    while LAction < LLogic.ActionCount do
    begin
      if LLogic.Action(LAction).ActionType = RADIX_ACTION_END_OF_LEVEL then
        LRunning := True;
      LAction := LLogic.NextRunnable(LAction + 1);
    end;
    Assert.IsTrue(LRunning, 'the end of level action does not run after its cell');
  finally
    LLogic.Free;
    LGrid.Free;
  end;
end;

end.
