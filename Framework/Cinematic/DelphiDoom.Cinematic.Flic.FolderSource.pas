{******************************************************************************}
{                                                                              }
{  DelphiDoom: cinematic library - the animations in a folder (#199)           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Cinematic.Flic.FolderSource;

interface

uses
  System.SysUtils,
  DelphiDoom.Cinematic.Flic.Scene.Intf;

type
  /// <summary>
  ///   IFlicSource over a folder: the animation CAVE1 is the file CAVE1 plus the extension (.WAR for Warcraft).
  ///   A name that is not a plain file name (a path, a drive, "..") is never read, so a name that comes from
  ///   a table or a script cannot leave the folder
  /// </summary>
  TFlicFolderSource = class(TInterfacedObject, IFlicSource)
  strict private
    FFolder: string;
    FExtension: string;
  public
    constructor Create(const AFolder, AExtension: string);
    function TryRead(const AName: string; out ABytes: TBytes): Boolean;
  end;

implementation

uses
  System.IOUtils;

{ TFlicFolderSource }

constructor TFlicFolderSource.Create(const AFolder, AExtension: string);
begin
  inherited Create;
  FFolder := AFolder;
  FExtension := AExtension;
end;

function TFlicFolderSource.TryRead(const AName: string; out ABytes: TBytes): Boolean;
var
  LPath: string;
  LIndex: Integer;
begin
  ABytes := nil;
  Result := False;
  if AName = '' then
    Exit;
  for LIndex := 1 to Length(AName) do
    if CharInSet(AName[LIndex], ['\', '/', ':', '*', '?', '"', '<', '>', '|']) then
      Exit;
  if AName.Contains('..') then
    Exit;
  LPath := TPath.Combine(FFolder, AName + FExtension);
  if not TFile.Exists(LPath) then
    Exit;
  ABytes := TFile.ReadAllBytes(LPath);
  Result := True;
end;

end.
