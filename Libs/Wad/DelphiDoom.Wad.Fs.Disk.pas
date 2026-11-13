{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - file system of id Tech 4: the real disk           }
{                                                                              }
{  Port of the file system of Doom 3 (id Software, GPL v3): Sys_ListFiles,     }
{  OpenOSFile and Sys_FileTimeStamp seen through one interface. Copyright (C)  }
{  1999-2011 id Software LLC, a ZeniMax Media company.                         }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Libs\IdLib\README.md); the repository   }
{  as a whole is GPL v2 or later.                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Fs.Disk;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Wad.Fs.Intf;

type
  /// <summary>
  ///   IGameDisk on the disk of the machine (System.IOUtils). Case counts as much as the file system of
  ///   the OS makes it count; fs_caseSensitiveOS of the original (the cache of folder listings and the
  ///   search of a file by name when the OS is case sensitive) is not ported
  /// </summary>
  TGameDisk = class(TInterfacedObject, IGameDisk)
  public
    function ListFiles(const ADirectory, AExtension: string): TArray<string>;
    function OpenRead(const AFileName: string): TStream;
    function FileTimestamp(const AFileName: string): Int64;
  end;

implementation

uses
  System.IOUtils, System.DateUtils;

{ TGameDisk }

function TGameDisk.ListFiles(const ADirectory, AExtension: string): TArray<string>;
var
  LFound: TArray<string>;
  LPath, LName: string;
  LCount: Integer;
begin
  Result := nil;
  if not TDirectory.Exists(ADirectory) then
    Exit;
  LCount := 0;
  if AExtension = '/' then
    LFound := TDirectory.GetDirectories(ADirectory)
  else
    LFound := TDirectory.GetFiles(ADirectory);
  SetLength(Result, Length(LFound));
  for LPath in LFound do
  begin
    LName := ExtractFileName(ExcludeTrailingPathDelimiter(LPath));
    if (AExtension <> '/') and not LName.EndsWith(AExtension, True) then
      Continue;
    Result[LCount] := LName;
    Inc(LCount);
  end;
  SetLength(Result, LCount);
end;

function TGameDisk.OpenRead(const AFileName: string): TStream;
begin
  Result := nil;
  if not TFile.Exists(AFileName) then
    Exit;
  try
    Result := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  except
    on EFOpenError do
      Result := nil;
  end;
end;

function TGameDisk.FileTimestamp(const AFileName: string): Int64;
begin
  if not TFile.Exists(AFileName) then
    Exit(0);
  Result := DateTimeToUnix(TFile.GetLastWriteTimeUtc(AFileName), False);
end;

end.
