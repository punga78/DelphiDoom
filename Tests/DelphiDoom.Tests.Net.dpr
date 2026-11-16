{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the net library (DUnitX)                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Net;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  DelphiDoom.Logging.Types in '..\Framework\Logging\DelphiDoom.Logging.Types.pas',
  DelphiDoom.Logging.Intf in '..\Framework\Logging\DelphiDoom.Logging.Intf.pas',
  DelphiDoom.Clock.Intf in '..\Framework\Clock\DelphiDoom.Clock.Intf.pas',
  DelphiDoom.GameState.Intf in '..\Libs\GameState\DelphiDoom.GameState.Intf.pas',
  DelphiDoom.Net.Transport.Types in '..\Framework\NetTransport\DelphiDoom.Net.Transport.Types.pas',
  DelphiDoom.Net.Transport.Intf in '..\Framework\NetTransport\DelphiDoom.Net.Transport.Intf.pas',
  DelphiDoom.Net.Types in '..\Libs\Net\DelphiDoom.Net.Types.pas',
  DelphiDoom.Net.Intf in '..\Libs\Net\DelphiDoom.Net.Intf.pas',
  DelphiDoom.Net.PacketCodec in '..\Libs\Net\DelphiDoom.Net.PacketCodec.pas',
  DelphiDoom.Net.TicSync in '..\Libs\Net\DelphiDoom.Net.TicSync.pas',
  DelphiDoom.Net.ConsistencyTracker in '..\Libs\Net\DelphiDoom.Net.ConsistencyTracker.pas',
  DelphiDoom.Net.StartArbiter in '..\Libs\Net\DelphiDoom.Net.StartArbiter.pas',
  DelphiDoom.Net.NodeListParser in '..\Framework\NetTransport\DelphiDoom.Net.NodeListParser.pas',
  DelphiDoom.Net.WinsockTransport in '..\Framework\NetTransport\DelphiDoom.Net.WinsockTransport.pas',
  DelphiDoom.Net.Factory in '..\Libs\Net\DelphiDoom.Net.Factory.pas',
  DelphiDoom.MathCore.TableCrc32 in '..\Framework\MathCore\DelphiDoom.MathCore.TableCrc32.pas',
  DelphiDoom.MathCore.Crc32 in '..\Framework\MathCore\DelphiDoom.MathCore.Crc32.pas',
  DelphiDoom.IdLib.Core.Intf in '..\Framework\IdLib\Core\DelphiDoom.IdLib.Core.Intf.pas',
  DelphiDoom.IdLib.Core.Exceptions in '..\Framework\IdLib\Core\DelphiDoom.IdLib.Core.Exceptions.pas',
  DelphiDoom.IdLib.Text.Strings in '..\Framework\IdLib\Text\DelphiDoom.IdLib.Text.Strings.pas',
  DelphiDoom.IdLib.Text.Types in '..\Framework\IdLib\Text\DelphiDoom.IdLib.Text.Types.pas',
  DelphiDoom.IdLib.Text.Token in '..\Framework\IdLib\Text\DelphiDoom.IdLib.Text.Token.pas',
  DelphiDoom.IdLib.Math.Math in '..\Framework\IdLib\Math\DelphiDoom.IdLib.Math.Math.pas',
  DelphiDoom.IdLib.Math.Random in '..\Framework\IdLib\Math\DelphiDoom.IdLib.Math.Random.pas',
  DelphiDoom.IdLib.Math.Vec2 in '..\Framework\IdLib\Math\DelphiDoom.IdLib.Math.Vec2.pas',
  DelphiDoom.IdLib.Math.Vec3 in '..\Framework\IdLib\Math\DelphiDoom.IdLib.Math.Vec3.pas',
  DelphiDoom.IdLib.Math.Vec4 in '..\Framework\IdLib\Math\DelphiDoom.IdLib.Math.Vec4.pas',
  DelphiDoom.Scanner.IdCNumbers in '..\Framework\Scanner\DelphiDoom.Scanner.IdCNumbers.pas',
  DelphiDoom.Scanner.IdParser.Intf in '..\Framework\Scanner\DelphiDoom.Scanner.IdParser.Intf.pas',
  DelphiDoom.MathCore.Float.Angles in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Angles.pas',
  DelphiDoom.MathCore.Float.Mat3 in '..\Framework\MathCore\DelphiDoom.MathCore.Float.Mat3.pas',
  DelphiDoom.Scanner.IdDict in '..\Framework\Scanner\DelphiDoom.Scanner.IdDict.pas',
  DelphiDoom.Net.BitMessage.Types in '..\Libs\Net\DelphiDoom.Net.BitMessage.Types.pas',
  DelphiDoom.Net.BitMessage.Intf in '..\Libs\Net\DelphiDoom.Net.BitMessage.Intf.pas',
  DelphiDoom.Net.BitMessage in '..\Libs\Net\DelphiDoom.Net.BitMessage.pas',
  DelphiDoom.Net.BitMessageDelta in '..\Libs\Net\DelphiDoom.Net.BitMessageDelta.pas',
  DelphiDoom.Net.Q3.Types in '..\IdTech4\NetQ3\DelphiDoom.Net.Q3.Types.pas',
  DelphiDoom.Net.Q3.Intf in '..\IdTech4\NetQ3\DelphiDoom.Net.Q3.Intf.pas',
  DelphiDoom.Net.Q3.AdaptiveHuffman in '..\IdTech4\NetQ3\DelphiDoom.Net.Q3.AdaptiveHuffman.pas',
  DelphiDoom.Net.Q3.MessageHuffman in '..\IdTech4\NetQ3\DelphiDoom.Net.Q3.MessageHuffman.pas',
  DelphiDoom.Net.Q3.Message in '..\IdTech4\NetQ3\DelphiDoom.Net.Q3.Message.pas',
  DelphiDoom.Net.Q3.HuffmanCompressor in '..\IdTech4\NetQ3\DelphiDoom.Net.Q3.HuffmanCompressor.pas',
  DelphiDoom.Net.Q3.NetFieldTable in '..\IdTech4\NetQ3\DelphiDoom.Net.Q3.NetFieldTable.pas',
  DelphiDoom.Net.Q3.UserCmdCodec in '..\IdTech4\NetQ3\DelphiDoom.Net.Q3.UserCmdCodec.pas',
  DelphiDoom.Net.Q3.EntityStateCodec in '..\IdTech4\NetQ3\DelphiDoom.Net.Q3.EntityStateCodec.pas',
  DelphiDoom.Net.Q3.PlayerStateCodec in '..\IdTech4\NetQ3\DelphiDoom.Net.Q3.PlayerStateCodec.pas',
  DelphiDoom.Net.Q3.Netchan in '..\IdTech4\NetQ3\DelphiDoom.Net.Q3.Netchan.pas',
  DelphiDoom.Net.Q3.InfoString in '..\IdTech4\NetQ3\DelphiDoom.Net.Q3.InfoString.pas',
  DelphiDoom.Net.Q3.ServerMessage.Intf in '..\IdTech4\NetQ3\DelphiDoom.Net.Q3.ServerMessage.Intf.pas',
  DelphiDoom.Net.Q3.ServerMessageParser in '..\IdTech4\NetQ3\DelphiDoom.Net.Q3.ServerMessageParser.pas',
  DelphiDoom.Net.Q3.DemoReader in '..\IdTech4\NetQ3\DelphiDoom.Net.Q3.DemoReader.pas',
  DelphiDoom.Net.Q3.Factory in '..\IdTech4\NetQ3\DelphiDoom.Net.Q3.Factory.pas',
  DelphiDoom.Tests.Net.Q3Fakes in 'Source\DelphiDoom.Tests.Net.Q3Fakes.pas',
  DelphiDoom.Tests.Net.Q3Parity in 'Source\DelphiDoom.Tests.Net.Q3Parity.pas',
  DelphiDoom.Tests.Net.Q3 in 'Source\DelphiDoom.Tests.Net.Q3.pas',
  DelphiDoom.Tests.Net.Q3.InfoString in 'Source\DelphiDoom.Tests.Net.Q3.InfoString.pas',
  DelphiDoom.Tests.Net.Q3.ServerMessageParser in 'Source\DelphiDoom.Tests.Net.Q3.ServerMessageParser.pas',
  DelphiDoom.Tests.Net.Q3.DemoReader in 'Source\DelphiDoom.Tests.Net.Q3.DemoReader.pas',
  DelphiDoom.Tests.Net.BitMessage in 'Source\DelphiDoom.Tests.Net.BitMessage.pas',
  DelphiDoom.Tests.Net.BitMessageParity in 'Source\DelphiDoom.Tests.Net.BitMessageParity.pas',
  DelphiDoom.Tests.Net.Fakes in 'Source\DelphiDoom.Tests.Net.Fakes.pas',
  DelphiDoom.Tests.Net.PacketCodec in 'Source\DelphiDoom.Tests.Net.PacketCodec.pas',
  DelphiDoom.Tests.Net.TicSync in 'Source\DelphiDoom.Tests.Net.TicSync.pas',
  DelphiDoom.Tests.Net.TicPlanner in 'Source\DelphiDoom.Tests.Net.TicPlanner.pas',
  DelphiDoom.Tests.Net.ConsistencyTracker in 'Source\DelphiDoom.Tests.Net.ConsistencyTracker.pas',
  DelphiDoom.Tests.Net.StartArbiter in 'Source\DelphiDoom.Tests.Net.StartArbiter.pas',
  DelphiDoom.Tests.Net.NodeListParser in 'Source\DelphiDoom.Tests.Net.NodeListParser.pas',
  DelphiDoom.Tests.Net.WinsockTransport in 'Source\DelphiDoom.Tests.Net.WinsockTransport.pas';

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
