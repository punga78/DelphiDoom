{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine system library - the shutdown of the engine              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.EngineSystem.ShutdownSequence;

// The order of I_Destroy of i_system.pas (issue #185). What each step does is the plan's: the
// sequence knows nothing of the sound, the video or the network, so that what fails first cannot
// depend on what comes after.

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.EngineSystem.Types,
  DelphiDoom.EngineSystem.Intf;

type
  /// <summary>
  ///   Writes that the game is finished, runs the steps of the plan in order (each one announced
  ///   to the log before it runs) and ends the process. An exception of a step goes up to the caller:
  ///   the process is not ended, as before
  /// </summary>
  TShutdownSequence = class(TInterfacedObject, IShutdownSequence)
  strict private
    FPlan: IShutdownPlan;
    FLog: ILog;
    FTerminate: TProc<Integer>;
    FIsFinished: Boolean;
  public
    /// <summary>
    ///   ATerminate ends the process (Halt in the engine);
    ///   EArgumentNilException if one of the three is nil
    /// </summary>
    constructor Create(const APlan: IShutdownPlan; const ALog: ILog;
      const ATerminate: TProc<Integer>);
    function IsFinished: Boolean;
    procedure Run(ACode: Integer);
  end;

implementation

{ TShutdownSequence }

constructor TShutdownSequence.Create(const APlan: IShutdownPlan; const ALog: ILog;
  const ATerminate: TProc<Integer>);
begin
  inherited Create;
  if not Assigned(APlan) then
    raise EArgumentNilException.CreateFmt(SNullPointerArgument, ['APlan']);
  if not Assigned(ALog) then
    raise EArgumentNilException.CreateFmt(SNullPointerArgument, ['ALog']);
  if not Assigned(ATerminate) then
    raise EArgumentNilException.CreateFmt(SNullPointerArgument, ['ATerminate']);
  FPlan := APlan;
  FLog := ALog;
  FTerminate := ATerminate;
end;

function TShutdownSequence.IsFinished: Boolean;
begin
  Result := FIsFinished;
end;

procedure TShutdownSequence.Run(ACode: Integer);
var
  LStep: TShutdownStep;
begin
  FLog.Info(SGameFinished);
  FIsFinished := True;
  for LStep in FPlan.Steps(ACode) do
  begin
    FLog.Info(LStep.Announcement);
    if Assigned(LStep.Action) then
      LStep.Action();
  end;
  FTerminate(ACode);
end;

end.
