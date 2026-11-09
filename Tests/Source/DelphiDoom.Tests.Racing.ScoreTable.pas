{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRacingScoreTableStore                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Racing.ScoreTable;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Racing.Types, DelphiDoom.Racing.Intf;

type
  [TestFixture]
  [Category('racing')]
  TTestRacingScoreTable = class(TObject)
  strict private
    FTable: IRacingScoreTable;
    function Score(ACarInfo, ALaps, ABaseLap: Integer): TRacingScore;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeAvereLeStesseDimensioniDelFileDelVecchioGioco;
    [Test]
    procedure DovrebbeAvereICampiDelRecordAgliStessiPosti;
    [Test]
    procedure DovrebbeEssereVuotaAllInizio;
    [Test]
    procedure DovrebbeMettereIGiriMigliori;
    [Test]
    procedure DovrebbeMettereLaGaraMigliore;
    [Test]
    procedure DovrebbeTenereLeTabelleOrdinate;
    [Test]
    procedure DovrebbeTenereSoloIDieciMigliori;
    [Test]
    procedure DovrebbeTenereSeparatePerFamigliaDiAuto;
    [Test]
    procedure DovrebbeIgnorareUnaPistaCheNonEsiste;
    [Test]
    procedure DovrebbeIgnorareUnNumeroDiGiriFuoriDalLimite;
    [Test]
    procedure DovrebbeTagliareIlNomeDelPilota;
    [Test]
    procedure DovrebbeDireSeUnTempoESUnRecordDelGiro;
    [Test]
    procedure DovrebbeDireDiNoSeLaTabellaHaTempiMigliori;
    [Test]
    procedure DovrebbeRifiutareUnaPistaCheNonEsisteNelControllo;
    [Test]
    procedure DovrebbeRileggereIlFileScritto;
    [Test]
    procedure DovrebbeRifiutareUnFileDiUnaDimensioneSbagliata;
    [Test]
    procedure DovrebbeSvuotareLeTabelle;
  end;

implementation

uses
  DelphiDoom.Racing.Factory;

{ TTestRacingScoreTable }

procedure TTestRacingScoreTable.Setup;
begin
  FTable := TRacingFactory.CreateScoreTable;
end;

function TTestRacingScoreTable.Score(ACarInfo, ALaps, ABaseLap: Integer): TRacingScore;
var
  LIndex: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Episode := 2;
  Result.Map := 3;
  Result.CarInfo := ACarInfo;
  Result.NumLaps := ALaps;
  for LIndex := 0 to ALaps - 1 do
  begin
    Result.LapTimes[LIndex] := ABaseLap + LIndex * 10;
    Inc(Result.TotalTime, Result.LapTimes[LIndex]);
  end;
end;

procedure TTestRacingScoreTable.DovrebbeAvereLeStesseDimensioniDelFileDelVecchioGioco;
begin
  Assert.AreEqual(32, SizeOf(TRacingScoreItem));
  Assert.AreEqual(230400, SizeOf(TRacingRecordTable));
  Assert.AreEqual(230400, Length(FTable.SaveToBytes));
end;

procedure TTestRacingScoreTable.DovrebbeAvereICampiDelRecordAgliStessiPosti;
var
  LItem: TRacingScoreItem;
begin
  Assert.AreEqual(20, Integer(NativeInt(@LItem.Time) - NativeInt(@LItem)));
  Assert.AreEqual(24, Integer(NativeInt(@LItem.CarId) - NativeInt(@LItem)));
  Assert.AreEqual(28, Integer(NativeInt(@LItem.Skill) - NativeInt(@LItem)));
end;

procedure TTestRacingScoreTable.DovrebbeEssereVuotaAllInizio;
var
  LIndex: Integer;
begin
  for LIndex := 0 to RACING_SCORES_PER_TABLE - 1 do
    Assert.AreEqual(0, FTable.Records.LapRecords[1, 1, TRacingCarType.Formula][LIndex].Time);
end;

procedure TTestRacingScoreTable.DovrebbeMettereIGiriMigliori;
begin
  FTable.Update(Score(3, 3, 1000), 'ANN', TRacingSkill.Hard);
  Assert.AreEqual(1000, FTable.Records.LapRecords[2, 3, TRacingCarType.Formula][0].Time);
  Assert.AreEqual(1010, FTable.Records.LapRecords[2, 3, TRacingCarType.Formula][1].Time);
  Assert.AreEqual(1020, FTable.Records.LapRecords[2, 3, TRacingCarType.Formula][2].Time);
  Assert.AreEqual(0, FTable.Records.LapRecords[2, 3, TRacingCarType.Formula][3].Time);
  Assert.AreEqual('ANN', string(FTable.Records.LapRecords[2, 3, TRacingCarType.Formula][0].DriverName));
  Assert.AreEqual(3, FTable.Records.LapRecords[2, 3, TRacingCarType.Formula][0].CarId);
  Assert.AreEqual(Ord(TRacingSkill.Hard), Integer(FTable.Records.LapRecords[2, 3, TRacingCarType.Formula][0].Skill));
end;

procedure TTestRacingScoreTable.DovrebbeMettereLaGaraMigliore;
begin
  FTable.Update(Score(3, 3, 1000), 'ANN', TRacingSkill.Hard);
  Assert.AreEqual(3030, FTable.Records.CourseRecords[3][2, 3, TRacingCarType.Formula][0].Time);
end;

procedure TTestRacingScoreTable.DovrebbeTenereLeTabelleOrdinate;
var
  LIndex: Integer;
begin
  FTable.Update(Score(3, 2, 2000), 'A', TRacingSkill.Easy);
  FTable.Update(Score(3, 2, 1500), 'B', TRacingSkill.Easy);
  FTable.Update(Score(3, 2, 1800), 'C', TRacingSkill.Easy);
  for LIndex := 1 to 5 do
    if FTable.Records.LapRecords[2, 3, TRacingCarType.Formula][LIndex].Time <> 0 then
      Assert.IsTrue(FTable.Records.LapRecords[2, 3, TRacingCarType.Formula][LIndex - 1].Time <=
        FTable.Records.LapRecords[2, 3, TRacingCarType.Formula][LIndex].Time);
  Assert.AreEqual('B', string(FTable.Records.CourseRecords[2][2, 3, TRacingCarType.Formula][0].DriverName));
end;

procedure TTestRacingScoreTable.DovrebbeTenereSoloIDieciMigliori;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 15 do
    FTable.Update(Score(3, 2, 5000 - LIndex * 100), 'P' + IntToStr(LIndex), TRacingSkill.Medium);
  // The best are 3500, 3510, 3600, 3610 ... 3900, 3910
  Assert.AreEqual(3500, FTable.Records.LapRecords[2, 3, TRacingCarType.Formula][0].Time);
  Assert.AreEqual(3910, FTable.Records.LapRecords[2, 3, TRacingCarType.Formula][RACING_SCORES_PER_TABLE - 1].Time);
end;

procedure TTestRacingScoreTable.DovrebbeTenereSeparatePerFamigliaDiAuto;
begin
  FTable.Update(Score(RACING_FORMULA_CAR_COUNT + 1, 2, 1000), 'ANN', TRacingSkill.Easy);
  Assert.AreEqual(1000, FTable.Records.LapRecords[2, 3, TRacingCarType.Stock][0].Time);
  Assert.AreEqual(0, FTable.Records.LapRecords[2, 3, TRacingCarType.Formula][0].Time);
end;

procedure TTestRacingScoreTable.DovrebbeIgnorareUnaPistaCheNonEsiste;
var
  LScore: TRacingScore;
begin
  LScore := Score(3, 2, 1000);
  LScore.Episode := 5;
  FTable.Update(LScore, 'ANN', TRacingSkill.Easy);
  LScore.Episode := 1;
  LScore.Map := 10;
  FTable.Update(LScore, 'ANN', TRacingSkill.Easy);
  LScore.Map := 0;
  FTable.Update(LScore, 'ANN', TRacingSkill.Easy);
  Assert.AreEqual(Int64(0), Int64(FTable.Records.LapRecords[1, 1, TRacingCarType.Formula][0].Time));
end;

procedure TTestRacingScoreTable.DovrebbeIgnorareUnNumeroDiGiriFuoriDalLimite;
begin
  FTable.Update(Score(3, 1, 1000), 'ANN', TRacingSkill.Easy);
  Assert.AreEqual(0, FTable.Records.LapRecords[2, 3, TRacingCarType.Formula][0].Time);
  FTable.Update(Score(3, 11, 1000), 'ANN', TRacingSkill.Easy);
  Assert.AreEqual(0, FTable.Records.LapRecords[2, 3, TRacingCarType.Formula][0].Time);
end;

procedure TTestRacingScoreTable.DovrebbeTagliareIlNomeDelPilota;
begin
  FTable.Update(Score(3, 2, 1000), 'A NAME THAT IS MUCH TOO LONG', TRacingSkill.Easy);
  Assert.AreEqual('A NAME THAT IS M', string(FTable.Records.LapRecords[2, 3, TRacingCarType.Formula][0].DriverName));
end;

procedure TTestRacingScoreTable.DovrebbeDireSeUnTempoESUnRecordDelGiro;
begin
  Assert.IsTrue(FTable.CheckLapRecord(2, 3, TRacingCarType.Formula, 99999));
  FTable.Update(Score(3, 2, 1000), 'ANN', TRacingSkill.Easy);
  // The table is not full: any time is good
  Assert.IsTrue(FTable.CheckLapRecord(2, 3, TRacingCarType.Formula, 99999));
end;

procedure TTestRacingScoreTable.DovrebbeDireDiNoSeLaTabellaHaTempiMigliori;
var
  LIndex: Integer;
begin
  for LIndex := 1 to 12 do
    FTable.Update(Score(3, 2, 1000 + LIndex), 'P', TRacingSkill.Easy);
  Assert.IsFalse(FTable.CheckLapRecord(2, 3, TRacingCarType.Formula, 5000));
  Assert.IsTrue(FTable.CheckLapRecord(2, 3, TRacingCarType.Formula, 900));
end;

procedure TTestRacingScoreTable.DovrebbeRifiutareUnaPistaCheNonEsisteNelControllo;
begin
  Assert.IsFalse(FTable.CheckLapRecord(0, 3, TRacingCarType.Formula, 1));
  Assert.IsFalse(FTable.CheckLapRecord(2, 10, TRacingCarType.Formula, 1));
  Assert.IsFalse(FTable.CheckLapRecord(2, 3, TRacingCarType.Any, 1));
end;

procedure TTestRacingScoreTable.DovrebbeRileggereIlFileScritto;
var
  LOther: IRacingScoreTable;
begin
  FTable.Update(Score(3, 3, 1000), 'ANN', TRacingSkill.Hard);
  LOther := TRacingFactory.CreateScoreTable;
  Assert.IsTrue(LOther.LoadFromBytes(FTable.SaveToBytes));
  Assert.AreEqual(1000, LOther.Records.LapRecords[2, 3, TRacingCarType.Formula][0].Time);
  Assert.AreEqual('ANN', string(LOther.Records.LapRecords[2, 3, TRacingCarType.Formula][0].DriverName));
end;

procedure TTestRacingScoreTable.DovrebbeRifiutareUnFileDiUnaDimensioneSbagliata;
var
  LBytes: TBytes;
begin
  FTable.Update(Score(3, 3, 1000), 'ANN', TRacingSkill.Hard);
  SetLength(LBytes, 100);
  Assert.IsFalse(FTable.LoadFromBytes(LBytes));
  // The old code left the tables empty
  Assert.AreEqual(0, FTable.Records.LapRecords[2, 3, TRacingCarType.Formula][0].Time);
end;

procedure TTestRacingScoreTable.DovrebbeSvuotareLeTabelle;
begin
  FTable.Update(Score(3, 3, 1000), 'ANN', TRacingSkill.Hard);
  FTable.Clear;
  Assert.AreEqual(0, FTable.Records.LapRecords[2, 3, TRacingCarType.Formula][0].Time);
end;

end.
