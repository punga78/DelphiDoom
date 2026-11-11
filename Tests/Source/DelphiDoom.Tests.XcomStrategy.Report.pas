{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the xcom strategy library - the monthly report of  }
{  the council on the real saved games, against what the real OpenXcom did      }
{  (simgen report: the code of MonthlyReportState::calculateChanges and of the  }
{  judgment of its constructor, on the real objects)                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (the library itself is derived from OpenXcom, GPL v3 or later)               }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.XcomStrategy.Report;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.XcomMod.Random, DelphiDoom.XcomSave.SavedGame,
  DelphiDoom.XcomSave.Region, DelphiDoom.XcomSave.Country, DelphiDoom.XcomSave.BaseCapacity,
  DelphiDoom.XcomStrategy.MonthlyReport, DelphiDoom.Tests.XcomSave.Sim;

type
  [TestFixture]
  [Category('xcom-strategy')]
  [Category('xcom-strategy-sim')]
  TTestXcomMonthlyReport = class(TObject)
  strict private
    FSim: TXcomSim;
    FRandom: IXcomRandom;
    function Pick(AValue: Integer): Integer;
    function Join(const AValues: TArray<string>): string;
  public
    [SetupFixture]
    procedure SetupFixture;
    [TearDownFixture]
    procedure TearDownFixture;
    [Test]
    procedure DovrebbeFareLoStessoRapportoMensileDelVeroOpenXcom;
  end;

implementation

{ TTestXcomMonthlyReport }

procedure TTestXcomMonthlyReport.SetupFixture;
begin
  FSim := TXcomSim.Create;
end;

procedure TTestXcomMonthlyReport.TearDownFixture;
begin
  FSim.Free;
end;

function TTestXcomMonthlyReport.Pick(AValue: Integer): Integer;
begin
  if AValue <= 0 then
    Result := 0
  else
    Result := FRandom.Generate(0, AValue - 1);
end;

function TTestXcomMonthlyReport.Join(const AValues: TArray<string>): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to High(AValues) do
  begin
    if LIndex > 0 then
      Result := Result + ',';
    Result := Result + AValues[LIndex];
  end;
end;

procedure TTestXcomMonthlyReport.DovrebbeFareLoStessoRapportoMensileDelVeroOpenXcom;
var
  LFolder: string;
  LVariant, LMonth: Integer;
  LGame: TXcomSavedGame;
  LRegion: TXcomRegion;
  LCountry: TXcomCountry;
  LLines: TStringList;
  LCapacity: TXcomBaseCapacity;
  LReport: TXcomMonthlyReport;
  LResult: TXcomMonthlyReportResult;
  LMaintenance: Int64;
  LHigh, LLow, LUfo: Integer;
begin
  LFolder := TXcomSim.GoldenFolder('XcomSave\sim');
  if not FSim.Available or (LFolder = '') then
  begin
    Assert.Pass('senza i dati di TFTD o i golden il confronto non si fa');
    Exit;
  end;
  LLines := TStringList.Create;
  LCapacity := TXcomBaseCapacity.Create(FSim.Ruleset);
  try
    for LVariant := 0 to 15 do
    begin
      LLines.Clear;
      FRandom := TXcomRandom.Create(1);
      try
        LGame := FSim.LoadSave(LVariant, FRandom);
      except
        on E: Exception do
          raise Exception.CreateFmt('salvataggio %d: %s', [LVariant, E.Message]);
      end;
      try
        FRandom.SetSeed(5000 + LVariant);
        // the UFOs with no mission and no trajectory cannot be saved after a month: the scenario removes them
        for LUfo := LGame.Ufos.Count - 1 downto 0 do
          if (LGame.Ufos[LUfo].Mission = nil) or (LGame.Ufos[LUfo].Trajectory = nil) then
            LGame.Ufos.Delete(LUfo);
        LReport :=TXcomMonthlyReport.Create(LGame, FSim.Ruleset, FRandom);
        try
          for LMonth := 0 to 5 do
          begin
            for LRegion in LGame.Regions do
            begin
              LRegion.AddActivityAlien(Pick(400));
              LRegion.AddActivityXcom(Pick(400));
            end;
            for LCountry in LGame.Countries do
            begin
              LCountry.AddActivityAlien(Pick(300));
              LCountry.AddActivityXcom(Pick(300));
            end;
            if Pick(2) = 0 then
              LGame.AddResearchScore(Pick(300));
            LGame.AddMonth;
            LMaintenance := LCapacity.BaseMaintenance(LGame);
            LGame.MonthlyFunding(Integer(LMaintenance));
            // the C++ evaluates the two Pick of the expression one after the other, left to right
            LHigh := Pick(7) - 3;
            LLow := Pick(1000);
            LGame.SetFunds(Int64(LHigh) * 1000000 + LLow);
            LResult := LReport.Calculate;
            LLines.Add(Format('report|%d|%d|rating=%d|last=%d|diff=%d|%s|%s|debts=%d|over=%d|income=%d|maintenance=%d|' +
              'funds=%d|happy=%s|sad=%s|pact=%s|infiltration=%s', [LVariant, LMonth, LResult.RatingTotal,
              LResult.LastMonthsRating, LResult.FundingDiff, LResult.Rating, LResult.Satisfaction, Ord(LResult.Debts),
              Ord(LResult.GameOver), LGame.CountryFunding, LCapacity.BaseMaintenance(LGame), LGame.Funds,
              Join(LResult.Happy), Join(LResult.Sad), Join(LResult.Pact), LResult.Infiltration]));
          end;
        finally
          LReport.Free;
        end;
        LLines.Add(Format('rng|%d|%s', [LVariant, UIntToStr(FRandom.Seed)]));
        Assert.AreEqual('', TXcomSim.FirstDifference(string(TXcomSim.GoldenText(LFolder +
          Format('sim%.2d.report.txt', [LVariant]))), LLines.Text), Format('risposte del salvataggio %d', [LVariant]));
        Assert.AreEqual('', TXcomSim.SaveDifference(TXcomSim.GoldenText(LFolder + Format('sim%.2d.report.sav',
          [LVariant])), FSim.SaveText(LGame, FRandom)), Format('stato finale del salvataggio %d', [LVariant]));
      finally
        LGame.Free;
      end;
    end;
  finally
    LCapacity.Free;
    LLines.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomMonthlyReport);

end.
