{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - the keys: the names       }
{  against the real cl_keys.c (Tests\Data\Q3Host\keys.golden.txt, made by       }
{  Tools\Verifica\254\client-keys.sh with the table and the two functions cut   }
{  out of the file and compiled by gcc), and the calls of cgame and ui          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.ClientKeys;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Tests.Q3Host.ClientSupport;

type
  [TestFixture]
  [Category('Q3Host')]
  TTestQ3ClientKeys = class
  strict private
    FRig: TQ3ClientRig;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure LaTabellaDeiNomiDovrebbeEssereQuellaDelC;
    [Test]
    procedure IlNomeDiOgniTastoDovrebbeEssereQuelloDelC;
    [Test]
    procedure IlTastoDiOgniNomeDovrebbeEssereQuelloDelC;
    [Test]
    procedure LeAssociazioniDovrebberoSeguireLeRegoleDelC;
    [Test]
    procedure PulireGliStatiDovrebbeRilasciareITastiPremuti;
    [Test]
    procedure UnTastoFuoriDaiLimitiNonDovrebbeEssereMaiPremuto;
    [Test]
    procedure LeChiamateDiCgameDovrebberoUsareITasti;
    [Test]
    procedure LeChiamateDiUiDovrebberoUsareITasti;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.Qvm.Intf, DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Opcodes,
  DelphiDoom.Q3Host.Client.KeyNames, DelphiDoom.Q3Host.Client.Types, DelphiDoom.Q3Host.ClientKeys,
  DelphiDoom.Tests.Shared.Files;

const
  BUFFER = 4096;

function GoldenLines: TStringList;
begin
  Result := TStringList.Create;
  Result.LoadFromFile(TTestFiles.DataFile('Q3Host', 'keys.golden.txt'));
end;

procedure TTestQ3ClientKeys.Setup;
begin
  FRig := TQ3ClientRig.Create;
end;

procedure TTestQ3ClientKeys.TearDown;
begin
  FRig.Free;
end;

procedure TTestQ3ClientKeys.LaTabellaDeiNomiDovrebbeEssereQuellaDelC;
var
  LLines: TStringList;
  LLine: string;
  LParts: TArray<string>;
  LIndex: Integer;
begin
  LLines := GoldenLines;
  try
    LIndex := 0;
    for LLine in LLines do
      if LLine.StartsWith('T ') then
      begin
        LParts := LLine.Trim.Split([' ']);
        Assert.IsTrue(LIndex < Q3_KEY_NAME_COUNT);
        Assert.AreEqual(LParts[1], string(Q3_KEY_NAMES[LIndex].Name));
        Assert.AreEqual(StrToInt(LParts[2]), Q3_KEY_NAMES[LIndex].Number);
        Inc(LIndex);
      end;
    Assert.AreEqual(Q3_KEY_NAME_COUNT, LIndex);
  finally
    LLines.Free;
  end;
end;

procedure TTestQ3ClientKeys.IlNomeDiOgniTastoDovrebbeEssereQuelloDelC;
var
  LLines: TStringList;
  LLine: string;
  LKey, LCount: Integer;
begin
  LLines := GoldenLines;
  try
    LCount := 0;
    for LLine in LLines do
      if LLine.StartsWith('N ') then
      begin
        LKey := StrToInt(Copy(LLine, 3, Pos(' ', LLine, 3) - 3));
        Assert.AreEqual(Trim(Copy(LLine, Pos(' ', LLine, 3) + 1, MaxInt)), string(FRig.Keys.KeynumToString(LKey)),
          'key ' + IntToStr(LKey));
        Inc(LCount);
      end;
    // -2 .. 257
    Assert.AreEqual(260, LCount);
  finally
    LLines.Free;
  end;
end;

procedure TTestQ3ClientKeys.IlTastoDiOgniNomeDovrebbeEssereQuelloDelC;
var
  LLines: TStringList;
  LLine, LText: string;
  LEnd, LCount: Integer;
begin
  LLines := GoldenLines;
  try
    LCount := 0;
    for LLine in LLines do
      if LLine.StartsWith('S [') then
      begin
        // the text is between the first bracket and the last one: it may hold spaces, quotes and semicolons
        LEnd := LLine.LastIndexOf(']');
        LText := Copy(LLine, 4, LEnd - 3);
        Assert.AreEqual(StrToInt(Trim(Copy(LLine, LEnd + 2, MaxInt))), TQ3ClientKeys.StringToKeynum(AnsiString(LText)),
          LText);
        Inc(LCount);
      end;
    Assert.IsTrue(LCount > 100);
  finally
    LLines.Free;
  end;
end;

procedure TTestQ3ClientKeys.LeAssociazioniDovrebberoSeguireLeRegoleDelC;
begin
  Assert.AreEqual('', string(FRig.Keys.GetBinding(65)));
  Assert.AreEqual(-1, FRig.Keys.GetKey('+attack'));
  FRig.Console.CVars.ModifiedFlags := 0;
  FRig.Keys.SetBinding(Ord('f'), '+attack');
  FRig.Keys.SetBinding(Ord('g'), '');
  Assert.AreEqual('+attack', string(FRig.Keys.GetBinding(Ord('f'))));
  // the binding of a key is found ignoring case, and the first key wins
  Assert.AreEqual(Ord('f'), FRig.Keys.GetKey('+ATTACK'));
  FRig.Keys.SetBinding(Ord('a'), '+attack');
  Assert.AreEqual(Ord('a'), FRig.Keys.GetKey('+attack'));
  // an empty binding is a binding
  Assert.AreEqual(Ord('g'), FRig.Keys.GetKey(''));
  // the file of the bindings must be written at the next opportunity (CVAR_ARCHIVE)
  Assert.AreEqual(1, FRig.Console.CVars.ModifiedFlags and 1);
  FRig.Keys.SetBinding(-1, 'ignored');
  FRig.Keys.SetBinding(300, 'ignored');
  Assert.AreEqual('', string(FRig.Keys.GetBinding(-1)));
  Assert.AreEqual('', string(FRig.Keys.GetBinding(300)));
  Assert.AreEqual(-1, FRig.Keys.GetKey('ignored'));
end;

procedure TTestQ3ClientKeys.PulireGliStatiDovrebbeRilasciareITastiPremuti;
var
  LReleased: string;
begin
  LReleased := '';
  FRig.Keys.OnKeyReleased :=
    procedure(AKey: Integer)
    begin
      LReleased := LReleased + IntToStr(AKey) + ' ';
    end;
  FRig.Keys.SetDown(10, True);
  FRig.Keys.SetDown(200, True);
  Assert.IsTrue(FRig.Keys.IsDown(10));
  FRig.Keys.ClearStates;
  Assert.AreEqual('10 200 ', LReleased);
  Assert.IsFalse(FRig.Keys.IsDown(10));
  Assert.IsFalse(FRig.Keys.IsDown(200));
  FRig.Keys.ClearStates;
  Assert.AreEqual('10 200 ', LReleased);
  FRig.Keys.OnKeyReleased := nil;
end;

procedure TTestQ3ClientKeys.UnTastoFuoriDaiLimitiNonDovrebbeEssereMaiPremuto;
begin
  // the C indexes keys[] with the number: here a key out of 0..255 is simply not down
  FRig.Keys.SetDown(256, True);
  FRig.Keys.SetDown(-1, True);
  Assert.IsFalse(FRig.Keys.IsDown(256));
  Assert.IsFalse(FRig.Keys.IsDown(-1));
  Assert.IsFalse(FRig.Keys.IsDown(-100));
end;

procedure TTestQ3ClientKeys.LeChiamateDiCgameDovrebberoUsareITasti;
begin
  FRig.Keys.SetDown(Ord('w'), True);
  Assert.AreEqual(1, FRig.Call(TQ3Module.CGame, [CG_KEY_ISDOWN, Ord('w')]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_KEY_ISDOWN, Ord('s')]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_KEY_ISDOWN, -1]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_KEY_GETCATCHER]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.CGame, [CG_KEY_SETCATCHER, Q3_KEYCATCH_CGAME]));
  Assert.AreEqual(Q3_KEYCATCH_CGAME, FRig.Call(TQ3Module.CGame, [CG_KEY_GETCATCHER]));
  FRig.Keys.SetBinding(Ord('x'), '+zoom');
  FRig.Memory(TQ3Module.CGame).WriteString(BUFFER, '+zoom', 6);
  Assert.AreEqual(Ord('x'), FRig.Call(TQ3Module.CGame, [CG_KEY_GETKEY, BUFFER]));
  FRig.Memory(TQ3Module.CGame).WriteString(BUFFER, '+nothing', 9);
  Assert.AreEqual(-1, FRig.Call(TQ3Module.CGame, [CG_KEY_GETKEY, BUFFER]));
  // a NULL binding is no key
  Assert.AreEqual(-1, FRig.Call(TQ3Module.CGame, [CG_KEY_GETKEY, 0]));
