{******************************************************************************}
{                                                                              }
{  DelphiDoom: IWAD library - the folders of the Steam applications             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Iwad.SteamPaths;

interface

uses
  DelphiDoom.Iwad.Intf;

type
  /// <summary>
  ///   For each installed application the folder, its base subfolder and base\wads; none when
  ///   the player switched this search off
  /// </summary>
  TIwadSteamPaths = class(TInterfacedObject, IIwadSearchPath)
  strict private
    FSteam: IIwadSteam;
    FOptions: IIwadOptions;
    FApplications: TArray<Integer>;
  public
    constructor Create(const ASteam: IIwadSteam; const AOptions: IIwadOptions;
      const AApplications: TArray<Integer>);
    function GetDirectories: TArray<string>;
  end;

implementation

uses
  System.SysUtils;

{ TIwadSteamPaths }

constructor TIwadSteamPaths.Create(const ASteam: IIwadSteam; const AOptions: IIwadOptions;
  const AApplications: TArray<Integer>);
begin
  inherited Create;
  if not Assigned(ASteam) then
    raise EArgumentNilException.Create('ASteam');
  if not Assigned(AOptions) then
    raise EArgumentNilException.Create('AOptions');
  FSteam := ASteam;
  FOptions := AOptions;
  FApplications := AApplications;
end;

function TIwadSteamPaths.GetDirectories: TArray<string>;
var
  LApplication: Integer;
  LDirectory: string;
  LCount: Integer;
begin
  SetLength(Result, 0);
  if not FOptions.SearchSteamPaths then
    Exit;
  LCount := 0;
  for LApplication in FApplications do
  begin
    LDirectory := FSteam.GetInstallDirectory(LApplication);
    if LDirectory <> '' then
    begin
      SetLength(Result, LCount + 3);
      Result[LCount] := LDirectory;
      Result[LCount + 1] := LDirectory + 'base\';
      Result[LCount + 2] := LDirectory + 'base\wads\';
      Inc(LCount, 3);
    end;
  end;
end;

end.
