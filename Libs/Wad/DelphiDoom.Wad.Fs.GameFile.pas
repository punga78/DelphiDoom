{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - file system of id Tech 4: an open file            }
{                                                                              }
{  Port of the file system of Doom 3 (id Software, GPL v3): idFile_Permanent   }
{  and idFile_InZip, for reading (framework\File.cpp). Copyright (C)           }
{  1999-2011 id Software LLC, a ZeniMax Media company.                         }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Libs\IdLib\README.md); the repository   }
{  as a whole is GPL v2 or later.                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Fs.GameFile;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Wad.Fs.Intf;

type
  /// <summary>
  ///   IGameFile for a file of a folder (it owns the stream) or for an entry of a pak. Only whole reads:
  ///   Read, Seek and the rest of idFile are not ported (the engine reads the file in memory)
  /// </summary>
  TGameFile = class(TInterfacedObject, IGameFile)
  strict private
    FName: string;
    FFullPath: string;
    FLength: Integer;
    FTimestamp: Int64;
    FStream: TStream;
    FPack: IGamePack;
    FEntryIndex: Integer;
  public
    /// <summary>A file of a folder; the file takes the stream</summary>
    constructor CreateFromDirectory(const AName, AFullPath: string; AStream: TStream; ATimestamp: Int64);
    /// <summary>An entry of a pak</summary>
    constructor CreateFromPack(const AName: string; const APack: IGamePack; AEntryIndex: Integer);
    destructor Destroy; override;
    function GetName: string;
    function GetFullPath: string;
    function GetLength: Integer;
    function GetTimestamp: Int64;
    function GetPack: IGamePack;
    function ReadAll: TBytes;
  end;

implementation

{ TGameFile }

constructor TGameFile.CreateFromDirectory(const AName, AFullPath: string; AStream: TStream; ATimestamp: Int64);
begin
  inherited Create;
  FName := AName;
  FFullPath := AFullPath;
  FStream := AStream;
  FLength := Integer(AStream.Size);
  FTimestamp := ATimestamp;
  FEntryIndex := -1;
end;

constructor TGameFile.CreateFromPack(const AName: string; const APack: IGamePack; AEntryIndex: Integer);
begin
  inherited Create;
  FName := AName;
  FPack := APack;
  FEntryIndex := AEntryIndex;
  FFullPath := APack.FileName + '/' + AName;
  FLength := Integer(APack.EntrySize(AEntryIndex));
  FTimestamp := 0;
end;

destructor TGameFile.Destroy;
begin
  FStream.Free;
  inherited Destroy;
end;

function TGameFile.GetName: string;
begin
  Result := FName;
end;

function TGameFile.GetFullPath: string;
begin
  Result := FFullPath;
end;

function TGameFile.GetLength: Integer;
begin
  Result := FLength;
end;

function TGameFile.GetTimestamp: Int64;
begin
  Result := FTimestamp;
end;

function TGameFile.GetPack: IGamePack;
begin
  Result := FPack;
end;

function TGameFile.ReadAll: TBytes;
begin
  if Assigned(FPack) then
    Exit(FPack.ReadEntry(FEntryIndex));
  SetLength(Result, FLength);
  FStream.Position := 0;
  if FLength > 0 then
    FStream.ReadBuffer(Result[0], FLength);
end;

end.
