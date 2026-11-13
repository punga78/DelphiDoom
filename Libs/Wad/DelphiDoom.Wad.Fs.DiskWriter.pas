{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - file system of id Tech 4: the disk for writing    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Fs.DiskWriter;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Wad.Fs.Write.Intf;

type
  /// <summary>IGameDiskWriter on the disk of the machine (System.IOUtils)</summary>
  TGameDiskWriter = class(TInterfacedObject, IGameDiskWriter)
  public
    function CreateDirectory(const ADirectory: string): Boolean;
    function OpenWrite(const AFileName: string; AAppend: Boolean): TStream;
    function RemoveFile(const AFileName: string): Boolean;
  end;

implementation

uses
  System.IOUtils;

{ TGameDiskWriter }

function TGameDiskWriter.CreateDirectory(const ADirectory: string): Boolean;
begin
  if TDirectory.Exists(ADirectory) then
    Exit(True);
  try
    TDirectory.CreateDirectory(ADirectory);
  except
    // EDirectoryNotFoundException and the other errors of the disk are EInOutError; a name with characters a path
    // cannot have is EArgumentException
    on EInOutError do
      Exit(False);
    on EArgumentException do
      Exit(False);
  end;
  Result := TDirectory.Exists(ADirectory);
end;

function TGameDiskWriter.OpenWrite(const AFileName: string; AAppend: Boolean): TStream;
var
  LMode: Word;
begin
  if AAppend and TFile.Exists(AFileName) then
    LMode := fmOpenReadWrite or fmShareDenyWrite
  else
    LMode := fmCreate or fmShareDenyWrite;
  try
    Result := TFileStream.Create(AFileName, LMode);
    if AAppend then
      Result.Seek(0, soEnd);
  except
    on EFOpenError do
      Result := nil;
    on EFCreateError do
      Result := nil;
  end;
end;

function TGameDiskWriter.RemoveFile(const AFileName: string): Boolean;
begin
  if not TFile.Exists(AFileName) then
    Exit(False);
  try
    TFile.Delete(AFileName);
    Result := True;
  except
    on EInOutError do
      Result := False;
  end;
end;

end.
