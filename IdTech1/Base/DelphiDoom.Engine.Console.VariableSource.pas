{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the variables of the console: the table defaults        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Console.VariableSource;

{$I Doom32.inc}

interface

uses
  System.Generics.Collections,
  DelphiDoom.Configuration.Intf,
  DelphiDoom.Console.Intf;

type
  /// <summary>
  ///   Every row of the table of the options that is not a group, in the order of the table; a
  ///   name is found as the old loop found it: the first row with that name
  /// </summary>
  TEngineConsoleVariableSource = class(TInterfacedObject, IConsoleVariableSource)
  strict private
    FVariables: TList<IConsoleVariable>;
  public
    /// <remarks>Raises EArgumentNilException if ATable is nil</remarks>
    constructor Create(const ATable: IConfigurationTable);
    destructor Destroy; override;
    function Count: Integer;
    function Item(AIndex: Integer): IConsoleVariable;
    function Find(const AName: string): IConsoleVariable;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Configuration.Types,
  DelphiDoom.Engine.Console.Variable;

const
  STableIsNil = 'TEngineConsoleVariableSource: the table is nil';

{ TEngineConsoleVariableSource }

constructor TEngineConsoleVariableSource.Create(const ATable: IConfigurationTable);
var
  LIndex: Integer;
begin
  inherited Create;
  if not Assigned(ATable) then
    raise EArgumentNilException.Create(STableIsNil);
  FVariables := TList<IConsoleVariable>.Create;
  for LIndex := 0 to ATable.Count - 1 do
    if ATable.Item(LIndex).Kind <> cikGroup then
      FVariables.Add(TEngineConsoleVariable.Create(ATable.Item(LIndex)));
end;

destructor TEngineConsoleVariableSource.Destroy;
begin
  FVariables.Free;
  inherited Destroy;
end;

function TEngineConsoleVariableSource.Count: Integer;
begin
  Result := FVariables.Count;
end;

function TEngineConsoleVariableSource.Item(AIndex: Integer): IConsoleVariable;
begin
  Result := FVariables[AIndex];
end;

function TEngineConsoleVariableSource.Find(const AName: string): IConsoleVariable;
var
  LVariable: IConsoleVariable;
begin
  for LVariable in FVariables do
    if LVariable.Name = AName then
      Exit(LVariable);
  Result := nil;
end;

end.
