{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the zone allocator for the classes of the engine       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Zone.Allocator;

interface

uses
  DelphiDoom.Zone.Types,
  DelphiDoom.Zone.Intf;

type
  /// <summary>
  ///   The allocator of Libs\Zone as the classes of the engine use it: the same blocks, tags and
  ///   user pointers of the one that z_zone.pas holds (the composition root gives both the
  ///   same allocator), but a pointer that is not a block of the zone (a double free, a
  ///   pointer never allocated) is an I_Error with the message of the Z_* functions, not an
  ///   EZoneException that the game does not handle
  /// </summary>
  TEngineZoneAllocator = class(TInterfacedObject, IZoneAllocator)
  strict private
    FInner: IZoneAllocator;
  public
    constructor Create(const AInner: IZoneAllocator);
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
  System.SysUtils,
  i_system;

{ TEngineZoneAllocator }

constructor TEngineZoneAllocator.Create(const AInner: IZoneAllocator);
begin
  inherited Create;
  if not Assigned(AInner) then
    raise EArgumentNilException.Create('AInner');
  FInner := AInner;
end;

function TEngineZoneAllocator.Allocate(ASize: Integer; ATag: Integer; AUser: PPointer): Pointer;
begin
  Result := FInner.Allocate(ASize, ATag, AUser);
end;

function TEngineZoneAllocator.Reallocate(APointer: Pointer; ASize: Integer; ATag: Integer;
  AUser: PPointer): Pointer;
begin
  try
    Result := FInner.Reallocate(APointer, ASize, ATag, AUser);
  except
    on E: EZoneException do
    begin
      Result := nil;
      I_Error('Z_Realloc(): %s', [E.Message]);
    end;
  end;
end;

procedure TEngineZoneAllocator.FreeBlock(APointer: Pointer);
begin
  try
    FInner.FreeBlock(APointer);
  except
    on E: EZoneException do
      I_Error('Z_Free(): %s', [E.Message]);
  end;
end;

function TEngineZoneAllocator.BlockSize(APointer: Pointer): Integer;
begin
  try
    Result := FInner.BlockSize(APointer);
  except
    on E: EZoneException do
    begin
      Result := 0;
      I_Error('Z_Size(): %s', [E.Message]);
    end;
  end;
end;

procedure TEngineZoneAllocator.ChangeTag(APointer: Pointer; ATag: Integer);
begin
  FInner.ChangeTag(APointer, ATag);
end;

function TEngineZoneAllocator.FreeTags(ALowTag, AHighTag: Integer): Integer;
begin
  Result := FInner.FreeTags(ALowTag, AHighTag);
end;

function TEngineZoneAllocator.MoveUsers(AOldStart: Pointer; AByteCount: NativeInt;
  ANewStart: Pointer): Integer;
begin
  Result := FInner.MoveUsers(AOldStart, AByteCount, ANewStart);
end;

procedure TEngineZoneAllocator.CheckHeap;
begin
  FInner.CheckHeap;
end;

procedure TEngineZoneAllocator.CheckUsers;
begin
  FInner.CheckUsers;
end;

function TEngineZoneAllocator.Statistics: TZoneStatistics;
begin
  Result := FInner.Statistics;
end;

function TEngineZoneAllocator.Describe(ALowTag, AHighTag: Integer): TArray<string>;
begin
  Result := FInner.Describe(ALowTag, AHighTag);
end;

end.
