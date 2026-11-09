//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - the external textures of the folders and the PAK files
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

unit DelphiDoom.Engine.Texture.Files;

interface

uses
  System.SysUtils,
  d_delphi,
  DelphiDoom.Texture.Image,
  DelphiDoom.Texture.Intf,
  DelphiDoom.Pak.Intf,
  DelphiDoom.Engine.Texture.Item,
  DelphiDoom.Engine.Texture.Intf;

type
  /// <summary>
  ///   IEngineTextureFiles on the decoders of Libs\Texture and the PAK file system: a name is
  ///   looked for with each extension of the decoders, in the game folders when the option
  ///   preferetexturesnamesingamedirectory is on, else by its short name and in the folder
  ///   TEXTURES (T_LoadHiResImage of the old t_main)
  /// </summary>
  TEngineTextureFiles = class(TInterfacedObject, IEngineTextureFiles)
  strict private
    FFormats: ITextureFormats;
    FPakFiles: IPakFileSystem;
    class function ReadAll(const AStream: TDStream): TBytes; static;
    class function GameFolders: TArray<string>; static;
  public
    /// <summary>Raises EArgumentNilException when AFormats or APakFiles is nil</summary>
    constructor Create(const AFormats: ITextureFormats; const APakFiles: IPakFileSystem);
    function LoadImage(const AFileName: string; ASilent: Boolean = False): TTextureImage;
    function LoadTexture(const AFileName: string; ASilent: Boolean = False): PTexture;
    function Decode(const AStream: TDStream; const AAlias: string; ATexture: PTexture): Boolean;
    function IsTextureExtension(const AExtension: string): Boolean;
  end;

implementation

uses
  doomdef,
  i_system,
  DelphiDoom.Engine.Texture.Settings,
  w_folders,
  DelphiDoom.Wad.Pak.Types;

const
  SFormatsMissing = 'TEngineTextureFiles: the texture formats are nil';
  SPakFilesMissing = 'TEngineTextureFiles: the PAK file system is nil';

{ TEngineTextureFiles }

constructor TEngineTextureFiles.Create(const AFormats: ITextureFormats; const APakFiles: IPakFileSystem);
begin
  inherited Create;
  if not Assigned(AFormats) then
    raise EArgumentNilException.Create(SFormatsMissing);
  if not Assigned(APakFiles) then
    raise EArgumentNilException.Create(SPakFilesMissing);
  FFormats := AFormats;
  FPakFiles := APakFiles;
end;

class function TEngineTextureFiles.ReadAll(const AStream: TDStream): TBytes;
var
  LSize: Integer;
begin
  AStream.Seek(0, sFromBeginning);
  LSize := AStream.Size;
  SetLength(Result, LSize);
  if LSize > 0 then
    AStream.Read(Result[0], LSize);
end;

class function TEngineTextureFiles.GameFolders: TArray<string>;
var
  LIndex: Integer;
begin
  // the folders and the option are read at each call: d_main and the .ini set them after the start
  Result := nil;
  if doomdef.gamedirectories = nil then
    Exit;
  SetLength(Result, doomdef.gamedirectories.Count);
  for LIndex := 0 to doomdef.gamedirectories.Count - 1 do
    Result[LIndex] := doomdef.gamedirectories[LIndex];
end;

function TEngineTextureFiles.LoadImage(const AFileName: string; ASilent: Boolean): TTextureImage;
var
  LExtension: string;
  LName: string;
  LStream: TDStream;
  LImage: TTextureImage;
begin
  Result := nil;
  for LExtension in FFormats.Extensions do
  begin
    if FFormats.FindDecoder(LExtension) = nil then
      Continue;
    LName := d_delphi.strupper(AFileName);
    if Copy(LName, Length(LName) - Length(LExtension) + 1, Length(LExtension)) <> LExtension then
      LName := LName + LExtension;
    if TEngineTextureSettings.PreferGameDirectory then
      LStream := FPakFiles.Open(LName, TPakLookupMode.Preferred, GameFolders, '')
    else
      LStream := FPakFiles.Open(LName, TPakLookupMode.Short, nil, FOLDER_TEXTURES);
    try
      LStream.OnBeginBusy := I_BeginDiskBusy;
      if LStream.IOResult = 0 then
      begin
        // every decoder starts from an empty image
        LImage := TTextureImage.Create;
        if FFormats.Decode(LExtension, ReadAll(LStream), LImage) then
        begin
          if not ASilent then
            printf('  Found external texture %s'#13#10, [LName]);
          Exit(LImage);
        end;
        LImage.Free;
      end;
    finally
      LStream.Free;
    end;
  end;
end;

function TEngineTextureFiles.LoadTexture(const AFileName: string; ASilent: Boolean): PTexture;
var
  LImage: TTextureImage;
begin
  LImage := LoadImage(AFileName, ASilent);
  if LImage = nil then
    Exit(nil);
  Result := New(PTexture, Create);
  Result.SetImage(LImage);
end;

function TEngineTextureFiles.Decode(const AStream: TDStream; const AAlias: string;
  ATexture: PTexture): Boolean;
var
  LDot: Integer;
  LImage: TTextureImage;
begin
  LDot := Length(AAlias);
  while (LDot > 0) and (AAlias[LDot] <> '.') do
    Dec(LDot);
  if LDot = 0 then
    Exit(False);
  LImage := TTextureImage.Create;
  Result := FFormats.Decode(Copy(AAlias, LDot, Length(AAlias)), ReadAll(AStream), LImage);
  ATexture.SetImage(LImage);
end;

function TEngineTextureFiles.IsTextureExtension(const AExtension: string): Boolean;
begin
  Result := FFormats.IsKnownExtension(AExtension);
end;

end.
