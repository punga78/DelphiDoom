{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom strategy library - the default options of OpenXcom         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomStrategy.DefaultSettings;

interface

uses
  DelphiDoom.XcomStrategy.Settings.Intf;

type
  /// <summary>The values of Options.cpp: no aggressive retaliation, no storage limits, monthly psi training, autosave on</summary>
  TXcomDefaultStrategySettings = class(TInterfacedObject, IXcomStrategySettings)
  public
    function AggressiveRetaliation: Boolean;
    function StorageLimitsEnforced: Boolean;
    function AnytimePsiTraining: Boolean;
    function Autosave: Boolean;
  end;

implementation

{ TXcomDefaultStrategySettings }

function TXcomDefaultStrategySettings.AggressiveRetaliation: Boolean;
begin
  Result := False;
end;

function TXcomDefaultStrategySettings.StorageLimitsEnforced: Boolean;
begin
  Result := False;
end;

function TXcomDefaultStrategySettings.AnytimePsiTraining: Boolean;
begin
  Result := False;
end;

function TXcomDefaultStrategySettings.Autosave: Boolean;
begin
  Result := True;
end;

end.
