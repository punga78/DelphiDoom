{******************************************************************************}
{                                                                              }
{  DelphiDoom: Nodes library - writes a PWAD in memory                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Nodes.PwadAssembler;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Nodes.Types;

type
  /// <summary>
  ///   Makes the bytes of a PWAD for the node builder: the header, the data of the lumps one after
  ///   the other with no padding, and the directory at the end (the layout that the engine has
  ///   always written for the files that glBSP reads)
  /// </summary>
  TNodesPwadAssembler = class
  strict private
    type
      TEntry = record
        Name: string;
        Data: TBytes;
        Position: Integer;
      end;
    var
      FEntries: TList<TEntry>;
      FDataSize: Integer;
    function GetEntryCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Adds a lump after the ones already added; its name is cut at 8 characters</summary>
    procedure AddLump(const AName: string; const AData: TBytes);
    /// <summary>Adds an empty lump placed at the end of the data so far</summary>
    procedure AddEmptyLump(const AName: string);
    /// <summary>Adds an empty lump at position 0 (a lump that is not in the file)</summary>
    procedure AddAbsentLump(const AName: string);
    /// <summary>Adds an entry made of zeros: no name, no position, no size</summary>
    procedure AddBlankEntry;
    /// <summary>The PWAD</summary>
    function Build: TBytes;
    property EntryCount: Integer read GetEntryCount;
  end;

implementation

const
  PWAD_IDENTIFICATION = Integer($44415750);

{ TNodesPwadAssembler }

constructor TNodesPwadAssembler.Create;
begin
  inherited Create;
  FEntries := TList<TEntry>.Create;
end;

destructor TNodesPwadAssembler.Destroy;
begin
  FEntries.Free;
  inherited;
end;

function TNodesPwadAssembler.GetEntryCount: Integer;
begin
  Result := FEntries.Count;
end;

procedure TNodesPwadAssembler.AddLump(const AName: string; const AData: TBytes);
var
  LEntry: TEntry;
begin
  LEntry.Name := Copy(AName, 1, NODES_LUMP_NAME_LENGTH);
  LEntry.Data := AData;
  LEntry.Position := NODES_WAD_HEADER_SIZE + FDataSize;
  FEntries.Add(LEntry);
  Inc(FDataSize, Length(AData));
end;

procedure TNodesPwadAssembler.AddEmptyLump(const AName: string);
begin
  AddLump(AName, nil);
end;

procedure TNodesPwadAssembler.AddAbsentLump(const AName: string);
var
  LEntry: TEntry;
begin
  LEntry.Name := Copy(AName, 1, NODES_LUMP_NAME_LENGTH);
  LEntry.Data := nil;
  LEntry.Position := 0;
  FEntries.Add(LEntry);
end;

procedure TNodesPwadAssembler.AddBlankEntry;
var
  LEntry: TEntry;
begin
  LEntry.Name := '';
  LEntry.Data := nil;
  LEntry.Position := 0;
  FEntries.Add(LEntry);
end;

function TNodesPwadAssembler.Build: TBytes;
var
  LHeader: TNodesWadHeader;
  LEntry: TEntry;
  LWadEntry: TNodesWadEntry;
  LOffset: Integer;
  LDirectory: Integer;
  LIndex: Integer;
  LNameIndex: Integer;
begin
  LDirectory := NODES_WAD_HEADER_SIZE + FDataSize;
  SetLength(Result, LDirectory + FEntries.Count * NODES_WAD_ENTRY_SIZE);

  LHeader.Identification := PWAD_IDENTIFICATION;
  LHeader.LumpCount := FEntries.Count;
  LHeader.DirectoryOffset := LDirectory;
  Move(LHeader, Result[0], SizeOf(LHeader));

  LOffset := NODES_WAD_HEADER_SIZE;
  for LIndex := 0 to FEntries.Count - 1 do
  begin
    LEntry := FEntries[LIndex];
    if Length(LEntry.Data) > 0 then
    begin
      Move(LEntry.Data[0], Result[LOffset], Length(LEntry.Data));
      Inc(LOffset, Length(LEntry.Data));
    end;
    FillChar(LWadEntry, SizeOf(LWadEntry), 0);
    LWadEntry.Position := LEntry.Position;
    LWadEntry.Size := Length(LEntry.Data);
    for LNameIndex := 1 to Length(LEntry.Name) do
      LWadEntry.Name[LNameIndex - 1] := AnsiChar(Ord(LEntry.Name[LNameIndex]) and $FF);
    Move(LWadEntry, Result[LDirectory + LIndex * NODES_WAD_ENTRY_SIZE], SizeOf(LWadEntry));
  end;
end;

end.
