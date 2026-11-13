{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TSpeedCircuitReader                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Speed.CircuitReader;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Speed.Intf, DelphiDoom.Tests.Speed.Fakes;

type
  [TestFixture]
  [Category('speed')]
  TTestSpeedCircuitReader = class(TObject)
  strict private
    FLog: TFakeLog;
    FReader: ISpeedCircuitReader;
    FLogReference: IInterface;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeLeggereIDatiDiUnCircuito;
    [Test]
    procedure DovrebbeLeggereIlNomeConGliSpaziEUnApostrofo;
    [Test]
    procedure DovrebbeDareSempreOttoCircuiti;
    [Test]
    procedure DovrebbeDareCircuitiVuotiSeIlTestoEVuoto;
    [Test]
    procedure DovrebbeLeggereSoloOttoCircuiti;
    [Test]
    procedure DovrebbeTagliareUnNomeDiOltreSessantaquattroCaratteri;
    [Test]
    procedure DovrebbeLasciareaZeroICampiCheMancano;
    [Test]
    procedure DovrebbeLeggereDueCircuitiDiSeguito;
    [Test]
    procedure DovrebbeRifiutareUnLogNil;
    [Test]
    procedure DovrebbeLeggereIlTestoSintetico;
  end;

implementation

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Speed.Types, DelphiDoom.Speed.Factory, DelphiDoom.Speed.CircuitReader,
  DelphiDoom.Tests.Speed.JclBuilder;

const
  ONE_CIRCUIT =
    '1'#13#10 +
    'Circuit'#13#10 +
    'Name "Racer''s Edge"'#13#10 +
    'Number 3'#13#10 +
    'Level  2'#13#10 +
    'Length 2568'#13#10 +
    'Best   1968'#13#10 +
    'Record 28 33'#13#10 +
    'NBack  4'#13#10;

{ TTestSpeedCircuitReader }

procedure TTestSpeedCircuitReader.Setup;
begin
  FLog := TFakeLog.Create;
  FLogReference := FLog;
  FReader := TSpeedFactory.CreateCircuitReader(FLog);
end;

procedure TTestSpeedCircuitReader.TearDown;
begin
  FReader := nil;
  FLogReference := nil;
end;

procedure TTestSpeedCircuitReader.DovrebbeLeggereIDatiDiUnCircuito;
var
  LCircuits: TArray<TSpeedCircuit>;
begin
  LCircuits := FReader.Parse(ONE_CIRCUIT);
  Assert.AreEqual(3, LCircuits[0].Number);
  Assert.AreEqual(2, LCircuits[0].Level);
  Assert.AreEqual(2568, LCircuits[0].Length);
  Assert.AreEqual(1968, LCircuits[0].Best);
  Assert.AreEqual(28, LCircuits[0].FirstRecord);
  Assert.AreEqual(33, LCircuits[0].SecondRecord);
  Assert.AreEqual(4, LCircuits[0].Background);
end;

procedure TTestSpeedCircuitReader.DovrebbeLeggereIlNomeConGliSpaziEUnApostrofo;
begin
  Assert.AreEqual('Racer''s Edge', FReader.Parse(ONE_CIRCUIT)[0].Name);
end;

procedure TTestSpeedCircuitReader.DovrebbeDareSempreOttoCircuiti;
begin
  Assert.AreEqual<Integer>(SPEED_MAX_CIRCUITS, Length(FReader.Parse(ONE_CIRCUIT)));
  Assert.AreEqual('', FReader.Parse(ONE_CIRCUIT)[7].Name);
end;

procedure TTestSpeedCircuitReader.DovrebbeDareCircuitiVuotiSeIlTestoEVuoto;
var
  LCircuits: TArray<TSpeedCircuit>;
begin
  LCircuits := FReader.Parse('');
  Assert.AreEqual<Integer>(SPEED_MAX_CIRCUITS, Length(LCircuits));
  Assert.AreEqual(0, LCircuits[0].Length);
end;

procedure TTestSpeedCircuitReader.DovrebbeLeggereSoloOttoCircuiti;
var
  LText: TBytes;
  LCircuits: TArray<TSpeedCircuit>;
begin
  LText := TJclBuilder.CircuitsText(12);
  LCircuits := FReader.Parse(TEncoding.ASCII.GetString(LText));
  Assert.AreEqual<Integer>(8, Length(LCircuits));
  Assert.AreEqual('Circuit 7 of Speed', LCircuits[7].Name);
end;

procedure TTestSpeedCircuitReader.DovrebbeTagliareUnNomeDiOltreSessantaquattroCaratteri;
var
  LName: string;
begin
  LName := StringOfChar('X', 100);
  Assert.AreEqual(64, Length(FReader.Parse('1 Circuit Name "' + LName + '" Number 1')[0].Name));
end;

procedure TTestSpeedCircuitReader.DovrebbeLasciareaZeroICampiCheMancano;
var
  LCircuits: TArray<TSpeedCircuit>;
begin
  LCircuits := FReader.Parse('1 Circuit Name "A" Number 5');
  Assert.AreEqual(5, LCircuits[0].Number);
  Assert.AreEqual(0, LCircuits[0].Best);
  Assert.AreEqual(0, LCircuits[0].Level);
end;

procedure TTestSpeedCircuitReader.DovrebbeLeggereDueCircuitiDiSeguito;
var
  LCircuits: TArray<TSpeedCircuit>;
begin
  LCircuits := FReader.Parse(
    '2 Circuit Name "A" Number 0 Level 1 Length 10 Best 20 Record 1 2 NBack 0 ' +
    'Circuit Name "B" Number 1 Level 3 Length 30 Best 40 Record 5 6 NBack 1');
  Assert.AreEqual('A', LCircuits[0].Name);
  Assert.AreEqual('B', LCircuits[1].Name);
  Assert.AreEqual(40, LCircuits[1].Best);
  Assert.AreEqual(6, LCircuits[1].SecondRecord);
end;

procedure TTestSpeedCircuitReader.DovrebbeRifiutareUnLogNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TSpeedCircuitReader.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestSpeedCircuitReader.DovrebbeLeggereIlTestoSintetico;
var
  LCircuits: TArray<TSpeedCircuit>;
begin
  LCircuits := FReader.Parse(TEncoding.ASCII.GetString(TJclBuilder.CircuitsText(2)));
  Assert.AreEqual('Circuit 1 of Speed', LCircuits[1].Name);
  Assert.AreEqual(2111, LCircuits[1].Length);
  Assert.AreEqual(1077, LCircuits[1].Best);
  Assert.AreEqual(26, LCircuits[1].SecondRecord);
  Assert.AreEqual(0, FLog.Warnings.Count);
end;

end.
