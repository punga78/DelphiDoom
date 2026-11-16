{******************************************************************************}
{                                                                              }
{  DelphiDoom: dynamic lights library - the registry of the lights            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DynLights.Registry;

interface

uses
  System.Generics.Collections, DelphiDoom.DynLights.Types, DelphiDoom.DynLights.Intf;

type
  /// <summary>
  ///   The lights that were read, by index and by name (the old R_AddDynamicLight and
  ///   R_FindDynamicLight). A name is cut to 32 characters when the light is added, but a name
  ///   that is looked for is not: a longer name is never found, as in the old code
  /// </summary>
  TDynLightRegistry = class(TInterfacedObject, IDynLightRegistry)
  private
    FLights: TList<TDynLightDefinition>;
  public
    constructor Create;
    destructor Destroy; override;
    function Add(const ADefinition: TDynLightDefinition): Integer;
    function Find(const AName: string): Integer;
    function Count: Integer;
    function Get(AIndex: Integer): TDynLightDefinition;
    procedure Clear;
  end;

implementation

uses
  DelphiDoom.Scanner.Strings;

{ TDynLightRegistry }

constructor TDynLightRegistry.Create;
begin
  inherited Create;
  FLights := TList<TDynLightDefinition>.Create;
end;

destructor TDynLightRegistry.Destroy;
begin
  FLights.Free;
  inherited Destroy;
end;

function TDynLightRegistry.Add(const ADefinition: TDynLightDefinition): Integer;
var
  LDefinition: TDynLightDefinition;
begin
  LDefinition := ADefinition;
  LDefinition.Name := Copy(TScannerStrings.UpperAscii(LDefinition.Name), 1, DYNLIGHT_NAME_LENGTH);
  Result := FLights.Add(LDefinition);
end;

function TDynLightRegistry.Find(const AName: string): Integer;
var
  LName: string;
  LIndex: Integer;
begin
  LName := TScannerStrings.UpperAscii(AName);
  for LIndex := FLights.Count - 1 downto 0 do
    if FLights[LIndex].Name = LName then
      Exit(LIndex);
  Result := -1;
end;

function TDynLightRegistry.Count: Integer;
begin
  Result := FLights.Count;
end;

function TDynLightRegistry.Get(AIndex: Integer): TDynLightDefinition;
begin
  Result := FLights[AIndex];
end;

procedure TDynLightRegistry.Clear;
begin
  FLights.Clear;
end;

end.
