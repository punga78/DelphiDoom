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
  DelphiDoom.Console.Intf;

type
  /// <summary>
  ///   Every row of defaults that is not a group, in the order of the table; a name is found as
  ///   the old loop found it: the first row with that name
  /// </summary>
  TEngineConsoleVariableSource = class(TInterfacedObject, IConsoleVariableSource)
  private
    FVariables: TList<IConsoleVariable>;
  public
    constructor Create;
    destructor Destroy; override;
    function Count: Integer;
    function Item(AIndex: Integer): IConsoleVariable;
    function Find(const AName: string): IConsoleVariable;
  end;

implementation

uses
  m_defs,
  DelphiDoom.Engine.Console.Variable;

{ TEngineConsoleVariableSource }

constructor TEngineConsoleVariableSource.Create;
var
  LIndex: Integer;
begin
  inherited Create;
  FVariables := TList<IConsoleVariable>.Create;
  for LIndex := 0 to NUMDEFAULTS - 1 do
    if defaults[LIndex]._type <> m_defs.tGroup then
      FVariables.Add(TEngineConsoleVariable.Create(@defaults[LIndex]));
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
