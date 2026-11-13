{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the tokenizer of the Quake III console                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.Q3.CommandArguments;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Console.Q3.Intf, DelphiDoom.Console.Q3.CommandArguments;

type
  [TestFixture]
  [Category('console')]
  TTestQ3CommandArguments = class(TObject)
  private
    FArguments: IQ3CommandArguments;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeDareZeroTokenPerUnTestoVuoto;
    [Test]
    procedure DovrebbeSeparareConGliSpaziEUnirePerLeVirgolette;
    [Test]
    procedure DovrebbeSaltareICommenti;
    [Test]
    procedure DovrebbeTrattareIByteAltiComeSeparatori;
    [Test]
    procedure DovrebbeFermarsiAlPrimoNul;
    [Test]
    procedure DovrebbeTenereAlPiuMilleVentiquattroToken;
    [Test]
    procedure DovrebbeDareUnaStringaVuotaFuoriIndice;
    [Test]
    procedure DovrebbeUnireGliArgomentiDaUnIndice;
    [Test]
    procedure DovrebbeTrattareUnIndiceNegativoDiArgsFromComeZero;
    [Test]
    procedure DovrebbeTagliareLaRigaOriginaleAOttomilacentonovantuno;
    [Test]
    procedure DovrebbeCancellareITokenPrimaDiUnaNuovaRiga;
  end;

implementation

procedure TTestQ3CommandArguments.Setup;
begin
  FArguments := TQ3CommandArguments.Create;
end;

procedure TTestQ3CommandArguments.DovrebbeDareZeroTokenPerUnTestoVuoto;
begin
  FArguments.Tokenize('');
  Assert.AreEqual(0, FArguments.Count);
  FArguments.Tokenize('   // niente');
  Assert.AreEqual(0, FArguments.Count);
end;

procedure TTestQ3CommandArguments.DovrebbeSeparareConGliSpaziEUnirePerLeVirgolette;
begin
  FArguments.Tokenize('probe  a "b c" d"e f"g');
  Assert.AreEqual(6, FArguments.Count);
  Assert.AreEqual('b c', string(FArguments.Argv(2)));
  Assert.AreEqual('e f', string(FArguments.Argv(4)));
  Assert.AreEqual('g', string(FArguments.Argv(5)));
end;

procedure TTestQ3CommandArguments.DovrebbeSaltareICommenti;
begin
  FArguments.Tokenize('a /* x */ b// c');
  Assert.AreEqual(2, FArguments.Count);
  FArguments.Tokenize('a /* aperto');
  Assert.AreEqual(1, FArguments.Count);
end;

procedure TTestQ3CommandArguments.DovrebbeTrattareIByteAltiComeSeparatori;
begin
  FArguments.Tokenize('a'#$E9'b'#$FF'c');
  Assert.AreEqual(3, FArguments.Count);
  FArguments.Tokenize('"'#$E9'x"');
  Assert.AreEqual(2, Length(FArguments.Argv(0)));
end;

procedure TTestQ3CommandArguments.DovrebbeFermarsiAlPrimoNul;
begin
  FArguments.Tokenize('a b'#0'c d');
  Assert.AreEqual(2, FArguments.Count);
  Assert.AreEqual('a b', string(FArguments.Cmd));
end;

procedure TTestQ3CommandArguments.DovrebbeTenereAlPiuMilleVentiquattroToken;
var
  LText: AnsiString;
  LIndex: Integer;
begin
  LText := '';
  for LIndex := 1 to 1100 do
    LText := LText + 'x ';
  FArguments.Tokenize(LText);
  Assert.AreEqual(1024, FArguments.Count);
end;

procedure TTestQ3CommandArguments.DovrebbeDareUnaStringaVuotaFuoriIndice;
begin
  FArguments.Tokenize('a b');
  Assert.AreEqual('', string(FArguments.Argv(2)));
  Assert.AreEqual('', string(FArguments.Argv(-1)));
end;

procedure TTestQ3CommandArguments.DovrebbeUnireGliArgomentiDaUnIndice;
begin
  FArguments.Tokenize('cmd a b c');
  Assert.AreEqual('a b c', string(FArguments.Args));
  Assert.AreEqual('b c', string(FArguments.ArgsFrom(2)));
  Assert.AreEqual('', string(FArguments.ArgsFrom(9)));
end;

procedure TTestQ3CommandArguments.DovrebbeTrattareUnIndiceNegativoDiArgsFromComeZero;
begin
  FArguments.Tokenize('cmd a');
  Assert.AreEqual('cmd a', string(FArguments.ArgsFrom(-3)));
end;

procedure TTestQ3CommandArguments.DovrebbeTagliareLaRigaOriginaleAOttomilacentonovantuno;
begin
  FArguments.Tokenize(AnsiString(StringOfChar('a', 9000)));
  Assert.AreEqual(8191, Length(FArguments.Cmd));
  Assert.AreEqual(9000, Length(FArguments.Argv(0)));
end;

procedure TTestQ3CommandArguments.DovrebbeCancellareITokenPrimaDiUnaNuovaRiga;
begin
  FArguments.Tokenize('a b c');
  FArguments.Tokenize('x');
  Assert.AreEqual(1, FArguments.Count);
  Assert.AreEqual('', string(FArguments.Argv(1)));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestQ3CommandArguments);

end.
