{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the TableExport library - the chain of states          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.TableExport.StateChain;

interface

uses
  DUnitX.TestFramework, DelphiDoom.TableExport.Types, DelphiDoom.TableExport.Intf,
  DelphiDoom.TableExport.StateChain, DelphiDoom.TableExport.IndentedText,
  DelphiDoom.Tests.TableExport.Fakes;

type
  [TestFixture]
  [Category('tableexport')]
  TTestTableExportStateChain = class(TObject)
  private
    FStates: TFakeStates;
    FStatesIntf: IExportStateSource;
    FChain: TExportStateChain;
    FText: TExportIndentedText;
    function Write(const ALabel: string; AFirst: Integer; const ALabels: TArray<TExportStateLabel>): string;
    function Labels(const ANames: array of string; const AStates: array of Integer): TArray<TExportStateLabel>;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestDovrebbeChiudereUnCicloConLoop;
    [Test]
    procedure TestDovrebbeFermarsiConStopSeNonCeIlSeguente;
    [Test]
    procedure TestDovrebbeFermarsiSuUnoStatoSenzaFine;
    [Test]
    procedure TestDovrebbeRimandareAUnaEtichettaDelProprietario;
    [Test]
    procedure TestDovrebbeRimandareAUnoStatoGiaScrittoConLOffset;
    [Test]
    procedure TestDovrebbeScrivereAzioneBrightEFast;
    [Test]
    procedure TestDovrebbeOmetterelAzioneNull;
    [Test]
    procedure TestDovrebbeScrivereLeDurateCasuali;
    [Test]
    procedure TestDovrebbeNonScrivereNullaPerUnoStatoZero;
    [Test]
    procedure TestDovrebbeRifiutareUnaSorgenteMancante;
  end;

implementation

uses
  System.SysUtils;

{ TTestTableExportStateChain }

procedure TTestTableExportStateChain.Setup;
begin
  FStates := TFakeStates.Create;
  FStatesIntf := FStates;
  FStates.AddState('NULL', 0, 0, 0);
  FChain := TExportStateChain.Create(FStatesIntf);
  FText := TExportIndentedText.Create;
end;

procedure TTestTableExportStateChain.TearDown;
begin
  FText.Free;
  FChain.Free;
  FStatesIntf := nil;
end;

function TTestTableExportStateChain.Write(const ALabel: string; AFirst: Integer;
  const ALabels: TArray<TExportStateLabel>): string;
begin
  FChain.Write(FText, ALabel, AFirst, ALabels);
  Result := FText.Text;
end;

function TTestTableExportStateChain.Labels(const ANames: array of string;
  const AStates: array of Integer): TArray<TExportStateLabel>;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(ANames));
  for LIndex := 0 to High(ANames) do
  begin
    Result[LIndex].Name := ANames[LIndex];
    Result[LIndex].State := AStates[LIndex];
  end;
end;

procedure TTestTableExportStateChain.TestDovrebbeChiudereUnCicloConLoop;
begin
  FStates.AddState('TROO', 0, 4, 2);
  FStates.AddState('TROO', 1, 4, 1);
  Assert.AreEqual('Spawn:'#13#10'{'#13#10'  TROO A 4'#13#10'  TROO B 4'#13#10'  Loop'#13#10'}'#13#10,
    Write('Spawn', 1, Labels(['Spawn'], [1])));
end;

procedure TTestTableExportStateChain.TestDovrebbeFermarsiConStopSeNonCeIlSeguente;
begin
  FStates.AddState('TROO', 2, 6, 0);
  Assert.AreEqual('Death:'#13#10'{'#13#10'  TROO C 6'#13#10'  Stop'#13#10'}'#13#10,
    Write('Death', 1, Labels(['Death'], [1])));
end;

procedure TTestTableExportStateChain.TestDovrebbeFermarsiSuUnoStatoSenzaFine;
begin
  FStates.AddState('TROO', 3, -1, 1);
  Assert.AreEqual('Death:'#13#10'{'#13#10'  TROO D -1'#13#10'}'#13#10,
    Write('Death', 1, Labels(['Death'], [1])));
