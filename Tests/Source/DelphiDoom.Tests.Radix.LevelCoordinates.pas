{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixLevelCoordinates                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.LevelCoordinates;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.Level.Coordinates;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixLevelCoordinates = class(TObject)
  public
    [Test]
    procedure DovrebbeSpostareEdInvertireLaYNellaPosizioneUsuale;
    [Test]
    procedure DovrebbeUsareLaPosizioneUsualeOltre48000SeLaMappaNonEDivisa;
    [Test]
    procedure DovrebbeUsareLaPosizioneDellaParteDivisaDa48000InPoi;
    [Test]
    procedure DovrebbeUsareLaPosizioneUsualeSottoLa48000AncheNellaMappaDivisa;
    [Test]
    procedure DovrebbeDareSempreLaPosizioneUsualeConConvertDefault;
  end;

implementation

{ TTestRadixLevelCoordinates }

procedure TTestRadixLevelCoordinates.DovrebbeSpostareEdInvertireLaYNellaPosizioneUsuale;
var
  LCoordinates: TRadixLevelCoordinates;
  LX: Integer;
  LY: Integer;
begin
  LCoordinates := TRadixLevelCoordinates.Create(False);
  try
    LX := 40000;
    LY := 100;
    LCoordinates.Convert(LX, LY);
    Assert.AreEqual(7233, LX);
    Assert.AreEqual(-100, LY);
  finally
    LCoordinates.Free;
  end;
end;

procedure TTestRadixLevelCoordinates.DovrebbeUsareLaPosizioneUsualeOltre48000SeLaMappaNonEDivisa;
var
  LCoordinates: TRadixLevelCoordinates;
  LX: Integer;
  LY: Integer;
begin
  LCoordinates := TRadixLevelCoordinates.Create(False);
  try
    LX := 50000;
    LY := 10;
    LCoordinates.Convert(LX, LY);
    Assert.AreEqual(17233, LX);
    Assert.AreEqual(-10, LY);
  finally
    LCoordinates.Free;
  end;
end;

procedure TTestRadixLevelCoordinates.DovrebbeUsareLaPosizioneDellaParteDivisaDa48000InPoi;
var
  LCoordinates: TRadixLevelCoordinates;
  LX: Integer;
  LY: Integer;
begin
  LCoordinates := TRadixLevelCoordinates.Create(True);
  try
    LX := 48000;
    LY := 10;
    LCoordinates.Convert(LX, LY);
    Assert.AreEqual(-17536, LX);
    Assert.AreEqual(-10 - 4096, LY);
  finally
    LCoordinates.Free;
  end;
end;

procedure TTestRadixLevelCoordinates.DovrebbeUsareLaPosizioneUsualeSottoLa48000AncheNellaMappaDivisa;
var
  LCoordinates: TRadixLevelCoordinates;
  LX: Integer;
  LY: Integer;
begin
  LCoordinates := TRadixLevelCoordinates.Create(True);
  try
    LX := 47999;
    LY := 10;
    LCoordinates.Convert(LX, LY);
    Assert.AreEqual(15232, LX);
    Assert.AreEqual(-10, LY);
  finally
    LCoordinates.Free;
  end;
end;

procedure TTestRadixLevelCoordinates.DovrebbeDareSempreLaPosizioneUsualeConConvertDefault;
var
  LX: Integer;
  LY: Integer;
begin
  LX := 60000;
  LY := -5;
  TRadixLevelCoordinates.ConvertDefault(LX, LY);
  Assert.AreEqual(27233, LX);
  Assert.AreEqual(5, LY);
end;

end.
