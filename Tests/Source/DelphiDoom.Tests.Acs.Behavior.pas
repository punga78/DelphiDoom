{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ACS machine - the object code of a map             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Acs.Behavior;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Acs.Machine.Types,
  DelphiDoom.Acs.Machine.Behavior, DelphiDoom.Logging.Intf, DelphiDoom.Logging.Types,
  DelphiDoom.Logging.Recorder;

type
  [TestFixture]
  [Category('acs')]
  TTestAcsBehavior = class(TObject)
  private
    FBehavior: TAcsBehavior;
    FRecorder: TLogRecorder;
    FSink: ILogSink;
    FCode: TBytes;
    function LoadCode(const ACode: TBytes): Boolean;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereLaTabellaDegliScript;
    [Test]
    procedure DovrebbeTrattareGliScriptConNumeroDaMilleInPoiComeAperti;
    [Test]
    procedure DovrebbeLeggereLeStringhe;
    [Test]
    procedure DovrebbeDareFalsoPerUnIndiceDiStringaSbagliato;
    [Test]
    procedure DovrebbeTrovareLIndiceDiUnoScript;
    [Test]
    procedure DovrebbeRifiutareUnMarcatoreSbagliato;
    [Test]
    procedure DovrebbeRifiutareUnOggettoTroppoCorto;
    [Test]
    procedure DovrebbeRifiutareUnaTabellaFuoriDalCodice;
    [Test]
    procedure DovrebbeRifiutareUnoScriptCheParteFuoriDalCodice;
    [Test]
    procedure DovrebbeRifiutareUnoScriptConTroppiArgomenti;
    [Test]
    procedure DovrebbeRifiutareUnaStringaFuoriDalCodice;
    [Test]
    procedure DovrebbeRisolvereSoloIndirizziDentroIlCodice;
  end;

implementation

uses
  DelphiDoom.Logging.Factory, DelphiDoom.Tests.Acs.ObjectBuilder;

{ TTestAcsBehavior }

procedure TTestAcsBehavior.Setup;
begin
  FRecorder := TLogRecorder.Create;
  FSink := FRecorder;
  FBehavior := TAcsBehavior.Create(TLogFactory.CreateLog(TArray<ILogSink>.Create(FSink), nil));
end;

procedure TTestAcsBehavior.TearDown;
begin
  FBehavior.Free;
  FSink := nil;
  FRecorder := nil;
end;

function TTestAcsBehavior.LoadCode(const ACode: TBytes): Boolean;
begin
  FCode := ACode;
  Result := FBehavior.Load(@FCode[0], Length(FCode));
end;

procedure TTestAcsBehavior.DovrebbeLeggereLaTabellaDegliScript;
begin
  Assert.IsTrue(LoadCode(TAcsObjectBuilder.Build([1], [], 7, 2)));
  Assert.AreEqual(1, FBehavior.ScriptCount);
  Assert.AreEqual(7, FBehavior.GetScript(0).Number);
  Assert.AreEqual(2, FBehavior.GetScript(0).ArgCount);
  Assert.IsTrue(FBehavior.GetScript(0).State = assInactive);
  Assert.AreEqual(12, Integer(NativeInt(FBehavior.GetScript(0).Address) - NativeInt(FBehavior.Code)));
  Assert.IsFalse(FBehavior.IsOpenScript(0));
end;

procedure TTestAcsBehavior.DovrebbeTrattareGliScriptConNumeroDaMilleInPoiComeAperti;
begin
  Assert.IsTrue(LoadCode(TAcsObjectBuilder.Build([1], [], 1003)));
  Assert.IsTrue(FBehavior.IsOpenScript(0));
  Assert.AreEqual(3, FBehavior.GetScript(0).Number);
  Assert.IsTrue(FBehavior.GetScript(0).State = assRunning);
end;

procedure TTestAcsBehavior.DovrebbeLeggereLeStringhe;
var
  LText: string;
begin
  Assert.IsTrue(LoadCode(TAcsObjectBuilder.Build([1], ['first', '', 'third'])));
  Assert.AreEqual(3, FBehavior.StringCount);
  Assert.IsTrue(FBehavior.TryGetString(0, LText));
  Assert.AreEqual('first', LText);
  Assert.IsTrue(FBehavior.TryGetString(1, LText));
  Assert.AreEqual('', LText);
  Assert.IsTrue(FBehavior.TryGetString(2, LText));
  Assert.AreEqual('third', LText);
end;

procedure TTestAcsBehavior.DovrebbeDareFalsoPerUnIndiceDiStringaSbagliato;
var
  LText: string;
begin
  Assert.IsTrue(LoadCode(TAcsObjectBuilder.Build([1], ['a'])));
  Assert.IsFalse(FBehavior.TryGetString(1, LText));
  Assert.IsFalse(FBehavior.TryGetString(-1, LText));
end;

procedure TTestAcsBehavior.DovrebbeTrovareLIndiceDiUnoScript;
begin
  Assert.IsTrue(LoadCode(TAcsObjectBuilder.Build([1], [], 42)));
  Assert.AreEqual(0, FBehavior.IndexOfScript(42));
  Assert.AreEqual(-1, FBehavior.IndexOfScript(43));
end;

procedure TTestAcsBehavior.DovrebbeRifiutareUnMarcatoreSbagliato;
var
  LCode: TBytes;
begin
  LCode := TAcsObjectBuilder.Build([1], []);
  TAcsObjectBuilder.PutLong(LCode, 0, $45534341);
  Assert.IsFalse(LoadCode(LCode));
  Assert.AreEqual(0, FBehavior.ScriptCount);
  Assert.IsTrue(FRecorder.Count > 0, 'a warning');
end;

procedure TTestAcsBehavior.DovrebbeRifiutareUnOggettoTroppoCorto;
begin
  SetLength(FCode, 8);
  Assert.IsFalse(FBehavior.Load(@FCode[0], 8));
  Assert.IsFalse(FBehavior.Load(nil, 0));
end;

procedure TTestAcsBehavior.DovrebbeRifiutareUnaTabellaFuoriDalCodice;
var
  LCode: TBytes;
begin
  LCode := TAcsObjectBuilder.Build([1], []);
  TAcsObjectBuilder.PutLong(LCode, 4, Length(LCode) + 100);
  Assert.IsFalse(LoadCode(LCode));
  LCode := TAcsObjectBuilder.Build([1], []);
  TAcsObjectBuilder.PutLong(LCode, TAcsObjectBuilder.LongAt(LCode, 4), 100000);
  Assert.IsFalse(LoadCode(LCode), 'too many scripts');
  Assert.AreEqual(0, FBehavior.ScriptCount);
end;

procedure TTestAcsBehavior.DovrebbeRifiutareUnoScriptCheParteFuoriDalCodice;
var
  LCode: TBytes;
begin
  LCode := TAcsObjectBuilder.Build([1], []);
  TAcsObjectBuilder.PutLong(LCode, TAcsObjectBuilder.LongAt(LCode, 4) + 8, Length(LCode) + 4);
  Assert.IsFalse(LoadCode(LCode));
end;

procedure TTestAcsBehavior.DovrebbeRifiutareUnoScriptConTroppiArgomenti;
begin
  Assert.IsFalse(LoadCode(TAcsObjectBuilder.Build([1], [], 1, 11)));
  Assert.IsFalse(LoadCode(TAcsObjectBuilder.Build([1], [], 1, -1)));
end;

procedure TTestAcsBehavior.DovrebbeRifiutareUnaStringaFuoriDalCodice;
var
  LCode: TBytes;
  LTable: Integer;
begin
  LCode := TAcsObjectBuilder.Build([1], ['abc']);
  LTable := TAcsObjectBuilder.LongAt(LCode, 4);
  TAcsObjectBuilder.PutLong(LCode, LTable + 20, Length(LCode) + 10);
  Assert.IsFalse(LoadCode(LCode));
  Assert.AreEqual(0, FBehavior.ScriptCount);
end;
procedure TTestAcsBehavior.DovrebbeRisolvereSoloIndirizziDentroIlCodice;
begin
  Assert.IsTrue(LoadCode(TAcsObjectBuilder.Build([1], [])));
  Assert.IsTrue(Assigned(FBehavior.AddressAt(0)));
  Assert.IsTrue(Assigned(FBehavior.AddressAt(Length(FCode) - 4)));
  Assert.IsFalse(Assigned(FBehavior.AddressAt(Length(FCode) - 3)));
  Assert.IsFalse(Assigned(FBehavior.AddressAt(-1)));
  Assert.IsTrue(FBehavior.Contains(PInteger(FBehavior.Code)));
  Assert.IsFalse(FBehavior.Contains(PInteger(FBehavior.Code + FBehavior.Size)));
  Assert.IsFalse(FBehavior.Contains(nil));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAcsBehavior);

end.
