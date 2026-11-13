{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - file system of id Tech 4: an open file for        }
{  writing                                                                     }
{                                                                              }
{  Port of idFile_Permanent as far as writing goes (id Software, GPL v3).      }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Libs\IdLib\README.md); the repository   }
{  as a whole is GPL v2 or later.                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Fs.WriteFile;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Wad.Fs.Write.Intf;

type
  /// <summary>
  ///   IGameWriteFile over a stream it owns. The stream is a file of the disk opened by
  ///   <c>IGameDiskWriter.OpenWrite</c>; it is freed with the object, which is what closes the file.
  /// </summary>
  TGameWriteFile = class(TInterfacedObject, IGameWriteFile)
  strict private
    FName: string;
    FFullPath: string;
    FStream: TStream;
    FIsAppend: Boolean;
    FSync: Boolean;
    FLength: Int64;
  public
    /// <summary>The file takes the stream; <c>ASync</c> is handleSync (a flush after each write)</summary>
    constructor Create(const AName, AFullPath: string; AStream: TStream; AIsAppend, ASync: Boolean);
    destructor Destroy; override;
    function GetName: string;
    function GetFullPath: string;
    function GetLength: Int64;
    function GetIsAppend: Boolean;
    function Write(const ABytes: TBytes): Integer;
    function WriteText(const AText: AnsiString): Integer;
    procedure Flush;
  end;

implementation

uses
  Winapi.Windows, DelphiDoom.Wad.Fs.Types;

const
  SNoStream = 'TGameWriteFile.Create without a stream';

{ TGameWriteFile }

constructor TGameWriteFile.Create(const AName, AFullPath: string; AStream: TStream; AIsAppend, ASync: Boolean);
begin
  inherited Create;
  if not Assigned(AStream) then
    raise EGameFsException.Create(SNoStream);
  FName := AName;
  FFullPath := AFullPath;
  FStream := AStream;
  FIsAppend := AIsAppend;
  FSync := ASync;
  if AIsAppend then
    FLength := AStream.Size;
end;

destructor TGameWriteFile.Destroy;
begin
  FStream.Free;
  inherited Destroy;
end;

function TGameWriteFile.GetName: string;
begin
  Result := FName;
end;

function TGameWriteFile.GetFullPath: string;
begin
  Result := FFullPath;
end;

function TGameWriteFile.GetLength: Int64;
begin
  Result := FLength;
end;

function TGameWriteFile.GetIsAppend: Boolean;
begin
  Result := FIsAppend;
end;

function TGameWriteFile.Write(const ABytes: TBytes): Integer;
begin
  Result := System.Length(ABytes);
  if Result = 0 then
    Exit;
  FStream.WriteBuffer(ABytes[0], Result);
  Inc(FLength, Result);
  if FSync then
    Flush;
end;

function TGameWriteFile.WriteText(const AText: AnsiString): Integer;
var
  LBytes: TBytes;
begin
  SetLength(LBytes, System.Length(AText));
  if System.Length(AText) > 0 then
    Move(AText[1], LBytes[0], System.Length(AText));
  Result := Write(LBytes);
end;

procedure TGameWriteFile.Flush;
begin
  // only a file of the disk has a handle to flush; a stream in memory has nothing to do
  if FStream is THandleStream then
    FlushFileBuffers(THandleStream(FStream).Handle);
end;

end.
