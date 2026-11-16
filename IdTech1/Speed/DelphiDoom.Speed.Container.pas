{******************************************************************************}
{                                                                              }
{  DelphiDoom: speed library - TSpeedContainer                                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Copyright (C) 1995 by Noriaworks (Speed Haste)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of ReadHeader and ReadDirectory of speed_xlat_wad.pas                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.Container;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  DelphiDoom.Speed.Types, DelphiDoom.Speed.Intf;

type
  /// <summary>
  ///   Reads the container SPEEDH.JCL: the header is the last 16 bytes of the file, the directory
  ///   is before it and every file is stored at a distance from the start of the directory
  ///   (the container is written back to front)
  /// </summary>
  TSpeedContainer = class(TInterfacedObject, ISpeedContainer)
  strict private
    FStream: TStream;
    FOwnsStream: Boolean;
    FSize: Integer;
    FEntries: TArray<TSpeedContainerEntry>;
    FIndexes: TDictionary<string, Integer>;
    procedure ReadDirectory;
    procedure Sort;
    function NameOf(const ARecord: TSpeedJclEntryRecord): string;
  public
    /// <param name="AStream">The container; ESpeedException when it is not a JCL one</param>
    /// <param name="AOwnsStream">True when the object frees the stream</param>
    constructor Create(const AStream: TStream; AOwnsStream: Boolean);
    destructor Destroy; override;
    function GetCount: Integer;
    function GetEntry(AIndex: Integer): TSpeedContainerEntry;
    function GetSize: Integer;
    function IndexOf(const AName: string): Integer;
    function Read(AIndex: Integer): TBytes;
    function ReadAtLeast(AIndex, AMinimumSize: Integer): TBytes;
    function TryRead(const AName: string; out ABytes: TBytes): Boolean;
  end;

implementation

uses
  DelphiDoom.Speed.Names;

{ TSpeedContainer }

constructor TSpeedContainer.Create(const AStream: TStream; AOwnsStream: Boolean);
begin
  inherited Create;
  if not Assigned(AStream) then
    raise EArgumentNilException.Create('AStream');
  FStream := AStream;
  FOwnsStream := AOwnsStream;
  FIndexes := TDictionary<string, Integer>.Create;
  // when the directory is not good the destructor frees what is there
  ReadDirectory;
end;

destructor TSpeedContainer.Destroy;
begin
  FIndexes.Free;
  if FOwnsStream then
    FStream.Free;
  inherited Destroy;
end;

function TSpeedContainer.NameOf(const ARecord: TSpeedJclEntryRecord): string;
var
  LIndex: Integer;
begin
  Result := '';
  // one character for every byte (Latin-1), up to the first #0
  for LIndex := Low(ARecord.FileName) to High(ARecord.FileName) do
  begin
    if ARecord.FileName[LIndex] = #0 then
      Break;
    Result := Result + Char(Byte(ARecord.FileName[LIndex]));
  end;
  Result := Trim(Result);
end;

procedure TSpeedContainer.ReadDirectory;
var
  LHeader: TSpeedJclHeader;
  LRecords: TArray<TSpeedJclEntryRecord>;
  LDirectory: Int64;
  LIndex: Integer;
begin
  if FStream.Size > High(Integer) then
    raise ESpeedException.Create(SSpeedBadHeader);
  FSize := FStream.Size;
  if FSize < SizeOf(TSpeedJclHeader) then
    raise ESpeedException.Create(SSpeedBadHeader);
  FStream.Position := FSize - SizeOf(TSpeedJclHeader);
  FStream.ReadBuffer(LHeader, SizeOf(LHeader));
  if (LHeader.Magic <> SPEED_JCL_MAGIC) or (LHeader.Count < 0) then
    raise ESpeedException.Create(SSpeedBadHeader);
  LDirectory := Int64(FSize) - LHeader.DirectoryOffset;
  if (LHeader.DirectoryOffset < 0) or (LDirectory < 0) or
    (LDirectory + Int64(LHeader.Count) * SizeOf(TSpeedJclEntryRecord) > FSize) then
    raise ESpeedException.Create(SSpeedBadDirectory);
  SetLength(LRecords, LHeader.Count);
  SetLength(FEntries, LHeader.Count);
  if LHeader.Count > 0 then
  begin
    FStream.Position := LDirectory;
    FStream.ReadBuffer(LRecords[0], LHeader.Count * SizeOf(TSpeedJclEntryRecord));
  end;
  for LIndex := 0 to LHeader.Count - 1 do
  begin
    FEntries[LIndex].Name := NameOf(LRecords[LIndex]);
    // the start of a file is a distance back from the start of the directory
    FEntries[LIndex].Position := Integer(LDirectory - LRecords[LIndex].Start);
    FEntries[LIndex].Size := LRecords[LIndex].Size;
    // out of the file: kept as it is, Read refuses it
    if (LDirectory - LRecords[LIndex].Start < Low(Integer)) or
      (LDirectory - LRecords[LIndex].Start > High(Integer)) then
      FEntries[LIndex].Position := -1;
  end;
  Sort;
  for LIndex := 0 to High(FEntries) do
    if not FIndexes.ContainsKey(FEntries[LIndex].Name) then
      FIndexes.Add(FEntries[LIndex].Name, LIndex);
end;

procedure TSpeedContainer.Sort;
var
  LIndex: Integer;
  LInner: Integer;
  LItem: TSpeedContainerEntry;
begin
  // an insertion sort is stable, as the bubble sort of the old code was
  for LIndex := 1 to High(FEntries) do
  begin
    LItem := FEntries[LIndex];
    LInner := LIndex - 1;
    while (LInner >= 0) and (TSpeedNames.Compare(FEntries[LInner].Name, LItem.Name) > 0) do
    begin
      FEntries[LInner + 1] := FEntries[LInner];
      Dec(LInner);
    end;
    FEntries[LInner + 1] := LItem;
  end;
end;

function TSpeedContainer.GetCount: Integer;
begin
  Result := Length(FEntries);
end;

function TSpeedContainer.GetEntry(AIndex: Integer): TSpeedContainerEntry;
begin
  if (AIndex < 0) or (AIndex > High(FEntries)) then
    raise ESpeedException.CreateFmt(SSpeedBadIndex, [AIndex]);
  Result := FEntries[AIndex];
end;

function TSpeedContainer.GetSize: Integer;
begin
  Result := FSize;
end;

function TSpeedContainer.IndexOf(const AName: string): Integer;
begin
  if not FIndexes.TryGetValue(AName, Result) then
    Result := -1;
end;

function TSpeedContainer.Read(AIndex: Integer): TBytes;
var
  LEntry: TSpeedContainerEntry;
begin
  LEntry := GetEntry(AIndex);
  if (LEntry.Position < 0) or (LEntry.Size < 0) or
    (Int64(LEntry.Position) + LEntry.Size > FSize) then
    raise ESpeedException.CreateFmt(SSpeedBadEntry, [LEntry.Name]);
  SetLength(Result, LEntry.Size);
  if LEntry.Size > 0 then
  begin
    FStream.Position := LEntry.Position;
    FStream.ReadBuffer(Result[0], LEntry.Size);
  end;
end;

function TSpeedContainer.ReadAtLeast(AIndex, AMinimumSize: Integer): TBytes;
var
  LEntry: TSpeedContainerEntry;
  LCount: Integer;
begin
  LEntry := GetEntry(AIndex);
  if (LEntry.Position < 0) or (LEntry.Size < 0) or (Int64(LEntry.Position) + LEntry.Size > FSize) then
    raise ESpeedException.CreateFmt(SSpeedBadEntry, [LEntry.Name]);
  LCount := LEntry.Size;
  if (AMinimumSize > LCount) and (Int64(LEntry.Position) + AMinimumSize <= FSize) then
    LCount := AMinimumSize;
  SetLength(Result, LCount);
  if LCount > 0 then
  begin
    FStream.Position := LEntry.Position;
    FStream.ReadBuffer(Result[0], LCount);
  end;
end;

function TSpeedContainer.TryRead(const AName: string; out ABytes: TBytes): Boolean;
var
  LIndex: Integer;
begin
  LIndex := IndexOf(AName);
  Result := LIndex >= 0;
  if Result then
    ABytes := Read(LIndex)
  else
    ABytes := nil;
end;

end.