end;

procedure TTestTableExportStateChain.TestDovrebbeRimandareAUnaEtichettaDelProprietario;
begin
  FStates.AddState('TROO', 0, 4, 2);
  FStates.AddState('TROO', 1, 4, 3);
  FStates.AddState('SPOS', 0, 4, 3);
  Assert.AreEqual('See:'#13#10'{'#13#10'  TROO A 4'#13#10'  TROO B 4'#13#10'  Goto Spawn'#13#10'}'#13#10,
    Write('See', 1, Labels(['Spawn', 'See'], [3, 1])));
end;

procedure TTestTableExportStateChain.TestDovrebbeRimandareAUnoStatoGiaScrittoConLOffset;
begin
  FStates.AddState('TROO', 0, 4, 2);
  FStates.AddState('TROO', 1, 4, 3);
  FStates.AddState('TROO', 2, 4, 2);
  Assert.AreEqual('Spawn:'#13#10'{'#13#10'  TROO A 4'#13#10'  TROO B 4'#13#10'  TROO C 4'#13#10'  Goto Spawn+1'#13#10'}'#13#10,
    Write('Spawn', 1, Labels(['Spawn'], [1])));
end;

procedure TTestTableExportStateChain.TestDovrebbeScrivereAzioneBrightEFast;
var
  LState: TExportState;
begin
  FStates.AddState('TROO', 0, 4, 0, 'CHASE');
  LState := FStates.Items[1];
  LState.Numbers[sfFrame] := EXPORT_FRAME_FULLBRIGHT or 1;
  LState.Numbers[sfMbf21Bits] := EXPORT_STATE_SKILL5FAST;
  LState.HasParams := True;
  LState.Params := '(1, 2)';
  FStates.Items[1] := LState;
  Assert.AreEqual('See:'#13#10'{'#13#10'  TROO B 4 CHASE (1, 2) BRIGHT FAST'#13#10'  Stop'#13#10'}'#13#10,
    Write('See', 1, Labels(['See'], [1])));
end;

procedure TTestTableExportStateChain.TestDovrebbeOmetterelAzioneNull;
begin
  FStates.AddState('TROO', 0, 4, 0, 'NULL');
  Assert.AreEqual('See:'#13#10'{'#13#10'  TROO A 4'#13#10'  Stop'#13#10'}'#13#10,
    Write('See', 1, Labels(['See'], [1])));
end;

procedure TTestTableExportStateChain.TestDovrebbeScrivereLeDurateCasuali;
var
  LState: TExportState;
begin
  FStates.AddState('TROO', 0, 4, 2);
  FStates.AddState('TROO', 0, 4, 0);
  LState := FStates.Items[1];
  LState.Numbers[sfTics2] := 9;
  LState.Numbers[sfFlagsEx] := EXPORT_STATE_RANDOM_SELECT;
  FStates.Items[1] := LState;
  LState := FStates.Items[2];
  LState.Numbers[sfTics2] := 12;
  LState.Numbers[sfFlagsEx] := EXPORT_STATE_RANDOM_RANGE;
  FStates.Items[2] := LState;
  Assert.AreEqual('See:'#13#10'{'#13#10'  TROO A RANDOMSELECT(4,9)'#13#10'  TROO A RANDOMRANGE(4,12)'#13#10'  Stop'#13#10'}'#13#10,
    Write('See', 1, Labels(['See'], [1])));
end;

procedure TTestTableExportStateChain.TestDovrebbeNonScrivereNullaPerUnoStatoZero;
begin
  Assert.AreEqual('', Write('Spawn', 0, nil));
end;

procedure TTestTableExportStateChain.TestDovrebbeRifiutareUnaSorgenteMancante;
begin
  Assert.WillRaise(
    procedure
    begin
      TExportStateChain.Create(nil).Free;
    end, EArgumentNilException);
end;

end.
