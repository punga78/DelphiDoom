{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the history of the console                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Console.History;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Console.History;

type
  [TestFixture]
  [Category('console')]
  TTestConsoleHistory = class(TObject)
  private
    FHistory: TConsoleHistory;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestEmptyHistoryHasNothingBefore;
    [Test]
    procedure TestPreviousWalksBackFromTheLastLine;
    [Test]
    procedure TestNextWalksForward;
    [Test]
    procedure TestAfterAddThereIsNothingNext;
    [Test]
    procedure TestAddStartsTheWalkAgain;
    [Test]
    procedure TestTheRingForgetsTheOldestLines;
    [Test]
    procedure TestClearForgetsEverything;
    [Test]
    procedure TestTheWalkStaysWhereItStoppedWhenThereIsNothingMore;
  end;

implementation

{ TTestConsoleHistory }

procedure TTestConsoleHistory.Setup;
begin
  FHistory := TConsoleHistory.Create;
end;

procedure TTestConsoleHistory.TearDown;
begin
  FHistory.Free;
end;

procedure TTestConsoleHistory.TestEmptyHistoryHasNothingBefore;
var
  LLine: string;
begin
  Assert.IsFalse(FHistory.Previous(LLine), 'dovrebbe dire che non c''e'' niente');
  Assert.IsFalse(FHistory.Next(LLine), 'dovrebbe dire che non c''e'' niente');
end;

procedure TTestConsoleHistory.TestPreviousWalksBackFromTheLastLine;
var
  LLine: string;
begin
  FHistory.Add('a');
  FHistory.Add('b');
  FHistory.Add('c');
  Assert.IsTrue(FHistory.Previous(LLine));
  Assert.AreEqual('c', LLine, 'dovrebbe dare l''ultima riga');
  Assert.IsTrue(FHistory.Previous(LLine));
  Assert.AreEqual('b', LLine);
  Assert.IsTrue(FHistory.Previous(LLine));
  Assert.AreEqual('a', LLine);
  Assert.IsFalse(FHistory.Previous(LLine), 'dovrebbe fermarsi alla prima riga');
end;

procedure TTestConsoleHistory.TestNextWalksForward;
var
  LLine: string;
begin
  FHistory.Add('a');
  FHistory.Add('b');
  FHistory.Add('c');
  FHistory.Previous(LLine);
  FHistory.Previous(LLine);
  FHistory.Previous(LLine);
  Assert.IsTrue(FHistory.Next(LLine));
  Assert.AreEqual('b', LLine, 'dovrebbe tornare avanti');
  Assert.IsTrue(FHistory.Next(LLine));
  Assert.AreEqual('c', LLine);
  Assert.IsFalse(FHistory.Next(LLine), 'dovrebbe fermarsi all''ultima riga');
end;

procedure TTestConsoleHistory.TestAfterAddThereIsNothingNext;
var
  LLine: string;
begin
  FHistory.Add('a');
  Assert.IsFalse(FHistory.Next(LLine), 'dovrebbe dire che dopo non c''e'' niente');
end;

procedure TTestConsoleHistory.TestAddStartsTheWalkAgain;
var
  LLine: string;
begin
  FHistory.Add('a');
  FHistory.Add('b');
  FHistory.Previous(LLine);
  FHistory.Previous(LLine);
  FHistory.Add('c');
  FHistory.Previous(LLine);
  Assert.AreEqual('c', LLine, 'dovrebbe ripartire dall''ultima riga aggiunta');
end;

procedure TTestConsoleHistory.TestTheRingForgetsTheOldestLines;
var
  LLine: string;
  LOldest: string;
  LIndex: Integer;
  LGoneBack: Integer;
begin
  for LIndex := 1 to 70 do
    FHistory.Add('l' + IntToStr(LIndex));
  FHistory.Previous(LLine);
  Assert.AreEqual('l70', LLine, 'dovrebbe partire dall''ultima riga');
  LGoneBack := 1;
  LOldest := LLine;
  while FHistory.Previous(LLine) do
  begin
    Inc(LGoneBack);
    LOldest := LLine;
  end;
  Assert.AreEqual(CONSOLE_HISTORY_SIZE - 1, LGoneBack, 'dovrebbe ricordare una riga in meno della dimensione');
  Assert.AreEqual('l8', LOldest, 'dovrebbe aver dimenticato le righe piu'' vecchie');
end;

procedure TTestConsoleHistory.TestClearForgetsEverything;
var
  LLine: string;
begin
  FHistory.Add('a');
  FHistory.Clear;
  Assert.IsFalse(FHistory.Previous(LLine), 'dovrebbe aver dimenticato tutto');
end;

procedure TTestConsoleHistory.TestTheWalkStaysWhereItStoppedWhenThereIsNothingMore;
var
  LLine: string;
begin
  FHistory.Add('a');
  FHistory.Previous(LLine);
  Assert.IsFalse(FHistory.Previous(LLine));
  Assert.IsFalse(FHistory.Next(LLine), 'dovrebbe restare sull''ultima riga trovata');
  FHistory.Add('b');
  FHistory.Previous(LLine);
  Assert.IsTrue(FHistory.Previous(LLine));
  Assert.AreEqual('a', LLine);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestConsoleHistory);

end.
