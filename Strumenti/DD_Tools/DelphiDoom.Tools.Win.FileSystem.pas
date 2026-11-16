{******************************************************************************}
{                                                                              }
{  DD_Tools: the files of Windows for the tools core library                    }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT, DD_FONT, DD_VOXEL) }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tools.Win.FileSystem;

interface

uses
  System.SysUtils,
  DelphiDoom.Tools.Intf;

type
  /// <summary>IToolFileSystem on the disk. A call that fails gives false; the folder of a file to write is made</summary>
  TWindowsToolFileSystem = class(TInterfacedObject, IToolFileSystem)
  public
    function FileExists(const APath: string): Boolean;
    function TryReadAllBytes(const APath: string; out ABytes: TBytes): Boolean;
    function TryWriteAllBytes(const APath: string; const ABytes: TBytes): Boolean;
    function TryCopyFile(const ASource, ATarget: string): Boolean;
  end;

implementation

uses
  System.Classes, System.IOUtils;

{ TWindowsToolFileSystem }

function TWindowsToolFileSystem.FileExists(const APath: string): Boolean;
begin
  Result := System.SysUtils.FileExists(APath);
end;

function TWindowsToolFileSystem.TryReadAllBytes(const APath: string; out ABytes: TBytes): Boolean;
begin
  ABytes := nil;
  try
    ABytes := TFile.ReadAllBytes(APath);
    Result := True;
  except
    on EInOutError do
      Result := False;
    on EFileStreamError do
      Result := False;
    on EDirectoryNotFoundException do
      Result := False;
    on EFileNotFoundException do
      Result := False;
    on EArgumentException do
      Result := False;
    on EOSError do
      Result := False;
  end;
end;

function TWindowsToolFileSystem.TryWriteAllBytes(const APath: string; const ABytes: TBytes): Boolean;
var
  LFolder: string;
begin
  try
    LFolder := ExtractFilePath(ExpandFileName(APath));
    if (LFolder <> '') and not TDirectory.Exists(LFolder) then
      TDirectory.CreateDirectory(LFolder);
    TFile.WriteAllBytes(APath, ABytes);
    Result := True;
  except
    on EInOutError do
      Result := False;
    on EFileStreamError do
      Result := False;
    on EDirectoryNotFoundException do
      Result := False;
    on EArgumentException do
      Result := False;
    on EOSError do
      Result := False;
  end;
end;

function TWindowsToolFileSystem.TryCopyFile(const ASource, ATarget: string): Boolean;
begin
  try
    TFile.Copy(ASource, ATarget, True);
    Result := True;
  except
    on EInOutError do
      Result := False;
    on EFileNotFoundException do
      Result := False;
    on EDirectoryNotFoundException do
      Result := False;
    on EArgumentException do
      Result := False;
    on EOSError do
      Result := False;
  end;
end;

end.
