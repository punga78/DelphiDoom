{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the automap library - parity with the old am_map       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Automap.Parity;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Tests.Automap.Golden;

type
  /// <summary>
  ///   The scenarios give the same fingerprints as the old code of Base\am_map.pas (Tests\Data\Automap):
  ///   conversions, limits of the level, navigation, marks, clipping and rotation
  /// </summary>
  [TestFixture]
  [Category('automap')]
  TTestAutomapParity = class(TObject)
  private
    FGolden: TGoldenFile;
    procedure CheckScenario(const AName: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareLeStesseCostantiDiZoom;
    [Test]
    procedure DovrebbeConvertireLeCoordinateCometeIlVecchioCodice;
    [Test]
    procedure DovrebbeTrovareGliStessiLimitiDelLivello;
    [Test]
    procedure DovrebbeNavigareCometeIlVecchioCodice;
    [Test]
    procedure DovrebbeTenereGliStessiSegni;
    [Test]
    procedure DovrebbeRitagliareLeLineeCometeIlVecchioCodice;
    [Test]
    procedure DovrebbeRitagliareLeLineeSuiBordiDellaFinestra;
    [Test]
    procedure DovrebbeRuotareCometeIlVecchioCodice;
    [Test]
    procedure DovrebbeRuotareInVirgolaMobileCometeIlVecchioCodice;
  end;

implementation

uses
  DelphiDoom.Tests.Automap.Scenarios, DelphiDoom.Tests.Automap.LibraryDriver;

{ TTestAutomapParity }

procedure TTestAutomapParity.Setup;
begin
  FGolden := TGoldenFile.Create('automap.golden.txt');
end;

procedure TTestAutomapParity.TearDown;
begin
  FGolden.Free;
end;

procedure TTestAutomapParity.CheckScenario(const AName: string);
var
  LScenarios: TAutomapScenarios;
begin
  LScenarios := TAutomapScenarios.Create(TLibraryDriver.Create);
  try
    FGolden.Check(AName, LScenarios.Run(AName));
  finally
    LScenarios.Free;
  end;
end;

procedure TTestAutomapParity.DovrebbeDareLeStesseCostantiDiZoom;
begin
  CheckScenario('constants');
end;

procedure TTestAutomapParity.DovrebbeConvertireLeCoordinateCometeIlVecchioCodice;
begin
  CheckScenario('transform');
end;

procedure TTestAutomapParity.DovrebbeTrovareGliStessiLimitiDelLivello;
begin
  CheckScenario('bounds');
end;

procedure TTestAutomapParity.DovrebbeNavigareCometeIlVecchioCodice;
begin
  CheckScenario('navigation');
end;

procedure TTestAutomapParity.DovrebbeTenereGliStessiSegni;
begin
  CheckScenario('marks');
end;

procedure TTestAutomapParity.DovrebbeRitagliareLeLineeCometeIlVecchioCodice;
begin
  CheckScenario('clip');
end;

procedure TTestAutomapParity.DovrebbeRitagliareLeLineeSuiBordiDellaFinestra;
begin
  CheckScenario('clipedges');
end;

procedure TTestAutomapParity.DovrebbeRuotareCometeIlVecchioCodice;
begin
  CheckScenario('rotate');
end;

procedure TTestAutomapParity.DovrebbeRuotareInVirgolaMobileCometeIlVecchioCodice;
begin
  CheckScenario('rotateexact');
end;

end.
