//------------------------------------------------------------------------------
//
//  DelphiDoom: Engine - the sprites of the voxels without a patch in the WADs
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

unit DelphiDoom.Engine.Voxel.SpriteGenerator;

interface

uses
  System.SysUtils,
  DelphiDoom.Voxel.Intf,
  DelphiDoom.Engine.Voxel.Intf,
  DelphiDoom.Pak.Intf;

type
  /// <summary>
  ///   The old VX_VoxelToSprite (vx_voxelsprite.pas): the voxel files of the file system that
  ///   are a sprite the WADs do not have (the choice is IVoxelSpriteNames) become a WAD in
  ///   DATA\TMP, with a patch made from the top of the voxel (or an empty picture if the option
  ///   is off or the file is not good), and the WAD is loaded at runtime. The name of the WAD is
  ///   the SHA-1 of its bytes, as before.
  /// </summary>
  TEngineVoxelSpriteGenerator = class(TInterfacedObject, IEngineVoxelSprites)
  strict private
    FLoader: IVoxelLoader;
    FCubes: IVoxelCubeBuilder;
    FPatches: IVoxelPatchBuilder;
    FNewNames: TFunc<IVoxelSpriteNames>;
    FGenerateOption: TFunc<Boolean>;
    FPakFiles: IPakFileSystem;
    function CollectNames: IVoxelSpriteNames;
    function BuildWadFile(const ANames: IVoxelSpriteNames; const AGenerate: Boolean): string;
  public
    /// <param name="ANewNames">An empty list of names for each call of Generate</param>
    /// <param name="AGenerateOption">The option r_generatespritesfromvoxels, read at each call</param>
    /// <param name="APakFiles">The PAK file system whose files are looked at</param>
    constructor Create(const ALoader: IVoxelLoader; const ACubes: IVoxelCubeBuilder;
      const APatches: IVoxelPatchBuilder; const ANewNames: TFunc<IVoxelSpriteNames>;
      const AGenerateOption: TFunc<Boolean>; const APakFiles: IPakFileSystem);
    procedure Generate;
  end;

implementation

uses
  d_delphi,
  doomdef,
  i_tmp,
  m_argv,
  DelphiDoom.MathCore.Sha1,
  DelphiDoom.Voxel.Types,
  w_wad,
  w_wadwriter;

const
  // An empty picture of 128x128 (PNG): the sprite of a voxel when the patch is not made
  EMPTY_SPRITE: array[0..434] of Byte = (
    $89, $50, $4E, $47, $0D, $0A, $1A, $0A, $00, $00, $00, $0D, $49, $48, $44,
    $52, $00, $00, $00, $80, $00, $00, $00, $80, $08, $02, $00, $00, $00, $4C,
    $5C, $F6, $9C, $00, $00, $00, $08, $67, $72, $41, $62, $00, $00, $00, $40,
    $00, $00, $00, $80, $37, $F7, $B6, $0F, $00, $00, $00, $09, $70, $48, $59,
    $73, $00, $00, $0B, $13, $00, $00, $0B, $13, $01, $00, $9A, $9C, $18, $00,
    $00, $01, $51, $49, $44, $41, $54, $78, $9C, $ED, $D9, $B1, $09, $C0, $30,
    $10, $04, $41, $0B, $5C, $98, $FA, $6F, $4A, $2E, $C1, $3C, $08, $36, $99,
    $89, $DF, $D1, $82, $02, $DF, $3A, $67, $3F, $84, $46, $01, $A6, $B5, $DC,
    $FF, $DE, $BF, $A3, $0F, $B8, $4E, $80, $98, $00, $31, $01, $62, $02, $C4,
    $04, $88, $09, $10, $13, $20, $26, $40, $4C, $80, $98, $00, $31, $01, $62,
    $02, $C4, $96, $DF, $D1, $31, $BF, $A3, $DB, $7B, $4F, $50, $4C, $80, $98,
    $00, $31, $01, $62, $02, $C4, $04, $88, $09, $10, $13, $20, $26, $40, $4C,
    $80, $98, $00, $31, $01, $62, $02, $C4, $04, $88, $D9, $03, $6A, $F6, $80,
    $F6, $DE, $13, $14, $13, $20, $26, $40, $4C, $80, $98, $00, $31, $01, $62,
    $02, $C4, $04, $88, $09, $10, $13, $20, $26, $40, $4C, $80, $98, $00, $31,
    $01, $62, $F6, $80, $9A, $3D, $A0, $BD, $F7, $04, $C5, $04, $88, $09, $10,
    $13, $20, $26, $40, $4C, $80, $98, $00, $31, $01, $62, $02, $C4, $04, $88,
    $09, $10, $13, $20, $26, $40, $4C, $80, $98, $3D, $A0, $66, $0F, $68, $EF,
    $3D, $41, $31, $01, $62, $02, $C4, $04, $88, $09, $10, $13, $20, $26, $40,
    $4C, $80, $98, $00, $31, $01, $62, $02, $C4, $04, $88, $09, $10, $13, $20,
    $66, $0F, $A8, $D9, $03, $DA, $7B, $4F, $50, $4C, $80, $98, $00, $31, $01,
    $62, $02, $C4, $04, $88, $09, $10, $13, $20, $26, $40, $4C, $80, $98, $00,
    $31, $01, $62, $02, $C4, $04, $88, $D9, $03, $6A, $F6, $80, $F6, $DE, $13,
    $14, $13, $20, $26, $40, $4C, $80, $98, $00, $31, $01, $62, $02, $C4, $04,
    $88, $09, $10, $13, $20, $26, $40, $4C, $80, $98, $00, $31, $01, $62, $F6,
    $80, $9A, $3D, $A0, $BD, $F7, $04, $C5, $04, $88, $09, $10, $13, $20, $26,
    $40, $4C, $80, $98, $00, $31, $01, $62, $02, $C4, $04, $88, $09, $10, $13,
    $20, $26, $40, $4C, $80, $98, $3D, $20, $F6, $01, $68, $2F, $B7, $64, $73,
    $C2, $B3, $80, $00, $00, $00, $00, $49, $45, $4E, $44, $AE, $42, $60, $82
  );

