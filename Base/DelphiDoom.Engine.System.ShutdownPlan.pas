{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the steps of the shutdown                              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.System.ShutdownPlan;

// The steps of I_Destroy of i_system.pas (issue #185) as the engine takes them: what each step calls
// is a function of the engine, so this is the unit that knows the sound, the video, the network and
// the files. The order and the text are the ones of the old procedure; the sequence (Libs\EngineSystem)
// writes them and runs them.

interface

uses
  DelphiDoom.CommandLine.Intf, DelphiDoom.Input.Intf, DelphiDoom.Engine.Net.Intf,
  DelphiDoom.Engine.Configuration.Intf, DelphiDoom.EngineSystem.Types,
  DelphiDoom.EngineSystem.Intf;

type
  /// <summary>The steps from the network game to the files, for a program that stops with a code</summary>
  TEngineShutdownPlan = class(TInterfacedObject, IShutdownPlan)
  strict private
    FNetGame: IEngineNetGame;
    FDefaults: IEngineDefaults;
    FInput: IInputPoller;
    FCommandLine: ICommandLine;
  public
    /// <summary>
    ///   Any of them can be nil but the command line: the old code skipped what the composition
    ///   had not given. EArgumentNilException if ACommandLine is nil
    /// </summary>
    constructor Create(const ANetGame: IEngineNetGame; const ADefaults: IEngineDefaults;
      const AInput: IInputPoller; const ACommandLine: ICommandLine);
    function Steps(ACode: Integer): TArray<TShutdownStep>;
  end;

implementation

uses
  System.SysUtils,
  Windows,
  s_sound,
  i_io,
  i_tmp,
{$IFDEF OPENGL}
  gl_main,
{$ELSE}
  i_video,
{$ENDIF}
  d_main;

{ TEngineShutdownPlan }

constructor TEngineShutdownPlan.Create(const ANetGame: IEngineNetGame;
  const ADefaults: IEngineDefaults; const AInput: IInputPoller; const ACommandLine: ICommandLine);
begin
  inherited Create;
  if not Assigned(ACommandLine) then
    raise EArgumentNilException.CreateFmt(SNullPointerArgument, ['ACommandLine']);
  FNetGame := ANetGame;
  FDefaults := ADefaults;
  FInput := AInput;
  FCommandLine := ACommandLine;
end;

function TEngineShutdownPlan.Steps(ACode: Integer): TArray<TShutdownStep>;
var
  LSteps: TArray<TShutdownStep>;

  procedure Add(const AAnnouncement: string; const AAction: TProc);
  begin
    SetLength(LSteps, Length(LSteps) + 1);
    LSteps[High(LSteps)] := TShutdownStep.Make(AAnnouncement, AAction);
  end;

begin
  Add('D_QuitNetGame: Quit network game.'#13#10,
    procedure
    begin
      if FNetGame <> nil then
        FNetGame.Quit;
    end);
  Add('I_ShutDownSound: Shut down sound.'#13#10,
    procedure
    begin
      S_ShutDownSoundDevice;
    end);
  Add('I_ShutDownMusic: Shut down music.'#13#10,
    procedure
    begin
      S_ShutDownMusicDevice;
    end);
  Add('I_ShutDownInput: Shut down input.'#13#10,
    procedure
    begin
      if FInput <> nil then
        FInput.Shutdown;
    end);
  if FCommandLine.IndexOf('-dontsavedefaults') = 0 then
    Add('M_SaveDefaults: Saving defaults.'#13#10,
      procedure
      begin
        if FDefaults <> nil then
          FDefaults.Save;
      end);
  Add('I_ShutDownGraphics: Shut down graphics.'#13#10,
    procedure
    begin
      I_ShutDownGraphics;
    end);
  Add('D_ShutDown: Shut down doom engine.'#13#10,
    procedure
    begin
      D_ShutDown;
    end);
  Add('I_ShutDownNetwork: Shut down network.'#13#10,
    procedure
    begin
      if FNetGame <> nil then
        FNetGame.Shutdown;
    end);
  Add('I_RestoreDesktop: Restoring desktop.'#13#10,
    procedure
    begin
      InvalidateRect(0, nil, True);
    end);
  Add('I_ShutDownTempFiles: Shut down temporary file managment.'#13#10,
    procedure
    begin
      I_ShutDownTempFiles;
    end);
  Add(Format('I_ShutDownIO: Shut down input/output.'#13#10'Halt(%d)'#13#10, [ACode]),
    procedure
    begin
      I_ShutDownIO;
    end);
  Result := LSteps;
end;

end.
