{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TToolUndoHistory                                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ToolsCore.UndoHistory;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework,
  DelphiDoom.Tools.Intf;

type
  /// <summary>
  ///   The UNDO lines of Tests\Data\ToolsCore\old.golden.txt were written by the TUndoRedoManager of
  ///   ENDEDIT (ee_undo) on the same scripts as these tests
  /// </summary>
  [TestFixture]
  [Category('toolscore')]
  TTestToolsUndoHistory = class(TObject)
  strict private
    FHistory: IToolUndoHistory;
    function Bytes(const AText: string): TBytes;
    function Text(const ABytes: TBytes): string;
    function Replay(const AScript: string; ALimit: Integer; AIndex: Integer): TArray<string>;
  public
    [Setup]
    procedure Setup;

    [Test]
    procedure DovrebbeEssereVuotaAllaNascita;
    [Test]
    procedure DovrebbeTornareIndietroEInAvanti;
    [Test]
    procedure DovrebbeSvuotareIlRifaiConUnNuovoSalvataggio;
    [Test]
    procedure DovrebbeTenereSoloGliUltimiSalvataggiDelLimite;
    [Test]
    procedure DovrebbeNonLimitareConLimiteZero;
    [Test]
    procedure DovrebbeDareLoStatoCorrenteSeNonCeNulla;
    [Test]
    procedure DovrebbeCopiareGliStatiSalvati;
    [Test]
    procedure DovrebbeSvuotareTutto;
    [Test]
    procedure DovrebbeRifiutareUnLimiteNegativo;
    [Test]
    procedure DovrebbeDareGliStessiStatiDelVecchioGestore;
  end;

implementation

uses
  DelphiDoom.Tools.Factory, DelphiDoom.Tools.UndoHistory, DelphiDoom.Tools.Types,
  DelphiDoom.Tests.ToolsCore.Fakes;

{ TTestToolsUndoHistory }

procedure TTestToolsUndoHistory.Setup;
begin
  FHistory := TToolsFactory.CreateUndoHistory(TOOLS_UNDO_LIMIT);
end;

function TTestToolsUndoHistory.Bytes(const AText: string): TBytes;
begin
  Result := TEncoding.UTF8.GetBytes(AText);
end;

function TTestToolsUndoHistory.Text(const ABytes: TBytes): string;
begin
  Result := TEncoding.UTF8.GetString(ABytes);
end;

function TTestToolsUndoHistory.Replay(const AScript: string; ALimit: Integer;
  AIndex: Integer): TArray<string>;
var
  LHistory: IToolUndoHistory;
  LState: string;
  LOperations: TStringList;
  LOperation: string;
  LIndex: Integer;
begin
  LHistory := TToolsFactory.CreateUndoHistory(ALimit);
  LState := 'init';
  LOperations := TStringList.Create;
  try
    LOperations.Delimiter := ' ';
    LOperations.DelimitedText := AScript;
    SetLength(Result, LOperations.Count);
    for LIndex := 0 to LOperations.Count - 1 do
    begin
      LOperation := LOperations[LIndex];
      if LOperation = 'S' then
        LHistory.Save(Bytes(LState))
      else if LOperation = 'U' then
        LState := Text(LHistory.Undo(Bytes(LState)))
      else if LOperation = 'R' then
        LState := Text(LHistory.Redo(Bytes(LState)))
      else if LOperation = 'C' then
        LHistory.Clear
      else
        LState := LOperation;
      Result[LIndex] := Format('%d.%d %s state=%s canundo=%d canredo=%d',
        [AIndex, LIndex, LOperation, LState, Ord(LHistory.CanUndo), Ord(LHistory.CanRedo)]);
    end;
  finally
    LOperations.Free;
  end;
end;

procedure TTestToolsUndoHistory.DovrebbeEssereVuotaAllaNascita;
begin
  Assert.IsFalse(FHistory.CanUndo);
  Assert.IsFalse(FHistory.CanRedo);
end;

procedure TTestToolsUndoHistory.DovrebbeTornareIndietroEInAvanti;
var
  LState: TBytes;
begin
  FHistory.Save(Bytes('uno'));
  FHistory.Save(Bytes('due'));
  LState := FHistory.Undo(Bytes('tre'));
  Assert.AreEqual('due', Text(LState));
  Assert.IsTrue(FHistory.CanRedo);
  LState := FHistory.Undo(LState);
  Assert.AreEqual('uno', Text(LState));
  Assert.IsFalse(FHistory.CanUndo);
  LState := FHistory.Redo(LState);
  Assert.AreEqual('due', Text(LState));
  LState := FHistory.Redo(LState);
  Assert.AreEqual('tre', Text(LState));
  Assert.IsFalse(FHistory.CanRedo);
  Assert.IsTrue(FHistory.CanUndo);
end;

procedure TTestToolsUndoHistory.DovrebbeSvuotareIlRifaiConUnNuovoSalvataggio;
begin
  FHistory.Save(Bytes('a'));
  FHistory.Undo(Bytes('b'));
  Assert.IsTrue(FHistory.CanRedo);
  FHistory.Save(Bytes('c'));
  Assert.IsFalse(FHistory.CanRedo);
end;

procedure TTestToolsUndoHistory.DovrebbeTenereSoloGliUltimiSalvataggiDelLimite;
var
  LHistory: IToolUndoHistory;
  LState: TBytes;
begin
  LHistory := TToolsFactory.CreateUndoHistory(2);
  LHistory.Save(Bytes('a'));
  LHistory.Save(Bytes('b'));
  LHistory.Save(Bytes('c'));
  LState := LHistory.Undo(Bytes('d'));
  Assert.AreEqual('c', Text(LState));
  LState := LHistory.Undo(LState);
  Assert.AreEqual('b', Text(LState));
  Assert.IsFalse(LHistory.CanUndo);
  // the redo puts the states back on the undo stack, which keeps its limit
  LState := LHistory.Redo(LState);
  LState := LHistory.Redo(LState);
  Assert.AreEqual('d', Text(LState));
  Assert.IsTrue(LHistory.CanUndo);
end;

procedure TTestToolsUndoHistory.DovrebbeNonLimitareConLimiteZero;
var
  LHistory: IToolUndoHistory;
  LIndex: Integer;
  LState: TBytes;
  LCount: Integer;
begin
  LHistory := TToolsFactory.CreateUndoHistory(0);
  for LIndex := 1 to 3000 do
    LHistory.Save(Bytes(IntToStr(LIndex)));
  LCount := 0;
  LState := Bytes('fine');
  while LHistory.CanUndo do
  begin
    LState := LHistory.Undo(LState);
    Inc(LCount);
  end;
  Assert.AreEqual(3000, LCount);
  Assert.AreEqual('1', Text(LState));
end;

procedure TTestToolsUndoHistory.DovrebbeDareLoStatoCorrenteSeNonCeNulla;
begin
  Assert.AreEqual('x', Text(FHistory.Undo(Bytes('x'))));
  Assert.AreEqual('y', Text(FHistory.Redo(Bytes('y'))));
  Assert.IsFalse(FHistory.CanRedo);
end;

procedure TTestToolsUndoHistory.DovrebbeCopiareGliStatiSalvati;
var
  LBuffer: TBytes;
begin
  LBuffer := Bytes('abc');
  FHistory.Save(LBuffer);
  LBuffer[0] := Ord('X');
  Assert.AreEqual('abc', Text(FHistory.Undo(Bytes('z'))));
end;

procedure TTestToolsUndoHistory.DovrebbeSvuotareTutto;
begin
  FHistory.Save(Bytes('a'));
  FHistory.Undo(Bytes('b'));
  FHistory.Clear;
  Assert.IsFalse(FHistory.CanUndo);
  Assert.IsFalse(FHistory.CanRedo);
end;

procedure TTestToolsUndoHistory.DovrebbeRifiutareUnLimiteNegativo;
begin
  Assert.WillRaise(
    procedure
    begin
      TToolUndoHistory.Create(-1).Free;
    end, EToolsException);
end;

procedure TTestToolsUndoHistory.DovrebbeDareGliStessiStatiDelVecchioGestore;
const
  SCRIPTS: array[0..5] of string = (
    'S c1 S c2 S c3 U U U U R R R R',
    'S c1 S c2 U c3 R S c4 U U R',
    'S c1 S c2 S c3 S c4 S c5 S c6 U U U U U U U R R R R R R R',
    'U R S c1 S c2 U U U S c9 R U',
    'S c1 S c2 S c3 U R S c4 S c5 S c6 S c7 U U U U U U',
    'S c1 S c2 S c3 S c4 C S c5 U');
  LIMITS: array[0..5] of Integer = (0, 1000, 3, 2, 3, 100);
var
  LGolden: TArray<string>;
  LScript: Integer;
  LLine: string;
  LExpected: TStringList;
begin
  LGolden := TToolsGolden.Lines('ToolsCore\old.golden.txt', 'UNDO');
  LExpected := TStringList.Create;
  try
    for LScript := 0 to High(SCRIPTS) do
      for LLine in Replay(SCRIPTS[LScript], LIMITS[LScript], LScript) do
        LExpected.Add(LLine);
    Assert.AreEqual(Length(LGolden), LExpected.Count);
    for LScript := 0 to High(LGolden) do
      Assert.AreEqual(LGolden[LScript], LExpected[LScript]);
  finally
    LExpected.Free;
  end;
end;

end.
