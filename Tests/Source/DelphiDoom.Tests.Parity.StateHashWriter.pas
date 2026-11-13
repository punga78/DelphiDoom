{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the parity library - the writer of the state           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Parity.StateHashWriter;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Parity.Intf,
  DelphiDoom.Parity.StateHashWriter,
  DelphiDoom.Tests.Parity.Fakes;

type
  [TestFixture]
  [Category('parity')]
  TTestParityStateHashWriter = class(TObject)
  strict private
    FLog: TFakeParityLog;
    FLogRef: IParityLog;
    function CreateWriter(ADetail: Boolean; AFirst, ALast: Integer): IParityStateSink;
    procedure WriteTic(const ASink: IParityStateSink; ATic, AValue: Integer);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareUnLogNil;
    [Test]
    procedure DovrebbeScrivereUnaRigaPerTic;
    [Test]
    procedure LaRigaDovrebbeAvereIlTicIlTotaleLeCategorieEiNumeri;
    [Test]
    procedure DueEsecuzioniUgualiDovrebberoDareRigheUguali;
    [Test]
    procedure UnCampoDiversoDovrebbeCambiareLaSuaCategoriaESoloQuella;
    [Test]
    procedure UnCampoDiversoDovrebbeCambiareIlTotale;
    [Test]
    procedure LOrdineDegliOggettiDovrebbeContare;
    [Test]
    procedure UnNumeroDiOggettiDiversoDovrebbeCambiareLaCategoria;
    [Test]
    procedure UnTicNuovoDovrebbeRipartireDaCapo;
    [Test]
    procedure SenzaDettaglioNonDovrebbeScrivereLeRigheD;
    [Test]
    procedure ConIlDettaglioDovrebbeScrivereUnaRigaPerCampoNelLIntervallo;
    [Test]
    procedure FuoriDalLIntervalloNonDovrebbeScrivereIlDettaglio;
    [Test]
    procedure UnaCategoriaSconosciutaDovrebbeDareEccezione;
    [Test]
    procedure UnCampoSenzaOggettoDovrebbeDareEccezione;
    [Test]
    procedure UnCampoNonDichiaratoNelDettaglioDovrebbeDareEccezione;
  end;

implementation

uses
  DelphiDoom.Parity.Types;

procedure TTestParityStateHashWriter.Setup;
begin
  FLog := TFakeParityLog.Create;
  FLogRef := FLog;
end;

procedure TTestParityStateHashWriter.TearDown;
begin
  FLog := nil;
  FLogRef := nil;
end;

function TTestParityStateHashWriter.CreateWriter(ADetail: Boolean; AFirst, ALast: Integer): IParityStateSink;
begin
  Result := TStateHashWriter.Create(FLogRef, ADetail, AFirst, ALast);
  Result.RegisterCategory('mobj', ['x', 'y']);
  Result.RegisterCategory('sector', ['floor']);
end;

procedure TTestParityStateHashWriter.WriteTic(const ASink: IParityStateSink; ATic, AValue: Integer);
begin
  ASink.BeginTic(ATic);
  ASink.BeginObject(0, 0);
  ASink.Field(0, AValue);
  ASink.Field(1, 20);
  ASink.EndObject;
  ASink.BeginObject(1, 0);
  ASink.Field(0, 100);
  ASink.EndObject;
  ASink.Scalar('lt', ATic);
  ASink.EndTic;
end;

procedure TTestParityStateHashWriter.DovrebbeRifiutareUnLogNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TStateHashWriter.Create(nil, False, 0, 0);
    end, EArgumentNilException);
end;

procedure TTestParityStateHashWriter.DovrebbeScrivereUnaRigaPerTic;
var
  LSink: IParityStateSink;
begin
  LSink := CreateWriter(False, 0, 0);
  WriteTic(LSink, 1, 10);
  WriteTic(LSink, 2, 10);
  Assert.AreEqual(2, FLog.Lines.Count);
end;

procedure TTestParityStateHashWriter.LaRigaDovrebbeAvereIlTicIlTotaleLeCategorieEiNumeri;
var
  LSink: IParityStateSink;
  LParts: TArray<string>;
begin
  LSink := CreateWriter(False, 0, 0);
  WriteTic(LSink, 7, 10);
  LParts := FLog.Lines[0].Split([' ']);
  Assert.AreEqual<Integer>(6, Length(LParts));
  Assert.AreEqual('T', LParts[0]);
  Assert.AreEqual('7', LParts[1]);
  Assert.AreEqual(16, Length(LParts[2]));
  Assert.IsTrue(LParts[3].StartsWith('mobj='));
  Assert.AreEqual(5 + 8, Length(LParts[3]));
  Assert.IsTrue(LParts[4].StartsWith('sector='));
  Assert.AreEqual('lt=7', LParts[5]);
end;

procedure TTestParityStateHashWriter.DueEsecuzioniUgualiDovrebberoDareRigheUguali;
var
  LFirst: IParityStateSink;
  LSecond: IParityStateSink;
begin
  LFirst := CreateWriter(False, 0, 0);
  WriteTic(LFirst, 3, 10);
  LSecond := CreateWriter(False, 0, 0);
  WriteTic(LSecond, 3, 10);
  Assert.AreEqual(FLog.Lines[0], FLog.Lines[1]);
end;

procedure TTestParityStateHashWriter.UnCampoDiversoDovrebbeCambiareLaSuaCategoriaESoloQuella;
var
  LSink: IParityStateSink;
  LFirst: TArray<string>;
  LSecond: TArray<string>;
