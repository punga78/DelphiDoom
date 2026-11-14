{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests - greed library: TGreedNetSession against net.pas          }
{                                                                              }
{  The golden file Tests\Data\Greed\net.golden.txt is written by the harness    }
{  Tools\Verifica\175-net, which runs the code of net.pas of xGreed on the      }
{  scenarios of DelphiDoom.Tests.Greed.NetScenarios                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.NetParity;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedNetParity = class
  public
    [Test]
    procedure DovrebbeDareGliStessiPacchettiDelCodiceOriginale;
    [Test]
    procedure DovrebbeDareDueVolteLeStesseRighe;
    [Test]
    procedure DovrebbeScrivereChiamateEStatoPerEsteso;
  end;

implementation

uses
  DelphiDoom.Tests.Greed.RealData, DelphiDoom.Tests.Greed.NetScenarios, DelphiDoom.Tests.Greed.NetRunner,
  DelphiDoom.Tests.Greed.NetLibraryRunner;

{ TTestGreedNetParity }

procedure TTestGreedNetParity.DovrebbeDareGliStessiPacchettiDelCodiceOriginale;
var
  LGolden, LActual: TStringList;
  LRunner: TLibraryNetRunner;
  LScenario, LLine, LPackets: Integer;
begin
  LGolden := TStringList.Create;
  LActual := TStringList.Create;
  LRunner := TLibraryNetRunner.Create;
  try
    LGolden.LoadFromFile(TGreedRealData.GoldenPath('net.golden.txt'));
    // to look for a difference: the calls and the state in full, to compare with "Compila.ps1 -Verbose1"
    if GetEnvironmentVariable('GREED_NET_DUMP') <> '' then
    begin
      LRunner.Verbose := True;
      for LScenario := 0 to TNetScenarios.Count - 1 do
        LRunner.Run(LScenario, LActual);
      LActual.SaveToFile(GetEnvironmentVariable('GREED_NET_DUMP'), TEncoding.ASCII);
      LActual.Clear;
      LRunner.Verbose := False;
    end;
    for LScenario := 0 to TNetScenarios.Count - 1 do
      LRunner.Run(LScenario, LActual);
    LPackets := 0;
    for LLine := 0 to LActual.Count - 1 do
    begin
      if LLine >= LGolden.Count then
        Assert.Fail(Format('the golden file ends at line %d', [LLine]));
      if LGolden[LLine] <> LActual[LLine] then
        Assert.Fail(Format('line %d differs from the original:'#13#10'%s'#13#10'here:'#13#10'%s',
          [LLine + 1, LGolden[LLine], LActual[LLine]]));
      if LActual[LLine].Contains('|  |') = False then
        Inc(LPackets);
    end;
    Assert.AreEqual(LGolden.Count, LActual.Count, 'the number of lines');
    Assert.IsTrue(LActual.Count > 3000, 'the steps that were compared');
    Assert.IsTrue(LPackets > 1000, 'the steps that sent packets');
  finally
    LRunner.Free;
    LActual.Free;
    LGolden.Free;
  end;
end;

procedure TTestGreedNetParity.DovrebbeDareDueVolteLeStesseRighe;
var
  LFirst, LSecond: TStringList;
  LRunner: TLibraryNetRunner;
begin
  LFirst := TStringList.Create;
  LSecond := TStringList.Create;
  LRunner := TLibraryNetRunner.Create;
  try
    LRunner.Run(TNetScenarios.Count - 1, LFirst);
    LRunner.Run(TNetScenarios.Count - 1, LSecond);
    Assert.AreEqual(LFirst.Text, LSecond.Text);
    Assert.IsTrue(LFirst.Count > 50);
  finally
    LRunner.Free;
    LSecond.Free;
    LFirst.Free;
  end;
end;

procedure TTestGreedNetParity.DovrebbeScrivereChiamateEStatoPerEsteso;
var
  LLines: TStringList;
  LRunner: TLibraryNetRunner;
begin
  LLines := TStringList.Create;
  LRunner := TLibraryNetRunner.Create;
  try
    LRunner.Verbose := True;
    // the scenario of the deaths: messages, score, sprites
    LRunner.Run(10, LLines);
    Assert.IsTrue(LLines.Text.Contains('> writemsg Fragged'), 'the calls are written');
    Assert.IsTrue(LLines.Text.Contains('> addscore 5000'), 'the score of a frag');
    Assert.IsTrue(LLines.Text.Contains(' p0 frags='), 'the state is written');
  finally
    LRunner.Free;
    LLines.Free;
  end;
end;

end.
