{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the text maps (UDMF) of a level                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Udmf.MapLoader;

interface

uses
  System.SysUtils,
  DelphiDoom.CommandLine.Intf,
  DelphiDoom.Udmf.Types,
  DelphiDoom.Udmf.Intf,
  DelphiDoom.Udmf.Apply.Intf,
  DelphiDoom.Engine.Wad.Intf,
  DelphiDoom.Engine.Level.Intf;

type
  /// <summary>
  ///   A map in the UDMF text format for the loading of a level. Prepare converts the TEXTMAP
  ///   with the converter of Libs\Udmf, writes the vanilla map and the extra lumps in a PWAD of
  ///   DATA\WADS and loads it at runtime; for a vanilla map it reads the extra lumps (THINGS2,
  ///   SECTORS2...) that are already there. The extra records go in the data of p_udmf.pas,
  ///   that the appliers write in sectors[], lines[], sides[] and segs[]. It was the facade
  ///   p_udmf.pas (UDMF_Check, UDMF_Make*)
  /// </summary>
  TEngineUdmfMapLoader = class(TInterfacedObject, ILevelUdmf)
  strict private
    FConverter: IUdmfConverter;
    FWadServices: IEngineWadServices;
    FSectors: IUdmfMapPartApplier;
    FLines: IUdmfMapPartApplier;
    FSides: IUdmfMapPartApplier;
    FSegs: IUdmfMapPartApplier;
    FSaveFileNames: ISaveFileNames;
    class procedure CheckRecordSize(const AWhat: string; AEngineSize, ALibrarySize: Integer); static;
    class function LumpIsNamed(ALump: Integer; const AName: string): Boolean; static;
    class function LumpToBytes(ALump: Integer): TBytes; static;
    class function ExtraToMemory(const AData: TBytes): Pointer; static;
    procedure ClearExtraData;
    procedure ReadExtraLumps(AMapLump: Integer);
    function FindLumpOfMap(AMapLump: Integer; const AName: string): Integer;
    function FindScriptLump(AMapLump: Integer): Integer;
    procedure StoreExtraRecords(const AConverted: IUdmfConvertedMap);
    procedure SaveToVanilla(const AConverted: IUdmfConvertedMap; const AMapName, AFileName: string;
      ABehaviorLump, AScriptLump: Integer);
  public
    /// <summary>
    ///   The records of the converter have to be the ones of this game: the sizes are checked
    ///   (I_Error if they are not); ASaveFileNames puts DATA\ in the working folder of the
    ///   CD-ROM when needed
    /// </summary>
    constructor Create(const AConverter: IUdmfConverter; const AWadServices: IEngineWadServices;
      const ASectors, ALines, ASides, ASegs: IUdmfMapPartApplier;
      const ASaveFileNames: ISaveFileNames);
    function Prepare(const AMapName: string): Boolean;
    function ApplySides: Boolean;
    function ApplyLines: Boolean;
    function ApplySegs: Boolean;
    function ApplySectors: Boolean;
  end;

implementation

uses
  d_delphi,
  doomdef,
  doomdata,
  acs,
  m_base,
  i_system,
  z_zone,
  w_wad,
  p_udmf,
  DelphiDoom.Wad.Types,
  DelphiDoom.Wad.Intf,
  DelphiDoom.Udmf.Namespaces;

const
  // the lumps after the label of the map where BEHAVIOR and SCRIPTS are looked for
  MAX_LUMP_CHECK = 10;
  TEXTMAP_LUMP_NAME = 'TEXTMAP';
  ENDMAP_LUMP_NAME = 'ENDMAP';
  BEHAVIOR_LUMP_NAME = 'BEHAVIOR';

resourcestring
  SRecordSizeMismatch = 'TEngineUdmfMapLoader.Create(): the %s of the engine is %d bytes, the one of the UDMF library %d';

{ TEngineUdmfMapLoader }

constructor TEngineUdmfMapLoader.Create(const AConverter: IUdmfConverter;
  const AWadServices: IEngineWadServices; const ASectors, ALines, ASides, ASegs: IUdmfMapPartApplier;
  const ASaveFileNames: ISaveFileNames);
begin
  inherited Create;
  if not Assigned(ASaveFileNames) then
    raise EArgumentNilException.Create('ASaveFileNames');
  if not Assigned(AConverter) then
    raise EArgumentNilException.Create('AConverter');
  if not Assigned(AWadServices) then
    raise EArgumentNilException.Create('AWadServices');
  if not Assigned(ASectors) then
    raise EArgumentNilException.Create('ASectors');
  if not Assigned(ALines) then
    raise EArgumentNilException.Create('ALines');
  if not Assigned(ASides) then
    raise EArgumentNilException.Create('ASides');
  if not Assigned(ASegs) then
    raise EArgumentNilException.Create('ASegs');

  CheckRecordSize('record of a thing', SizeOf(mapthing_t), AConverter.Profile.Things.BaseSize);
  CheckRecordSize('extra record of a thing', SizeOf(extrathing_t), AConverter.Profile.Things.ExtraSize);
  CheckRecordSize('record of a line', SizeOf(maplinedef_t), AConverter.Profile.Lines.BaseSize);
  CheckRecordSize('extra record of a line', SizeOf(extraline_t), AConverter.Profile.Lines.ExtraSize);
  CheckRecordSize('record of a side', SizeOf(mapsidedef_t), AConverter.Profile.Sides.BaseSize);
  CheckRecordSize('extra record of a side', SizeOf(extraside_t), AConverter.Profile.Sides.ExtraSize);
  CheckRecordSize('record of a vertex', SizeOf(mapvertex_t), AConverter.Profile.Vertexes.BaseSize);
  CheckRecordSize('extra record of a vertex', SizeOf(extravertex_t), AConverter.Profile.Vertexes.ExtraSize);
  CheckRecordSize('record of a sector', SizeOf(mapsector_t), AConverter.Profile.Sectors.BaseSize);
  CheckRecordSize('extra record of a sector', SizeOf(extrasector_t), AConverter.Profile.Sectors.ExtraSize);

  FConverter := AConverter;
  FWadServices := AWadServices;
  FSectors := ASectors;
  FLines := ALines;
  FSides := ASides;
  FSegs := ASegs;
  FSaveFileNames := ASaveFileNames;
end;

class procedure TEngineUdmfMapLoader.CheckRecordSize(const AWhat: string; AEngineSize,
  ALibrarySize: Integer);
begin
  if AEngineSize <> ALibrarySize then
    I_Error(SRecordSizeMismatch, [AWhat, AEngineSize, ALibrarySize]);
end;

class function TEngineUdmfMapLoader.LumpIsNamed(ALump: Integer; const AName: string): Boolean;
begin
  Result := strupper(char8tostring(W_GetNameForNum(ALump))) = AName;
end;

class function TEngineUdmfMapLoader.LumpToBytes(ALump: Integer): TBytes;
var
  LData: PByteArray;
  LLength: Integer;
begin
  // none if it is not a lump
  Result := nil;
  if ALump > 0 then
  begin
    LData := W_CacheLumpNum(ALump, PU_STATIC);
    LLength := W_LumpLength(ALump);
    SetLength(Result, LLength);
    if LLength > 0 then
      memcpy(@Result[0], LData, LLength);
    Z_Free(LData);
  end;
end;

class function TEngineUdmfMapLoader.ExtraToMemory(const AData: TBytes): Pointer;
begin
  // the extra records live as long as the level
  Result := Z_Malloc(Length(AData), PU_LEVEL, nil);
  memcpy(Result, @AData[0], Length(AData));
end;

procedure TEngineUdmfMapLoader.ClearExtraData;
begin
  hasudmfdata := False;
  udmfnamespace := '';
  udmflinetranslate := False;
  udmfthings := nil;
  numudmfthings := 0;
  udmfsectors := nil;
  numudmfsectors := 0;
  udmfvertexes := nil;
  numudmfvertexes := 0;
  udmflinedefs := nil;
  numudmflinedefs := 0;
end;

procedure TEngineUdmfMapLoader.ReadExtraLumps(AMapLump: Integer);
begin
  if AMapLump + ML_THINGS2 < W_NumLumps then
    if LumpIsNamed(AMapLump + ML_THINGS2, MLN_THINGS2) then
    begin
      udmfthings := W_CacheLumpNum(AMapLump + ML_THINGS2, PU_LEVEL);
      numudmfthings := W_LumpLength(AMapLump + ML_THINGS2) div SizeOf(extrathing_t);
    end;
  if AMapLump + ML_SECTORS2 < W_NumLumps then
    if LumpIsNamed(AMapLump + ML_SECTORS2, MLN_SECTORS2) then
    begin
      udmfsectors := W_CacheLumpNum(AMapLump + ML_SECTORS2, PU_LEVEL);
      numudmfsectors := W_LumpLength(AMapLump + ML_SECTORS2) div SizeOf(extrasector_t);
    end;
  if AMapLump + ML_VERTEX2 < W_NumLumps then
    if LumpIsNamed(AMapLump + ML_VERTEX2, MLN_VERTEX2) then
    begin
      udmfvertexes := W_CacheLumpNum(AMapLump + ML_VERTEX2, PU_LEVEL);
      numudmfvertexes := W_LumpLength(AMapLump + ML_VERTEX2) div SizeOf(extravertex_t);
    end;
  if AMapLump + ML_LINEDEF2 < W_NumLumps then
    if LumpIsNamed(AMapLump + ML_LINEDEF2, MLN_LINEDEF2) then
    begin
      udmflinedefs := W_CacheLumpNum(AMapLump + ML_LINEDEF2, PU_LEVEL);
      numudmflinedefs := W_LumpLength(AMapLump + ML_LINEDEF2) div SizeOf(extraline_t);
    end;
  if AMapLump + ML_SIDEDEF2 < W_NumLumps then
    if LumpIsNamed(AMapLump + ML_SIDEDEF2, MLN_SIDEDEF2) then
    begin
      udmfsidedefs := W_CacheLumpNum(AMapLump + ML_SIDEDEF2, PU_LEVEL);
      numudmfsidedefs := W_LumpLength(AMapLump + ML_SIDEDEF2) div SizeOf(extraside_t);
    end;
  if AMapLump + ML_NSPACE < W_NumLumps then
    if LumpIsNamed(AMapLump + ML_NSPACE, MLN_NSPACE) then
    begin
      udmfnamespace := W_TextLumpNum(AMapLump + ML_NSPACE);
      udmflinetranslate := TUdmfNamespaces.TranslatesLines(udmfnamespace, _GAME);
    end;
  hasudmfdata := (numudmfthings <> 0) and (numudmfsectors <> 0) and (numudmfvertexes <> 0) and
    (numudmflinedefs <> 0) and (numudmfsidedefs <> 0);
end;

function TEngineUdmfMapLoader.FindLumpOfMap(AMapLump: Integer; const AName: string): Integer;
var
  LLump: Integer;
begin
  Result := -1;
  for LLump := AMapLump + 1 to AMapLump + MAX_LUMP_CHECK do
  begin
    if LLump >= W_NumLumps then
      Break;
    if LumpIsNamed(LLump, ENDMAP_LUMP_NAME) then
      Break;
    if LumpIsNamed(LLump, AName) then
      Exit(LLump);
  end;
end;

function TEngineUdmfMapLoader.FindScriptLump(AMapLump: Integer): Integer;
var
  LLump: Integer;
begin
  Result := -1;
  for LLump := AMapLump + 1 to AMapLump + MAX_LUMP_CHECK do
  begin
    if LLump >= W_NumLumps then
      Break;
    if LumpIsNamed(LLump, ENDMAP_LUMP_NAME) then
      Break;
    if acc_isscriptlump(LLump) then
      Exit(LLump);
  end;
end;

procedure TEngineUdmfMapLoader.StoreExtraRecords(const AConverted: IUdmfConvertedMap);
begin
  numudmfthings := AConverted.ThingCount;
  if numudmfthings > 0 then
    udmfthings := ExtraToMemory(AConverted.ExtraThings);

  numudmfsectors := AConverted.SectorCount;
  if numudmfsectors > 0 then
    udmfsectors := ExtraToMemory(AConverted.ExtraSectors);

  numudmfvertexes := AConverted.VertexCount;
  if numudmfvertexes > 0 then
    udmfvertexes := ExtraToMemory(AConverted.ExtraVertexes);

  numudmflinedefs := AConverted.LineCount;
  if numudmflinedefs > 0 then
    udmflinedefs := ExtraToMemory(AConverted.ExtraLines);

  numudmfsidedefs := AConverted.SideCount;
  if numudmfsidedefs > 0 then
    udmfsidedefs := ExtraToMemory(AConverted.ExtraSides);
end;

procedure TEngineUdmfMapLoader.SaveToVanilla(const AConverted: IUdmfConvertedMap;
  const AMapName, AFileName: string; ABehaviorLump, AScriptLump: Integer);
var
  LBuilder: IWadBuilder;
  LLumps: TArray<TUdmfLump>;
  LIndex: Integer;
begin
  // the lumps of a vanilla map, then the extra ones
  LLumps := AConverted.GetLumps(AMapName, LumpToBytes(ABehaviorLump), LumpToBytes(AScriptLump));
  LBuilder := FWadServices.CreateBuilder(TWadKind.PWad);
  for LIndex := 0 to Length(LLumps) - 1 do
    LBuilder.AddLump(LLumps[LIndex].Name, LLumps[LIndex].Data);
  LBuilder.SaveToFile(AFileName);
end;

function TEngineUdmfMapLoader.Prepare(const AMapName: string): Boolean;
var
  LConverted: IUdmfConvertedMap;
  LMapLump: Integer;
  LTextLump: Integer;
  LWadFileName: string;
  LBehaviorLump: Integer;
  LScriptLump: Integer;
begin
  ClearExtraData;

  LMapLump := W_GetNumForName(AMapName);
  if (LMapLump < 0) or (LMapLump >= W_NumLumps - 1) then
    Exit(False);

  if not LumpIsNamed(LMapLump + 1, TEXTMAP_LUMP_NAME) then
  begin
    ReadExtraLumps(LMapLump);
    Exit(False);
  end;

  LBehaviorLump := FindLumpOfMap(LMapLump, BEHAVIOR_LUMP_NAME);
  LScriptLump := FindScriptLump(LMapLump);

  LTextLump := LMapLump + 1;
  LWadFileName := FSaveFileNames.ResolveName('DATA\');
  MkDir(LWadFileName);
  LWadFileName := LWadFileName + 'WADS\';
  MkDir(LWadFileName);
  LWadFileName := LWadFileName + AMapName + '_' + W_LumpCRC32(LTextLump) + '.wad';

  LConverted := FConverter.Convert(W_TextLumpNum(LTextLump));
  StoreExtraRecords(LConverted);
  SaveToVanilla(LConverted, AMapName, LWadFileName, LBehaviorLump, LScriptLump);
  udmfnamespace := LConverted.Namespace;
  udmflinetranslate := TUdmfNamespaces.TranslatesLines(udmfnamespace, _GAME);

  W_RuntimeLoad(LWadFileName, F_ORIGIN_WAD);

  hasudmfdata := True;
  Result := True;
end;

function TEngineUdmfMapLoader.ApplySides: Boolean;
begin
  Result := FSides.Apply;
end;

function TEngineUdmfMapLoader.ApplyLines: Boolean;
begin
  Result := FLines.Apply;
end;

function TEngineUdmfMapLoader.ApplySegs: Boolean;
begin
  Result := FSegs.Apply;
end;

function TEngineUdmfMapLoader.ApplySectors: Boolean;
begin
  Result := FSectors.Apply;
end;

end.
