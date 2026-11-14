{******************************************************************************}
{                                                                              }
{  DD_IDE: the files and folders of Windows for the ide library                }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.Win.FileSystem;

interface

uses
  System.SysUtils,
  System.Classes,
  DelphiDoom.Ide.Intf;

type
  /// <summary>
  ///   IIdeFileSystem on the disk. Every call that fails gives false: the library writes the
  ///   message. The ide keeps the files of a project relative to the current folder, which it
  ///   changes when a project is opened or saved, so the current folder is the process one
  /// </summary>
  TWindowsIdeFileSystem = class(TInterfacedObject, IIdeFileSystem)
  public
    function FileExists(const APath: string): Boolean;
    function DirectoryExists(const APath: string): Boolean;
    function ExpandFileName(const APath: string): string;
    function TryCreateEmptyFile(const APath: string): Boolean;
    function TryReadAllText(const APath: string; out AText: AnsiString): Boolean;
    function TryWriteAllText(const APath: string; const AText: AnsiString): Boolean;
    function TryCopyFile(const ASource, ATarget: string): Boolean;
    function TrySetCurrentDirectory(const APath: string): Boolean;
    function TryCreateDirectory(const APath: string): Boolean;
    function TryLoadTextFile(const APath: string; out AText: string): Boolean;
    function TrySaveTextFile(const APath: string; const AText: string): Boolean;
    function ProgramFolder: string;
  end;

implementation

uses
  Winapi.Windows, DelphiDoom.Platform.DataFolder.Factory;

{ TWindowsIdeFileSystem }

function TWindowsIdeFileSystem.FileExists(const APath: string): Boolean;
begin
  Result := System.SysUtils.FileExists(APath);
end;

function TWindowsIdeFileSystem.DirectoryExists(const APath: string): Boolean;
begin
  Result := System.SysUtils.DirectoryExists(APath);
end;

function TWindowsIdeFileSystem.ExpandFileName(const APath: string): string;
begin
  Result := System.SysUtils.ExpandFileName(APath);
end;

function TWindowsIdeFileSystem.TryCreateEmptyFile(const APath: string): Boolean;
begin
  Result := TryWriteAllText(APath, '');
end;

function TWindowsIdeFileSystem.TryReadAllText(const APath: string; out AText: AnsiString): Boolean;
var
  LStream: TFileStream;
begin
  AText := '';
  try
    LStream := TFileStream.Create(APath, fmOpenRead or fmShareDenyWrite);
    try
      SetLength(AText, LStream.Size);
      if LStream.Size > 0 then
        LStream.ReadBuffer(AText[1], LStream.Size);
    finally
      LStream.Free;
    end;
    Result := True;
  except
    AText := '';
    Result := False;
  end;
end;

function TWindowsIdeFileSystem.TryWriteAllText(const APath: string; const AText: AnsiString): Boolean;
var
  LStream: TFileStream;
begin
  try
    LStream := TFileStream.Create(APath, fmCreate or fmShareExclusive);
    try
      if Length(AText) > 0 then
        LStream.WriteBuffer(AText[1], Length(AText));
    finally
      LStream.Free;
    end;
    Result := True;
  except
    Result := False;
  end;
end;

function TWindowsIdeFileSystem.TryCopyFile(const ASource, ATarget: string): Boolean;
begin
  // a source that does not exist gives an empty copy, as the old backup did
  if System.SysUtils.FileExists(ASource) then
    Result := Winapi.Windows.CopyFile(PChar(ASource), PChar(ATarget), False)
  else
    Result := TryCreateEmptyFile(ATarget);
end;

function TWindowsIdeFileSystem.TrySetCurrentDirectory(const APath: string): Boolean;
begin
  Result := SetCurrentDir(APath);
end;

function TWindowsIdeFileSystem.TryCreateDirectory(const APath: string): Boolean;
begin
  Result := CreateDir(APath);
end;

function TWindowsIdeFileSystem.TryLoadTextFile(const APath: string; out AText: string): Boolean;
var
  LLines: TStringList;
begin
  AText := '';
  LLines := TStringList.Create;
  try
    try
      LLines.LoadFromFile(APath);
      AText := LLines.Text;
      Result := True;
    except
      Result := False;
    end;
  finally
    LLines.Free;
  end;
end;

function TWindowsIdeFileSystem.TrySaveTextFile(const APath: string; const AText: string): Boolean;
var
  LLines: TStringList;
begin
  LLines := TStringList.Create;
  try
    try
      LLines.Text := AText;
      LLines.SaveToFile(APath);
      Result := True;
    except
      Result := False;
    end;
  finally
    LLines.Free;
  end;
end;

function TWindowsIdeFileSystem.ProgramFolder: string;
begin
  // built in bin\Platform\Configuration\Tools, the examples and the resources stay in bin\Tools
  Result := TDataFolderFactory.CreateLocator.Locate(ExtractFilePath(ParamStr(0)), '');
end;

end.
