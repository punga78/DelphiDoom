{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Mp3 library (DUnitX)                                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
program DelphiDoom.Tests.Mp3;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  mp3_Shared in '..\Framework\Mp3\Decoder\mp3_Shared.pas',
  mp3_CRC in '..\Framework\Mp3\Decoder\mp3_CRC.pas',
  mp3_BitReserve in '..\Framework\Mp3\Decoder\mp3_BitReserve.pas',
  mp3_Source in '..\Framework\Mp3\Decoder\mp3_Source.pas',
  mp3_BitStream in '..\Framework\Mp3\Decoder\mp3_BitStream.pas',
  mp3_Header in '..\Framework\Mp3\Decoder\mp3_Header.pas',
  mp3_OBuffer in '..\Framework\Mp3\Decoder\mp3_OBuffer.pas',
  mp3_SynthFilter in '..\Framework\Mp3\Decoder\mp3_SynthFilter.pas',
  mp3_L3Type in '..\Framework\Mp3\Decoder\mp3_L3Type.pas',
  mp3_L3Tables in '..\Framework\Mp3\Decoder\mp3_L3Tables.pas',
  mp3_Huffman in '..\Framework\Mp3\Decoder\mp3_Huffman.pas',
  mp3_InvMDT in '..\Framework\Mp3\Decoder\mp3_InvMDT.pas',
  mp3_Layer3 in '..\Framework\Mp3\Decoder\mp3_Layer3.pas',
  DelphiDoom.Mp3.Intf in '..\Framework\Mp3\DelphiDoom.Mp3.Intf.pas',
  DelphiDoom.Mp3.Stream in '..\Framework\Mp3\DelphiDoom.Mp3.Stream.pas',
  DelphiDoom.Mp3.FrameLocator in '..\Framework\Mp3\DelphiDoom.Mp3.FrameLocator.pas',
  DelphiDoom.Mp3.PcmBuffer in '..\Framework\Mp3\DelphiDoom.Mp3.PcmBuffer.pas',
  DelphiDoom.Mp3.Native in '..\Framework\Mp3\DelphiDoom.Mp3.Native.pas',
  DelphiDoom.Mp3.Decoder in '..\Framework\Mp3\DelphiDoom.Mp3.Decoder.pas',
  DelphiDoom.Mp3.Engine in '..\Framework\Mp3\DelphiDoom.Mp3.Engine.pas',
  DelphiDoom.Mp3.Client in '..\Framework\Mp3\DelphiDoom.Mp3.Client.pas',
  DelphiDoom.Mp3.Loader in '..\Framework\Mp3\DelphiDoom.Mp3.Loader.pas',
  DelphiDoom.Mp3.Provider in '..\Framework\Mp3\DelphiDoom.Mp3.Provider.pas',
  DelphiDoom.Tests.Mp3.Samples in 'Source\DelphiDoom.Tests.Mp3.Samples.pas',
  DelphiDoom.Tests.Mp3.Engine in 'Source\DelphiDoom.Tests.Mp3.Engine.pas',
  DelphiDoom.Tests.Mp3.Client in 'Source\DelphiDoom.Tests.Mp3.Client.pas',
  DelphiDoom.Tests.Mp3.Loader in 'Source\DelphiDoom.Tests.Mp3.Loader.pas',
  DelphiDoom.Tests.Mp3.Provider in 'Source\DelphiDoom.Tests.Mp3.Provider.pas',
  DelphiDoom.Tests.Mp3.RandomFrames in 'Source\DelphiDoom.Tests.Mp3.RandomFrames.pas',
  DelphiDoom.Tests.Mp3.Stream in 'Source\DelphiDoom.Tests.Mp3.Stream.pas',
  DelphiDoom.Tests.Mp3.PcmBuffer in 'Source\DelphiDoom.Tests.Mp3.PcmBuffer.pas',
  DelphiDoom.Tests.Mp3.Errors in 'Source\DelphiDoom.Tests.Mp3.Errors.pas';

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
