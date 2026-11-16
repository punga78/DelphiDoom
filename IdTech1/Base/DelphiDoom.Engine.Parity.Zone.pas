{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the zone of the parity tools                           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Parity.Zone;

interface

uses
  DelphiDoom.Parity.Intf,
  DelphiDoom.Zone.Intf,
  DelphiDoom.Zone.Types;

type
  /// <summary>
  ///   The zone allocator of the engine when the parity tools may be on: while they are off every call goes
  ///   straight to the real allocator; when they are on the blocks that Allocate and Reallocate give are
  ///   cleared. The engine reads some memory that it never wrote (a texture with a patch that is not in the
  ///   WAD has holes, and a hole shows what the block held before), so two runs would draw other pixels
  /// </summary>
  TEngineParityZone = class(TInterfacedObject, IZoneAllocator)
  strict private
    FReal: IZoneAllocator;
    FSwitch: IParitySwitch;
  public
    constructor Create(const AReal: IZoneAllocator; const ASwitch: IParitySwitch);
    function Allocate(ASize: Integer; ATag: Integer; AUser: PPointer): Pointer;
    function Reallocate(APointer: Pointer; ASize: Integer; ATag: Integer; AUser: PPointer): Pointer;
    procedure FreeBlock(APointer: Pointer);
    function BlockSize(APointer: Pointer): Integer;
    procedure ChangeTag(APointer: Pointer; ATag: Integer);
    function FreeTags(ALowTag, AHighTag: Integer): Integer;
    function MoveUsers(AOldStart: Pointer; AByteCount: NativeInt; ANewStart: Pointer): Integer;
    procedure CheckHeap;
    procedure CheckUsers;
    function Statistics: TZoneStatistics;
    function Describe(ALowTag, AHighTag: Integer): TArray<string>;
  end;

implementation

uses
  System.SysUtils;

{ TEngineParityZone }

constructor TEngineParityZone.Create(const AReal: IZoneAllocator; const ASwitch: IParitySwitch);
begin
  inherited Create;
  if not Assigned(AReal) then
    raise EArgumentNilException.Create('AReal');
  if not Assigned(ASwitch) then
    raise EArgumentNilException.Create('ASwitch');
  FReal := AReal;
  FSwitch := ASwitch;
end;

function TEngineParityZone.Allocate(ASize: Integer; ATag: Integer; AUser: PPointer): Pointer;
begin
  Result := FReal.Allocate(ASize, ATag, AUser);
  if (ASize > 0) and (Result <> nil) and FSwitch.IsActive then
    FillChar(Result^, ASize, 0);
end;

function TEngineParityZone.Reallocate(APointer: Pointer; ASize: Integer; ATag: Integer; AUser: PPointer): Pointer;
var
  LOldSize: Integer;
begin
  if not FSwitch.IsActive then
    Exit(FReal.Reallocate(APointer, ASize, ATag, AUser));
  LOldSize := 0;
  if APointer <> nil then
    LOldSize := FReal.BlockSize(APointer);
  Result := FReal.Reallocate(APointer, ASize, ATag, AUser);
  // the bytes after the old size are new
  if (Result <> nil) and (ASize > LOldSize) then
    FillChar((PByte(Result) + LOldSize)^, ASize - LOldSize, 0);
end;

procedure TEngineParityZone.FreeBlock(APointer: Pointer);
begin
  FReal.FreeBlock(APointer);
end;

function TEngineParityZone.BlockSize(APointer: Pointer): Integer;
begin
  Result := FReal.BlockSize(APointer);
end;

procedure TEngineParityZone.ChangeTag(APointer: Pointer; ATag: Integer);
begin
  FReal.ChangeTag(APointer, ATag);
end;

function TEngineParityZone.FreeTags(ALowTag, AHighTag: Integer): Integer;
begin
  Result := FReal.FreeTags(ALowTag, AHighTag);
end;

function TEngineParityZone.MoveUsers(AOldStart: Pointer; AByteCount: NativeInt; ANewStart: Pointer): Integer;
begin
  Result := FReal.MoveUsers(AOldStart, AByteCount, ANewStart);
end;

procedure TEngineParityZone.CheckHeap;
begin
  FReal.CheckHeap;
end;

procedure TEngineParityZone.CheckUsers;
begin
  FReal.CheckUsers;
end;

function TEngineParityZone.Statistics: TZoneStatistics;
begin
  Result := FReal.Statistics;
end;

function TEngineParityZone.Describe(ALowTag, AHighTag: Integer): TArray<string>;
begin
  Result := FReal.Describe(ALowTag, AHighTag);
end;

end.
