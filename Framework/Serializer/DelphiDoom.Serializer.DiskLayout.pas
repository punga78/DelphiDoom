{******************************************************************************}
{                                                                              }
{  DelphiDoom: serializer library - the layout on disk of a raw record         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Serializer.DiskLayout;

interface

uses
  DelphiDoom.Serializer.Intf,
  DelphiDoom.Serializer.Types;

type
  /// <summary>
  ///   A record of a saved game as a list of runs: where each run is in memory and where on disk. The
  ///   builder makes the list (TDiskLayoutBuilder); this class only moves the bytes. When the two layouts
  ///   are the same (a 32 bit program) the record is copied whole, padding included, as the engine always did
  /// </summary>
  TDiskLayout = class(TInterfacedObject, IDiskLayout)
  strict private
    FName: string;
    FNativeSize: Integer;
    FDiskSize: Integer;
    FSegments: TArray<TDiskLayoutSegment>;
    FFields: TArray<string>;
    FIdentity: Boolean;
    function FindIdentity: Boolean;
  public
    /// <summary>AFields are the lines that Describe tells after the first one</summary>
    constructor Create(const AName: string; ANativeSize, ADiskSize: Integer;
      const ASegments: TArray<TDiskLayoutSegment>; const AFields: TArray<string>);
    function GetName: string;
    function GetNativeSize: Integer;
    function GetDiskSize: Integer;
    procedure Pack(const ANative: Pointer; const ADisk: Pointer);
    procedure Unpack(const ADisk: Pointer; const ANative: Pointer);
    procedure UnpackPrefix(const ADisk: Pointer; const ANative: Pointer; ADiskBytes: Integer);
    function Describe: TArray<string>;
    /// <summary>True when memory and disk are the same bytes</summary>
    property Identity: Boolean read FIdentity;
  end;

implementation

uses
  System.SysUtils;

{ TDiskLayout }

constructor TDiskLayout.Create(const AName: string; ANativeSize, ADiskSize: Integer;
  const ASegments: TArray<TDiskLayoutSegment>; const AFields: TArray<string>);
begin
  inherited Create;
  FName := AName;
  FNativeSize := ANativeSize;
  FDiskSize := ADiskSize;
  FSegments := ASegments;
  FFields := AFields;
  FIdentity := FindIdentity;
end;

function TDiskLayout.FindIdentity: Boolean;
var
  LIndex: Integer;
  LPointerSize: Integer;
begin
  LPointerSize := SizeOf(Pointer);
  Result := (FNativeSize = FDiskSize) and (LPointerSize = SizeOf(Integer));
  for LIndex := 0 to High(FSegments) do
    if FSegments[LIndex].NativeOffset <> FSegments[LIndex].DiskOffset then
      Result := False;
end;

function TDiskLayout.GetName: string;
begin
  Result := FName;
end;

function TDiskLayout.GetNativeSize: Integer;
begin
  Result := FNativeSize;
end;

function TDiskLayout.GetDiskSize: Integer;
begin
  Result := FDiskSize;
end;

procedure TDiskLayout.Pack(const ANative: Pointer; const ADisk: Pointer);
var
  LIndex: Integer;
  LNative: PByte;
  LDisk: PByte;
begin
  if FIdentity then
  begin
    Move(ANative^, ADisk^, FDiskSize);
    Exit;
  end;
  // the padding of the layout on disk has no bytes of its own in memory
  FillChar(ADisk^, FDiskSize, 0);
  for LIndex := 0 to High(FSegments) do
  begin
    LNative := PByte(ANative) + FSegments[LIndex].NativeOffset;
    LDisk := PByte(ADisk) + FSegments[LIndex].DiskOffset;
    if FSegments[LIndex].Reference then
      PInteger(LDisk)^ := TSerializerNativeValue.ToDisk(PNativeInt(LNative)^)
    else
      Move(LNative^, LDisk^, FSegments[LIndex].Size);
  end;
end;

procedure TDiskLayout.Unpack(const ADisk: Pointer; const ANative: Pointer);
var
  LIndex: Integer;
  LNative: PByte;
  LDisk: PByte;
begin
  if FIdentity then
  begin
    Move(ADisk^, ANative^, FDiskSize);
    Exit;
  end;
  for LIndex := 0 to High(FSegments) do
  begin
    LNative := PByte(ANative) + FSegments[LIndex].NativeOffset;
    LDisk := PByte(ADisk) + FSegments[LIndex].DiskOffset;
    if FSegments[LIndex].Reference then
      PNativeInt(LNative)^ := TSerializerNativeValue.FromDisk(PInteger(LDisk)^)
    else
      Move(LDisk^, LNative^, FSegments[LIndex].Size);
  end;
end;

procedure TDiskLayout.UnpackPrefix(const ADisk: Pointer; const ANative: Pointer; ADiskBytes: Integer);
var
  LIndex: Integer;
  LNative: PByte;
  LDisk: PByte;
  LSize: Integer;
begin
  if ADiskBytes > FDiskSize then
    ADiskBytes := FDiskSize;
  if FIdentity then
  begin
    Move(ADisk^, ANative^, ADiskBytes);
    Exit;
  end;
  for LIndex := 0 to High(FSegments) do
  begin
    if FSegments[LIndex].DiskOffset >= ADiskBytes then
      Continue;
    LNative := PByte(ANative) + FSegments[LIndex].NativeOffset;
    LDisk := PByte(ADisk) + FSegments[LIndex].DiskOffset;
    if FSegments[LIndex].Reference then
    begin
      // a value cut in two by the end of the prefix is not read
      if FSegments[LIndex].DiskOffset + SizeOf(Integer) <= ADiskBytes then
        PNativeInt(LNative)^ := TSerializerNativeValue.FromDisk(PInteger(LDisk)^);
    end
    else
    begin
      LSize := FSegments[LIndex].Size;
      if FSegments[LIndex].DiskOffset + LSize > ADiskBytes then
        LSize := ADiskBytes - FSegments[LIndex].DiskOffset;
      Move(LDisk^, LNative^, LSize);
    end;
  end;
end;

function TDiskLayout.Describe: TArray<string>;
var
  LIndex: Integer;
  LReferences: string;
begin
  SetLength(Result, Length(FFields) + 2);
  Result[0] := Format('%s disk=%d', [FName, FDiskSize]);
  for LIndex := 0 to High(FFields) do
    Result[LIndex + 1] := '  ' + FFields[LIndex];
  LReferences := '';
  for LIndex := 0 to High(FSegments) do
    if FSegments[LIndex].Reference then
      LReferences := LReferences + ' ' + IntToStr(FSegments[LIndex].DiskOffset);
  Result[High(Result)] := '  references:' + LReferences;
end;

end.
