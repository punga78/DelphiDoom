{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixContainer                                 }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{  Copyright (C) 1995 by Epic MegaGames, Inc. (Radix - beyond the void)        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of ReadHeader, ReadDirectory, ReadLump and FindLump of                 }
{  radix_xlat_wad.pas                                                          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.Container;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  DelphiDoom.Radix.Types, DelphiDoom.Radix.Intf;

type
  /// <summary>
  ///   Reads RADIX.DAT: a header with the signature "NSRes:Radix", the number of lumps and the
  ///   position of the directory; every entry has a name of up to 32 characters, a position and a
  ///   length
  /// </summary>
  TRadixContainer = class(TInterfacedObject, IRadixContainer)
  strict private
    FStream: TStream;
    FOwnsStream: Boolean;
    FLumps: TArray<TRadixLumpInfo>;
    FIndexes: TDictionary<string, Integer>;
    procedure ReadDirectory;
    class function NameOf(const AName: array of AnsiChar): string; static;
  public
    /// <param name="AStream">The container; ERadixException when it is not a Radix one</param>
    /// <param name="AOwnsStream">True when the object frees the stream</param>
    constructor Create(const AStream: TStream; AOwnsStream: Boolean);
    destructor Destroy; override;
    function GetCount: Integer;
    function GetInfo(AIndex: Integer): TRadixLumpInfo;
    function IndexOf(const AName: string): Integer;
    function Read(AIndex: Integer): TBytes;
    function TryRead(const AName: string; out ABytes: TBytes): Boolean;
    function ReadAt(APosition, ASize: Integer): TBytes;
    /// <summary>The name of a record of the container: the bytes up to the first zero</summary>
    class function ReadName(const AName: array of AnsiChar): string; static;
  end;

implementation

{ TRadixContainer }

constructor TRadixContainer.Create(const AStream: TStream; AOwnsStream: Boolean);
begin
  inherited Create;
  if not Assigned(AStream) then
    raise EArgumentNilException.Create('AStream');
  FStream := AStream;
  FOwnsStream := AOwnsStream;
  FIndexes := TDictionary<string, Integer>.Create;
  ReadDirectory;
end;

destructor TRadixContainer.Destroy;
begin
  FIndexes.Free;
  if FOwnsStream then
    FStream.Free;
  inherited Destroy;
end;

class function TRadixContainer.NameOf(const AName: array of AnsiChar): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to High(AName) do
  begin
    if AName[LIndex] = #0 then
      Break;
    Result := Result + Char(Byte(AName[LIndex]));
  end;
end;

class function TRadixContainer.ReadName(const AName: array of AnsiChar): string;
begin
  Result := NameOf(AName);
end;

procedure TRadixContainer.ReadDirectory;
var
  LHeader: TRadixHeaderRecord;
  LRecords: TArray<TRadixLumpRecord>;
  LIndex: Integer;
  LName: string;
begin
  if FStream.Size < SizeOf(TRadixHeaderRecord) then
    raise ERadixException.Create(SRadixNotContainer);
  FStream.Position := 0;
  FStream.ReadBuffer(LHeader, SizeOf(TRadixHeaderRecord));
  if NameOf(LHeader.Id) <> RADIX_SIGNATURE then
    raise ERadixException.Create(SRadixNotContainer);
  if (LHeader.NumLumps < 0) or (LHeader.Start < 0) or
    (Int64(LHeader.Start) + Int64(LHeader.NumLumps) * SizeOf(TRadixLumpRecord) > FStream.Size) then
    raise ERadixException.CreateFmt(SRadixBadDirectory, [LHeader.NumLumps, LHeader.Start]);

  SetLength(LRecords, LHeader.NumLumps);
  if LHeader.NumLumps > 0 then
  begin
    FStream.Position := LHeader.Start;
    FStream.ReadBuffer(LRecords[0], LHeader.NumLumps * SizeOf(TRadixLumpRecord));
  end;
  SetLength(FLumps, LHeader.NumLumps);
  for LIndex := 0 to LHeader.NumLumps - 1 do
  begin
    LName := NameOf(LRecords[LIndex].Name);
    FLumps[LIndex].Name := LName;
    FLumps[LIndex].Position := LRecords[LIndex].Position;
    FLumps[LIndex].Length := LRecords[LIndex].Length;
    // the first lump with a name is the one that is found
    if not FIndexes.ContainsKey(LName) then
      FIndexes.Add(LName, LIndex);
  end;
end;

function TRadixContainer.GetCount: Integer;
begin
  Result := Length(FLumps);
end;

function TRadixContainer.GetInfo(AIndex: Integer): TRadixLumpInfo;
begin
  Result := FLumps[AIndex];
end;

function TRadixContainer.IndexOf(const AName: string): Integer;
begin
  if not FIndexes.TryGetValue(AName, Result) then
    Result := -1;
end;

function TRadixContainer.ReadAt(APosition, ASize: Integer): TBytes;
begin
  if (APosition < 0) or (ASize < 0) or (Int64(APosition) + ASize > FStream.Size) then
    raise ERadixException.CreateFmt(SRadixBadLump, [IntToStr(APosition)]);
  SetLength(Result, ASize);
  if ASize > 0 then
  begin
    FStream.Position := APosition;
    FStream.ReadBuffer(Result[0], ASize);
  end;
end;

function TRadixContainer.Read(AIndex: Integer): TBytes;
begin
  if (AIndex < 0) or (AIndex >= Length(FLumps)) then
    raise ERadixException.CreateFmt(SRadixBadLump, [IntToStr(AIndex)]);
  try
    Result := ReadAt(FLumps[AIndex].Position, FLumps[AIndex].Length);
  except
    on ERadixException do
      raise ERadixException.CreateFmt(SRadixBadLump, [FLumps[AIndex].Name]);
  end;
end;

function TRadixContainer.TryRead(const AName: string; out ABytes: TBytes): Boolean;
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
