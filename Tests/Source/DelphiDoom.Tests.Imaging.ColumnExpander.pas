{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TImagingColumnExpander                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.ColumnExpander;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Intf,
  DelphiDoom.Imaging.ColumnExpander, DelphiDoom.Tests.Imaging.Samples,
  DelphiDoom.Tests.Imaging.Golden;

type
  [TestFixture]
  [Category('imaging')]
  TTestImagingColumnExpander = class(TObject)
  private
    FExpander: IImagingColumnExpander;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure TestExpandMatchesOldCodeForEveryFactor;
    [Test]
    procedure TestExpandWithFactorOneKeepsTheLength;
    [Test]
    procedure TestExpandOfEqualPixelsLosesOneStep;
    [Test]
    procedure TestExpandWithFactorZeroRaises;
    [Test]
    procedure TestExpandWithASmallBufferRaises;
  end;

implementation

procedure TTestImagingColumnExpander.Setup;
begin
  FExpander := TImagingColumnExpander.Create;
end;

procedure TTestImagingColumnExpander.TestExpandMatchesOldCodeForEveryFactor;
var
  LFactor: Integer;
  LBuffer: TImagingPixels;
begin
  for LFactor := 1 to 8 do
  begin
    LBuffer := TImagingSamples.RandomPixels(Cardinal(LFactor) + 500, 129 * 8, $00FFFFFF);
    SetLength(LBuffer, 129 * LFactor);
    FExpander.Expand(LBuffer, LFactor);
    TImagingGolden.Check('expand.golden.txt', 'factor_' + IntToStr(LFactor),
      TImagingSamples.Hex(TImagingSamples.Hash(LBuffer)));
  end;
end;

procedure TTestImagingColumnExpander.TestExpandWithFactorOneKeepsTheLength;
var
  LBuffer: TImagingPixels;
begin
  LBuffer := TImagingSamples.RandomPixels(1, 129, $00FFFFFF);
  FExpander.Expand(LBuffer, 1);
  Assert.AreEqual(129, Length(LBuffer), 'dovrebbe lasciare la lunghezza del buffer');
end;

procedure TTestImagingColumnExpander.TestExpandOfEqualPixelsLosesOneStep;
var
  LBuffer: TImagingPixels;
  LGroup: Integer;
begin
  // a column of 128 equal pixels stays so (but for the loss of a step of the old blend)
  SetLength(LBuffer, 129 * 4);
  for LGroup := 0 to 127 do
    LBuffer[LGroup] := $00808080;
  FExpander.Expand(LBuffer, 4);
  Assert.AreEqual(Cardinal($007F7F7F), LBuffer[0], 'dovrebbe dare lo stesso colore meno un passo');
end;

procedure TTestImagingColumnExpander.TestExpandWithFactorZeroRaises;
var
  LBuffer: TImagingPixels;
begin
  SetLength(LBuffer, 1000);
  Assert.WillRaise(
    procedure
    begin
      FExpander.Expand(LBuffer, 0);
    end, EImagingException, 'dovrebbe rifiutare il fattore zero');
end;

procedure TTestImagingColumnExpander.TestExpandWithASmallBufferRaises;
var
  LBuffer: TImagingPixels;
begin
  SetLength(LBuffer, 129 * 2 - 1);
  Assert.WillRaise(
    procedure
    begin
      FExpander.Expand(LBuffer, 2);
    end, EImagingException, 'dovrebbe rifiutare un buffer di meno di 129 volte il fattore');
end;

end.