{ TEngineVoxelSpriteGenerator }

constructor TEngineVoxelSpriteGenerator.Create(const ALoader: IVoxelLoader;
  const ACubes: IVoxelCubeBuilder; const APatches: IVoxelPatchBuilder;
  const ANewNames: TFunc<IVoxelSpriteNames>; const AGenerateOption: TFunc<Boolean>;
  const APakFiles: IPakFileSystem);
begin
  inherited Create;
  if not Assigned(APakFiles) then
    raise EArgumentNilException.Create('APakFiles');
  FPakFiles := APakFiles;
  if not Assigned(ALoader) then
    raise EArgumentNilException.Create('ALoader');
  if not Assigned(ACubes) then
    raise EArgumentNilException.Create('ACubes');
  if not Assigned(APatches) then
    raise EArgumentNilException.Create('APatches');
  if not Assigned(ANewNames) then
    raise EArgumentNilException.Create('ANewNames');
  if not Assigned(AGenerateOption) then
    raise EArgumentNilException.Create('AGenerateOption');
  FLoader := ALoader;
  FCubes := ACubes;
  FPatches := APatches;
  FNewNames := ANewNames;
  FGenerateOption := AGenerateOption;
end;

function TEngineVoxelSpriteGenerator.CollectNames: IVoxelSpriteNames;
var
  LIndex: Integer;
begin
  Result := FNewNames();
  for LIndex := 0 to FPakFiles.EntryCount - 1 do
    Result.AddFileName(FPakFiles.EntryName(LIndex));
end;

function TEngineVoxelSpriteGenerator.BuildWadFile(const ANames: IVoxelSpriteNames;
  const AGenerate: Boolean): string;
var
  LWad: TWADWriter;
  LMemory: TDMemoryStream;
  LIndex: Integer;
  LModel: IVoxelModel;
  LPatch: TBytes;
begin
  LWad := TWADWriter.Create;
  try
    LWad.AddSeparator('SS_START');
    for LIndex := 0 to ANames.Count - 1 do
    begin
      LModel := nil;
      // a name without a known extension is a KVX, as it has always been
      if AGenerate then
        LModel := FLoader.Load(ANames.Entry(LIndex));
      if LModel <> nil then
      begin
        LPatch := FPatches.Build(FCubes.Build(LModel, cfSprite));
        LWad.AddData(ANames.SpriteName(LIndex), @LPatch[0], Length(LPatch));
      end
      else
        LWad.AddData(ANames.SpriteName(LIndex), @EMPTY_SPRITE, SizeOf(EMPTY_SPRITE));
    end;
    LWad.AddSeparator('SS_END');

    LMemory := TDMemoryStream.Create;
    try
      LWad.SaveToStream(LMemory);
      Result := M_SaveFileName('DATA\');
      MkDir(Result);
      Result := Result + 'TMP\';
      MkDir(Result);
      // the name of the old code: readablestring of the raw digest seen as a string
      Result := Result + 'voxelsprite_' +
        readablestring(string(TSha1.ToRawString(TSha1.Calculate(LMemory.memory^, LMemory.Size)))) + '.wad';
    finally
      LMemory.Free;
    end;

    LWad.SaveToFile(Result);
  finally
    LWad.Free;
  end;
end;

procedure TEngineVoxelSpriteGenerator.Generate;
var
  LNames: IVoxelSpriteNames;
  LWadFileName: string;
begin
  LNames := CollectNames;
  if LNames.Count = 0 then
    Exit;

  LWadFileName := BuildWadFile(LNames, FGenerateOption());
  W_RuntimeLoad(LWadFileName, F_ORIGIN_WAD);
  I_DeclareTempFile(LWadFileName);
end;

end.
