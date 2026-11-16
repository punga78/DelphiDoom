{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - the commands run at the start                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.AutoExec;

interface

uses
  DelphiDoom.Console.Intf;

type
  /// <summary>
  ///   What the console runs the first time it receives an event (old C_RunAutoExec): the
  ///   autoexec file (created with two lines of comment if the game never made it), the
  ///   AUTOEXEC lumps, and the file given with "-con"
  /// </summary>
  TConsoleAutoExec = class
  private
    FStartup: IConsoleStartupSource;
    FRunner: IConsoleScriptRunner;
    FOutput: IConsoleOutput;
    FApplicationTitle: string;
  public
    constructor Create(const AStartup: IConsoleStartupSource; const ARunner: IConsoleScriptRunner;
      const AOutput: IConsoleOutput; const AApplicationTitle: string);
    procedure Run;
  end;

implementation

uses
  System.SysUtils;

const
  LINE_BREAK = #13#10;

{ TConsoleAutoExec }

constructor TConsoleAutoExec.Create(const AStartup: IConsoleStartupSource;
  const ARunner: IConsoleScriptRunner; const AOutput: IConsoleOutput;
  const AApplicationTitle: string);
begin
  inherited Create;
  if not Assigned(AStartup) then
    raise EArgumentNilException.Create('AStartup');
  if not Assigned(ARunner) then
    raise EArgumentNilException.Create('ARunner');
  if not Assigned(AOutput) then
    raise EArgumentNilException.Create('AOutput');
  FStartup := AStartup;
  FRunner := ARunner;
  FOutput := AOutput;
  FApplicationTitle := AApplicationTitle;
end;

procedure TConsoleAutoExec.Run;
var
  LText: string;
  LFileName: string;
begin
  FOutput.Write('C_RunAutoExec()' + LINE_BREAK);
  if not FStartup.DefaultAutoExecExists then
    FStartup.CreateDefaultAutoExec(TArray<string>.Create(
      '// Add autoexec console commands in this file.',
      '// These console commands will be executed everytime you start ' + FApplicationTitle));

  FRunner.RunFile(FStartup.AutoExecFileName);
  for LText in FStartup.AutoExecLumpTexts do
    FRunner.RunText(LText);
  LFileName := FStartup.CommandLineFileName;
  if LFileName <> '' then
    FRunner.RunFile(LFileName);
end;

end.
