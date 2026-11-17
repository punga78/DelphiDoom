{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - which system calls of      }
{  the catalog have a handler when every service of phase 2b is given, and      }
{  which are left (Tests\Data\Q3Host\unhandled.golden.txt: the list of the      }
{  traps that still raise with their name, for the census)                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.Coverage;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Q3Host')]
  TTestQ3HostCoverage = class
  public
    [Test]
    procedure LeTrappeSenzaGestoreDovrebberoEssereQuelleDelGolden;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.Console.Q3.Factory, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Q3Host.Types,
  DelphiDoom.Q3Host.Intf, DelphiDoom.Q3Host.Services.Intf, DelphiDoom.Q3Host.Factory, DelphiDoom.Q3Host.GameFiles,
  DelphiDoom.Q3Host.ClipMap, DelphiDoom.Q3Host.ServerState, DelphiDoom.Q3Host.OpcodeCatalog,
  DelphiDoom.Tests.Q3Host.Support, DelphiDoom.Tests.Q3Host.Services, DelphiDoom.Tests.Shared.Files,
  DelphiDoom.Tests.Shared.Golden;

procedure TTestQ3HostCoverage.LeTrappeSenzaGestoreDovrebberoEssereQuelleDelGolden;
var
  LConsole: TQ3Console;
  LServices: TQ3HostServices;
  LHost: IQ3SyscallHost;
  LActual, LGolden: TStringList;
  LModule: TQ3Module;
  LEntry: TQ3OpcodeEntry;
  LEntries: TArray<TQ3OpcodeEntry>;
  LOut: string;
begin
  LConsole := TQ3Console.Create;
  LActual := TStringList.Create;
  try
    LConsole.Init;
    LConsole.CVars.Get('sv_maxclients', '8', 0);
    LServices := Default(TQ3HostServices);
    LServices.CVars := LConsole.CVars;
    LServices.Arguments := LConsole.Arguments;
    LServices.Buffer := LConsole.Buffer;
    LServices.Commands := LConsole.Commands;
    LServices.Files := TQ3GameHostFiles.Create(TQ3FakeGameFileSystem.Create, nil);
    LServices.ClipMap := TQ3HostClipMap.Create(nil);
    LServices.State := TQ3HostServerState.Create(LConsole.CVars);
    LServices.ServerCommands := TQ3RecordingServerCommands.Create;
    LServices.Calendar := TQ3FixedCalendar.Create;
    for LModule := Low(TQ3Module) to High(TQ3Module) do
    begin
      LHost := TQ3HostFactory.CreateHostWithServices(LModule, TQ3RecordingConsole.Create(nil),
        TQ3FixedTime.Create(0), LServices);
      LEntries := TQ3OpcodeCatalog.ImportEntries(LModule);
      LActual.Add(Format('%s registered=%d of %d', [TQ3OpcodeCatalog.ModuleName(LModule),
        LHost.Registry.RegisteredCount, Length(LEntries)]));
      for LEntry in LEntries do
        if not LHost.Registry.IsRegistered(LEntry.Value) then
          LActual.Add(Format('%s %s', [TQ3OpcodeCatalog.ModuleName(LModule), LEntry.Name]));
    end;
    LOut := GetEnvironmentVariable('DELPHIDOOM_Q3_UNHANDLED_OUT');
    if LOut <> '' then
      LActual.SaveToFile(LOut);
    LGolden := TTestFiles.Lines(TTestFiles.DataFile('Q3Host', 'unhandled.golden.txt'));
    try
      TTestGolden.AssertSameLines(LGolden, LActual);
    finally
      LGolden.Free;
    end;
  finally
    LActual.Free;
    LConsole.Free;
  end;
end;

end.
