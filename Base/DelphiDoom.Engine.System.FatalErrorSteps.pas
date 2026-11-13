{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the steps of a fatal error                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.System.FatalErrorSteps;

// What I_Error of i_system.pas did (issue #185), one step at a time. The handler of
// Libs\EngineSystem gives the order; the state of "an error is being handled" stays the variable in_i_error
// of i_system, which r_data reads while the engine shuts down.

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.EngineSystem.Intf;

type
  /// <summary>The steps of I_Error on the globals and the units of the engine</summary>
  TEngineFatalErrorSteps = class(TInterfacedObject, IFatalErrorSteps)
  strict private
    FLog: ILog;
  public
    /// <summary>ALog shows the error (the error file, the message box and the output); EArgumentNilException if nil</summary>
    constructor Create(const ALog: ILog);
    function IsFailing: Boolean;
    procedure FlashOutput;
    procedure MarkFailing;
    procedure FinishDemo;
    procedure Report(const AMessage: string);
    procedure Terminate;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.EngineSystem.Types,
  i_system,
  i_io,
  i_startup,
{$IFDEF HEXEN}
  g_demo,
{$ENDIF}
  g_game;

{ TEngineFatalErrorSteps }

constructor TEngineFatalErrorSteps.Create(const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ALog) then
    raise EArgumentNilException.CreateFmt(SNullPointerArgument, ['ALog']);
  FLog := ALog;
end;

function TEngineFatalErrorSteps.IsFailing: Boolean;
begin
  Result := in_i_error;
end;

procedure TEngineFatalErrorSteps.FlashOutput;
begin
  I_FlashCachedOutput;
end;

procedure TEngineFatalErrorSteps.MarkFailing;
begin
  in_i_error := True;
end;

procedure TEngineFatalErrorSteps.FinishDemo;
begin
  if demorecording then
    G_CheckDemoStatus;
end;

procedure TEngineFatalErrorSteps.Report(const AMessage: string);
begin
  I_IOSetWindowHandle(SUC_GetHandle);
  // the error file, the message box and the output
  FLog.Error(AMessage);
end;

procedure TEngineFatalErrorSteps.Terminate;
begin
  I_Destroy(1);
end;

end.
