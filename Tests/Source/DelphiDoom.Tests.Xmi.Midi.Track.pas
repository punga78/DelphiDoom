{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TXmiTrack                                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xmi.Midi.Track;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xmi.Midi.Types,
  DelphiDoom.Xmi.Midi.Track;

type
  [TestFixture]
  [Category('xmi')]
  TTestXmiMidiTrack = class(TObject)
  private
    FTrack: TXmiTrack;
    function NewEvent(AStatus: Byte; ATicks: UInt64): TXmiEvent;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareUnIndiceFuoriDallaTraccia;
    [Test]
    procedure DovrebbeTenerePiuDiSediciEventiInOrdine;
    [Test]
    procedure DovrebbeDareLAttesaDellEventoCancellatoAlSuccessivo;
    [Test]
    procedure DovrebbeInserirePrimaDellIndiceDato;
    [Test]
    procedure DovrebbePrendereIlTitoloDalPrimoNomeDiTraccia;
  end;

implementation

{ TTestXmiMidiTrack }

procedure TTestXmiMidiTrack.Setup;
begin
  FTrack := TXmiTrack.Create;
end;

procedure TTestXmiMidiTrack.TearDown;
begin
  FreeAndNil(FTrack);
end;

function TTestXmiMidiTrack.NewEvent(AStatus: Byte; ATicks: UInt64): TXmiEvent;
begin
  Result := Default(TXmiEvent);
  Result.Status := AStatus;
  Result.Ticks := ATicks;
end;

procedure TTestXmiMidiTrack.DovrebbeRifiutareUnIndiceFuoriDallaTraccia;
begin
  FTrack.Add(NewEvent($90, 0));
  Assert.WillRaise(
    procedure
    begin
      FTrack.EventAt(-1);
    end, EArgumentOutOfRangeException);
  Assert.WillRaise(
    procedure
    begin
      FTrack.EventAt(1);
    end, EArgumentOutOfRangeException);
  Assert.WillRaise(
    procedure
    begin
      FTrack.Insert(2, NewEvent($80, 0));
    end, EArgumentOutOfRangeException);
  Assert.WillRaise(
    procedure
    begin
      FTrack.Delete(1, False);
    end, EArgumentOutOfRangeException);
  Assert.AreEqual(1, FTrack.Count);
end;

procedure TTestXmiMidiTrack.DovrebbeTenerePiuDiSediciEventiInOrdine;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 39 do
    Assert.AreEqual(LIndex, FTrack.Add(NewEvent($90, LIndex)));

  Assert.AreEqual(40, FTrack.Count);
  for LIndex := 0 to 39 do
    Assert.AreEqual(UInt64(LIndex), FTrack[LIndex].Ticks);
end;

procedure TTestXmiMidiTrack.DovrebbeDareLAttesaDellEventoCancellatoAlSuccessivo;
begin
  FTrack.Add(NewEvent($90, 5));
  FTrack.Add(NewEvent($80, 7));
  FTrack.Add(NewEvent($B0, 11));

  FTrack.Delete(0, True);
  Assert.AreEqual(UInt64(12), FTrack[0].Ticks);
  FTrack.Delete(0, False);
  Assert.AreEqual(1, FTrack.Count);
  Assert.AreEqual(UInt64(11), FTrack[0].Ticks);
  // The last event has no next one to take its delay
  FTrack.Delete(0, True);
  Assert.AreEqual(0, FTrack.Count);
end;

procedure TTestXmiMidiTrack.DovrebbeInserirePrimaDellIndiceDato;
begin
  FTrack.Add(NewEvent($90, 1));
  FTrack.Add(NewEvent($80, 2));
  FTrack.Insert(1, NewEvent($B0, 3));
  FTrack.Insert(3, NewEvent($C0, 4));

  Assert.AreEqual(4, FTrack.Count);
  Assert.AreEqual($90, Integer(FTrack[0].Status));
  Assert.AreEqual($B0, Integer(FTrack[1].Status));
  Assert.AreEqual($80, Integer(FTrack[2].Status));
  Assert.AreEqual($C0, Integer(FTrack[3].Status));
end;

procedure TTestXmiMidiTrack.DovrebbePrendereIlTitoloDalPrimoNomeDiTraccia;
var
  LEvent: TXmiEvent;
begin
  LEvent := NewEvent(XMI_STATUS_META, 0);
  LEvent.Param1 := XMI_META_TRACK_NAME;
  FTrack.AddRead(LEvent);
  Assert.AreEqual('', string(FTrack.Title), 'a name without text');
  LEvent.Text := 'Primo';
  FTrack.AddRead(LEvent);
  LEvent.Text := 'Secondo';
  FTrack.AddRead(LEvent);

  Assert.AreEqual('Primo', string(FTrack.Title));
  Assert.AreEqual(3, FTrack.Count);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXmiMidiTrack);

end.
