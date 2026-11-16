{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the offsets at the start of a file of chunks      }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.OffsetTable;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   EGAHEAD.KDR (grstarts: 3017 long) and AUDIOHHD.KDR (audiostarts: 85 long): where every chunk starts
  ///   in the data file, and in the last entry where the file ends. -1 is a chunk with no data
  ///   (a sparse tile); the next chunk of the file that is there gives the end of a chunk
  /// </summary>
  TKeenOffsetTable = class(TInterfacedObject, IKeenOffsetTable)
  strict private
    FOffsets: TArray<Integer>;
  public
    /// <param name="ABytes">The file; its length must be a multiple of 4 (what is left over is ignored) and at least 8</param>
    /// <param name="AName">The name of the file, for the messages</param>
    constructor Create(const ABytes: TBytes; const AName: string);
    function GetCount: Integer;
    function GetOffset(AIndex: Integer): Integer;
    function IsSparse(AIndex: Integer): Boolean;
    function EndOf(AIndex: Integer): Integer;
  end;

implementation

uses
  DelphiDoom.Keen.LittleEndian;

{ TKeenOffsetTable }

constructor TKeenOffsetTable.Create(const ABytes: TBytes; const AName: string);
var
  LIndex: Integer;
begin
  inherited Create;
  if Length(ABytes) < 8 then
    raise EKeenDataException.CreateFmt(SKeenHeaderInvalid, [AName, Length(ABytes), 8]);
  SetLength(FOffsets, Length(ABytes) div 4);
  for LIndex := 0 to High(FOffsets) do
    FOffsets[LIndex] := TKeenLittleEndian.ReadInt32(ABytes, LIndex * 4);
end;

function TKeenOffsetTable.GetCount: Integer;
begin
  Result := Length(FOffsets);
end;

function TKeenOffsetTable.GetOffset(AIndex: Integer): Integer;
begin
  if (AIndex < 0) or (AIndex >= Length(FOffsets)) then
    raise EKeenDataException.CreateFmt(SKeenChunkInvalid, [AIndex, Length(FOffsets) - 1]);
  Result := FOffsets[AIndex];
end;

function TKeenOffsetTable.IsSparse(AIndex: Integer): Boolean;
begin
  Result := GetOffset(AIndex) < 0;
end;

function TKeenOffsetTable.EndOf(AIndex: Integer): Integer;
var
  LNext: Integer;
begin
  GetOffset(AIndex);
  LNext := AIndex + 1;
  while (LNext < Length(FOffsets)) and (FOffsets[LNext] = -1) do
    Inc(LNext);
  if LNext >= Length(FOffsets) then
    raise EKeenDataException.CreateFmt(SKeenChunkNoEnd, [AIndex]);
  Result := FOffsets[LNext];
end;

end.
