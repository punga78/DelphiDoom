{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - builder: makes and changes WADs                   }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Builder;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Wad.Types,
  DelphiDoom.Wad.Intf;

type
  /// <summary>
  ///   Makes a WAD in memory: lumps in order, a header and a directory at the
  ///   end. Data is aligned to 4 bytes; names are upper case, 1 to 8
  ///   characters
  /// </summary>
  TWadBuilder = class(TInterfacedObject, IWadBuilder)
  private
    type
      TBuilderLump = record
        Name: string;
        Data: TBytes;
      end;
  private
    FKind: TWadKind;
    FLumps: TList<TBuilderLump>;
    procedure CheckIndex(AIndex: Integer; AMaximum: Integer);
  public
    constructor Create(AKind: TWadKind = TWadKind.PWad);
    destructor Destroy; override;
    function GetKind: TWadKind;
    procedure SetKind(AValue: TWadKind);
    function GetCount: Integer;
    function GetLumpName(AIndex: Integer): string;
    function GetLumpData(AIndex: Integer): TBytes;
    function AddLump(const AName: string; const AData: TBytes): Integer;
    procedure InsertLump(AIndex: Integer; const AName: string; const AData: TBytes);
    procedure ReplaceLump(AIndex: Integer; const AData: TBytes);
    procedure RenameLump(AIndex: Integer; const AName: string);
    procedure DeleteLump(AIndex: Integer);
    procedure MoveLump(AFromIndex, AToIndex: Integer);
    function IndexOf(const AName: string): Integer;
    procedure LoadFrom(const ASource: IWadSource);
    procedure Clear;
    function ToBytes: TBytes;
    procedure SaveToStream(AStream: TStream);
    procedure SaveToFile(const AFileName: string);
  end;

implementation

uses
  DelphiDoom.Wad.Name;

const
  SBadLumpIndex = 'Lump %d does not exist (there are %d)';
  DATA_ALIGNMENT = 4;

function Align(AValue: Integer): Integer;
begin
  Result := (AValue + DATA_ALIGNMENT - 1) and not (DATA_ALIGNMENT - 1);
end;

{ TWadBuilder }

constructor TWadBuilder.Create(AKind: TWadKind);
begin
  inherited Create;
  FKind := AKind;
  FLumps := TList<TBuilderLump>.Create;
end;

destructor TWadBuilder.Destroy;
begin
  FLumps.Free;
  inherited Destroy;
end;

procedure TWadBuilder.CheckIndex(AIndex, AMaximum: Integer);
begin
  if (AIndex < 0) or (AIndex > AMaximum) then
    raise EWadException.CreateFmt(SBadLumpIndex, [AIndex, FLumps.Count]);
end;

function TWadBuilder.GetKind: TWadKind;
begin
  Result := FKind;
end;

procedure TWadBuilder.SetKind(AValue: TWadKind);
begin
  FKind := AValue;
end;

function TWadBuilder.GetCount: Integer;
begin
  Result := FLumps.Count;
end;

function TWadBuilder.GetLumpName(AIndex: Integer): string;
begin
  CheckIndex(AIndex, FLumps.Count - 1);
  Result := FLumps[AIndex].Name;
end;

function TWadBuilder.GetLumpData(AIndex: Integer): TBytes;
begin
  CheckIndex(AIndex, FLumps.Count - 1);
  Result := Copy(FLumps[AIndex].Data);
end;

function TWadBuilder.AddLump(const AName: string; const AData: TBytes): Integer;
begin
  Result := FLumps.Count;
  InsertLump(Result, AName, AData);
end;

procedure TWadBuilder.InsertLump(AIndex: Integer; const AName: string; const AData: TBytes);
var
  LLump: TBuilderLump;
begin
  CheckIndex(AIndex, FLumps.Count);
  if not TWadLumpName.IsValid(AName) then
    raise EWadException.CreateFmt('Invalid lump name "%s"', [AName]);
  LLump.Name := TWadLumpName.UpperCase(AName);
  LLump.Data := Copy(AData);
  FLumps.Insert(AIndex, LLump);
end;

procedure TWadBuilder.ReplaceLump(AIndex: Integer; const AData: TBytes);
var
  LLump: TBuilderLump;
begin
  CheckIndex(AIndex, FLumps.Count - 1);
  LLump := FLumps[AIndex];
  LLump.Data := Copy(AData);
  FLumps[AIndex] := LLump;
end;

