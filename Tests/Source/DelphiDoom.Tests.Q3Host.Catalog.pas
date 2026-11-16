{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - the numbers and names of   }
{  the system calls against what the C compiler prints for the real headers     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.Catalog;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework;

type
  /// <summary>
  ///   Tests\Data\Q3Host\opcodes.golden.txt is what gcc prints for the enums of g_public.h, cg_public.h and
  ///   ui_public.h (Tools\Verifica\254\opcodes.sh); the .asm files of the real modules are a second, independent
  ///   source of the numbers (Reference\quake3, read only; skipped if it is not there)
  /// </summary>
  [TestFixture]
  [Category('Q3Host')]
  TTestQ3OpcodeCatalog = class
  strict private
    function AsmFile(AIndex: Integer): string;
  public
    [Test]
    procedure OgniMembroDelleEnumDelCDovrebbeEssereNelCatalogoConLoStessoNumero;
    [Test]
    procedure IlCatalogoNonDovrebbeAvereMembriInPiuDelC;
    [Test]
    procedure OgniTrapDeiFileAsmDovrebbeEssereUnImportDelModulo;
    [Test]
    procedure UnNumeroSenzaNomeDovrebbeEssereSconosciuto;
    [Test]
    procedure IlNumeroDiUnImportDovrebbeEssereTrovatoPerNome;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.OpcodeCatalog, DelphiDoom.Q3Host.Opcodes,
  DelphiDoom.Tests.Shared.Files, DelphiDoom.Tests.Shared.Skip;

const
  ENUMS: array[0..5] of string = ('gameImport_t', 'gameExport_t', 'cgameImport_t', 'cgameExport_t', 'uiImport_t',
    'uiExport_t');

function IsImport(const AEnum: string): Boolean;
begin
  // sharedTraps_t (qcommon.h): memset ... ceil of game
  Result := AEnum.EndsWith('Import_t') or (AEnum = 'sharedTraps_t');
end;

function ModuleOfEnum(const AEnum: string): TQ3Module;
begin
  if AEnum = 'sharedTraps_t' then
    Result := TQ3Module.Game
  else if AEnum.StartsWith('cgame') then
    Result := TQ3Module.CGame
  else if AEnum.StartsWith('game') then
    Result := TQ3Module.Game
  else
    Result := TQ3Module.Ui;
end;

function TTestQ3OpcodeCatalog.AsmFile(AIndex: Integer): string;
const
  FOLDERS: array[0..2] of string = ('game\g_syscalls.asm', 'cgame\cg_syscalls.asm', 'ui\ui_syscalls.asm');
begin
  Result := TTestFiles.FindFileUp('Reference\quake3\code\' + FOLDERS[AIndex]);
  if Result = '' then
    TTestSkip.Ignore('Reference\quake3 non c''e''');
end;

procedure TTestQ3OpcodeCatalog.OgniMembroDelleEnumDelCDovrebbeEssereNelCatalogoConLoStessoNumero;
var
  LLines: TStringList;
  LLine, LName: string;
  LParts: TArray<string>;
  LModule: TQ3Module;
  LNumber, LValue: Integer;
  LFound, LCount: Integer;
begin
  LLines := TTestFiles.Lines(TTestFiles.DataFile('Q3Host', 'opcodes.golden.txt'));
  try
    LCount := 0;
    for LLine in LLines do
    begin
      LParts := LLine.Split([' ']);
      if Length(LParts) <> 3 then
        Continue;
      LModule := ModuleOfEnum(LParts[0]);
      LValue := StrToInt(LParts[2]);
      if IsImport(LParts[0]) then
        LFound := Ord(TQ3OpcodeCatalog.TryImportName(LModule, LValue, LName))
      else
        LFound := Ord(TQ3OpcodeCatalog.TryExportName(LModule, LValue, LName));
      Assert.AreEqual(1, LFound, LLine);
      Assert.AreEqual(LParts[1], LName, LLine);
      if IsImport(LParts[0]) then
      begin
        Assert.IsTrue(TQ3OpcodeCatalog.TryImportNumber(LModule, LParts[1], LNumber), LLine);
        Assert.AreEqual(LValue, LNumber, LLine);
      end;
      Inc(LCount);
    end;
    Assert.AreEqual(427, LCount);
  finally
    LLines.Free;
  end;
end;

procedure TTestQ3OpcodeCatalog.IlCatalogoNonDovrebbeAvereMembriInPiuDelC;
var
  LLines: TStringList;
  LLine, LEnum: string;
  LCounts: array[0..5] of Integer;
  LModule: TQ3Module;
  LIndex: Integer;
begin
  LLines := TTestFiles.Lines(TTestFiles.DataFile('Q3Host', 'opcodes.golden.txt'));
  try
    FillChar(LCounts, SizeOf(LCounts), 0);
    for LLine in LLines do
      for LIndex := 0 to 5 do
        if LLine.StartsWith(ENUMS[LIndex] + ' ') or ((LIndex = 0) and LLine.StartsWith('sharedTraps_t ')) then
          Inc(LCounts[LIndex]);
    for LIndex := 0 to 5 do
    begin
      LEnum := ENUMS[LIndex];
      LModule := ModuleOfEnum(LEnum);
      if IsImport(LEnum) then
        Assert.AreEqual(LCounts[LIndex], TQ3OpcodeCatalog.ImportCount(LModule), LEnum)
      else
        Assert.AreEqual(LCounts[LIndex], TQ3OpcodeCatalog.ExportCount(LModule), LEnum);
    end;
  finally
    LLines.Free;
  end;
end;

procedure TTestQ3OpcodeCatalog.OgniTrapDeiFileAsmDovrebbeEssereUnImportDelModulo;
const
  MODULES: array[0..2] of string = ('game', 'cgame', 'ui');
var
  LFile, LLine, LName, LTrim: string;
  LParts: TArray<string>;
  LModule: TQ3Module;
  LIndex, LNumber, LChecked: Integer;
begin
  LChecked := 0;
  for LIndex := 0 to 2 do
  begin
    LFile := AsmFile(LIndex);
    LModule := TQ3Module(LIndex);
    for LLine in TFile.ReadAllLines(LFile) do
    begin
      LTrim := LLine.Trim;
      // "equ trap_Print -1": the program calls the address -1 - number
      if not LTrim.StartsWith('equ') then
        Continue;
      LParts := LTrim.Split([#9, ' '], TStringSplitOptions.ExcludeEmpty);
      LNumber := -1 - StrToInt(LParts[2]);
      Assert.IsTrue(TQ3OpcodeCatalog.TryImportName(LModule, LNumber, LName), MODULES[LIndex] + ' ' + LTrim);
      Inc(LChecked);
    end;
  end;
  // every "equ" line of the three files: the traps and memset, sin, ... floor
  Assert.IsTrue(LChecked > 350, IntToStr(LChecked));
end;

procedure TTestQ3OpcodeCatalog.UnNumeroSenzaNomeDovrebbeEssereSconosciuto;
var
  LName: string;
begin
  Assert.IsFalse(TQ3OpcodeCatalog.TryImportName(TQ3Module.Game, 9999, LName));
  Assert.IsFalse(TQ3OpcodeCatalog.TryExportName(TQ3Module.Ui, -5, LName));
  Assert.IsFalse(TQ3OpcodeCatalog.TryImportName(TQ3Module.CGame, 60000, LName));
end;

procedure TTestQ3OpcodeCatalog.IlNumeroDiUnImportDovrebbeEssereTrovatoPerNome;
var
  LNumber: Integer;
begin
  Assert.IsTrue(TQ3OpcodeCatalog.TryImportNumber(TQ3Module.Game, 'G_TRACE', LNumber));
  Assert.AreEqual(G_TRACE, LNumber);
  Assert.IsTrue(TQ3OpcodeCatalog.TryImportNumber(TQ3Module.Ui, 'UI_R_DRAWSTRETCHPIC', LNumber));
  Assert.AreEqual(UI_R_DRAWSTRETCHPIC, LNumber);
  Assert.IsFalse(TQ3OpcodeCatalog.TryImportNumber(TQ3Module.Ui, 'G_TRACE', LNumber));
  Assert.AreEqual('ui', TQ3OpcodeCatalog.ModuleName(TQ3Module.Ui));
end;

end.
