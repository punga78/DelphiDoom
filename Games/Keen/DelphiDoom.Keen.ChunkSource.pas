{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - a file of Huffman chunks (graphics, audio)        }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  CA_CacheGrChunk, CAL_ReadGrChunk, CA_CacheAudioChunk of id_ca.c              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.ChunkSource;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

const
  /// <summary>The largest chunk the code accepts once expanded: a larger length is a corrupted file</summary>
  KEEN_MAX_CHUNK_BYTES = 16 * 1024 * 1024;

type
  /// <summary>
  ///   The chunks of KDREAMS.EGA or KDREAMS.AUD: the offsets say where each chunk is, the layout says
  ///   whether the chunk starts with its expanded length, the Huffman dictionary expands it. A chunk
  ///   with no bytes (offset -1 in the graphics, two equal offsets in the audio) reads as an empty array
  /// </summary>
  TKeenChunkSource = class(TInterfacedObject, IKeenChunkSource)
  strict private
    FOffsets: IKeenOffsetTable;
    FHuffman: IKeenHuffman;
    FLayout: IKeenChunkLayout;
    FStream: TStream;
  public
    /// <param name="AStream">The data file; the chunk source owns it and frees it</param>
    constructor Create(const AOffsets: IKeenOffsetTable; const AHuffman: IKeenHuffman;
      const ALayout: IKeenChunkLayout; AStream: TStream);
    destructor Destroy; override;
    function GetChunkCount: Integer;
    function HasChunk(AIndex: Integer): Boolean;
    function ReadCompressed(AIndex: Integer): TBytes;
    function Read(AIndex: Integer): TBytes;
  end;

implementation

uses
  DelphiDoom.Keen.LittleEndian;

{ TKeenChunkSource }

constructor TKeenChunkSource.Create(const AOffsets: IKeenOffsetTable;
  const AHuffman: IKeenHuffman; const ALayout: IKeenChunkLayout; AStream: TStream);
begin
  inherited Create;
  if not Assigned(AOffsets) then
    raise EArgumentNilException.Create('AOffsets');
  if not Assigned(AHuffman) then
    raise EArgumentNilException.Create('AHuffman');
  if not Assigned(ALayout) then
    raise EArgumentNilException.Create('ALayout');
  if not Assigned(AStream) then
    raise EArgumentNilException.Create('AStream');
  FOffsets := AOffsets;
  FHuffman := AHuffman;
  FLayout := ALayout;
  FStream := AStream;
end;

destructor TKeenChunkSource.Destroy;
begin
  FStream.Free;
  inherited Destroy;
end;

function TKeenChunkSource.GetChunkCount: Integer;
begin
  Result := FOffsets.Count - 1;
end;

function TKeenChunkSource.HasChunk(AIndex: Integer): Boolean;
begin
  if (AIndex < 0) or (AIndex >= GetChunkCount) then
    raise EKeenDataException.CreateFmt(SKeenChunkInvalid, [AIndex, GetChunkCount]);
  Result := (not FOffsets.IsSparse(AIndex)) and (FOffsets.EndOf(AIndex) > FOffsets[AIndex]);
end;

function TKeenChunkSource.ReadCompressed(AIndex: Integer): TBytes;
var
  LStart: Integer;
  LEnd: Integer;
begin
  if not HasChunk(AIndex) then
    Exit(nil);
  LStart := FOffsets[AIndex];
  LEnd := FOffsets.EndOf(AIndex);
  if LEnd > FStream.Size then
  begin
    if not FLayout.IsLenient(AIndex) then
      raise EKeenDataException.CreateFmt(SKeenChunkOffsets, [AIndex, LStart, LEnd, FStream.Size]);
    // a short read: what the file has of the chunk
    LEnd := Integer(FStream.Size);
    if LEnd <= LStart then
      Exit(nil);
  end;
  if LStart < 0 then
    raise EKeenDataException.CreateFmt(SKeenChunkOffsets, [AIndex, LStart, LEnd, FStream.Size]);
  SetLength(Result, LEnd - LStart);
  FStream.Position := LStart;
  FStream.ReadBuffer(Result[0], Length(Result));
end;

function TKeenChunkSource.Read(AIndex: Integer): TBytes;
var
  LCompressed: TBytes;
  LExpanded: Integer;
  LStart: Integer;
begin
  LCompressed := ReadCompressed(AIndex);
  if Length(LCompressed) = 0 then
    Exit(nil);
  LExpanded := FLayout.ImplicitLength(AIndex);
  LStart := 0;
  if LExpanded < 0 then
  begin
    LExpanded := TKeenLittleEndian.ReadInt32(LCompressed, 0);
    LStart := 4;
  end;
  if (LExpanded < 0) or (LExpanded > KEEN_MAX_CHUNK_BYTES) then
    raise EKeenDataException.CreateFmt(SKeenLengthInvalid, [LExpanded]);
  if FLayout.IsLenient(AIndex) then
    Result := FHuffman.ExpandAvailable(LCompressed, LStart, LExpanded)
  else
    Result := FHuffman.Expand(LCompressed, LStart, LExpanded);
end;

end.
