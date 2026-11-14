{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the QVM library - the 12 .qvm of OpenArena 0.8.8 (GPL  }
{  v2), read where they are (inside the pk3) and ignored if they are not there }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Qvm.OpenArena;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Wad.Zip.Intf,
  DelphiDoom.Tests.Qvm.Support;

type
  /// <summary>The files of a pk3 by path, as the manager of the machines asks for them</summary>
  TQvmPakFiles = class(TInterfacedObject, IBotFileSource)
  strict private
    FArchive: IZipArchive;
  public
    constructor Create(const AArchive: IZipArchive);
    function TryReadFile(const APath: AnsiString; out AData: TBytes): Boolean;
  end;

  /// <summary>
  ///   vm/qagame.qvm, vm/cgame.qvm and vm/ui.qvm of baseoa\pak0.pk3, pak6-patch085.pk3, pak6-patch088.pk3
  ///   and missionpack\mp-pak0.pk3 (DELPHIDOOM_OPENARENA = the folder with baseoa and missionpack, or
  ///   Reference\openarena\openarena-0.8.8), read with TZipFileSource of Libs\Wad. Nothing of OpenArena is
  ///   in the repository: Tests\Data\Qvm\openarena.golden.txt has what the virtual machine of Quake III
  ///   (Tools\Verifica\120) returned, counted and printed on the same files.
  ///   OpenArena is built with ioquake3: its files have the VM_MAGIC_VER2 header ($12721445, one more field
  ///   and a jump table after the literals), which Quake III 1.32 refuses as "bad header". The instructions
  ///   are the same; the C of the harness is compiled with that magic number to read them
  /// </summary>
  [TestFixture]
  [Category('Qvm')]
  [Category('OpenArena')]
  TTestQvmOpenArena = class
  strict private
    function BaseFolder: string;
    function OpenPak(const AFolder, APak: string): IZipArchive;
    function ReadModule(const AArchive: IZipArchive; const AModule: string): TBytes;
  public
    [Test]
    procedure IDodiciFileDovrebberoEssereDellaVersioneDueDiIoquake3;
    [Test]
    procedure IDodiciFileDovrebberoCaricarsiConOgniSaltoEOgniBersaglioValido;
    [Test]
    procedure LInizializzazioneDovrebbeDareLaTracciaDelCSugliStessiFile;
    [Test]
    procedure IlGestoreDovrebbeCaricareITreModuliDaUnPk3;
  end;

implementation

uses
  System.IOUtils, DUnitX.Exceptions, DelphiDoom.Wad.Source.Zip, DelphiDoom.Logging.Intf, DelphiDoom.Qvm.Types,
  DelphiDoom.Qvm.Intf, DelphiDoom.Qvm.Image, DelphiDoom.Qvm.Factory, DelphiDoom.Tests.Shared.Files,
  DelphiDoom.Tests.Shared.Golden, DelphiDoom.Tests.Shared.Skip;

const
  PAKS: array[0..3] of string = ('baseoa\pak0.pk3', 'baseoa\pak6-patch085.pk3', 'baseoa\pak6-patch088.pk3',
    'missionpack\mp-pak0.pk3');
  MODULES: array[0..2] of string = ('qagame', 'cgame', 'ui');
  PROFILES: array[0..2] of TQvmHostProfile = (TQvmHostProfile.Game, TQvmHostProfile.CGame, TQvmHostProfile.Ui);
  OPENARENA_VARIABLE = 'DELPHIDOOM_OPENARENA';
  OPENARENA_FOLDER = 'Reference\openarena\openarena-0.8.8';
  GOLDEN_AREA = 'Qvm';
  GOLDEN_FILE = 'openarena.golden.txt';
  SNoOpenArena = 'OpenArena non c''e'' (DELPHIDOOM_OPENARENA o Reference\openarena)';

{ TQvmPakFiles }

constructor TQvmPakFiles.Create(const AArchive: IZipArchive);
begin
  inherited Create;
  FArchive := AArchive;
end;

