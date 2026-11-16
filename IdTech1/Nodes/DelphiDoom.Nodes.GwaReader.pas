{******************************************************************************}
{                                                                              }
{  DelphiDoom: Nodes library - reader of a standalone GWA                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Nodes.GwaReader;

interface

uses
  System.SysUtils, DelphiDoom.Nodes.Intf;

type
  /// <summary>
  ///   Reads a GWA, the WAD that glBSP writes with only the GL lumps (a label, GL_VERT, GL_SEGS,
  ///   GL_SSECT, GL_NODES). The version of the nodes comes from the magic numbers of GL_VERT and
  ///   GL_SEGS; the records are those of TNodesGlParser
  /// </summary>
  TNodesGwaReader = class sealed
  public
    /// <summary>Reads the nodes from the bytes of the file</summary>
    /// <exception cref="ENodesException">The file is not a WAD with 1 to 10 lumps, or a lump is outside it</exception>
    class function Read(const ABytes: TBytes): INodesGwa; static;
  end;

implementation

uses
  DelphiDoom.Nodes.Types, DelphiDoom.Nodes.Gwa, DelphiDoom.Nodes.GlParser;

const
  SGwaTooShort = 'The GWA has %d bytes: too short for a WAD';
  SGwaBadLumpCount = 'The standalone GWA has %d lumps';
  SGwaBadDirectory = 'The directory of the GWA is outside the file';
  SGwaBadLump = 'The lump %s of the GWA is outside the file';

function EntryName(const AEntry: TNodesWadEntry): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to NODES_LUMP_NAME_LENGTH - 1 do
  begin
    if AEntry.Name[LIndex] = #0 then
      Break;
    Result := Result + Char(AEntry.Name[LIndex]);
  end;
end;

function LumpBytes(const ABytes: TBytes; const AEntry: TNodesWadEntry): TBytes;
begin
  if (AEntry.Position < 0) or (AEntry.Size < 0) or
     (Int64(AEntry.Position) + AEntry.Size > Length(ABytes)) then
    raise ENodesException.CreateFmt(SGwaBadLump, [EntryName(AEntry)]);
  SetLength(Result, AEntry.Size);
  if AEntry.Size > 0 then
    Move(ABytes[AEntry.Position], Result[0], AEntry.Size);
end;

function MagicOf(const ABytes: TBytes; const AEntry: TNodesWadEntry): Cardinal;
begin
  // a lump with less than four bytes has no magic number
  Result := 0;
  if (AEntry.Size >= SizeOf(Cardinal)) and (AEntry.Position >= 0) and
     (Int64(AEntry.Position) + SizeOf(Cardinal) <= Length(ABytes)) then
    Move(ABytes[AEntry.Position], Result, SizeOf(Result));
end;

class function TNodesGwaReader.Read(const ABytes: TBytes): INodesGwa;
var
  LHeader: TNodesWadHeader;
  LEntries: array of TNodesWadEntry;
  LIndex: Integer;
  LName: string;
  LMagic: Cardinal;
  LVersion: Integer;
  LGlVertexes: TArray<TNodesGlVertex>;
  LSubsectors: TArray<TNodesGlSubsector>;
  LNodes: TArray<TNodesGlNode>;
  LSegs: TArray<TNodesGlSeg>;
begin
  if Length(ABytes) < NODES_WAD_HEADER_SIZE then
    raise ENodesException.CreateFmt(SGwaTooShort, [Length(ABytes)]);
  Move(ABytes[0], LHeader, SizeOf(LHeader));
  if (LHeader.LumpCount < 1) or (LHeader.LumpCount > NODES_GWA_MAX_LUMPS) then
    raise ENodesException.CreateFmt(SGwaBadLumpCount, [LHeader.LumpCount]);
  if (LHeader.DirectoryOffset < 0) or
     (Int64(LHeader.DirectoryOffset) + Int64(LHeader.LumpCount) * NODES_WAD_ENTRY_SIZE >
       Length(ABytes)) then
    raise ENodesException.Create(SGwaBadDirectory);

  SetLength(LEntries, LHeader.LumpCount);
  Move(ABytes[LHeader.DirectoryOffset], LEntries[0], LHeader.LumpCount * NODES_WAD_ENTRY_SIZE);

  // the magic numbers: GL_VERT gives the version, GL_SEGS can say V3 (in the order of the directory)
  LMagic := 0;
  for LIndex := 0 to High(LEntries) do
  begin
    LName := UpperCase(EntryName(LEntries[LIndex]));
    if LName = NODES_LUMP_GL_VERT then
      LMagic := MagicOf(ABytes, LEntries[LIndex])
    else if (LName = NODES_LUMP_GL_SEGS) and
            (MagicOf(ABytes, LEntries[LIndex]) = NODES_GL_MAGIC_V3) then
      LMagic := NODES_GL_MAGIC_V3;
  end;
  if LMagic = NODES_GL_MAGIC_V2 then
    LVersion := 2
  else if LMagic = NODES_GL_MAGIC_V3 then
    LVersion := 3
  else if LMagic = NODES_GL_MAGIC_V4 then
    LVersion := 4
  else if LMagic = NODES_GL_MAGIC_V5 then
    LVersion := 5
  else
    LVersion := 0;

  for LIndex := 0 to High(LEntries) do
  begin
    LName := UpperCase(EntryName(LEntries[LIndex]));
    if LName = NODES_LUMP_GL_VERT then
      LGlVertexes := TNodesGlParser.ParseVertexes(LumpBytes(ABytes, LEntries[LIndex]), LVersion)
    else if LName = NODES_LUMP_GL_SSECT then
      LSubsectors := TNodesGlParser.ParseSubsectors(LumpBytes(ABytes, LEntries[LIndex]), LVersion)
    else if LName = NODES_LUMP_GL_NODES then
      LNodes := TNodesGlParser.ParseNodes(LumpBytes(ABytes, LEntries[LIndex]), LVersion)
    else if LName = NODES_LUMP_GL_SEGS then
      LSegs := TNodesGlParser.ParseSegs(LumpBytes(ABytes, LEntries[LIndex]), LVersion);
  end;

  Result := TNodesGwa.Create(LVersion, LGlVertexes, LSubsectors, LNodes, LSegs);
end;

end.
