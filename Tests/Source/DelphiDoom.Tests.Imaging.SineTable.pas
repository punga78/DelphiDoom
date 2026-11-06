{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TImagingFixedSineTable                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.SineTable;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Intf,
  DelphiDoom.Imaging.SineTable, DelphiDoom.Tests.Imaging.Samples,
  DelphiDoom.Tests.Imaging.Golden;

type
  [TestFixture]
  [Category('imaging')]
  TTestImagingFixedSineTable = class(TObject)
  private
    FTable: IImagingSineTable;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestTableIsTheOneOfTheEngine;
    [Test]
    procedure TestFirstEntryIsTheSineOfHalfAStep;
    [Test]
    procedure TestQuarterOfTheCircleIsTheMaximum;
    [Test]
    procedure TestHalfOfTheCircleIsNegative;
    [Test]
    procedure TestIndexOutOfTheTableRaises;
  end;

implementation

procedure TTestImagingFixedSineTable.Setup;
begin
  FTable := TImagingFixedSineTable.Create;
end;

procedure TTestImagingFixedSineTable.TestTableIsTheOneOfTheEngine;
var
  LValues: TArray<Integer>;
  LIndex: Integer;
begin
  SetLength(LValues, IMAGING_SINE_TABLE_SIZE);
  for LIndex := 0 to High(LValues) do
    LValues[LIndex] := FTable.Sine(LIndex);
  TImagingGolden.Check('scale.golden.txt', 'sine_table',
    IntToStr(Length(LValues)) + ':' + TImagingSamples.Hex(TImagingSamples.Hash(LValues)));
end;

procedure TTestImagingFixedSineTable.TestFirstEntryIsTheSineOfHalfAStep;
begin
  Assert.AreEqual(3, FTable.Sine(0), 'dovrebbe dare 3 per il primo passo');
end;

procedure TTestImagingFixedSineTable.TestQuarterOfTheCircleIsTheMaximum;
begin
  Assert.AreEqual(65535, FTable.Sine(16384), 'dovrebbe dare FRACUNIT - 1 a un quarto di cerchio');
end;

procedure TTestImagingFixedSineTable.TestHalfOfTheCircleIsNegative;
begin
  Assert.IsTrue(FTable.Sine(40000) < 0, 'dovrebbe essere negativo a meta'' cerchio');
end;

procedure TTestImagingFixedSineTable.TestIndexOutOfTheTableRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      FTable.Sine(IMAGING_SINE_TABLE_SIZE);
    end, EImagingException, 'dovrebbe rifiutare un indice oltre la tabella');
  Assert.WillRaise(
    procedure
    begin
      FTable.Sine(-1);
    end, EImagingException, 'dovrebbe rifiutare un indice negativo');
end;

end.
