{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Dehacked library - the fields of the things that   }
{  only one game has (IDehackedExtraThingFields)                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Dehacked.ExtraThingFields;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Logging.Intf, DelphiDoom.Logging.Recorder,
  DelphiDoom.Dehacked.Types, DelphiDoom.Dehacked.Intf, DelphiDoom.Dehacked.Games;

type
  [TestFixture]
  [Category('dehacked')]
  TTestDehackedExtraThingFields = class(TObject)
  private
    FRecorder: TLogRecorder;
    FSink: ILogSink;
    FSeen: TArray<string>;
    FExtra: IDehackedExtraThingFields;
    function Parse(const AText: string; const AExtra: IDehackedExtraThingFields): IDehackedPatch;
    function Warnings: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure UnCampoDelGiocoDovrebbeEssereLettoEIlBloccoContinuare;
    [Test]
    procedure DovrebbeDareIlNumeroDellaCosaOIlNomeDiUnaNuova;
    [Test]
    procedure UnCampoCheNeancheIlGiocoConosceDovrebbeDareLAvvisoEChiudereIlBlocco;
    [Test]
    procedure SenzaLettoreDovrebbeRestareComePrima;
    [Test]
    procedure IlLettoreNonDovrebbeEssereChiestoPerGliAltriBlocchi;
  end;

implementation

uses
  DelphiDoom.Logging.Types, DelphiDoom.Logging.Factory, DelphiDoom.Dehacked.Section,
  DelphiDoom.Dehacked.Factory;

const
  CRLF = #13#10;

type
  // knows the fields "ARMOR INC" and "AMMO ADD" and writes down what it was asked
  TFakeThingFields = class(TInterfacedObject, IDehackedExtraThingFields)
  strict private
    FOwner: TTestDehackedExtraThingFields;
  public
    constructor Create(AOwner: TTestDehackedExtraThingFields);
    function TryRead(const AThing: TDehackedReference; const AKey, AValue: string): Boolean;
  end;

{ TFakeThingFields }

constructor TFakeThingFields.Create(AOwner: TTestDehackedExtraThingFields);
begin
  inherited Create;
  FOwner := AOwner;
end;

function TFakeThingFields.TryRead(const AThing: TDehackedReference; const AKey, AValue: string): Boolean;
begin
  FOwner.FSeen := FOwner.FSeen + [Format('%d/%s/%s=%s', [AThing.Number, AThing.Name, AKey, AValue])];
  Result := (AKey = 'ARMOR INC') or (AKey = 'AMMO ADD');
end;

{ TTestDehackedExtraThingFields }

procedure TTestDehackedExtraThingFields.Setup;
begin
  FRecorder := TLogRecorder.Create;
  FSink := FRecorder;
  FSeen := nil;
  FExtra := TFakeThingFields.Create(Self);
end;

procedure TTestDehackedExtraThingFields.TearDown;
begin
  FExtra := nil;
  FSink := nil;
  FRecorder := nil;
end;

function TTestDehackedExtraThingFields.Parse(const AText: string;
  const AExtra: IDehackedExtraThingFields): IDehackedPatch;
begin
  Result := TDehackedFactory.CreateParser(dgDoom,
    TLogFactory.CreateLog(TArray<ILogSink>.Create(FSink), nil), AExtra).Parse(AText);
end;

function TTestDehackedExtraThingFields.Warnings: string;
begin
  Result := StringReplace(FRecorder.TextOf(TLogChannel.Output), CRLF, '|', [rfReplaceAll]);
end;

procedure TTestDehackedExtraThingFields.UnCampoDelGiocoDovrebbeEssereLettoEIlBloccoContinuare;
var
  LPatch: IDehackedPatch;
begin
  LPatch := Parse('Thing 3'#10'Speed = 1'#10'Armor Inc = 25'#10'Ammo Add = 0, 5, 0, 0'#10'Mass = 2', FExtra);
  // "Ammo Add" is not the header of an Ammo block here
  Assert.AreEqual(1, LPatch.SectionCount);
  Assert.AreEqual(2, LPatch.Section(0).Count);
  Assert.AreEqual('', Warnings);
  Assert.AreEqual<Integer>(2, Length(FSeen));
  Assert.AreEqual('3//ARMOR INC=25', FSeen[0]);
  Assert.AreEqual('3//AMMO ADD=0, 5, 0, 0', FSeen[1]);
end;

procedure TTestDehackedExtraThingFields.DovrebbeDareIlNumeroDellaCosaOIlNomeDiUnaNuova;
begin
  Parse('NewThing Supercharge'#10'Armor Inc = 7', FExtra);
  Assert.AreEqual<Integer>(1, Length(FSeen));
  Assert.AreEqual('-1/SUPERCHARGE/ARMOR INC=7', FSeen[0]);
end;

procedure TTestDehackedExtraThingFields.UnCampoCheNeancheIlGiocoConosceDovrebbeDareLAvvisoEChiudereIlBlocco;
var
  LPatch: IDehackedPatch;
begin
  LPatch := Parse('Thing 1'#10'Nonexistent = 3'#10'Mass = 2', FExtra);
  Assert.AreEqual(1, LPatch.SectionCount);
  Assert.AreEqual(0, LPatch.Section(0).Count);
  Assert.Contains(Warnings, 'Wrong think field = NONEXISTENT (Think number = 0)');
  Assert.AreEqual<Integer>(1, Length(FSeen));
end;

procedure TTestDehackedExtraThingFields.SenzaLettoreDovrebbeRestareComePrima;
begin
  Parse('Thing 1'#10'Speed = 1'#10'Armor Inc = 25'#10'Ammo Add = 0, 5, 0, 0', nil);
  Assert.Contains(Warnings, 'Wrong think field = ARMOR INC (Think number = 0)');
  Assert.Contains(Warnings, 'Wrong ammo number = ADD');
end;

procedure TTestDehackedExtraThingFields.IlLettoreNonDovrebbeEssereChiestoPerGliAltriBlocchi;
begin
  Parse('Frame 1'#10'Armor Inc = 25', FExtra);
  Assert.AreEqual<Integer>(0, Length(FSeen));
  Assert.Contains(Warnings, 'Wrong state field = ARMOR INC');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDehackedExtraThingFields);

end.
