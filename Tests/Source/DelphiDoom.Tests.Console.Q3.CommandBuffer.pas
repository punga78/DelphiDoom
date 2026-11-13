{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the command buffer of the Quake III console            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.Q3.CommandBuffer;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Console.Q3.Types, DelphiDoom.Console.Q3.Intf,
  DelphiDoom.Console.Q3.CommandBuffer, DelphiDoom.Tests.Console.Q3.Fakes;

type
  [TestFixture]
  [Category('console')]
  TTestQ3CommandBuffer = class(TObject)
  private
    FRegistry: TFakeQ3Registry;
    FRegistryIntf: IQ3CommandRegistry;
    FLog: TFakeQ3Log;
    FLogIntf: IQ3ConsoleLog;
    FBuffer: TQ3CommandBuffer;
    FBufferIntf: IQ3CommandBuffer;
    function Joined: string;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeRifiutareUnRegistroNil;
    [Test]
    procedure DovrebbeEseguireLeRigheSeparatePerPuntoEVirgolaEACapo;
    [Test]
    procedure DovrebbeNonSpezzareUnPuntoEVirgolaTraVirgolette;
    [Test]
    procedure DovrebbeInserireInTestaConUnACapo;
    [Test]
    procedure DovrebbeEseguireSubitoUnTestoENonIlBuffer;
    [Test]
    procedure DovrebbeEseguireIlBufferConUnTestoVuotoSubito;
    [Test]
    procedure DovrebbeLasciareIlRestoSeUnWaitEPendente;
    [Test]
    procedure DovrebbeTagliareUnaRigaLungaEPerdereUnCarattere;
    [Test]
    procedure DovrebbeSegnalareUnOverflowNellAggiunta;
    [Test]
    procedure DovrebbeSegnalareUnOverflowNellInserimento;
    [Test]
    procedure DovrebbeTroncareIlTestoAlPrimoNul;
    [Test]
    procedure DovrebbeRifiutareUnTipoDiEsecuzioneNonValido;
    [Test]
    procedure DovrebbeFunzionareSenzaLog;
  end;

implementation

procedure TTestQ3CommandBuffer.Setup;
begin
  FRegistry := TFakeQ3Registry.Create;
  FRegistryIntf := FRegistry;
  FLog := TFakeQ3Log.Create;
  FLogIntf := FLog;
  FBuffer := TQ3CommandBuffer.Create(FRegistryIntf, FLogIntf);
  FBufferIntf := FBuffer;
end;

function TTestQ3CommandBuffer.Joined: string;
var
  LLine: AnsiString;
begin
  Result := '';
  for LLine in FRegistry.Lines do
    Result := Result + string(LLine) + '|';
end;

procedure TTestQ3CommandBuffer.DovrebbeRifiutareUnRegistroNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TQ3CommandBuffer.Create(nil);
    end, EArgumentNilException);
end;

