{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the racing library - the parity with the old code      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Racing.Parity;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework;

type
  /// <summary>
  ///   Tests\Data\Racing\racing.golden.txt is what the old code of Speed Haste (the functions of speed_cars,
  ///   speed_race, speed_path, speed_score and speed_particles, compiled as they are by
  ///   Tools\Verifica\168\Racing) gives for the scenarios of DelphiDoom.Tests.Racing.Scenarios; the
  ///   library must give the same lines
  /// </summary>
  [TestFixture]
  [Category('racing')]
  TTestRacingParity = class(TObject)
  strict private
    class var FGolden: TStringList;
    class var FActual: TStringList;
    procedure CompareLines(const APrefix: string);
  public
    [SetupFixture]
    procedure SetupFixture;
    [TeardownFixture]
    procedure TeardownFixture;
    [Test]
    procedure DovrebbeAvereLeStesseDimensioniDeiRecordDelFile;
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelTerreno;
    [Test]
    procedure DovrebbeDareLeStesseTabelleDeiTempi;
    [Test]
    procedure DovrebbeSceglierLeStesseAutoPerLaGriglia;
    [Test]
    procedure DovrebbeOrdinareIlPercorsoComeIlVecchioCodice;
    [Test]
    procedure DovrebbeMuovereLeAutoComeIlVecchioCodice;
    [Test]
    procedure DovrebbeFarCorrereUnaGaraComeIlVecchioCodice;
    [Test]
    procedure DovrebbeAvereLeStesseRigheDelGolden;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Tests.Racing.Scenarios, DelphiDoom.Tests.Racing.LibraryTarget;

{ TTestRacingParity }

procedure TTestRacingParity.SetupFixture;
var
  LPath: string;
begin
  FGolden := TStringList.Create;
  FActual := TStringList.Create;
  LPath := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\..\..\Tests\Data\Racing\racing.golden.txt'));
  FGolden.LoadFromFile(LPath);
  TRacingScenarios.Run(TRacingLibraryTarget.Create, FActual);
end;

procedure TTestRacingParity.TeardownFixture;
begin
  FreeAndNil(FGolden);
  FreeAndNil(FActual);
end;

procedure TTestRacingParity.CompareLines(const APrefix: string);
var
  LGolden, LActual: TStringList;
  LIndex: Integer;
begin
  LGolden := TStringList.Create;
  LActual := TStringList.Create;
  try
    for LIndex := 0 to FGolden.Count - 1 do
      if Pos(APrefix, FGolden[LIndex]) = 1 then
        LGolden.Add(FGolden[LIndex]);
    for LIndex := 0 to FActual.Count - 1 do
      if Pos(APrefix, FActual[LIndex]) = 1 then
        LActual.Add(FActual[LIndex]);
    Assert.IsTrue(LGolden.Count > 0, 'The golden file has no line for ' + APrefix);
    Assert.AreEqual(LGolden.Count, LActual.Count, 'Number of lines of ' + APrefix);
    for LIndex := 0 to LGolden.Count - 1 do
      Assert.AreEqual(LGolden[LIndex], LActual[LIndex], 'Line ' + IntToStr(LIndex) + ' of ' + APrefix);
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

procedure TTestRacingParity.DovrebbeAvereLeStesseDimensioniDeiRecordDelFile;
begin
  CompareLines('sizes');
end;

procedure TTestRacingParity.DovrebbeDareLeStesseRisposteDelTerreno;
begin
  CompareLines('ground');
end;

procedure TTestRacingParity.DovrebbeDareLeStesseTabelleDeiTempi;
begin
  CompareLines('scores');
end;

procedure TTestRacingParity.DovrebbeSceglierLeStesseAutoPerLaGriglia;
begin
  CompareLines('grid');
end;

procedure TTestRacingParity.DovrebbeOrdinareIlPercorsoComeIlVecchioCodice;
begin
  CompareLines('track');
end;

procedure TTestRacingParity.DovrebbeMuovereLeAutoComeIlVecchioCodice;
begin
  CompareLines('physics');
end;

procedure TTestRacingParity.DovrebbeFarCorrereUnaGaraComeIlVecchioCodice;
begin
  CompareLines('race');
end;

procedure TTestRacingParity.DovrebbeAvereLeStesseRigheDelGolden;
var
  LIndex: Integer;
begin
  Assert.AreEqual(FGolden.Count, FActual.Count);
  for LIndex := 0 to FGolden.Count - 1 do
    Assert.AreEqual(FGolden[LIndex], FActual[LIndex]);
end;

end.
