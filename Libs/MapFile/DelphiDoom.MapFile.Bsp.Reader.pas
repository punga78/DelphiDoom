{******************************************************************************}
{                                                                              }
{  DelphiDoom: map file library - the BSP of Quake III Arena: reading          }
{                                                                              }
{  Port of the checks of the header and of the lumps of CM_LoadMap             }
{  (cm_load.c) and RE_LoadWorldMap (tr_bsp.c). Based on the Quake III Arena    }
{  GPL Source Code (id Software). Copyright (C) 1999-2005 Id Software, Inc.    }
{  This unit is derived from the Quake III Arena source code and is therefore  }
{  available under the GNU General Public License, version 2 or (at your       }
{  option) any later version.                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapFile.Bsp.Reader;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.IdLib.Core.Intf, DelphiDoom.MapFile.Bsp.Intf;

type
  /// <summary>
  ///   Reads a .bsp file from bytes (or from a file system that the caller injects). The
  ///   checks are those of the engine: version, "funny lump size" (a length that is not a
  ///   multiple of the record), no shaders, models, nodes, leafs or planes, more than
  ///   MAX_SUBMODELS models. The original does not check the identifier, nor that a lump is
  ///   inside the file (it reads past the buffer) nor the size of the visibility header: here
  ///   they are errors. The rest is left to TBspValidator, which looks at the references.
  /// </summary>
  TBspReader = class(TInterfacedObject, IBspReader)
  strict private
    FFileSystem: IIdLibFileSystem;
    class procedure CheckRecordLump(const ALump, ARecordSize, AMinimum: Integer;
      const ALength: Integer; const AName, AMissing: string); static;
  public
    /// <summary>The file system is needed by Parse (not by ParseBytes)</summary>
    constructor Create(const AFileSystem: IIdLibFileSystem = nil);
    function Parse(const AFileName: AnsiString): IBspFile;
    function ParseBytes(const AData: TBytes; const AName: AnsiString): IBspFile;
  end;

implementation

uses
  DelphiDoom.MapFile.Bsp.BspFile, DelphiDoom.MapFile.Bsp.Types;

resourcestring
  SBspTruncated = 'LoadMap: %s is too short for a BSP header (%d bytes)';
  SBspBadIdent = 'LoadMap: %s is not a BSP file (identifier %.8x)';
  SBspBadVersion = 'LoadMap: %s has wrong version number (%d should be %d)';
  SBspLumpOutside = 'LoadMap: lump %d of %s is outside the file (offset %d, length %d, file %d bytes)';
  SBspFunnyLumpSize = 'LoadMap: funny lump size in %s (lump %d: length %d, record %d bytes)';
  SBspNoShaders = 'Map with no shaders';
  SBspNoModels = 'Map with no models';
  SBspNoNodes = 'Map has no nodes';
  SBspNoLeafs = 'Map with no leafs';
  SBspNoPlanes = 'Map with no planes';
  SBspTooManyModels = 'MAX_SUBMODELS exceeded';
  SBspVisibilityShort = 'LoadMap: visibility lump of %s is %d bytes long, the header needs 8';

{ TBspReader }

constructor TBspReader.Create(const AFileSystem: IIdLibFileSystem);
begin
  inherited Create;
  FFileSystem := AFileSystem;
end;

class procedure TBspReader.CheckRecordLump(const ALump, ARecordSize, AMinimum: Integer;
  const ALength: Integer; const AName, AMissing: string);
begin
  if ALength mod ARecordSize <> 0 then
    raise EBspFileException.CreateFmt(SBspFunnyLumpSize, [AName, ALump, ALength, ARecordSize]);
  if ALength div ARecordSize < AMinimum then
    raise EBspFileException.Create(AMissing);
end;

function TBspReader.Parse(const AFileName: AnsiString): IBspFile;
var
  LFile: TIdLibFileData;
begin
  if not Assigned(FFileSystem) or not FFileSystem.TryReadFile(AFileName, False, LFile) then
    Exit(nil);
  Result := ParseBytes(LFile.Data, AFileName);
end;

function TBspReader.ParseBytes(const AData: TBytes; const AName: AnsiString): IBspFile;
var
  LHeader: TBspHeader;
  LName: string;
  LData: array[0..HEADER_LUMPS - 1] of TBytes;
  LLump: TBspLump;
  LIndex: Integer;
begin
  LName := string(AName);
  if Length(AData) < SizeOf(TBspHeader) then
    raise EBspFileException.CreateFmt(SBspTruncated, [LName, Length(AData)]);
  Move(AData[0], LHeader, SizeOf(TBspHeader));
  if LHeader.Ident <> BSP_IDENT then
    raise EBspFileException.CreateFmt(SBspBadIdent, [LName, LHeader.Ident]);
  if LHeader.Version <> BSP_VERSION then
    raise EBspFileException.CreateFmt(SBspBadVersion, [LName, LHeader.Version, BSP_VERSION]);

  for LIndex := 0 to HEADER_LUMPS - 1 do
  begin
    LLump := LHeader.Lumps[LIndex];
    if (LLump.FileOfs < 0) or (LLump.FileLen < 0) or
       (Int64(LLump.FileOfs) + LLump.FileLen > Length(AData)) then
      raise EBspFileException.CreateFmt(SBspLumpOutside, [LIndex, LName, LLump.FileOfs, LLump.FileLen,
        Length(AData)]);
    SetLength(LData[LIndex], LLump.FileLen);
    if LLump.FileLen > 0 then
      Move(AData[LLump.FileOfs], LData[LIndex][0], LLump.FileLen);
  end;

  // the checks of CM_LoadMap and R_LoadSurfaces, in the order of the original
  CheckRecordLump(LUMP_SHADERS, SizeOf(TBspShader), 1, LHeader.Lumps[LUMP_SHADERS].FileLen, LName, SBspNoShaders);
  CheckRecordLump(LUMP_LEAFS, SizeOf(TBspLeaf), 1, LHeader.Lumps[LUMP_LEAFS].FileLen, LName, SBspNoLeafs);
  CheckRecordLump(LUMP_LEAFBRUSHES, SizeOf(Integer), 0, LHeader.Lumps[LUMP_LEAFBRUSHES].FileLen, LName, '');
  CheckRecordLump(LUMP_LEAFSURFACES, SizeOf(Integer), 0, LHeader.Lumps[LUMP_LEAFSURFACES].FileLen, LName, '');
  CheckRecordLump(LUMP_PLANES, SizeOf(TBspPlane), 1, LHeader.Lumps[LUMP_PLANES].FileLen, LName, SBspNoPlanes);
  CheckRecordLump(LUMP_BRUSHSIDES, SizeOf(TBspBrushSide), 0, LHeader.Lumps[LUMP_BRUSHSIDES].FileLen, LName, '');
  CheckRecordLump(LUMP_BRUSHES, SizeOf(TBspBrush), 0, LHeader.Lumps[LUMP_BRUSHES].FileLen, LName, '');
  CheckRecordLump(LUMP_MODELS, SizeOf(TBspModel), 1, LHeader.Lumps[LUMP_MODELS].FileLen, LName, SBspNoModels);
  if LHeader.Lumps[LUMP_MODELS].FileLen div SizeOf(TBspModel) > BSP_MAX_SUBMODELS then
    raise EBspFileException.Create(SBspTooManyModels);
  CheckRecordLump(LUMP_NODES, SizeOf(TBspNode), 1, LHeader.Lumps[LUMP_NODES].FileLen, LName, SBspNoNodes);
  CheckRecordLump(LUMP_SURFACES, SizeOf(TBspSurface), 0, LHeader.Lumps[LUMP_SURFACES].FileLen, LName, '');
  CheckRecordLump(LUMP_DRAWVERTS, SizeOf(TBspDrawVert), 0, LHeader.Lumps[LUMP_DRAWVERTS].FileLen, LName, '');
  CheckRecordLump(LUMP_DRAWINDEXES, SizeOf(Integer), 0, LHeader.Lumps[LUMP_DRAWINDEXES].FileLen, LName, '');
  CheckRecordLump(LUMP_FOGS, SizeOf(TBspFog), 0, LHeader.Lumps[LUMP_FOGS].FileLen, LName, '');
  LLump := LHeader.Lumps[LUMP_VISIBILITY];
  if (LLump.FileLen > 0) and (LLump.FileLen < 8) then
    raise EBspFileException.CreateFmt(SBspVisibilityShort, [LName, LLump.FileLen]);

  Result := TBspFile.Create(LHeader, LData);
end;

end.
