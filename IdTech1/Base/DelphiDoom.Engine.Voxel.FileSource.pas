//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - where the voxel files are
//  Copyright (C) 2004-2022 by Jim Valavanis
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//------------------------------------------------------------------------------
//  Site  : https://sourceforge.net/projects/delphidoom/
//------------------------------------------------------------------------------

{$I Doom32.inc}

unit DelphiDoom.Engine.Voxel.FileSource;

interface

uses
  System.SysUtils,
  DelphiDoom.Voxel.Intf,
  DelphiDoom.Pak.Intf,
  DelphiDoom.Engine.Wad.Lumps.Intf;

type
  /// <summary>
  ///   The voxel files as the old loaders found them: in the voxel folders of the game
  ///   directories and the PAK files, in the directory of the program, and as lumps of the WADs
  /// </summary>
  TEngineVoxelFileSource = class(TInterfacedObject, IVoxelFileSource)
  strict private
    FPakFiles: IPakFileSystem;
    FLumps: IEngineLumps;
    class function GameFolders: TArray<string>; static;
  public
    /// <summary>Raises EArgumentNilException when APakFiles or ALumps is nil</summary>
    constructor Create(const APakFiles: IPakFileSystem; const ALumps: IEngineLumps);
    function TryReadFile(const AName: string; out ABytes: TBytes): Boolean;
    function TryReadDirectoryFile(const AName: string; out ABytes: TBytes): Boolean;
    function TryReadLump(const AName: string; out ABytes: TBytes): Boolean;
  end;

implementation

uses
  d_delphi,
  doomdef,
  w_folders,
  DelphiDoom.Wad.Types,
  DelphiDoom.Wad.Pak.Types;

const
  SPakFilesMissing = 'TEngineVoxelFileSource: the PAK file system is nil';

{ TEngineVoxelFileSource }

constructor TEngineVoxelFileSource.Create(const APakFiles: IPakFileSystem;
  const ALumps: IEngineLumps);
begin
  inherited Create;
  if not Assigned(APakFiles) then
    raise EArgumentNilException.Create(SPakFilesMissing);
  if not Assigned(ALumps) then
    raise EArgumentNilException.Create('ALumps');
  FPakFiles := APakFiles;
  FLumps := ALumps;
end;

class function TEngineVoxelFileSource.GameFolders: TArray<string>;
var
  LIndex: Integer;
begin
  // the folders of the game are read at each call: d_main sets them after the composition
  Result := nil;
  if doomdef.gamedirectories = nil then
    Exit;
  SetLength(Result, doomdef.gamedirectories.Count);
  for LIndex := 0 to doomdef.gamedirectories.Count - 1 do
    Result[LIndex] := doomdef.gamedirectories[LIndex];
end;

function ReadAll(const AStream: TDStream; out ABytes: TBytes): Boolean;
var
  LSize: Integer;
begin
  Result := AStream.IOResult = 0;
  if not Result then
  begin
    ABytes := nil;
    Exit;
  end;
  LSize := AStream.Size;
  SetLength(ABytes, LSize);
  if LSize > 0 then
    AStream.Read(ABytes[0], LSize);
end;

function TEngineVoxelFileSource.TryReadFile(const AName: string; out ABytes: TBytes): Boolean;
var
  LStream: TDStream;
begin
  LStream := FPakFiles.Open(AName, TPakLookupMode.Preferred, GameFolders, FOLDER_VOXELS);
  try
    Result := ReadAll(LStream, ABytes);
  finally
    LStream.Free;
  end;
end;

function TEngineVoxelFileSource.TryReadDirectoryFile(const AName: string; out ABytes: TBytes): Boolean;
var
  LStream: TDStream;
begin
  LStream := FPakFiles.Open(AName, TPakLookupMode.Directory, nil, FOLDER_VOXELS);
  try
    Result := ReadAll(LStream, ABytes);
  finally
    LStream.Free;
  end;
end;

function TEngineVoxelFileSource.TryReadLump(const AName: string; out ABytes: TBytes): Boolean;
var
  LLump: Integer;
  LLength: Integer;
begin
  LLump := FLumps.CheckNumForName(AName, TYPE_VOXEL);
  Result := LLump >= 0;
  if not Result then
  begin
    ABytes := nil;
    Exit;
  end;
  LLength := FLumps.LengthOf(LLump);
  SetLength(ABytes, LLength);
  if LLength > 0 then
    FLumps.Read(LLump, @ABytes[0]);
end;

end.