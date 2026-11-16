{******************************************************************************}
{                                                                              }
{  DelphiDoom: IWAD library - the lists of folders in environment variables     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Iwad.EnvironmentPathLists;

interface

uses
  DelphiDoom.Iwad.Intf;

type
  /// <summary>
  ///   The folders of variables like DOOMWADPATH (folders separated by ';'), in the order of
  ///   the variables; none when the player switched this search off
  /// </summary>
  TIwadEnvironmentPathLists = class(TInterfacedObject, IIwadSearchPath)
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
  System.SysUtils, DelphiDoom.Iwad.PathList;

{ TIwadEnvironmentPathLists }

constructor TIwadEnvironmentPathLists.Create(const AEnvironment: IIwadEnvironment;
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

function TIwadEnvironmentPathLists.GetDirectories: TArray<string>;
var
  LVariable: string;
  LFolder: string;
  LCount: Integer;
begin
  SetLength(Result, 0);
  if not FOptions.SearchWadPath then
    Exit;
  LCount := 0;
  for LVariable in FVariables do
  begin
    for LFolder in TIwadPathList.Split(FEnvironment.GetValue(LVariable)) do
    begin
      SetLength(Result, LCount + 1);
      Result[LCount] := LFolder;
      Inc(LCount);
    end;
  end;
end;

end.
