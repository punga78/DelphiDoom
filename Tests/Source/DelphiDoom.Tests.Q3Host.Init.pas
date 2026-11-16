{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - the initialisation of the  }
{  12 .qvm of OpenArena 0.8.8 through the host, against the virtual machine of  }
{  Quake III (Tools\Verifica\254\init-golden.sh). The pk3 are read where they   }
{  are and the test is ignored if they are not there                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.Init;

interface

uses
  DUnitX.TestFramework;

type
  /// <summary>
  ///   GAME_INIT, CG_INIT and UI_GETAPIVERSION + UI_INIT of qagame, cgame and ui of the four pk3 with the host of
  ///   IdTech4\Q3Host: the same return values, the same texts printed, the same data image and the same
  ///   sequence of system calls with the same answers (count and fingerprint) as the C. Every number the modules
  ///   call must be a system call of the catalog. What the engine will answer is the C driver's: the entity
  ///   tokens, the configstring and the game state of the harness are registered here as the harness has them,
  ///   every other known call answers 0
  /// </summary>
  [TestFixture]
  [Category('Q3Host')]
  [Category('OpenArena')]
  TTestQ3HostInit = class
  public
    [Test]
    procedure LInizializzazioneDeiDodiciFileDovrebbeDareLaTracciaDelC;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, DelphiDoom.Wad.Zip.Intf, DelphiDoom.Wad.Source.Zip,
  DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Intf, DelphiDoom.Qvm.Factory, DelphiDoom.Q3Host.Types,
  DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Opcodes, DelphiDoom.Q3Host.Factory, DelphiDoom.Tests.Qvm.Support,
  DelphiDoom.Tests.Q3Host.Support, DelphiDoom.Tests.Shared.Files, DelphiDoom.Tests.Shared.Golden,
  DelphiDoom.Tests.Shared.Skip;

const
  PAKS: array[0..3] of string = ('baseoa\pak0.pk3', 'baseoa\pak6-patch085.pk3', 'baseoa\pak6-patch088.pk3',
    'missionpack\mp-pak0.pk3');
  MODULES: array[0..2] of string = ('qagame', 'cgame', 'ui');
  ENTITY_TOKENS: array[0..3] of AnsiString = ('{', 'classname', 'worldspawn', '}');
  GAME_STATE_OFFSETS = 4 * 1024;
  GAME_STATE_CHARS = 16000;

function ReadModule(const AArchive: IZipArchive; const AModule: string): TBytes;
var
  LIndex: Integer;
begin
  for LIndex := 0 to AArchive.ArchiveEntryCount - 1 do
    if SameText(AArchive.ArchiveEntryName(LIndex), 'vm/' + AModule + '.qvm') then
      Exit(AArchive.ReadArchiveEntry(LIndex));
  Assert.Fail(AArchive.ArchiveName + ': ' + AModule);
end;

// what the harness of the C answers to the three calls it knows beyond the common ones
procedure RegisterHarnessAnswers(AModule: TQ3Module; const ARegistry: IQ3SyscallRegistry);
var
  LToken: Integer;
begin
  LToken := 0;
  case AModule of
    TQ3Module.Game:
      begin
        ARegistry.Register(G_GET_ENTITY_TOKEN,
          function(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer
          begin
            if (LToken >= Length(ENTITY_TOKENS)) or (AArguments[2] <= 0) then
              Exit(0);
            AMachine.Memory.Range(AArguments[1], AArguments[2]);
            AMachine.Memory.WriteString(AArguments[1], ENTITY_TOKENS[LToken], AArguments[2]);
            Inc(LToken);
            Result := 1;
          end);
        ARegistry.Register(G_GET_CONFIGSTRING,
          function(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer
          begin
            if AArguments[3] > 0 then
              AMachine.Memory.WriteByte(AArguments[2], 0);
            Result := 0;
          end);
      end;
    TQ3Module.CGame:
      ARegistry.Register(CG_GETGAMESTATE,
        function(const AMachine: IQvmMachine; const AArguments: TQvmSystemCallArguments): Integer
        var
          LState: PByte;
          LText: AnsiString;
        begin
          LState := PByte(AMachine.Memory.Range(AArguments[1], GAME_STATE_OFFSETS + GAME_STATE_CHARS + 4));
          FillChar(LState^, GAME_STATE_OFFSETS + GAME_STATE_CHARS + 4, 0);
          PInteger(LState + 4 * 20)^ := 1;
          LText := 'baseoa-1';
          Move(LText[1], (LState + GAME_STATE_OFFSETS + 1)^, 9);
          PInteger(LState + GAME_STATE_OFFSETS + GAME_STATE_CHARS)^ := 10;
          Result := 0;
        end);
  end;
end;

procedure TTestQ3HostInit.LInizializzazioneDeiDodiciFileDovrebbeDareLaTracciaDelC;
var
  LFolder, LPak, LName: string;
  LArchive: IZipArchive;
  LGoldenFile, LGolden, LActual: TStringList;
  LModule: Integer;
  LHost: IQ3SyscallHost;
  LFingerprint: TQ3FingerprintHost;
  LKeeper: IQvmHost;
  LMachine: IQvmMachine;
  LStart, LCalls: Integer;
begin
  LFolder := GetEnvironmentVariable('DELPHIDOOM_OPENARENA');
  if (LFolder = '') or not TDirectory.Exists(LFolder) then
    LFolder := TTestFiles.FindFolderUp('Reference\openarena\openarena-0.8.8');
  if (LFolder = '') or not TFile.Exists(TPath.Combine(LFolder, PAKS[0])) then
    TTestSkip.Ignore('OpenArena non c''e'' (DELPHIDOOM_OPENARENA o Reference\openarena)');
  LGoldenFile := TTestFiles.Lines(TTestFiles.DataFile('Q3Host', 'init.golden.txt'));
  try
    LCalls := 0;
    for LPak in PAKS do
    begin
      LArchive := TZipFileSource.Create(TPath.Combine(LFolder, LPak));
      for LModule := 0 to 2 do
      begin
        LName := TPath.GetFileNameWithoutExtension(LPak) + '/' + MODULES[LModule];
        LActual := TStringList.Create;
        LGolden := TStringList.Create;
        try
          LStart := LGoldenFile.IndexOf('scenario ' + LName);
          Assert.IsTrue(LStart >= 0, LName);
          repeat
            LGolden.Add(LGoldenFile[LStart]);
            Inc(LStart);
          until LGoldenFile[LStart - 1] = 'end';

          LActual.Add('scenario ' + LName);
          LHost := TQ3HostFactory.CreateHost(TQ3Module(LModule), TQ3RecordingConsole.Create(LActual),
            TQ3FixedTime.Create(0));
          RegisterHarnessAnswers(TQ3Module(LModule), LHost.Registry);
          // every other call of the catalog answers 0, as in the harness
          LHost.Fallback := TQvmNullHost.Create;
          LFingerprint := TQ3FingerprintHost.Create(LHost);
          LKeeper := LFingerprint;
          LMachine := TQvmFactory.CreateMachine('m', ReadModule(LArchive, MODULES[LModule]), LKeeper);
          // a Com_Error of the module ends the run, as in the driver of the C ("X" the text, "E" the error)
          try
            case LModule of
              0:
                LActual.Add('R ' + IntToStr(LMachine.Call(0, [1000, 12345, 0])));
              1:
                LActual.Add('R ' + IntToStr(LMachine.Call(0, [0, 0, 0])));
            else
              begin
                LActual.Add('R ' + IntToStr(LMachine.Call(0, [])));
                LActual.Add('R ' + IntToStr(LMachine.Call(1, [])));
              end;
            end;
          except
            on E: EQ3ModuleErrorException do
            begin
              LActual.Add('X ' + TQvmScenarioRunner.Escaped(AnsiString(E.Message)));
              LActual.Add('E ' + TQvmScenarioRunner.Escaped(AnsiString(E.Message)));
            end;
          end;
          LActual.Add(Format('M %s %d %s', [TQvmScenarioRunner.MemoryFingerprint(LMachine), LFingerprint.Count,
            TQvmScenarioRunner.Hex64(LFingerprint.Hash)]));
          LActual.Add('end');
          Inc(LCalls, LFingerprint.Count);
          TTestGolden.AssertSameLines(LGolden, LActual);
        finally
          LGolden.Free;
          LActual.Free;
        end;
      end;
    end;
    TQvmScenarioRunner.Report(Format('12 file, %d chiamate di sistema', [LCalls]));
  finally
    LGoldenFile.Free;
  end;
end;

end.
