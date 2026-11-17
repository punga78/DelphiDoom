{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Quake III host library (the system calls of   }
{  qagame, cgame and ui, DUnitX)                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Q3Host;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Types in '..\Framework\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Framework\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.BotAi.Import.Intf in '..\IdTech4\BotAi\DelphiDoom.BotAi.Import.Intf.pas',
  DelphiDoom.Models.Q3Player.TokenReader in '..\Framework\Models\DelphiDoom.Models.Q3Player.TokenReader.pas',
  DelphiDoom.Decl.Q3Shader.Calc.FloatMask in '..\IdTech4\Decl\DelphiDoom.Decl.Q3Shader.Calc.FloatMask.pas',
  DelphiDoom.Wad.Types in '..\Framework\Wad\DelphiDoom.Wad.Types.pas',
  DelphiDoom.Wad.Intf in '..\Framework\Wad\DelphiDoom.Wad.Intf.pas',
  DelphiDoom.Wad.Zip.Intf in '..\Framework\Wad\DelphiDoom.Wad.Zip.Intf.pas',
  DelphiDoom.Wad.Name in '..\Framework\Wad\DelphiDoom.Wad.Name.pas',
  DelphiDoom.Wad.Source.Zip in '..\Framework\Wad\DelphiDoom.Wad.Source.Zip.pas',
  DelphiDoom.Qvm.Types in '..\IdTech4\Qvm\DelphiDoom.Qvm.Types.pas',
  DelphiDoom.Qvm.Opcodes in '..\IdTech4\Qvm\DelphiDoom.Qvm.Opcodes.pas',
  DelphiDoom.Qvm.Intf in '..\IdTech4\Qvm\DelphiDoom.Qvm.Intf.pas',
  DelphiDoom.Qvm.Image in '..\IdTech4\Qvm\DelphiDoom.Qvm.Image.pas',
  DelphiDoom.Qvm.Code in '..\IdTech4\Qvm\DelphiDoom.Qvm.Code.pas',
  DelphiDoom.Qvm.Memory in '..\IdTech4\Qvm\DelphiDoom.Qvm.Memory.pas',
  DelphiDoom.Qvm.Symbols in '..\IdTech4\Qvm\DelphiDoom.Qvm.Symbols.pas',
  DelphiDoom.Qvm.FloatMath in '..\IdTech4\Qvm\DelphiDoom.Qvm.FloatMath.pas',
  DelphiDoom.Qvm.Interpreter in '..\IdTech4\Qvm\DelphiDoom.Qvm.Interpreter.pas',
  DelphiDoom.Qvm.Machine in '..\IdTech4\Qvm\DelphiDoom.Qvm.Machine.pas',
  DelphiDoom.Qvm.Manager in '..\IdTech4\Qvm\DelphiDoom.Qvm.Manager.pas',
  DelphiDoom.Qvm.Factory in '..\IdTech4\Qvm\DelphiDoom.Qvm.Factory.pas',
  DelphiDoom.Q3Host.Types in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Types.pas',
  DelphiDoom.Q3Host.Opcodes in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Opcodes.pas',
  DelphiDoom.Q3Host.OpcodeTables in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.OpcodeTables.pas',
  DelphiDoom.Q3Host.OpcodeCatalog in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.OpcodeCatalog.pas',
  DelphiDoom.Q3Host.Intf in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Intf.pas',
  DelphiDoom.Q3Host.Arguments in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Arguments.pas',
  DelphiDoom.Q3Host.SyscallHost in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.SyscallHost.pas',
  DelphiDoom.Q3Host.CommonSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.CommonSyscalls.pas',
  DelphiDoom.Q3Host.Services.Intf in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Services.Intf.pas',
  DelphiDoom.Q3Host.CvarSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.CvarSyscalls.pas',
  DelphiDoom.Q3Host.FileSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.FileSyscalls.pas',
  DelphiDoom.Q3Host.GameFiles in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.GameFiles.pas',
  DelphiDoom.Q3Host.ClipMap in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ClipMap.pas',
  DelphiDoom.Q3Host.MapLoader in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.MapLoader.pas',
  DelphiDoom.Q3Host.TraceMemory in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.TraceMemory.pas',
  DelphiDoom.Q3Host.EntityTokens in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.EntityTokens.pas',
  DelphiDoom.Q3Host.CollisionSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.CollisionSyscalls.pas',
  DelphiDoom.Q3Host.ServerState in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ServerState.pas',
  DelphiDoom.Q3Host.GameWorld in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.GameWorld.pas',
  DelphiDoom.Q3Host.GameSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.GameSyscalls.pas',
  DelphiDoom.Q3Host.MiscSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.MiscSyscalls.pas',
  DelphiDoom.Q3Host.Client.Types in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Client.Types.pas',
  DelphiDoom.Q3Host.Client.KeyNames in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Client.KeyNames.pas',
  DelphiDoom.Q3Host.Client.Intf in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Client.Intf.pas',
  DelphiDoom.Q3Host.ClientState in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ClientState.pas',
  DelphiDoom.Q3Host.ClientKeys in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ClientKeys.pas',
  DelphiDoom.Q3Host.NetAddress in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.NetAddress.pas',
  DelphiDoom.Q3Host.LanServers in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.LanServers.pas',
  DelphiDoom.Q3Host.ClientCdKey in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ClientCdKey.pas',
  DelphiDoom.Q3Host.ClientRecordingRenderer in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ClientRecordingRenderer.pas',
  DelphiDoom.Q3Host.ClientSoundAdapter in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ClientSoundAdapter.pas',
  DelphiDoom.Q3Host.ScriptFiles in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ScriptFiles.pas',
  DelphiDoom.Q3Host.ScriptLog in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ScriptLog.pas',
  DelphiDoom.Q3Host.ClientStateSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.ClientStateSyscalls.pas',
  DelphiDoom.Q3Host.KeySyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.KeySyscalls.pas',
  DelphiDoom.Q3Host.SoundSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.SoundSyscalls.pas',
  DelphiDoom.Q3Host.CinematicSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.CinematicSyscalls.pas',
  DelphiDoom.Q3Host.RendererSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.RendererSyscalls.pas',
  DelphiDoom.Q3Host.PrecompilerSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.PrecompilerSyscalls.pas',
  DelphiDoom.Q3Host.LanSyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.LanSyscalls.pas',
  DelphiDoom.Q3Host.CdKeySyscalls in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.CdKeySyscalls.pas',
  DelphiDoom.Q3Host.Client.Services in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Client.Services.pas',
  DelphiDoom.Q3Host.Factory in '..\IdTech4\Q3Host\DelphiDoom.Q3Host.Factory.pas',
  DelphiDoom.Tests.Shared.Fnv in 'Source\DelphiDoom.Tests.Shared.Fnv.pas',
  DelphiDoom.Tests.Shared.Files in 'Source\DelphiDoom.Tests.Shared.Files.pas',
  DelphiDoom.Tests.Shared.Golden in 'Source\DelphiDoom.Tests.Shared.Golden.pas',
  DelphiDoom.Tests.Shared.Skip in 'Source\DelphiDoom.Tests.Shared.Skip.pas',
  DelphiDoom.Tests.Qvm.Assembler in 'Source\DelphiDoom.Tests.Qvm.Assembler.pas',
  DelphiDoom.Tests.Qvm.Support in 'Source\DelphiDoom.Tests.Qvm.Support.pas',
  DelphiDoom.Tests.Qvm.Programs in 'Source\DelphiDoom.Tests.Qvm.Programs.pas',
  DelphiDoom.Tests.Q3Host.Support in 'Source\DelphiDoom.Tests.Q3Host.Support.pas',
  DelphiDoom.Tests.Q3Host.Catalog in 'Source\DelphiDoom.Tests.Q3Host.Catalog.pas',
  DelphiDoom.Tests.Q3Host.Math in 'Source\DelphiDoom.Tests.Q3Host.Math.pas',
  DelphiDoom.Tests.Q3Host.Host in 'Source\DelphiDoom.Tests.Q3Host.Host.pas',
  DelphiDoom.Tests.Q3Host.Init in 'Source\DelphiDoom.Tests.Q3Host.Init.pas',
  DelphiDoom.Tests.Q3Host.Services in 'Source\DelphiDoom.Tests.Q3Host.Services.pas',
  DelphiDoom.Tests.Q3Host.Layout in 'Source\DelphiDoom.Tests.Q3Host.Layout.pas',
  DelphiDoom.Tests.Q3Host.Cvars in 'Source\DelphiDoom.Tests.Q3Host.Cvars.pas',
  DelphiDoom.Tests.Q3Host.Files in 'Source\DelphiDoom.Tests.Q3Host.Files.pas',
  DelphiDoom.Tests.Q3Host.GameWorld in 'Source\DelphiDoom.Tests.Q3Host.GameWorld.pas',
  DelphiDoom.Tests.Q3Host.Reach in 'Source\DelphiDoom.Tests.Q3Host.Reach.pas',
  DelphiDoom.Tests.Q3Host.Coverage in 'Source\DelphiDoom.Tests.Q3Host.Coverage.pas',
  DelphiDoom.Tests.Q3Host.ClientSupport in 'Source\DelphiDoom.Tests.Q3Host.ClientSupport.pas',
  DelphiDoom.Tests.Q3Host.ClientState in 'Source\DelphiDoom.Tests.Q3Host.ClientState.pas',
  DelphiDoom.Tests.Q3Host.ClientKeys in 'Source\DelphiDoom.Tests.Q3Host.ClientKeys.pas',
  DelphiDoom.Tests.Q3Host.ClientLan in 'Source\DelphiDoom.Tests.Q3Host.ClientLan.pas',
  DelphiDoom.Tests.Q3Host.ClientServices in 'Source\DelphiDoom.Tests.Q3Host.ClientServices.pas',
  DelphiDoom.Tests.Q3Host.ClientReach in 'Source\DelphiDoom.Tests.Q3Host.ClientReach.pas';

var
  Runner: ITestRunner;
  Results: IRunResults;
  Logger: ITestLogger;
  NUnitLogger: ITestLogger;

begin
  try
    TDUnitX.CheckCommandLine;
    Runner := TDUnitX.CreateRunner;
    Runner.UseRTTI := True;
    Runner.FailsOnNoAsserts := False;

    Logger := TDUnitXConsoleLogger.Create(True);
    Runner.AddLogger(Logger);
    NUnitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    Runner.AddLogger(NUnitLogger);

    Results := Runner.Execute;
    if not Results.AllPassed then
      System.ExitCode := EXIT_ERRORS;

    {$IFNDEF CI}
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done.. press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
end.