function TQvmPakFiles.TryReadFile(const APath: AnsiString; out AData: TBytes): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FArchive.ArchiveEntryCount - 1 do
    if SameText(FArchive.ArchiveEntryName(LIndex), string(APath)) then
    begin
      AData := FArchive.ReadArchiveEntry(LIndex);
      Exit(True);
    end;
  AData := nil;
  Result := False;
end;

{ TTestQvmOpenArena }

function TTestQvmOpenArena.BaseFolder: string;
begin
  Result := GetEnvironmentVariable(OPENARENA_VARIABLE);
  if (Result = '') or not TDirectory.Exists(Result) then
    Result := TTestFiles.FindFolderUp(OPENARENA_FOLDER);
  if (Result = '') or not TFile.Exists(TPath.Combine(Result, PAKS[0])) then
    TTestSkip.Ignore(SNoOpenArena);
end;

function TTestQvmOpenArena.OpenPak(const AFolder, APak: string): IZipArchive;
begin
  Result := TZipFileSource.Create(TPath.Combine(AFolder, APak));
end;

function TTestQvmOpenArena.ReadModule(const AArchive: IZipArchive; const AModule: string): TBytes;
var
  LFiles: IBotFileSource;
begin
  LFiles := TQvmPakFiles.Create(AArchive);
  Assert.IsTrue(LFiles.TryReadFile(AnsiString('vm/' + AModule + '.qvm'), Result),
    AArchive.ArchiveName + ': ' + AModule);
end;

procedure TTestQvmOpenArena.IDodiciFileDovrebberoEssereDellaVersioneDueDiIoquake3;
var
  LFolder, LPak, LModule: string;
  LArchive: IZipArchive;
  LData: TBytes;
  LMagic, LCount: Integer;
begin
  LFolder := BaseFolder;
  LCount := 0;
  for LPak in PAKS do
  begin
    LArchive := OpenPak(LFolder, LPak);
    for LModule in MODULES do
    begin
      LData := ReadModule(LArchive, LModule);
      Move(LData[0], LMagic, SizeOf(Integer));
      // not the VM_MAGIC of Quake III 1.32: vm.c as id released it says "bad header" to every one of them
      Assert.AreEqual(QVM_MAGIC_VER2, LMagic, LPak + ' ' + LModule);
      Inc(LCount);
    end;
  end;
  Assert.AreEqual(12, LCount);
end;

procedure TTestQvmOpenArena.IDodiciFileDovrebberoCaricarsiConOgniSaltoEOgniBersaglioValido;
var
  LFolder, LPak, LModule: string;
  LArchive: IZipArchive;
  LData: TBytes;
  LImage: TQvmImage;
  LMachine: IQvmMachine;
  LTarget, LInstructions: Integer;
begin
  LFolder := BaseFolder;
  LInstructions := 0;
  for LPak in PAKS do
  begin
    LArchive := OpenPak(LFolder, LPak);
    for LModule in MODULES do
    begin
      LData := ReadModule(LArchive, LModule);
      LImage := TQvmImage.Create(LData, TQvmLimits.Default, LModule);
      try
        Assert.IsTrue(LImage.Version2, LPak + ' ' + LModule);
        Assert.IsTrue(Length(LImage.JumpTargets) > 0, LPak + ' ' + LModule);
        // every entry of the jump table (the targets of the switch statements) is an instruction
        for LTarget in LImage.JumpTargets do
          if Cardinal(LTarget) >= Cardinal(LImage.InstructionCount) then
            Assert.Fail(Format('%s %s: jump target %d of %d', [LPak, LModule, LTarget, LImage.InstructionCount]));
        // the program stack of the machine fits in the bss
        Assert.IsTrue(LImage.DataSize >= QVM_STACK_SIZE, LPak + ' ' + LModule);
        Inc(LInstructions, LImage.InstructionCount);
      finally
        LImage.Free;
      end;
      // the whole code is checked when the machine is made: every byte an instruction, every branch to an
      // instruction that exists
      LMachine := TQvmFactory.CreateMachine(AnsiString(LModule), LData, TQvmNullHost.Create);
      Assert.AreEqual(LMachine.Info.DataLength, LMachine.ProgramStack, LPak + ' ' + LModule);
    end;
  end;
  TQvmScenarioRunner.Report(Format('12 file, %d istruzioni', [LInstructions]));
  Assert.IsTrue(LInstructions > 1000000);
