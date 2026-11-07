{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ACS machine - the variables and the store          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Acs.Variables;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Acs.Machine.Types,
  DelphiDoom.Acs.Machine.Variables;

type
  [TestFixture]
  [Category('acs')]
  TTestAcsVariables = class(TObject)
  private
    FVariables: TAcsVariables;
    function Arguments(AFirst: Byte): TAcsArguments;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbePartireConTuttoAZero;
    [Test]
    procedure DovrebbeDareLoSpazioDiUnaVariabileDellaMappa;
    [Test]
    procedure DovrebbeDareNilPerUnIndiceSbagliato;
    [Test]
    procedure DovrebbeAzzerareLeVariabiliDellaMappaSenzaToccareQuelleDelMondo;
    [Test]
    procedure DovrebbeAzzerareMondoEArchivioInUnNuovoGioco;
    [Test]
    procedure DovrebbeAggiungereAllArchivioEChiudereLaLista;
    [Test]
    procedure DovrebbeRifiutareUnDoppioneNellArchivio;
    [Test]
    procedure DovrebbeRiusareUnaVoceLibera;
    [Test]
    procedure DovrebbeFallireQuandoLArchivioEPieno;
    [Test]
    procedure DovrebbeAvereUnaVoceDiArchivioDiDodiciByte;
  end;

implementation

{ TTestAcsVariables }

procedure TTestAcsVariables.Setup;
begin
  FVariables := TAcsVariables.Create;
end;

procedure TTestAcsVariables.TearDown;
begin
  FVariables.Free;
end;

function TTestAcsVariables.Arguments(AFirst: Byte): TAcsArguments;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result[0] := AFirst;
end;

procedure TTestAcsVariables.DovrebbePartireConTuttoAZero;
begin
  Assert.AreEqual(0, FVariables.MapSlot(0)^);
  Assert.AreEqual(0, FVariables.WorldSlot(63)^);
  Assert.AreEqual(0, FVariables.StoreEntry(0).Map);
end;

procedure TTestAcsVariables.DovrebbeDareLoSpazioDiUnaVariabileDellaMappa;
begin
  FVariables.MapSlot(5)^ := 99;
  Assert.AreEqual(99, FVariables.Map[5]);
  FVariables.WorldSlot(7)^ := 11;
  Assert.AreEqual(11, FVariables.World[7]);
end;

procedure TTestAcsVariables.DovrebbeDareNilPerUnIndiceSbagliato;
begin
  Assert.IsFalse(Assigned(FVariables.MapSlot(32)));
  Assert.IsFalse(Assigned(FVariables.MapSlot(-1)));
  Assert.IsFalse(Assigned(FVariables.WorldSlot(64)));
end;

procedure TTestAcsVariables.DovrebbeAzzerareLeVariabiliDellaMappaSenzaToccareQuelleDelMondo;
begin
  FVariables.MapSlot(1)^ := 4;
  FVariables.WorldSlot(1)^ := 5;
  FVariables.ClearMap;
  Assert.AreEqual(0, FVariables.Map[1]);
  Assert.AreEqual(5, FVariables.World[1]);
end;

procedure TTestAcsVariables.DovrebbeAzzerareMondoEArchivioInUnNuovoGioco;
begin
  FVariables.WorldSlot(1)^ := 5;
  FVariables.AddToStore(2, 1, Arguments(1));
  FVariables.ClearWorld;
  Assert.AreEqual(0, FVariables.World[1]);
  Assert.AreEqual(0, FVariables.StoreEntry(0).Map);
end;

procedure TTestAcsVariables.DovrebbeAggiungereAllArchivioEChiudereLaLista;
begin
  Assert.IsTrue(FVariables.AddToStore(3, 10, Arguments(7)));
  Assert.AreEqual(3, FVariables.StoreEntry(0).Map);
  Assert.AreEqual(10, FVariables.StoreEntry(0).Script);
  Assert.AreEqual(7, Integer(FVariables.StoreEntry(0).Args[0]));
  Assert.AreEqual(0, FVariables.StoreEntry(1).Map);
end;

procedure TTestAcsVariables.DovrebbeRifiutareUnDoppioneNellArchivio;
begin
  Assert.IsTrue(FVariables.AddToStore(3, 10, Arguments(1)));
  Assert.IsFalse(FVariables.AddToStore(3, 10, Arguments(2)));
  Assert.AreEqual(1, Integer(FVariables.StoreEntry(0).Args[0]));
  Assert.IsTrue(FVariables.AddToStore(4, 10, Arguments(2)));
end;

procedure TTestAcsVariables.DovrebbeRiusareUnaVoceLibera;
begin
  FVariables.AddToStore(3, 10, Arguments(1));
  FVariables.AddToStore(3, 11, Arguments(1));
  FVariables.StoreEntry(0).Map := -1;
  Assert.IsTrue(FVariables.AddToStore(5, 12, Arguments(1)));
  Assert.AreEqual(5, FVariables.StoreEntry(0).Map);
  Assert.AreEqual(12, FVariables.StoreEntry(0).Script);
  Assert.AreEqual(3, FVariables.StoreEntry(1).Map);
end;

procedure TTestAcsVariables.DovrebbeFallireQuandoLArchivioEPieno;
var
  LIndex: Integer;
begin
  for LIndex := 1 to ACS_STORE_SIZE do
    Assert.IsTrue(FVariables.AddToStore(2, LIndex, Arguments(0)));
  Assert.WillRaise(
    procedure
    begin
      FVariables.AddToStore(2, 100, Arguments(0));
    end,
    EAcsMachineException);
end;

procedure TTestAcsVariables.DovrebbeAvereUnaVoceDiArchivioDiDodiciByte;
begin
  Assert.AreEqual(12, SizeOf(TAcsStoreEntry));
  Assert.AreEqual(252, SizeOf(TAcsStore));
  Assert.AreEqual(128, SizeOf(TAcsMapVariables));
  Assert.AreEqual(256, SizeOf(TAcsWorldVariables));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAcsVariables);

end.
