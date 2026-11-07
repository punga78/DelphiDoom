{******************************************************************************}
{                                                                              }
{  DelphiDoom: IWAD library - the locator of files                              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Iwad.Locator;

interface

uses
  DelphiDoom.Iwad.Intf;

type
  /// <summary>
  ///   Port of D_FileInDoomPath: the file as it is, or the same name in the first folder of
  ///   the search paths that has it. The sources are asked every time, so the options and
  ///   the variables that the player changes are always the current ones
  /// </summary>
  TIwadLocator = class(TInterfacedObject, IIwadLocator)
  strict private
    FFileSystem: IIwadFileSystem;
    FSearchPaths: TArray<IIwadSearchPath>;
  public
    /// <param name="ASearchPaths">In the order to try</param>
    constructor Create(const AFileSystem: IIwadFileSystem; const ASearchPaths: TArray<IIwadSearchPath>);
    function Locate(const AFileName: string): string;
  end;

implementation

uses
  System.SysUtils;

{ TIwadLocator }

constructor TIwadLocator.Create(const AFileSystem: IIwadFileSystem;
  const ASearchPaths: TArray<IIwadSearchPath>);
var
  LSearchPath: IIwadSearchPath;
begin
  inherited Create;
  if not Assigned(AFileSystem) then
    raise EArgumentNilException.Create('AFileSystem');
  for LSearchPath in ASearchPaths do
    if not Assigned(LSearchPath) then
      raise EArgumentNilException.Create('ASearchPaths');
  FFileSystem := AFileSystem;
  FSearchPaths := ASearchPaths;
end;

function TIwadLocator.Locate(const AFileName: string): string;
var
  LSearchPath: IIwadSearchPath;
  LDirectory: string;
  LShortName: string;
  LCandidate: string;
begin
  if FFileSystem.FileExists(AFileName) then
    Exit(AFileName);

  LShortName := ExtractFileName(AFileName);
  for LSearchPath in FSearchPaths do
  begin
    for LDirectory in LSearchPath.GetDirectories do
    begin
      LCandidate := StringReplace(LDirectory, '/', '\', [rfReplaceAll]);
      if (LCandidate = '') or (LCandidate[Length(LCandidate)] <> '\') then
        LCandidate := LCandidate + '\';
      LCandidate := LCandidate + LShortName;
      if FFileSystem.FileExists(LCandidate) then
        Exit(LCandidate);
    end;
  end;
  Result := AFileName;
end;

end.
