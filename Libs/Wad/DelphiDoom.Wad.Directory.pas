{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - directory of the lumps of several sources         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Directory;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Wad.Types, DelphiDoom.Wad.Intf;

type
  /// <summary>
  ///   The lumps of the sources added so far, one after the other. A lump has
  ///   an index in the whole; the last lump with a name takes precedence.
  ///   Holds no global state: the engine owns an instance
  /// </summary>
  TWadDirectory = class(TInterfacedObject, IWadDirectory, IWadFinder, ILumpReader)
  private
    type
      TLumpRef = record
        SourceIndex: Integer;
        EntryIndex: Integer;
      end;
  private
    FSources: TList<IWadSource>;
    FLumps: TList<TLumpRef>;
    FNames: TArray<string>;
    FSizes: TArray<Integer>;
    FFlags: TArray<Cardinal>;
    FByName: TDictionary<string, TList<Integer>>;
    procedure Rebuild;
    procedure CheckLump(ALump: Integer);
  public
    constructor Create;
    destructor Destroy; override;

    { IWadDirectory }
    function GetCount: Integer;
    function GetSourceCount: Integer;
    function GetSource(AIndex: Integer): IWadSource;
    procedure AddSource(const ASource: IWadSource);
    procedure Truncate(ASourceCount: Integer);
    function LumpName(ALump: Integer): string;
    function LumpSize(ALump: Integer): Integer;
    function LumpFlags(ALump: Integer): Cardinal;
    function LumpSourceIndex(ALump: Integer): Integer;

    { IWadFinder }
    function CheckNumForName(const AName: string; AFlags: Cardinal = 0): Integer;
    function CheckFirstNumForName(const AName: string): Integer;
    function CheckNumForNameInRange(const AName: string; AFirst, ALast: Integer): Integer;
    function GetNumForName(const AName: string; AFlags: Cardinal = 0): Integer;
    function GetFirstNumForName(const AName: string): Integer;

    { ILumpReader }
    function ReadLump(ALump: Integer): TBytes;
    procedure ReadLumpInto(ALump: Integer; ADestination: Pointer);
    function TextLump(ALump: Integer): string;
  end;

implementation

uses
  DelphiDoom.Wad.Name, DelphiDoom.Wad.Indicators;

const
  SNoSuchLump = 'Lump %d does not exist (there are %d)';
  SNameNotFound = 'Lump "%s" not found';
  SBadSourceCount = 'Cannot keep %d sources (there are %d)';

{ TWadDirectory }

constructor TWadDirectory.Create;
begin
  inherited Create;
  FSources := TList<IWadSource>.Create;
  FLumps := TList<TLumpRef>.Create;
  FByName := TObjectDictionary<string, TList<Integer>>.Create([doOwnsValues]);
end;

destructor TWadDirectory.Destroy;
begin
  FByName.Free;
  FLumps.Free;
  FSources.Free;
  inherited Destroy;
end;

procedure TWadDirectory.Rebuild;
var
  LIndex: Integer;
  LRef: TLumpRef;
  LEntry: TWadEntry;
  LList: TList<Integer>;
begin
  FByName.Clear;
  SetLength(FNames, FLumps.Count);
  SetLength(FSizes, FLumps.Count);
  for LIndex := 0 to FLumps.Count - 1 do
  begin
    LRef := FLumps[LIndex];
    LEntry := FSources[LRef.SourceIndex].Entries[LRef.EntryIndex];
    FNames[LIndex] := LEntry.Name;
    FSizes[LIndex] := LEntry.Size;
    if not FByName.TryGetValue(LEntry.Name, LList) then
    begin
      LList := TList<Integer>.Create;
      FByName.Add(LEntry.Name, LList);
    end;
    LList.Add(LIndex);
  end;
  FFlags := TWadIndicators.ComputeFlags(FNames);
end;

procedure TWadDirectory.CheckLump(ALump: Integer);
begin
  if (ALump < 0) or (ALump >= FLumps.Count) then
    raise EWadException.CreateFmt(SNoSuchLump, [ALump, FLumps.Count]);
end;

function TWadDirectory.GetCount: Integer;
begin
  Result := FLumps.Count;
end;

function TWadDirectory.GetSourceCount: Integer;
begin
  Result := FSources.Count;
end;

function TWadDirectory.GetSource(AIndex: Integer): IWadSource;
begin
  Result := FSources[AIndex];
end;

procedure TWadDirectory.AddSource(const ASource: IWadSource);
var
  LRef: TLumpRef;
  LIndex: Integer;
begin
  if ASource = nil then
    raise EWadException.Create('The source is nil');
  LRef.SourceIndex := FSources.Add(ASource);
  for LIndex := 0 to ASource.Count - 1 do
  begin
    LRef.EntryIndex := LIndex;
    FLumps.Add(LRef);
  end;
  Rebuild;
end;

procedure TWadDirectory.Truncate(ASourceCount: Integer);
var
  LIndex: Integer;
begin
  if (ASourceCount < 0) or (ASourceCount > FSources.Count) then
    raise EWadException.CreateFmt(SBadSourceCount, [ASourceCount, FSources.Count]);
  for LIndex := FLumps.Count - 1 downto 0 do
    if FLumps[LIndex].SourceIndex >= ASourceCount then
      FLumps.Delete(LIndex);
  while FSources.Count > ASourceCount do
    FSources.Delete(FSources.Count - 1);
  Rebuild;
end;

function TWadDirectory.LumpName(ALump: Integer): string;
begin
  CheckLump(ALump);
  Result := FNames[ALump];
end;

function TWadDirectory.LumpSize(ALump: Integer): Integer;
begin
  CheckLump(ALump);
  Result := FSizes[ALump];
end;

function TWadDirectory.LumpFlags(ALump: Integer): Cardinal;
begin
  CheckLump(ALump);
  Result := FFlags[ALump];
end;

function TWadDirectory.LumpSourceIndex(ALump: Integer): Integer;
begin
  CheckLump(ALump);
  Result := FLumps[ALump].SourceIndex;
end;

function TWadDirectory.CheckNumForName(const AName: string; AFlags: Cardinal): Integer;
var
  LList: TList<Integer>;
  LIndex: Integer;
begin
  Result := -1;
  if not FByName.TryGetValue(TWadLumpName.UpperCase(AName), LList) then
    Exit;
  // the last one takes precedence
  for LIndex := LList.Count - 1 downto 0 do
    if (AFlags = 0) or ((FFlags[LList[LIndex]] and AFlags) <> 0) then
      Exit(LList[LIndex]);
end;

function TWadDirectory.CheckFirstNumForName(const AName: string): Integer;
var
  LList: TList<Integer>;
begin
  if FByName.TryGetValue(TWadLumpName.UpperCase(AName), LList) then
    Result := LList[0]
  else
    Result := -1;
end;

function TWadDirectory.CheckNumForNameInRange(const AName: string; AFirst,
  ALast: Integer): Integer;
var
  LList: TList<Integer>;
  LIndex: Integer;
begin
  Result := -1;
  if not FByName.TryGetValue(TWadLumpName.UpperCase(AName), LList) then
    Exit;
  for LIndex := LList.Count - 1 downto 0 do
    if LList[LIndex] <= ALast then
    begin
      if LList[LIndex] >= AFirst then
        Result := LList[LIndex];
      Exit;
    end;
end;

function TWadDirectory.GetNumForName(const AName: string; AFlags: Cardinal): Integer;
begin
  Result := CheckNumForName(AName, AFlags);
  if Result = -1 then
    raise EWadException.CreateFmt(SNameNotFound, [AName]);
end;

function TWadDirectory.GetFirstNumForName(const AName: string): Integer;
begin
  Result := CheckFirstNumForName(AName);
  if Result = -1 then
    raise EWadException.CreateFmt(SNameNotFound, [AName]);
end;

function TWadDirectory.ReadLump(ALump: Integer): TBytes;
var
  LRef: TLumpRef;
begin
  CheckLump(ALump);
  LRef := FLumps[ALump];
  Result := FSources[LRef.SourceIndex].ReadEntry(LRef.EntryIndex);
end;

procedure TWadDirectory.ReadLumpInto(ALump: Integer; ADestination: Pointer);
var
  LBytes: TBytes;
begin
  LBytes := ReadLump(ALump);
  if Length(LBytes) > 0 then
    Move(LBytes[0], ADestination^, Length(LBytes));
end;

function TWadDirectory.TextLump(ALump: Integer): string;
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  LBytes := ReadLump(ALump);
  SetLength(Result, Length(LBytes));
  for LIndex := 0 to High(LBytes) do
    Result[LIndex + 1] := Char(LBytes[LIndex]);
end;

end.