procedure TTestQ3CommandBuffer.DovrebbeEseguireLeRigheSeparatePerPuntoEVirgolaEACapo;
begin
  FBufferIntf.AddText('a;b'#10'c'#13'd');
  FBufferIntf.Execute;
  Assert.AreEqual('a|b|c|d|', Joined);
  Assert.AreEqual('', string(FBufferIntf.Pending));
end;

procedure TTestQ3CommandBuffer.DovrebbeNonSpezzareUnPuntoEVirgolaTraVirgolette;
begin
  FBufferIntf.AddText('say "a;b";c');
  FBufferIntf.Execute;
  Assert.AreEqual('say "a;b"|c|', Joined);
end;

procedure TTestQ3CommandBuffer.DovrebbeInserireInTestaConUnACapo;
begin
  FBufferIntf.AddText('b');
  FBufferIntf.InsertText('a');
  Assert.AreEqual('a'#10'b', string(FBufferIntf.Pending));
end;

procedure TTestQ3CommandBuffer.DovrebbeEseguireSubitoUnTestoENonIlBuffer;
begin
  FBufferIntf.AddText('later');
  FBufferIntf.ExecuteText(qeNow, 'now');
  Assert.AreEqual('now|', Joined);
  Assert.AreEqual('later', string(FBufferIntf.Pending));
end;

procedure TTestQ3CommandBuffer.DovrebbeEseguireIlBufferConUnTestoVuotoSubito;
begin
  FBufferIntf.ExecuteText(qeAppend, 'one');
  FBufferIntf.ExecuteText(qeInsert, 'zero');
  FBufferIntf.ExecuteText(qeNow, '');
  Assert.AreEqual('zero|one|', Joined);
end;

procedure TTestQ3CommandBuffer.DovrebbeLasciareIlRestoSeUnWaitEPendente;
begin
  FBufferIntf.AddText('a;b');
  FBufferIntf.Wait := 1;
  FBufferIntf.Execute;
  Assert.AreEqual('', Joined);
  Assert.AreEqual(0, FBufferIntf.Wait);
  FBufferIntf.Execute;
  Assert.AreEqual('a|b|', Joined);
end;

procedure TTestQ3CommandBuffer.DovrebbeTagliareUnaRigaLungaEPerdereUnCarattere;
begin
  FBufferIntf.AddText(AnsiString(StringOfChar('x', 1030)));
  FBufferIntf.Execute;
  Assert.AreEqual<Integer>(2, Length(FRegistry.Lines));
  Assert.AreEqual(1023, Length(FRegistry.Lines[0]));
  // the character after the cut is lost with the line
  Assert.AreEqual(1030 - 1024, Length(FRegistry.Lines[1]));
end;

procedure TTestQ3CommandBuffer.DovrebbeSegnalareUnOverflowNellAggiunta;
begin
  FBufferIntf.AddText(AnsiString(StringOfChar('x', Q3_MAX_CMD_BUFFER - 1)));
  FBufferIntf.AddText('y');
  Assert.AreEqual('Cbuf_AddText: overflow'#10, FLog.TakePrinted);
  Assert.AreEqual(Q3_MAX_CMD_BUFFER - 1, Length(FBufferIntf.Pending));
end;

procedure TTestQ3CommandBuffer.DovrebbeSegnalareUnOverflowNellInserimento;
begin
  FBufferIntf.AddText(AnsiString(StringOfChar('x', Q3_MAX_CMD_BUFFER - 1)));
  FBufferIntf.InsertText('yy');
  Assert.AreEqual('Cbuf_InsertText overflowed'#10, FLog.TakePrinted);
  Assert.AreEqual(Q3_MAX_CMD_BUFFER - 1, Length(FBufferIntf.Pending));
end;

procedure TTestQ3CommandBuffer.DovrebbeTroncareIlTestoAlPrimoNul;
begin
  FBufferIntf.AddText('ab'#0'cd');
  Assert.AreEqual('ab', string(FBufferIntf.Pending));
  FBufferIntf.InsertText('x'#0'y');
  Assert.AreEqual('x'#10'ab', string(FBufferIntf.Pending));
end;

procedure TTestQ3CommandBuffer.DovrebbeRifiutareUnTipoDiEsecuzioneNonValido;
begin
  Assert.WillRaise(
    procedure
    begin
      FBufferIntf.ExecuteText(TQ3Execution(7), 'x');
    end, EQ3ConsoleException);
end;

procedure TTestQ3CommandBuffer.DovrebbeFunzionareSenzaLog;
var
  LBuffer: IQ3CommandBuffer;
begin
  LBuffer := TQ3CommandBuffer.Create(FRegistryIntf);
  LBuffer.AddText(AnsiString(StringOfChar('x', Q3_MAX_CMD_BUFFER)));
  Assert.AreEqual('', string(LBuffer.Pending));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3CommandBuffer);

end.
