{******************************************************************************}
{                                                                              }
{  DelphiDoom: platform library - whole files on the disk                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Platform.FileStore;

interface

uses
  System.SysUtils, DelphiDoom.Platform.Intf;

type
  /// <summary>IFileStore on the files of the disk</summary>
  TFileStore = class(TInterfacedObject, IFileStore)
  public
    function Exists(const AName: string): Boolean;
    function Write(const AName: string; ASource: Pointer; ALength: Integer): Boolean;
    function Append(const AName: string; ASource: Pointer; ALength: Integer): Integer;
    function Read(const AName: string): TBytes;
    function Delete(const AName: string): Boolean;
    function EnsureDirectory(const APath: string): Boolean;
  end;

implementation

uses
  System.Classes, DelphiDoom.Platform.Types;

{ TFileStore }

function TFileStore.Exists(const AName: string): Boolean;
begin
  Result := FileExists(AName);
end;

function TFileStore.Write(const AName: string; ASource: Pointer; ALength: Integer): Boolean;
var
  LStream: TFileStream;
begin
  Result := False;
  try
    LStream := TFileStream.Create(AName, fmCreate);
    try
      if ALength > 0 then
      begin
        LStream.WriteBuffer(ASource^, ALength);
        Result := True;
      end;
    finally
      LStream.Free;
    end;
  except
    on EStreamError do
      Result := False;
  end;
end;

function TFileStore.Append(const AName: string; ASource: Pointer; ALength: Integer): Integer;
var
  LStream: TFileStream;
begin
  Result := 0;
  if not FileExists(AName) then
  begin
    if Write(AName, ASource, ALength) then
      Result := ALength;
  end
  else if ALength > 0 then
  begin
    try
      LStream := TFileStream.Create(AName, fmOpenReadWrite or fmShareDenyWrite);
      try
        LStream.Seek(0, soEnd);
        Result := LStream.Write(ASource^, ALength);
      finally
        LStream.Free;
      end;
    except
      on EStreamError do
        Result := 0;
    end;
  end;
end;

function TFileStore.Read(const AName: string): TBytes;
var
  LStream: TFileStream;
begin
  try
    LStream := TFileStream.Create(AName, fmOpenRead or fmShareDenyNone);
    try
      SetLength(Result, LStream.Size);
      if Length(Result) > 0 then
        LStream.ReadBuffer(Result[0], Length(Result));
    finally
      LStream.Free;
    end;
  except
    on EStreamError do
      raise EPlatformException.CreateFmt(SPlatformFileNotRead, [AName]);
  end;
end;

function TFileStore.Delete(const AName: string): Boolean;
begin
  Result := FileExists(AName) and DeleteFile(AName);
end;

function TFileStore.EnsureDirectory(const APath: string): Boolean;
var
  LPath: string;
begin
  LPath := ExcludeTrailingPathDelimiter(APath);
  Result := (LPath <> '') and (DirectoryExists(LPath) or ForceDirectories(LPath));
end;

end.
