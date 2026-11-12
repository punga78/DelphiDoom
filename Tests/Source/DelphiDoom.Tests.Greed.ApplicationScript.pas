{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGreedApplicationScript                                 }
{                                                                              }
{  A script of keys for the menus and the commands of the game: no window, no   }
{  time                                                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.ApplicationScript;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.CommandState,
  DelphiDoom.Greed.ApplicationScript;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedApplicationScript = class(TObject)
  private
    FLines: TStringList;
    FScript: TGreedApplicationScript;
    procedure Build(const AText: string; const AInner: IGreedCommandSource = nil);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbePremereUnTastoDelMenuAlTicIndicato;
    [Test]
    procedure DovrebbeRilasciareIlTastoQuandoIlTicLoDice;
    [Test]
    procedure DovrebbeNonPremereNulla_PrimaDelTic;
    [Test]
    procedure DovrebbePremereUnComandoDelGioco;
    [Test]
    procedure DovrebbeDareSpazioComeTastoEComeUsaERiparti;
    [Test]
    procedure DovrebbeDareEscComeTastoEComeMenu;
    [Test]
    procedure DovrebbeRiconoscereLettereECifre;
    [Test]
    procedure DovrebbeServireILeRigheNellOrdineDeiTic;
    [Test]
    procedure DovrebbeDigitareUnCarattereAGiro;
    [Test]
    procedure DovrebbeSaltareRigheVuoteECommenti;
    [Test]
    procedure DovrebbeUnireIComandiDellaFinestra;
    [Test]
    procedure DovrebbeRifiutareUnaRigaNonCapita;
    [Test]
    procedure DovrebbeRifiutareUnNomeSconosciuto;
    [Test]
    procedure DovrebbeSollevareConUnTestoNullo;
    [Test]
    procedure DovrebbeDareFalsoPerUnCodiceFuoriTabella;
  end;

implementation

uses
  DelphiDoom.Greed.Types, DelphiDoom.Greed.MenuInput, DelphiDoom.Tests.Greed.GameFakes;

// True if the procedure raises an exception of that class
function Raises(const AProc: TProc; AClass: ExceptClass): Boolean;
begin
  Result := False;
  try
    AProc();
  except
    on E: Exception do
      Result := E is AClass;
  end;
end;

{ TTestGreedApplicationScript }

procedure TTestGreedApplicationScript.Setup;
begin
  FLines := TStringList.Create;
end;

procedure TTestGreedApplicationScript.TearDown;
begin
  FreeAndNil(FScript);
  FLines.Free;
end;

procedure TTestGreedApplicationScript.Build(const AText: string; const AInner: IGreedCommandSource);
begin
  FreeAndNil(FScript);
  FLines.Text := AText;
  FScript := TGreedApplicationScript.Create(FLines, AInner);
end;

procedure TTestGreedApplicationScript.DovrebbePremereUnTastoDelMenuAlTicIndicato;
begin
  Build('5 enter down');
  FScript.TicStarting(5);
  Assert.IsTrue(FScript.IsDown(GREED_SC_ENTER));
  Assert.IsFalse(FScript.IsDown(GREED_SC_ESCAPE));
end;

procedure TTestGreedApplicationScript.DovrebbeRilasciareIlTastoQuandoIlTicLoDice;
begin
  Build('5 down down' + sLineBreak + '9 down up');
  FScript.TicStarting(8);
  Assert.IsTrue(FScript.IsDown(GREED_SC_DOWNARROW));
  FScript.TicStarting(9);
  Assert.IsFalse(FScript.IsDown(GREED_SC_DOWNARROW));
end;

procedure TTestGreedApplicationScript.DovrebbeNonPremereNulla_PrimaDelTic;
begin
  Build('5 enter down');
  FScript.TicStarting(4);
  Assert.IsFalse(FScript.IsDown(GREED_SC_ENTER));
end;

procedure TTestGreedApplicationScript.DovrebbePremereUnComandoDelGioco;
begin
  Build('3 north down' + sLineBreak + '7 north up');
  FScript.TicStarting(3);
  Assert.IsTrue(FScript.IsPressed(gcNorth));
  Assert.IsFalse(FScript.IsPressed(gcSouth));
  FScript.TicStarting(7);
  Assert.IsFalse(FScript.IsPressed(gcNorth));
end;

procedure TTestGreedApplicationScript.DovrebbeDareSpazioComeTastoEComeUsaERiparti;
begin
  Build('1 space down');
  FScript.TicStarting(1);
  Assert.IsTrue(FScript.IsDown(GREED_SC_SPACE));
  Assert.IsTrue(FScript.IsPressed(gcUse));
  Assert.IsTrue(FScript.IsPressed(gcRestart));
end;

procedure TTestGreedApplicationScript.DovrebbeDareEscComeTastoEComeMenu;
begin
  Build('1 esc down');
  FScript.TicStarting(1);
  Assert.IsTrue(FScript.IsDown(GREED_SC_ESCAPE));
  Assert.IsTrue(FScript.IsPressed(gcMenu));
end;

procedure TTestGreedApplicationScript.DovrebbeRiconoscereLettereECifre;
begin
  Build('1 a down' + sLineBreak + '1 7 down');
  FScript.TicStarting(1);
  Assert.IsTrue(FScript.IsDown(TGreedMenuInput.ScanCodeOfChar('A')));
  Assert.IsTrue(FScript.IsDown(TGreedMenuInput.ScanCodeOfChar('7')));
  Assert.IsFalse(FScript.IsDown(TGreedMenuInput.ScanCodeOfChar('B')));
end;

procedure TTestGreedApplicationScript.DovrebbeServireILeRigheNellOrdineDeiTic;
begin
  // the lines are not in order: the later tic is written first
  Build('10 enter up' + sLineBreak + '2 enter down');
  FScript.TicStarting(2);
  Assert.IsTrue(FScript.IsDown(GREED_SC_ENTER));
  FScript.TicStarting(10);
  Assert.IsFalse(FScript.IsDown(GREED_SC_ENTER));
end;

procedure TTestGreedApplicationScript.DovrebbeDigitareUnCarattereAGiro;
var
  LCharacter: Char;
begin
  Build('1 type ab');
  FScript.TicStarting(1);
  FScript.BeginReading;
  Assert.IsTrue(FScript.TakeTyped(LCharacter));
  Assert.AreEqual('A', LCharacter);
  // one character for each reading
  Assert.IsFalse(FScript.TakeTyped(LCharacter));
  FScript.BeginReading;
  Assert.IsTrue(FScript.TakeTyped(LCharacter));
  Assert.AreEqual('B', LCharacter);
  FScript.BeginReading;
  Assert.IsFalse(FScript.TakeTyped(LCharacter));
end;

procedure TTestGreedApplicationScript.DovrebbeSaltareRigheVuoteECommenti;
begin
  Build('# a comment' + sLineBreak + sLineBreak + '1 north down');
  FScript.TicStarting(1);
  Assert.IsTrue(FScript.IsPressed(gcNorth));
end;

procedure TTestGreedApplicationScript.DovrebbeUnireIComandiDellaFinestra;
var
  LInner: TFakeCommandSource;
  LInnerIntf: IGreedCommandSource;
begin
  LInner := TFakeCommandSource.Create;
  LInnerIntf := LInner;
  LInner.Pressed := [gcFire];
  Build('1 north down', LInnerIntf);
  FScript.TicStarting(1);
  Assert.IsTrue(FScript.IsPressed(gcNorth), 'the script');
  Assert.IsTrue(FScript.IsPressed(gcFire), 'the window');
  Assert.IsFalse(FScript.IsPressed(gcSouth));
  FScript.BeginReading;
  Assert.AreEqual(1, LInner.Readings);
end;

procedure TTestGreedApplicationScript.DovrebbeRifiutareUnaRigaNonCapita;
begin
  Assert.IsTrue(Raises(
    procedure
    begin
      Build('north down');
    end, EGreedException));
  Assert.IsTrue(Raises(
    procedure
    begin
      Build('1 north sideways');
    end, EGreedException));
end;

procedure TTestGreedApplicationScript.DovrebbeRifiutareUnNomeSconosciuto;
begin
  Assert.IsTrue(Raises(
    procedure
    begin
      Build('1 fly down');
    end, EGreedException));
end;

procedure TTestGreedApplicationScript.DovrebbeSollevareConUnTestoNullo;
begin
  Assert.IsTrue(Raises(
    procedure
    begin
      TGreedApplicationScript.Create(nil, nil).Free;
    end, EArgumentNilException));
end;

procedure TTestGreedApplicationScript.DovrebbeDareFalsoPerUnCodiceFuoriTabella;
begin
  Build('1 enter down');
  FScript.TicStarting(1);
  Assert.IsFalse(FScript.IsDown(-1));
  Assert.IsFalse(FScript.IsDown(128));
end;

end.
