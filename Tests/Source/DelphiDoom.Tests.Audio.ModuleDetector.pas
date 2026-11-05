{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the detector of the modules in the lumps of music      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Audio.ModuleDetector;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Audio.ModuleDetector;

type
  [TestFixture]
  [Category('mikmod')]
  TTestModuleDetector = class(TObject)
  private
    function Buffer(const ASize: Integer; const AOffset: Integer; const ASignature: AnsiString): TBytes;
  public
    [Test]
    procedure TestRiconosceUnMod;
    [Test]
    procedure TestRiconosceUnMod8Canali;
    [Test]
    procedure TestRiconosceUnS3m;
    [Test]
    procedure TestRiconosceUnXm;
    [Test]
    procedure TestRiconosceUnIt;
    [Test]
    procedure TestNonRiconosceUnaMusicaMidi;
    [Test]
    procedure TestNonRiconosceUnaMusicaMus;
    [Test]
    procedure TestDatiTroppoCorti;
    [Test]
    procedure TestSenzaDati;
    [Test]
    procedure TestLaFirmaDelModFuoriPostoNonBasta;
  end;

implementation

{ TTestModuleDetector }

function TTestModuleDetector.Buffer(const ASize, AOffset: Integer; const ASignature: AnsiString): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, ASize);
  for LIndex := 1 to Length(ASignature) do
    Result[AOffset + LIndex - 1] := Ord(ASignature[LIndex]);
end;

procedure TTestModuleDetector.TestRiconosceUnMod;
var
  LData: TBytes;
begin
  LData := Buffer(2000, 1080, 'M.K.');

  Assert.IsTrue(TModuleDetector.IsModule(@LData[0], Length(LData)));
end;

procedure TTestModuleDetector.TestRiconosceUnMod8Canali;
var
  LData: TBytes;
begin
  LData := Buffer(1500, 1080, '8CHN');

  Assert.IsTrue(TModuleDetector.IsModule(@LData[0], Length(LData)));
end;

procedure TTestModuleDetector.TestRiconosceUnS3m;
var
  LData: TBytes;
begin
  LData := Buffer(200, 44, 'SCRM');

  Assert.IsTrue(TModuleDetector.IsModule(@LData[0], Length(LData)));
end;

procedure TTestModuleDetector.TestRiconosceUnXm;
var
  LData: TBytes;
begin
  LData := Buffer(400, 0, 'Extended Module: ');

  Assert.IsTrue(TModuleDetector.IsModule(@LData[0], Length(LData)));
end;

procedure TTestModuleDetector.TestRiconosceUnIt;
var
  LData: TBytes;
begin
  LData := Buffer(400, 0, 'IMPM');

  Assert.IsTrue(TModuleDetector.IsModule(@LData[0], Length(LData)));
end;

procedure TTestModuleDetector.TestNonRiconosceUnaMusicaMidi;
var
  LData: TBytes;
begin
  LData := Buffer(3000, 0, 'MThd');

  Assert.IsFalse(TModuleDetector.IsModule(@LData[0], Length(LData)));
end;

procedure TTestModuleDetector.TestNonRiconosceUnaMusicaMus;
var
  LData: TBytes;
begin
  LData := Buffer(3000, 0, 'MUS' + #$1A);

  Assert.IsFalse(TModuleDetector.IsModule(@LData[0], Length(LData)));
end;

procedure TTestModuleDetector.TestDatiTroppoCorti;
var
  LData: TBytes;
begin
  LData := Buffer(10, 0, 'IMPM');

  Assert.IsFalse(TModuleDetector.IsModule(@LData[0], Length(LData)));
end;

procedure TTestModuleDetector.TestSenzaDati;
begin
  Assert.IsFalse(TModuleDetector.IsModule(nil, 100));
  Assert.IsFalse(TModuleDetector.IsModule(Pointer(1), 0));
end;

procedure TTestModuleDetector.TestLaFirmaDelModFuoriPostoNonBasta;
var
  LData: TBytes;
begin
  LData := Buffer(2000, 1000, 'M.K.');

  Assert.IsFalse(TModuleDetector.IsModule(@LData[0], Length(LData)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestModuleDetector);

end.
