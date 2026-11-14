{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Doom 3 obstacle avoidance - parity with the C++    }
{                                                                              }
{  avoid.golden.txt is what the real obstacle avoidance of AI_pathing.cpp,     }
{  on the real idAASLocal (compiled with bcc32c by                             }
{  Tools\Verifica\109\Build-AvoidHarness.ps1), prints for the scenario.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 3 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Aas.D3.AvoidGolden;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('AasD3')]
  TTestAasD3AvoidGolden = class
  public
    [Test]
    procedure DovrebbeDareLeStesseRisposteDelVeroCodiceDiAiPathing;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Tests.Aas.D3.Support, DelphiDoom.Tests.Aas.D3.AvoidScenario;

const
  GOLDEN_NAME = 'avoid.golden.txt';

{ The angle and the time of a shot (BA lines) come from atan2( float, float ) and cos( float ) of the C library of the
  harness (bcc32c), which are not correctly rounded: atan2 is one unit in the last place off for some arguments, and
  AngleNormalize180 (which adds 360 to the angle and takes it off again) turns that into a few units in the last place of
  the degrees; the time divides by a cosine that can be near zero. The angle may differ by 1E-4 degrees and the time by a
  relative 1E-4; everything else must be equal }
function BitsToSingle(const AText: string): Single;
var
  LBits: Cardinal;
begin
  LBits := StrToUInt('$' + Copy(AText, 2, 8));
  Result := PSingle(@LBits)^;
end;

function SameLine(const AExpected, AActual: string): Boolean;
var
  LExpected, LActual: TArray<string>;
  LIndex, LCount: Integer;
  LExpectedValue, LActualValue, LTolerance: Single;
begin
  if AExpected = AActual then
    Exit(True);
  if Copy(AExpected, 1, 3) <> 'BA ' then
    Exit(False);
  LExpected := AExpected.Split([' ']);
  LActual := AActual.Split([' ']);
  if Length(LExpected) <> Length(LActual) then
    Exit(False);
  LCount := StrToIntDef(LExpected[2], 0);
  for LIndex := 0 to High(LExpected) do
    if LExpected[LIndex] <> LActual[LIndex] then
    begin
      // the angle (3, 5, ...) and the time (4, 6, ...) of the shots
      if (LIndex < 3) or (LIndex > 2 + 2 * LCount) then
        Exit(False);
      LExpectedValue := BitsToSingle(LExpected[LIndex]);
      LActualValue := BitsToSingle(LActual[LIndex]);
      if Odd(LIndex - 3) then
        LTolerance := 1E-4 * Abs(LExpectedValue)
      else
        LTolerance := 1E-4;
      if Abs(LExpectedValue - LActualValue) > LTolerance then
        Exit(False);
    end;
  Result := True;
end;
{ TTestAasD3AvoidGolden }

procedure TTestAasD3AvoidGolden.DovrebbeDareLeStesseRisposteDelVeroCodiceDiAiPathing;
var
  LCases, LActual, LGolden, LExpected: TStringList;
  LRunner: TD3AvoidScenarioRunner;
  LLine: string;
  LIndex: Integer;
begin
  LCases := TStringList.Create;
  LActual := TStringList.Create;
  LGolden := TStringList.Create;
  LExpected := TStringList.Create;
  try
    Assert.IsTrue(TFile.Exists(D3DataFolder + GOLDEN_NAME), GOLDEN_NAME + ' not found in ' + D3DataFolder);
    LCases.LoadFromFile(D3DataFolder + 'cases.txt');
    LRunner := TD3AvoidScenarioRunner.Create(LActual);
    try
      LRunner.Run(LCases);
    finally
      LRunner.Free;
    end;
    LGolden.LoadFromFile(D3DataFolder + GOLDEN_NAME);
    // the loading of the file prints three lines in the C++ and the scenario does not load a file
    for LLine in LGolden do
      if (Copy(LLine, 1, 15) <> 'P: [Load AAS]\n') and (Copy(LLine, 1, 11) <> 'P: loading ') and
        (LLine <> 'P: done.\n') then
        LExpected.Add(LLine);
    LActual.SaveToFile(ExtractFilePath(ParamStr(0)) + 'avoid.actual.txt');
    for LIndex := 0 to LExpected.Count - 1 do
    begin
      if LIndex < LActual.Count then
        LLine := LActual[LIndex]
      else
        LLine := '(none)';
      if not SameLine(LExpected[LIndex], LLine) then
        Assert.Fail(Format('first difference at line %d: expected "%s", got "%s"',
          [LIndex + 1, LExpected[LIndex], LLine]));
    end;
    Assert.AreEqual(LExpected.Count, LActual.Count, 'number of lines');
  finally
    LExpected.Free;
    LGolden.Free;
    LActual.Free;
    LCases.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAasD3AvoidGolden);

end.
