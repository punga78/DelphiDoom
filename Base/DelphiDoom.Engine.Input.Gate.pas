{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - when the game listens to the input                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Input.Gate;

interface

uses
  DelphiDoom.Input.Intf;

type
  /// <summary>Not when the game is over, in the background, minimized or not in the foreground</summary>
  TEngineInputGate = class(TInterfacedObject, IInputGate)
  public
    function IsInputAllowed: Boolean;
  end;

implementation

uses
  Windows,
  i_mainwindow,
  i_system;

{ TEngineInputGate }

function TEngineInputGate.IsInputAllowed: Boolean;
begin
  Result := not (I_GameFinished or InBackground or IsIconic(hMainWnd) or
    (GetForegroundWindow <> hMainWnd));
end;

end.