begin
  LSink := CreateWriter(False, 0, 0);
  WriteTic(LSink, 3, 10);
  WriteTic(LSink, 3, 11);
  LFirst := FLog.Lines[0].Split([' ']);
  LSecond := FLog.Lines[1].Split([' ']);
  Assert.AreNotEqual(LFirst[3], LSecond[3], 'mobj');
  Assert.AreEqual(LFirst[4], LSecond[4], 'sector');
end;

procedure TTestParityStateHashWriter.UnCampoDiversoDovrebbeCambiareIlTotale;
var
  LSink: IParityStateSink;
  LFirst: TArray<string>;
  LSecond: TArray<string>;
begin
  LSink := CreateWriter(False, 0, 0);
  WriteTic(LSink, 3, 10);
  WriteTic(LSink, 3, 11);
  LFirst := FLog.Lines[0].Split([' ']);
  LSecond := FLog.Lines[1].Split([' ']);
  Assert.AreNotEqual(LFirst[2], LSecond[2]);
end;

procedure TTestParityStateHashWriter.LOrdineDegliOggettiDovrebbeContare;
var
  LSink: IParityStateSink;
begin
  LSink := CreateWriter(False, 0, 0);
  LSink.BeginTic(1);
  LSink.BeginObject(0, 0);
  LSink.Field(0, 1);
  LSink.Field(1, 2);
  LSink.EndObject;
  LSink.BeginObject(0, 1);
  LSink.Field(0, 3);
  LSink.Field(1, 4);
  LSink.EndObject;
  LSink.EndTic;
  LSink.BeginTic(1);
  LSink.BeginObject(0, 0);
  LSink.Field(0, 3);
  LSink.Field(1, 4);
  LSink.EndObject;
  LSink.BeginObject(0, 1);
  LSink.Field(0, 1);
  LSink.Field(1, 2);
  LSink.EndObject;
  LSink.EndTic;
  Assert.AreNotEqual(FLog.Lines[0], FLog.Lines[1]);
end;

procedure TTestParityStateHashWriter.UnNumeroDiOggettiDiversoDovrebbeCambiareLaCategoria;
var
  LSink: IParityStateSink;
begin
  LSink := CreateWriter(False, 0, 0);
  LSink.BeginTic(1);
  LSink.BeginObject(0, 0);
  LSink.Field(0, 1);
  LSink.Field(1, 2);
  LSink.EndObject;
  LSink.EndTic;
  LSink.BeginTic(1);
  LSink.EndTic;
  Assert.AreNotEqual(FLog.Lines[0], FLog.Lines[1]);
end;

procedure TTestParityStateHashWriter.UnTicNuovoDovrebbeRipartireDaCapo;
var
  LSink: IParityStateSink;
begin
  LSink := CreateWriter(False, 0, 0);
  WriteTic(LSink, 5, 10);
  WriteTic(LSink, 5, 10);
  // the second tic does not carry the numbers of the first one: the same line
  Assert.AreEqual(FLog.Lines[0], FLog.Lines[1]);
end;

procedure TTestParityStateHashWriter.SenzaDettaglioNonDovrebbeScrivereLeRigheD;
var
  LSink: IParityStateSink;
  LIndex: Integer;
begin
  LSink := CreateWriter(False, 0, 100);
  WriteTic(LSink, 5, 10);
  for LIndex := 0 to FLog.Lines.Count - 1 do
    Assert.IsFalse(FLog.Lines[LIndex].StartsWith('D '));
end;

procedure TTestParityStateHashWriter.ConIlDettaglioDovrebbeScrivereUnaRigaPerCampoNelLIntervallo;
var
  LSink: IParityStateSink;
begin
  LSink := CreateWriter(True, 4, 6);
  WriteTic(LSink, 5, 10);
  Assert.AreEqual(4, FLog.Lines.Count);
  Assert.AreEqual('D 5 mobj 0 x 10', FLog.Lines[0]);
  Assert.AreEqual('D 5 mobj 0 y 20', FLog.Lines[1]);
  Assert.AreEqual('D 5 sector 0 floor 100', FLog.Lines[2]);
  Assert.IsTrue(FLog.Lines[3].StartsWith('T 5 '));
end;

procedure TTestParityStateHashWriter.FuoriDalLIntervalloNonDovrebbeScrivereIlDettaglio;
var
  LSink: IParityStateSink;
begin
  LSink := CreateWriter(True, 4, 6);
  WriteTic(LSink, 3, 10);
  WriteTic(LSink, 7, 10);
  Assert.AreEqual(2, FLog.Lines.Count);
end;

procedure TTestParityStateHashWriter.UnaCategoriaSconosciutaDovrebbeDareEccezione;
var
  LSink: IParityStateSink;
begin
  LSink := CreateWriter(False, 0, 0);
  LSink.BeginTic(1);
  Assert.WillRaise(
    procedure
    begin
      LSink.BeginObject(9, 0);
    end, EParityException);
end;

procedure TTestParityStateHashWriter.UnCampoSenzaOggettoDovrebbeDareEccezione;
var
  LSink: IParityStateSink;
begin
  LSink := CreateWriter(False, 0, 0);
  LSink.BeginTic(1);
  Assert.WillRaise(
    procedure
    begin
      LSink.Field(0, 1);
    end, EParityException);
end;

procedure TTestParityStateHashWriter.UnCampoNonDichiaratoNelDettaglioDovrebbeDareEccezione;
var
  LSink: IParityStateSink;
begin
  LSink := CreateWriter(True, 0, 10);
  LSink.BeginTic(1);
  LSink.BeginObject(1, 0);
  Assert.WillRaise(
    procedure
    begin
      LSink.Field(5, 1);
    end, EParityException);
end;

end.
