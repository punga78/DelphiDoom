{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI library tests - TMidiEventFeeder and the record of events    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Midi.EventFeeder;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Midi.Types,
  DelphiDoom.Midi.EventFeeder;

type
  [TestFixture]
  [Category('midi')]
  TTestMidiEventFeeder = class
  public
    [Test]
    procedure DovrebbeDareUnSoloPezzoSeLaCanzoneEPiccola;
    [Test]
    procedure DovrebbeDareIPezziUnoDopoLAltroEPoiRicominciare;
    [Test]
    procedure DovrebbeRicominciareSeLaCanzoneEUnMultiploDelPezzo;
    [Test]
    procedure DovrebbeAvereLeStesseDimensioniDegliEventiDelloStream;
  end;

implementation

procedure TTestMidiEventFeeder.DovrebbeDareUnSoloPezzoSeLaCanzoneEPiccola;
var
  LNext, LStart, LCount: Integer;
begin
  LNext := 0;
  TMidiEventFeeder.NextPiece(100, 512, LNext, LStart, LCount);
  Assert.AreEqual(0, LStart);
  Assert.AreEqual(100, LCount);
  Assert.AreEqual(0, LNext);
end;

procedure TTestMidiEventFeeder.DovrebbeDareIPezziUnoDopoLAltroEPoiRicominciare;
var
  LNext, LStart, LCount: Integer;
begin
  LNext := 0;
  TMidiEventFeeder.NextPiece(1300, 512, LNext, LStart, LCount);
  Assert.AreEqual(0, LStart);
  Assert.AreEqual(512, LCount);
  TMidiEventFeeder.NextPiece(1300, 512, LNext, LStart, LCount);
  Assert.AreEqual(512, LStart);
  Assert.AreEqual(512, LCount);
  TMidiEventFeeder.NextPiece(1300, 512, LNext, LStart, LCount);
  Assert.AreEqual(1024, LStart);
  Assert.AreEqual(276, LCount);
  Assert.AreEqual(0, LNext);
  TMidiEventFeeder.NextPiece(1300, 512, LNext, LStart, LCount);
  Assert.AreEqual(0, LStart);
end;

procedure TTestMidiEventFeeder.DovrebbeRicominciareSeLaCanzoneEUnMultiploDelPezzo;
var
  LNext, LStart, LCount: Integer;
begin
  LNext := 0;
  TMidiEventFeeder.NextPiece(1024, 512, LNext, LStart, LCount);
  TMidiEventFeeder.NextPiece(1024, 512, LNext, LStart, LCount);
  Assert.AreEqual(512, LStart);
  Assert.AreEqual(512, LCount);
  Assert.AreEqual(0, LNext);
end;

procedure TTestMidiEventFeeder.DovrebbeAvereLeStesseDimensioniDegliEventiDelloStream;
begin
  Assert.AreEqual(12, Integer(SizeOf(TMidiStreamEvent)));
  Assert.AreEqual(MIDI_STREAM_EVENT_SIZE, Integer(SizeOf(TMidiStreamEvent)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMidiEventFeeder);

end.