end;

procedure TTestQvmOpenArena.LInizializzazioneDovrebbeDareLaTracciaDelCSugliStessiFile;
var
  LFolder, LPak: string;
  LArchive: IZipArchive;
  LScenario: TQvmScenario;
  LGoldenFile, LGolden, LActual: TStringList;
  LModule, LStart: Integer;
begin
  LFolder := BaseFolder;
  LGoldenFile := TTestFiles.Lines(TTestFiles.DataFile(GOLDEN_AREA, GOLDEN_FILE));
  try
    for LPak in PAKS do
    begin
      LArchive := OpenPak(LFolder, LPak);
      for LModule := 0 to High(MODULES) do
      begin
        LScenario := Default(TQvmScenario);
        LScenario.Name := TPath.GetFileNameWithoutExtension(LPak) + '/' + MODULES[LModule];
        LScenario.Profile := PROFILES[LModule];
        LScenario.Image := ReadModule(LArchive, MODULES[LModule]);
        LScenario.Add('trace off');
        case PROFILES[LModule] of
          // GAME_INIT( levelTime, randomSeed, restart )
          TQvmHostProfile.Game:
            LScenario.AddCall([0, 1000, 12345, 0]);
          // CG_INIT( serverMessageNum, serverCommandSequence, clientNum )
          TQvmHostProfile.CGame:
            LScenario.AddCall([0, 0, 0, 0]);
        else
          // UI_GETAPIVERSION, then UI_INIT
          LScenario.AddCall([0]);
          LScenario.AddCall([1]);
        end;
        LScenario.Add('mem');

        LActual := TStringList.Create;
        LGolden := TStringList.Create;
        try
          LStart := LGoldenFile.IndexOf('scenario ' + LScenario.Name);
          Assert.IsTrue(LStart >= 0, LScenario.Name);
          repeat
            LGolden.Add(LGoldenFile[LStart]);
            Inc(LStart);
          until LGoldenFile[LStart - 1] = 'end';
          TQvmScenarioRunner.Run(LScenario, LActual);
          try
            TTestGolden.AssertSameLines(LGolden, LActual);
          except
            on E: ETestFailure do
              raise ETestFailure.Create(LScenario.Name + ', ' + E.Message);
          end;
        finally
          LGolden.Free;
          LActual.Free;
        end;
      end;
    end;
  finally
    LGoldenFile.Free;
  end;
end;

procedure TTestQvmOpenArena.IlGestoreDovrebbeCaricareITreModuliDaUnPk3;
var
  LManager: IQvmManager;
  LHost: IQvmHost;
  LMachine: IQvmMachine;
  LModule: string;
  LInfo: TArray<TQvmInfo>;
begin
  LHost := TQvmNullHost.Create;
  LManager := TQvmFactory.CreateManager(TQvmPakFiles.Create(OpenPak(BaseFolder, PAKS[2])), nil,
    TQvmLimits.Default, True);
  for LModule in MODULES do
  begin
    LMachine := LManager.Load(AnsiString(LModule), LHost);
    Assert.IsNotNull(LMachine, LModule);
    // the pk3 has no .map: no symbols
    Assert.AreEqual(0, LMachine.Symbols.Count);
    Assert.AreEqual<AnsiString>('NO SYMBOLS', LMachine.Symbols.ValueToSymbol(0));
  end;
  Assert.AreEqual(3, LManager.Count);
  LInfo := LManager.Info;
  Assert.AreEqual<AnsiString>('qagame', LInfo[0].Name);
  Assert.AreEqual<AnsiString>('ui', LInfo[2].Name);
  // UI_GETAPIVERSION needs no host
  Assert.AreEqual(4, LManager.Find('ui').Call(0, []));
end;

end.
