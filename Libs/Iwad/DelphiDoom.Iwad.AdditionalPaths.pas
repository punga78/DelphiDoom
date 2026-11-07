{******************************************************************************}
{                                                                              }
{  DelphiDoom: IWAD library - the folders that the player added                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Iwad.AdditionalPaths;

interface

uses
  DelphiDoom.Iwad.Intf;

type
  /// <summary>The folders of the option additionalwadpaths (separated by ';'); always searched</summary>
  TIwadAdditionalPaths = class(TInterfacedObject, IIwadSearchPath)
  strict private
    FOptions: IIwadOptions;
  public
    constructor Create(const AOptions: IIwadOptions);
    function GetDirectories: TArray<string>;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Iwad.PathList;

{ TIwadAdditionalPaths }

constructor TIwadAdditionalPaths.Create(const AOptions: IIwadOptions);
begin
  inherited Create;
  if not Assigned(AOptions) then
    raise EArgumentNilException.Create('AOptions');
  FOptions := AOptions;
end;

function TIwadAdditionalPaths.GetDirectories: TArray<string>;
begin
  Result := TIwadPathList.Split(FOptions.AdditionalPaths);
end;

end.
