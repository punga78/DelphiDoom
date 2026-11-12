{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRacingTextFormat                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Racing.TextFormat;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>The expected texts are those of speed_string_format.pas of the old fork, worked out by hand</summary>
  [TestFixture]
  [Category('racing')]
  TTestRacingTextFormat = class(TObject)
  public
    [Test]
    [TestCase('Zero', '0,0.000km')]
    [TestCase('Una cifra', '5,0.005km')]
    [TestCase('Due cifre', '42,0.042km')]
    [TestCase('Tre cifre', '123,0.123km')]
    [TestCase('Un chilometro', '1000,1.000km')]
    [TestCase('Quattro cifre', '1234,1.234km')]
    [TestCase('Cinque cifre', '12345,12.345km')]
    [TestCase('Un solo punto oltre il milione', '1234567,1234.567km')]
    procedure DovrebbeScrivereIMetriInChilometri(AMeters: Integer; const AExpected: string);
    [Test]
    procedure DovrebbeScrivereUnSecondo;
    [Test]
    procedure DovrebbeScrivereITicComeCentesimi;
    [Test]
    procedure DovrebbeScrivereMinutiSecondiECentesimi;
    [Test]
    procedure DovrebbeMettereLeOreDavantiSoloSeCiSono;
    [Test]
    procedure DovrebbeScrivereZeroTic;
    [Test]
    [TestCase('Primo', '1,1st')]
    [TestCase('Secondo', '2,2nd')]
    [TestCase('Terzo', '3,3rd')]
    [TestCase('Quarto', '4,4th')]
    [TestCase('Undicesimo', '11,11th')]
    [TestCase('Ultima auto', '20,20th')]
    [TestCase('Oltre le auto', '21,-')]
    [TestCase('Zero', '0,-')]
    [TestCase('Negativo', '-1,-')]
    procedure DovrebbeScrivereLaPosizioneInGara(APosition: Integer; const AExpected: string);
  end;

implementation

uses
  DelphiDoom.Racing.TextFormat;

{ TTestRacingTextFormat }

procedure TTestRacingTextFormat.DovrebbeScrivereIMetriInChilometri(AMeters: Integer;
  const AExpected: string);
begin
  Assert.AreEqual(AExpected, TRacingTextFormat.MetersToKilometers(AMeters));
end;

procedure TTestRacingTextFormat.DovrebbeScrivereUnSecondo;
begin
  Assert.AreEqual('00''01"00', TRacingTextFormat.TicsToTime(35));
end;

procedure TTestRacingTextFormat.DovrebbeScrivereITicComeCentesimi;
begin
  // one tic is 100 / 35 hundredths, cut: 2
  Assert.AreEqual('00''00"02', TRacingTextFormat.TicsToTime(1));
  Assert.AreEqual('00''00"97', TRacingTextFormat.TicsToTime(34));
end;

procedure TTestRacingTextFormat.DovrebbeScrivereMinutiSecondiECentesimi;
begin
  // 3356 tics: 9588 hundredths, that is 1 minute, 35 seconds and 88 hundredths
  Assert.AreEqual('01''35"88', TRacingTextFormat.TicsToTime(3356));
end;

procedure TTestRacingTextFormat.DovrebbeMettereLeOreDavantiSoloSeCiSono;
begin
  Assert.AreEqual('59''59"97', TRacingTextFormat.TicsToTime(35 * 3600 - 1));
  Assert.AreEqual('1''00''00"00', TRacingTextFormat.TicsToTime(35 * 3600));
  Assert.AreEqual('12''03''04"00', TRacingTextFormat.TicsToTime(35 * (12 * 3600 + 3 * 60 + 4)));
end;

procedure TTestRacingTextFormat.DovrebbeScrivereZeroTic;
begin
  Assert.AreEqual('00''00"00', TRacingTextFormat.TicsToTime(0));
end;

procedure TTestRacingTextFormat.DovrebbeScrivereLaPosizioneInGara(APosition: Integer;
  const AExpected: string);
begin
  Assert.AreEqual(AExpected, TRacingTextFormat.RacePosition(APosition));
end;

end.
