{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine system library - the fatal errors                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.EngineSystem.FatalErrorHandler;

// The order of I_Error of i_system.pas (issue #185). It depends on nothing but the steps that it is
// given: the code that handles an error cannot depend on what went wrong.

interface

uses
  System.SysUtils, DelphiDoom.EngineSystem.Types, DelphiDoom.EngineSystem.Intf;

type
  /// <summary>
  ///   Saves the output, closes the demo, shows the error and shuts the engine down with the code 1.
  ///   An error that happens while the engine handles an error is ignored (the guard of the old code)
  /// </summary>
  TFatalErrorHandler = class(TInterfacedObject, IFatalErrorHandler)
  strict private
    FSteps: IFatalErrorSteps;
  public
    /// <summary>EArgumentNilException if ASteps is nil</summary>
    constructor Create(const ASteps: IFatalErrorSteps);
    procedure Handle(const AMessage: string);
  end;

implementation

{ TFatalErrorHandler }

constructor TFatalErrorHandler.Create(const ASteps: IFatalErrorSteps);
begin
  inherited Create;
  if not Assigned(ASteps) then
    raise EArgumentNilException.CreateFmt(SNullPointerArgument, ['ASteps']);
  FSteps := ASteps;
end;

procedure TFatalErrorHandler.Handle(const AMessage: string);
begin
  // avoid recursive calls
  if not FSteps.IsFailing then
  begin
    FSteps.FlashOutput;
    FSteps.MarkFailing;
    // shut down: here might be other errors
    FSteps.FinishDemo;
    FSteps.Report(AMessage);
    FSteps.Terminate;
  end;
end;

end.
