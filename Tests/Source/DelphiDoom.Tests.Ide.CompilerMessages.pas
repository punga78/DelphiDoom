{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - TIdeCompilerMessages                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.CompilerMessages;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.Ide.CompilerMessages;

type
  [TestFixture]
  [Category('ide')]
  TTestIdeCompilerMessages = class(TObject)
  public
    [Test]
    procedure DovrebbeTrovareLaPosizioneComeIlVecchioEditorConIMessaggiDeiCompilatoriVeri;
    [Test]
    procedure DovrebbeLeggereRigaEColonnaDiUnErrore;
    [Test]
    procedure DovrebbeNonTrovareNullaSenzaErrori;
    [Test]
    procedure DovrebbeNonTrovareNullaSeIlTestoEVuoto;
    [Test]
    procedure DovrebbeNonTrovareNullaPerUnAvvisoSenzaErrore;
    [Test]
    procedure DovrebbeNonTrovareNullaSeIlNomeDavantiHaDellePareCifre;
    [Test]
    procedure DovrebbeNonTrovareNullaSeLeParentesiVengonoPrimaDellErrore;
    [Test]
    procedure DovrebbeTagliareLeRighe;
    [Test]
    procedure DovrebbeDareUnaListaVuotaPerIlTestoVuoto;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Ide.Types,
  DelphiDoom.Tests.Ide.CompilerGolden;

{ TTestIdeCompilerMessages }

procedure TTestIdeCompilerMessages.DovrebbeTrovareLaPosizioneComeIlVecchioEditorConIMessaggiDeiCompilatoriVeri;
var
  LGame, LScript, LExpected: string;
  LGolden: TCompilerGolden;
  LLocation: TIdeSourceLocation;
  LFound: Boolean;
  LChecked: Integer;
begin
  LChecked := 0;
  for LGame in TCompilerGolden.Games do
    for LScript in TCompilerGolden.Scripts do
    begin
      LGolden := TCompilerGolden.Load(LScript, LGame);
      LFound := TIdeCompilerMessages.TryFindErrorLocation(LGolden.Messages, LLocation);
      if Pos(',', LGolden.Location) > 0 then
      begin
        LExpected := Format('%d,%d', [LLocation.Line, LLocation.Column]);
        Assert.IsTrue(LFound, LScript + ' ' + LGame + ': a location was expected');
        Assert.AreEqual(LGolden.Location, LExpected, LScript + ' ' + LGame);
      end
      else
        Assert.IsFalse(LFound, LScript + ' ' + LGame + ': no location was expected');
      Inc(LChecked);
    end;
  Assert.AreEqual(36, LChecked);
end;

procedure TTestIdeCompilerMessages.DovrebbeLeggereRigaEColonnaDiUnErrore;
var
  LLocation: TIdeSourceLocation;
begin
  Assert.IsTrue(TIdeCompilerMessages.TryFindErrorLocation(
    ' Pos: 000046 Compiler: [Error] (6:3): Unknown identifier ''X''', LLocation));
  Assert.AreEqual(6, LLocation.Line);
  Assert.AreEqual(3, LLocation.Column);
end;

procedure TTestIdeCompilerMessages.DovrebbeNonTrovareNullaSenzaErrori;
var
  LLocation: TIdeSourceLocation;
begin
  Assert.IsFalse(TIdeCompilerMessages.TryFindErrorLocation('Compile successful', LLocation));
end;

procedure TTestIdeCompilerMessages.DovrebbeNonTrovareNullaSeIlTestoEVuoto;
var
  LLocation: TIdeSourceLocation;
begin
  Assert.IsFalse(TIdeCompilerMessages.TryFindErrorLocation('', LLocation));
end;

procedure TTestIdeCompilerMessages.DovrebbeNonTrovareNullaPerUnAvvisoSenzaErrore;
var
  LLocation: TIdeSourceLocation;
begin
  // the old code read before the first character of the text here
  Assert.IsFalse(TIdeCompilerMessages.TryFindErrorLocation(
    ' Pos: 000046 Compiler: [Warning] (6:3): Unused variable', LLocation));
end;

procedure TTestIdeCompilerMessages.DovrebbeNonTrovareNullaSeIlNomeDavantiHaDellePareCifre;
var
  LLocation: TIdeSourceLocation;
begin
  // the digits of the name mix with the two numbers: the old editor gave up
  Assert.IsFalse(TIdeCompilerMessages.TryFindErrorLocation(
    ' Pos: 000008 Compiler: [Error] unit1(2:3): Unknown identifier', LLocation));
end;

procedure TTestIdeCompilerMessages.DovrebbeNonTrovareNullaSeLeParentesiVengonoPrimaDellErrore;
var
  LLocation: TIdeSourceLocation;
begin
  Assert.IsFalse(TIdeCompilerMessages.TryFindErrorLocation(
    'before (1:2): then [Error] without numbers', LLocation));
end;

procedure TTestIdeCompilerMessages.DovrebbeTagliareLeRighe;
var
  LLines: TArray<string>;
begin
  LLines := TIdeCompilerMessages.SplitLines('one'#13#10'two'#10'three'#13);
  Assert.AreEqual<Integer>(3, Length(LLines));
  Assert.AreEqual('two', LLines[1]);
  Assert.AreEqual('three', LLines[2]);
end;

procedure TTestIdeCompilerMessages.DovrebbeDareUnaListaVuotaPerIlTestoVuoto;
begin
  Assert.AreEqual<Integer>(0, Length(TIdeCompilerMessages.SplitLines('')));
end;

end.
