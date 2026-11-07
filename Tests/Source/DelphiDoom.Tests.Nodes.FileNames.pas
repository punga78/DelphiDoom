{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Nodes library - the names of the files of nodes    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Nodes.FileNames;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Nodes.FileNames;

type
  [TestFixture]
  [Category('nodes')]
  TTestNodesFileNames = class(TObject)
  public
    [Test]
    [TestCase('Zero', '0,00000000')]
    [TestCase('Piccolo', '171,000000ab')]
    [TestCase('Massimo', '4294967295,ffffffff')]
    [TestCase('Misto', '305441741,1234abcd')]
    procedure TestIlChecksumDovrebbeAvereOttoCifreMinuscole(AValue: Cardinal; const AExpected: string);
    [Test]
    procedure TestIlGwaDovrebbeAvereMappaEChecksumNellaCartella;
    [Test]
    procedure TestIlWadPerGlbspDovrebbeAvereMappaEChecksumSenzaCartella;
    [Test]
    procedure TestIlNomeDellaMappaRicostruitaDovrebbeUnireICrcConIlTrattinoBasso;
    [Test]
    procedure TestSenzaCrcIlNomeDellaMappaRicostruitaDovrebbeEssereLaMappa;
  end;

implementation

{ TTestNodesFileNames }

procedure TTestNodesFileNames.TestIlChecksumDovrebbeAvereOttoCifreMinuscole(AValue: Cardinal;
  const AExpected: string);
begin
  Assert.AreEqual(AExpected, TNodesFileNames.ChecksumText(AValue));
end;

procedure TTestNodesFileNames.TestIlGwaDovrebbeAvereMappaEChecksumNellaCartella;
begin
  Assert.AreEqual('C:\DATA\BSP\E1M1_0badf00d.gwa',
    TNodesFileNames.GwaFileName('C:\DATA\BSP\', 'E1M1', $0BADF00D));
end;

procedure TTestNodesFileNames.TestIlWadPerGlbspDovrebbeAvereMappaEChecksumSenzaCartella;
begin
  Assert.AreEqual('MAP01_deadbeef.wad', TNodesFileNames.GlbspInputFileName('MAP01', $DEADBEEF));
end;

procedure TTestNodesFileNames.TestIlNomeDellaMappaRicostruitaDovrebbeUnireICrcConIlTrattinoBasso;
begin
  Assert.AreEqual('D:\WADS\MAP07_11111111_22222222_33333333_DEADDEAD',
    TNodesFileNames.RebuiltMapName('D:\WADS\', 'MAP07', ['11111111', '22222222', '33333333', 'DEADDEAD']));
end;

procedure TTestNodesFileNames.TestSenzaCrcIlNomeDellaMappaRicostruitaDovrebbeEssereLaMappa;
begin
  Assert.AreEqual('MAP07', TNodesFileNames.RebuiltMapName('', 'MAP07', []));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestNodesFileNames);

end.
