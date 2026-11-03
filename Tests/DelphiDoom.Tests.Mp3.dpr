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
  d_delphi in '..\Libs\Mp3\Shim\d_delphi.pas',
  i_system in '..\Libs\Mp3\Shim\i_system.pas',
  mp3_Shared in '..\MP3LIB\mp3_Shared.pas',
  mp3_CRC in '..\MP3LIB\mp3_CRC.pas',
  mp3_BitReserve in '..\MP3LIB\mp3_BitReserve.pas',
  mp3_BitStream in '..\MP3LIB\mp3_BitStream.pas',
  mp3_Header in '..\MP3LIB\mp3_Header.pas',
  mp3_OBuffer in '..\MP3LIB\mp3_OBuffer.pas',
  mp3_SynthFilter in '..\MP3LIB\mp3_SynthFilter.pas',
  mp3_L3Type in '..\MP3LIB\mp3_L3Type.pas',
  mp3_L3Tables in '..\MP3LIB\mp3_L3Tables.pas',
  mp3_Huffman in '..\MP3LIB\mp3_Huffman.pas',
  mp3_InvMDT in '..\MP3LIB\mp3_InvMDT.pas',
  mp3_Layer3 in '..\MP3LIB\mp3_Layer3.pas',
  DelphiDoom.Mp3.Intf in '..\Libs\Mp3\DelphiDoom.Mp3.Intf.pas',
  DelphiDoom.Mp3.Stream in '..\Libs\Mp3\DelphiDoom.Mp3.Stream.pas',
  DelphiDoom.Mp3.FrameLocator in '..\Libs\Mp3\DelphiDoom.Mp3.FrameLocator.pas',
  DelphiDoom.Mp3.PcmBuffer in '..\Libs\Mp3\DelphiDoom.Mp3.PcmBuffer.pas',
  DelphiDoom.Mp3.Native in '..\Libs\Mp3\DelphiDoom.Mp3.Native.pas',
  DelphiDoom.Mp3.Decoder in '..\Libs\Mp3\DelphiDoom.Mp3.Decoder.pas',
  DelphiDoom.Mp3.Engine in '..\Libs\Mp3\DelphiDoom.Mp3.Engine.pas',
  DelphiDoom.Mp3.Client in '..\Libs\Mp3\DelphiDoom.Mp3.Client.pas',
  DelphiDoom.Mp3.Loader in '..\Libs\Mp3\DelphiDoom.Mp3.Loader.pas',
  DelphiDoom.Tests.Mp3.Samples in 'Source\DelphiDoom.Tests.Mp3.Samples.pas',
  DelphiDoom.Tests.Mp3.Engine in 'Source\DelphiDoom.Tests.Mp3.Engine.pas',
  DelphiDoom.Tests.Mp3.Client in 'Source\DelphiDoom.Tests.Mp3.Client.pas',
  DelphiDoom.Tests.Mp3.Loader in 'Source\DelphiDoom.Tests.Mp3.Loader.pas';

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