end;

procedure TTestQ3ClientKeys.LeChiamateDiUiDovrebberoUsareITasti;
var
  LMemory: IQvmMemory;
begin
  LMemory := FRig.Memory(TQ3Module.Ui);
  LMemory.Fill(BUFFER, $77, 32);
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_KEY_KEYNUMTOSTRINGBUF, 132, BUFFER, 32]));
  Assert.AreEqual('UPARROW', string(LMemory.ReadString(BUFFER)));
  // the buffer is cut as Q_strncpyz does
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_KEY_KEYNUMTOSTRINGBUF, 132, BUFFER, 3]));
  Assert.AreEqual('UP', string(LMemory.ReadString(BUFFER)));
  LMemory.WriteString(BUFFER, '+jump', 6);
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_KEY_SETBINDING, 32, BUFFER]));
  LMemory.Fill(BUFFER, $77, 32);
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_KEY_GETBINDINGBUF, 32, BUFFER, 32]));
  Assert.AreEqual('+jump', string(LMemory.ReadString(BUFFER)));
  // an unbound key only puts a zero in the first byte
  LMemory.Fill(BUFFER, $77, 32);
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_KEY_GETBINDINGBUF, 33, BUFFER, 32]));
  Assert.AreEqual('', string(LMemory.ReadString(BUFFER)));
  Assert.AreEqual($77, Integer(LMemory.ReadByte(BUFFER + 1)));
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_KEY_GETOVERSTRIKEMODE]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_KEY_SETOVERSTRIKEMODE, 1]));
  Assert.AreEqual(1, FRig.Call(TQ3Module.Ui, [UI_KEY_GETOVERSTRIKEMODE]));
  FRig.Keys.SetDown(65, True);
  Assert.AreEqual(1, FRig.Call(TQ3Module.Ui, [UI_KEY_ISDOWN, 65]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_KEY_CLEARSTATES]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_KEY_ISDOWN, 65]));
  Assert.AreEqual(0, FRig.Call(TQ3Module.Ui, [UI_KEY_SETCATCHER, Q3_KEYCATCH_UI]));
  Assert.AreEqual(Q3_KEYCATCH_UI, FRig.Call(TQ3Module.Ui, [UI_KEY_GETCATCHER]));
end;

end.
