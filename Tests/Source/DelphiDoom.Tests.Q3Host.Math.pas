{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - the math system calls      }
{  against the C library (Tools\Verifica\254\mathgen.c)                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.Math;

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>
  ///   sin, cos, atan2, sqrt, floor and ceil of game, cgame and ui: Tests\Data\Q3Host\math.golden.txt has, for
  ///   4300 pairs of floats (the special values and 4000 seeded ones), the bits gcc gives to
  ///   (float)sin( (double)a ) and the others
  /// </summary>
  [TestFixture]
  [Category('Q3Host')]
  TTestQ3MathSyscalls = class
  public
    [Test]
    procedure LeFunzioniMatematicheDovrebberoDareGliStessiBitDelC;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.Qvm.Types, DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Intf,
  DelphiDoom.Q3Host.Factory, DelphiDoom.Q3Host.OpcodeCatalog, DelphiDoom.Tests.Q3Host.Support,
  DelphiDoom.Tests.Shared.Files, DelphiDoom.Tests.Qvm.Support;

const
  NAMES: array[0..5] of string = ('SIN', 'COS', 'ATAN2', 'SQRT', 'FLOOR', 'CEIL');

function Bits(const AText: string): Integer;
begin
  Result := Integer(Cardinal(StrToInt64('$' + AText)));
end;

function PrefixOf(AModule: TQ3Module; AFunction: Integer): string;
begin
  case AModule of
    TQ3Module.Game:
      Result := 'TRAP_';
    TQ3Module.CGame:
      Result := 'CG_';
  else
    Result := 'UI_';
  end;
end;

procedure TTestQ3MathSyscalls.LeFunzioniMatematicheDovrebberoDareGliStessiBitDelC;
var
  LLines: TStringList;
  LHosts: array[TQ3Module] of IQ3SyscallHost;
  LModule: TQ3Module;
  LNumbers: array[TQ3Module, 0..5] of Integer;
  LFunction, LRow, LCount, LMismatch: Integer;
  LParts: TArray<string>;
  LArguments: TQvmSystemCallArguments;
  LExpected, LActual: Integer;
  LNaN: Boolean;
begin
  for LModule := Low(TQ3Module) to High(TQ3Module) do
  begin
    LHosts[LModule] := TQ3HostFactory.CreateHost(LModule, TQ3RecordingConsole.Create(nil), TQ3FixedTime.Create(0));
    for LFunction := 0 to 5 do
    begin
      // game has TRAP_, cgame CG_ and ui UI_ in front of the names
      Assert.IsTrue(TQ3OpcodeCatalog.TryImportNumber(LModule, PrefixOf(LModule, LFunction) + NAMES[LFunction],
        LNumbers[LModule, LFunction]), NAMES[LFunction]);
    end;
  end;
  LLines := TTestFiles.Lines(TTestFiles.DataFile('Q3Host', 'math.golden.txt'));
  try
    LCount := 0;
    LMismatch := 0;
    for LRow := 0 to LLines.Count - 1 do
    begin
      LParts := LLines[LRow].Split([' ']);
      if Length(LParts) <> 8 then
        Continue;
      for LModule := Low(TQ3Module) to High(TQ3Module) do
        for LFunction := 0 to 5 do
        begin
          FillChar(LArguments, SizeOf(LArguments), 0);
          LArguments[0] := LNumbers[LModule, LFunction];
          LArguments[1] := Bits(LParts[0]);
          LArguments[2] := Bits(LParts[1]);
          LActual := LHosts[LModule].SystemCall(nil, LArguments);
          LExpected := Bits(LParts[2 + LFunction]);
          // a NaN is a NaN (the processor and the C library may differ in its sign and payload)
          LNaN := ((Cardinal(LExpected) and $7F800000) = $7F800000) and ((Cardinal(LExpected) and $7FFFFF) <> 0) and
            ((Cardinal(LActual) and $7F800000) = $7F800000) and ((Cardinal(LActual) and $7FFFFF) <> 0);
          if (LActual <> LExpected) and not LNaN then
          begin
            Inc(LMismatch);
            if LMismatch <= 5 then
              TQvmScenarioRunner.Report(Format('math %s %s %s: %08x invece di %08x', [NAMES[LFunction],
                LParts[0], LParts[1], LActual, LExpected]));
          end;
          Inc(LCount);
        end;
    end;
    Assert.AreEqual(0, LMismatch, Format('%d confronti', [LCount]));
    Assert.AreEqual(4289 * 18, LCount);
  finally
    LLines.Free;
  end;
end;

end.
