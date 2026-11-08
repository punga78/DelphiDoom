{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - I_Error and I_Quit for the classes of the engine       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Shutdown;

interface

uses
  DelphiDoom.Engine.Shutdown.Intf;

type
  /// <summary>
  ///   The facade of i_system behind IEngineShutdown: I_Error stays the one place where the
  ///   game stops (it flushes the output, closes the demo and runs I_Destroy), the classes
  ///   only know the interface
  /// </summary>
  TEngineShutdown = class(TInterfacedObject, IEngineShutdown)
  public
    procedure Fail(const AText: string);
    procedure Quit;
  end;

implementation

uses
  i_system;

{ TEngineShutdown }

procedure TEngineShutdown.Fail(const AText: string);
begin
  I_Error('%s', [AText]);
end;

procedure TEngineShutdown.Quit;
begin
  I_Quit;
end;

end.
