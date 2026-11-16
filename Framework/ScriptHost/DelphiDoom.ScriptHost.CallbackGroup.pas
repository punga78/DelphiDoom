{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - a group that describes itself with a procedure    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.CallbackGroup;

interface

uses
  DelphiDoom.ScriptHost.Intf;

type
  /// <summary>A procedure that writes the functions of a unit of script</summary>
  TScriptDescribeProcedure = reference to procedure(const ATable: IScriptFunctionTable);

  /// <summary>
  ///   The unit of script of a group that is not yet a class (PS_GAME, PS_OVERLAY): its functions
  ///   are written by a procedure
  /// </summary>
  TScriptCallbackGroup = class(TInterfacedObject, IScriptFunctionGroup)
  strict private
    FUnitName: string;
    FDescribe: TScriptDescribeProcedure;
  public
    /// <exception cref="EArgumentNilException">If the procedure is nil</exception>
    constructor Create(const AUnitName: string; const ADescribe: TScriptDescribeProcedure);
    function UnitName: string;
    procedure Describe(const ATable: IScriptFunctionTable);
  end;

implementation

uses
  System.SysUtils;

{ TScriptCallbackGroup }

constructor TScriptCallbackGroup.Create(const AUnitName: string;
  const ADescribe: TScriptDescribeProcedure);
begin
  inherited Create;
  if not Assigned(ADescribe) then
    raise EArgumentNilException.Create('ADescribe');
  FUnitName := AUnitName;
  FDescribe := ADescribe;
end;

function TScriptCallbackGroup.UnitName: string;
begin
  Result := FUnitName;
end;

procedure TScriptCallbackGroup.Describe(const ATable: IScriptFunctionTable);
begin
  FDescribe(ATable);
end;

end.