procedure TWadBuilder.RenameLump(AIndex: Integer; const AName: string);
var
  LLump: TBuilderLump;
begin
  CheckIndex(AIndex, FLumps.Count - 1);
  if not TWadLumpName.IsValid(AName) then
    raise EWadException.CreateFmt('Invalid lump name "%s"', [AName]);
  LLump := FLumps[AIndex];
  LLump.Name := TWadLumpName.UpperCase(AName);
  FLumps[AIndex] := LLump;
end;

procedure TWadBuilder.DeleteLump(AIndex: Integer);
begin
  CheckIndex(AIndex, FLumps.Count - 1);
  FLumps.Delete(AIndex);
end;

procedure TWadBuilder.MoveLump(AFromIndex, AToIndex: Integer);
begin
  CheckIndex(AFromIndex, FLumps.Count - 1);
  CheckIndex(AToIndex, FLumps.Count - 1);
  FLumps.Move(AFromIndex, AToIndex);
end;

function TWadBuilder.IndexOf(const AName: string): Integer;
var
  LName: string;
begin
  LName := TWadLumpName.UpperCase(AName);
  for Result := 0 to FLumps.Count - 1 do
    if FLumps[Result].Name = LName then
      Exit;
  Result := -1;
end;

procedure TWadBuilder.LoadFrom(const ASource: IWadSource);
var
  LIndex: Integer;
  LLump: TBuilderLump;
begin
  FLumps.Clear;
  for LIndex := 0 to ASource.Count - 1 do
  begin
    LLump.Name := ASource.Entries[LIndex].Name;
    LLump.Data := ASource.ReadEntry(LIndex);
    if not TWadLumpName.IsValid(LLump.Name) then
      raise EWadException.CreateFmt('Invalid lump name "%s"', [LLump.Name]);
    FLumps.Add(LLump);
  end;
end;

procedure TWadBuilder.Clear;
begin
  FLumps.Clear;
end;

function TWadBuilder.ToBytes: TBytes;
var
  LStream: TBytesStream;
begin
  LStream := TBytesStream.Create;
  try
    SaveToStream(LStream);
    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

procedure TWadBuilder.SaveToStream(AStream: TStream);
const
  PADDING: array[0..DATA_ALIGNMENT - 1] of Byte = (0, 0, 0, 0);
var
  LHeader: TWadHeader;
  LRecords: TArray<TWadDirectoryRecord>;
  LOffset, LIndex, LPad: Integer;
begin
  case FKind of
    TWadKind.IWad: LHeader.Identification := WAD_ID_IWAD;
    TWadKind.DWad: LHeader.Identification := WAD_ID_DWAD;
  else
    LHeader.Identification := WAD_ID_PWAD;
  end;
  LHeader.NumLumps := FLumps.Count;
  SetLength(LRecords, FLumps.Count);

  LOffset := Align(WAD_HEADER_SIZE);
  for LIndex := 0 to FLumps.Count - 1 do
  begin
    FillChar(LRecords[LIndex], SizeOf(LRecords[LIndex]), 0);
    TWadLumpName.ToRecord(FLumps[LIndex].Name, LRecords[LIndex]);
    LRecords[LIndex].FilePos := LOffset;
    LRecords[LIndex].Size := Length(FLumps[LIndex].Data);
    Inc(LOffset, Align(Length(FLumps[LIndex].Data)));
  end;
  LHeader.InfoTableOfs := LOffset;

  AStream.WriteBuffer(LHeader, SizeOf(LHeader));
  AStream.WriteBuffer(PADDING, Align(WAD_HEADER_SIZE) - WAD_HEADER_SIZE);
  for LIndex := 0 to FLumps.Count - 1 do
  begin
    if Length(FLumps[LIndex].Data) > 0 then
      AStream.WriteBuffer(FLumps[LIndex].Data[0], Length(FLumps[LIndex].Data));
    LPad := Align(Length(FLumps[LIndex].Data)) - Length(FLumps[LIndex].Data);
    if LPad > 0 then
      AStream.WriteBuffer(PADDING, LPad);
  end;
  if FLumps.Count > 0 then
    AStream.WriteBuffer(LRecords[0], FLumps.Count * WAD_DIRECTORY_RECORD_SIZE);
end;

procedure TWadBuilder.SaveToFile(const AFileName: string);
var
  LStream: TFileStream;
begin
  LStream := TFileStream.Create(AFileName, fmCreate);
  try
    SaveToStream(LStream);
  finally
    LStream.Free;
  end;
end;

end.
