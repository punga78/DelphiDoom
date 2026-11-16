{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - source: a pile of lumps in a stream               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Source.Base;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Wad.Types, DelphiDoom.Wad.Intf;

type
  /// <summary>
  ///   Common part of the sources that keep their lumps as (offset, size) in a
  ///   stream: reading by index and the checks of the limits
  /// </summary>
  TWadStreamSource = class(TInterfacedObject, IWadSource)
  private
    FName: string;
    FKind: TWadSourceKind;
    FStream: TStream;
    FOwnsStream: Boolean;
    FEntries: TArray<TWadEntry>;
  protected
    /// <summary>For the descendants: set once the directory has been read</summary>
    procedure SetEntries(const AEntries: TArray<TWadEntry>);
    property Stream: TStream read FStream;
  public
    constructor Create(const AName: string; AKind: TWadSourceKind; AStream: TStream;
      AOwnsStream: Boolean);
    destructor Destroy; override;
    function GetName: string;
    function GetKind: TWadSourceKind;
    function GetCount: Integer;
    function GetEntry(AIndex: Integer): TWadEntry;
    function ReadEntry(AIndex: Integer): TBytes;
    procedure ReadEntryInto(AIndex: Integer; ADestination: Pointer);
  end;

implementation

const
  SBadIndex = 'Lump %d does not exist in %s (it has %d)';
  SOutsideFile = 'Lump "%s" of %s lies outside the file';

{ TWadStreamSource }

constructor TWadStreamSource.Create(const AName: string; AKind: TWadSourceKind;
  AStream: TStream; AOwnsStream: Boolean);
begin
  inherited Create;
  FName := AName;
  FKind := AKind;
  FStream := AStream;
  FOwnsStream := AOwnsStream;
end;

destructor TWadStreamSource.Destroy;
begin
  if FOwnsStream then
    FStream.Free;
  inherited Destroy;
end;

procedure TWadStreamSource.SetEntries(const AEntries: TArray<TWadEntry>);
begin
  FEntries := AEntries;
end;

function TWadStreamSource.GetName: string;
begin
  Result := FName;
end;

function TWadStreamSource.GetKind: TWadSourceKind;
begin
  Result := FKind;
end;

function TWadStreamSource.GetCount: Integer;
begin
  Result := Length(FEntries);
end;

function TWadStreamSource.GetEntry(AIndex: Integer): TWadEntry;
begin
  if (AIndex < 0) or (AIndex >= Length(FEntries)) then
    raise EWadException.CreateFmt(SBadIndex, [AIndex, FName, Length(FEntries)]);
  Result := FEntries[AIndex];
end;

function TWadStreamSource.ReadEntry(AIndex: Integer): TBytes;
begin
  SetLength(Result, GetEntry(AIndex).Size);
  if Length(Result) > 0 then
    ReadEntryInto(AIndex, @Result[0]);
end;

procedure TWadStreamSource.ReadEntryInto(AIndex: Integer; ADestination: Pointer);
var
  LEntry: TWadEntry;
begin
  LEntry := GetEntry(AIndex);
  // a lump with no bytes needs no valid position: some tools write any
  if LEntry.Size = 0 then
    Exit;
  if (LEntry.Size < 0) or (LEntry.Offset < 0) or
     (Int64(LEntry.Offset) + LEntry.Size > FStream.Size) then
    raise EWadException.CreateFmt(SOutsideFile, [LEntry.Name, FName]);
  FStream.Position := LEntry.Offset;
  if FStream.Read(ADestination^, LEntry.Size) <> LEntry.Size then
    raise EWadException.CreateFmt(SOutsideFile, [LEntry.Name, FName]);
end;

end.