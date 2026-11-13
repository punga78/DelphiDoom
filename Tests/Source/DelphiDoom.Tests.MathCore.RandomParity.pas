{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the MathCore library - the game random generator      }
{  against a copy of the old m_rnd, ten million calls                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.RandomParity;

interface

uses
  DUnitX.TestFramework,
  DelphiDoom.MathCore.Intf;

type
  /// <summary>
  ///   Issue #185, fetta 1c: m_rnd stays the facade over IGameRandom; demos, network and saved
  ///   games depend on the series and on the indices, so the class is compared with a copy of
  ///   m_rnd before the issue #75 (7d8c7a42~1) on 10 million random calls, with five seeds of
  ///   the scenario, comparing the value and the five indices after every call
  /// </summary>
  [TestFixture]
  [Category('mathcore')]
  TTestMathCoreRandomParity = class(TObject)
  public
    [Test]
    procedure DovrebbeDareGliStessiNumeriEIndiciSuDieciMilioniDiChiamate;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.MathCore.Factory,
  DelphiDoom.MathCore.TableRandom,
  DelphiDoom.MathCore.TableSysRandom;

type
  // m_rnd at 7d8c7a42~1: the globals and the functions, with the tables of the library (their
  // content is compared with the old tables by the golden of the suite)
  TOldRandom = class
  public
    rndindex: integer;
    prndindex: integer;
    nrndindex: integer;
    sysrndindex: integer;
    sysrndseed: integer;
    stack: TStack<Integer>;
    constructor Create;
    destructor Destroy; override;
    function M_Random: integer;
    function P_Random: integer;
    function N_Random: integer;
    function Sys_Random: integer;
    function C_Random(var idx: integer): integer;
    function P_RandomFromSeed(const seed: integer): integer;
    procedure M_ClearRandom;
    procedure P_SaveRandom;
    function P_RestoreRandom: boolean;
  end;

const
  SYSRNDSIZE = 10007;

constructor TOldRandom.Create;
begin
  inherited Create;
  stack := TStack<Integer>.Create;
end;

destructor TOldRandom.Destroy;
begin
  stack.Free;
  inherited Destroy;
end;

function TOldRandom.M_Random: integer;
begin
  rndindex := (rndindex + 1) and $ff;
  result := RANDOM_TABLE[rndindex];
end;

function TOldRandom.P_Random: integer;
begin
  prndindex := (prndindex + 1) and $ff;
  result := RANDOM_TABLE[prndindex];
end;

function TOldRandom.N_Random: integer;
begin
  nrndindex := (nrndindex + 1) and $ff;
  result := RANDOM_TABLE[nrndindex];
end;

function TOldRandom.Sys_Random: integer;
begin
  sysrndindex := sysrndindex + sysrndseed + 1;
  if sysrndindex >= SYSRNDSIZE then
    sysrndindex := sysrndindex - SYSRNDSIZE;
  result := SYS_RANDOM_TABLE[sysrndindex];
end;

function TOldRandom.C_Random(var idx: integer): integer;
begin
  idx := (idx + 1) and $ff;
  result := RANDOM_TABLE[idx];
end;

function TOldRandom.P_RandomFromSeed(const seed: integer): integer;
begin
  result := RANDOM_TABLE[seed and $ff];
end;

procedure TOldRandom.M_ClearRandom;
begin
  rndindex := 0;
  prndindex := 0;
  nrndindex := 0;
  sysrndindex := 0;
  stack.Clear;
end;

procedure TOldRandom.P_SaveRandom;
begin
  stack.Push(prndindex);
end;

function TOldRandom.P_RestoreRandom: boolean;
begin
  // the old code gave I_DevError and left the index as it was
  result := stack.Count > 0;
  if result then
    prndindex := stack.Pop;
end;

{ TTestMathCoreRandomParity }

procedure TTestMathCoreRandomParity.DovrebbeDareGliStessiNumeriEIndiciSuDieciMilioniDiChiamate;
const
  SEEDS: array[0..4] of Cardinal = (185, 1, 20261113, $DEADBEEF, 7777777);
  CALLS_PER_SEED = 2000000;
var
  LSeedIndex: Integer;
  LCall: Integer;
  LState: Cardinal;
  LOld: TOldRandom;
  LNew: IGameRandom;
  LOldValue, LNewValue: Integer;
  LOldIndex, LNewIndex: Integer;
  LOperation: Integer;
  LTotal: Int64;
begin
  LTotal := 0;
  for LSeedIndex := 0 to High(SEEDS) do
  begin
    LState := SEEDS[LSeedIndex];
    LOld := TOldRandom.Create;
    try
      LNew := TMathCoreFactory.CreateGameRandom;
      LOldIndex := 0;
      LNewIndex := 0;
      for LCall := 1 to CALLS_PER_SEED do
      begin
        LState := LState * 1664525 + 1013904223;
        LOperation := (LState shr 24) mod 100;
        LOldValue := 0;
        LNewValue := 0;
        // mostly P_Random, as in the game; the rest in proportion
        if LOperation < 55 then
        begin
          LOldValue := LOld.P_Random;
          LNewValue := LNew.NextPlay;
        end
        else if LOperation < 65 then
        begin
          LOldValue := LOld.M_Random;
          LNewValue := LNew.NextMenu;
        end
        else if LOperation < 80 then
        begin
          LOldValue := LOld.N_Random;
          LNewValue := LNew.NextNonCompatible;
        end
        else if LOperation < 88 then
        begin
          LOldValue := LOld.Sys_Random;
          LNewValue := LNew.NextSystem;
        end
        else if LOperation < 92 then
        begin
          LOldValue := LOld.C_Random(LOldIndex);
          LNewValue := LNew.NextWithIndex(LNewIndex);
        end
        else if LOperation < 94 then
        begin
          LOldValue := LOld.P_RandomFromSeed(Integer(LState));
          LNewValue := LNew.FromSeed(Integer(LState));
        end
        else if LOperation < 96 then
        begin
          LOld.P_SaveRandom;
          LNew.SavePlayIndex;
        end
        else if LOperation < 98 then
        begin
          if LOld.P_RestoreRandom <> LNew.RestorePlayIndex then
            Assert.Fail(Format('seme %d chiamata %d: ripristino', [LSeedIndex, LCall]));
        end
        else if LOperation < 99 then
        begin
          // the seed of the random monsters that the demos keep
          LOld.sysrndseed := Integer((LState shr 8) and $FF);
          LNew.SystemSeed := LOld.sysrndseed;
        end
        else
        begin
          LOld.M_ClearRandom;
          LNew.Clear;
        end;
        if (LOldValue <> LNewValue) or (LOld.rndindex <> LNew.MenuIndex) or
          (LOld.prndindex <> LNew.PlayIndex) or (LOld.nrndindex <> LNew.NonCompatibleIndex) or
          (LOld.sysrndindex <> LNew.SystemIndex) or (LOld.sysrndseed <> LNew.SystemSeed) or
          (LOldIndex <> LNewIndex) then
          Assert.Fail(Format('seme %d chiamata %d operazione %d: %d <> %d', [LSeedIndex, LCall,
            LOperation, LOldValue, LNewValue]));
        Inc(LTotal);
      end;
    finally
      LOld.Free;
    end;
  end;
  Assert.AreEqual(Int64(10000000), LTotal);
end;

end.
