{******************************************************************************}
{                                                                              }
{  DelphiDoom: actions library - the only place that knows the classes         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Actions.Factory;

interface

uses
  DelphiDoom.Actions.Intf;

type
  /// <summary>Creates the registry of the actions</summary>
  TActionsFactory = class
  public
    /// <summary>An empty registry</summary>
    class function CreateRegistry: IActionRegistry; static;
  end;

implementation

uses
  DelphiDoom.Actions.Registry;

{ TActionsFactory }

class function TActionsFactory.CreateRegistry: IActionRegistry;
begin
  Result := TActionRegistry.Create;
end;

end.
