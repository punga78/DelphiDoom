{******************************************************************************}
{                                                                              }
{  DelphiDoom: IWAD library - the folders named by environment variables        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Iwad.EnvironmentDirectories;

interface

uses
  DelphiDoom.Iwad.Intf;

type
  /// <summary>
  ///   The folders that variables like DOOMWADDIR name, in the order of the variables; none
  ///   when the player switched this search off
  /// </summary>
  TIwadEnvironmentDirectories = class(TInterfacedObject, IIwadSearchPath)
  strict private
    FEnvironment: IIwadEnvironment;
    FOptions: IIwadOptions;
    FVariables: TArray<string>;
  public
    constructor Create(const AEnvironment: IIwadEnvironment; const AOptions: IIwadOptions;
      const AVariables: TArray<string>);
    function GetDirectories: TArray<string>;
  end;

implementation

uses
  System.SysUtils;

{ TIwadEnvironmentDirectories }

constructor TIwadEnvironmentDirectories.Create(const AEnvironment: IIwadEnvironment;
  const AOptions: IIwadOptions; const AVariables: TArray<string>);
begin
  inherited Create;
  if not Assigned(AEnvironment) then
    raise EArgumentNilException.Create('AEnvironment');
  if not Assigned(AOptions) then
    raise EArgumentNilException.Create('AOptions');
  FEnvironment := AEnvironment;
  FOptions := AOptions;
  FVariables := AVariables;
end;

function TIwadEnvironmentDirectories.GetDirectories: TArray<string>;
var
  LVariable: string;
  LValue: string;
  LCount: Integer;
begin
  SetLength(Result, 0);
  if not FOptions.SearchWadDirectory then
    Exit;
  LCount := 0;
  for LVariable in FVariables do
  begin
    LValue := FEnvironment.GetValue(LVariable);
    if LValue <> '' then
    begin
      SetLength(Result, LCount + 1);
      Result[LCount] := LValue;
      Inc(LCount);
    end;
  end;
end;

end.
