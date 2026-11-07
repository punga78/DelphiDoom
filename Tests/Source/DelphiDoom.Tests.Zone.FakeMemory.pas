{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the zone library - a fake memory source                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Zone.FakeMemory;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Zone.Intf;

type
  /// <summary>
  ///   A memory source that counts, checks that every release gives back what was taken, and
  ///   keeps freed memory (filled with $DD) until it is destroyed, so a block freed twice or
  ///   used after the free is always found in the same state
  /// </summary>
  TFakeZoneMemory = class(TInterfacedObject, IZoneMemory)
  strict private
    FLive: TDictionary<Pointer, NativeInt>;
    FGraveyard: TList<Pointer>;
  public
    AllocateCalls: Integer;
    ReleaseCalls: Integer;
    /// <summary>Releases of something that is not live, or of a wrong size</summary>
    BadReleases: Integer;
    /// <summary>When not negative, the allocation that makes this count of live blocks fails</summary>
    FailAtLiveBlocks: Integer;
    constructor Create;
    destructor Destroy; override;
    function Allocate(ASize: NativeInt): Pointer;
    procedure Release(APointer: Pointer; ASize: NativeInt);
    function LiveBlocks: Integer;
    function LiveBytes: Int64;
  end;

implementation

{ TFakeZoneMemory }

constructor TFakeZoneMemory.Create;
begin
  inherited Create;
  FLive := TDictionary<Pointer, NativeInt>.Create;
  FGraveyard := TList<Pointer>.Create;
  FailAtLiveBlocks := -1;
end;

destructor TFakeZoneMemory.Destroy;
var
  LPointer: Pointer;
begin
  for LPointer in FLive.Keys do
    FreeMem(LPointer);
  for LPointer in FGraveyard do
    FreeMem(LPointer);
  FGraveyard.Free;
  FLive.Free;
  inherited;
end;

function TFakeZoneMemory.Allocate(ASize: NativeInt): Pointer;
begin
  Inc(AllocateCalls);
  if FLive.Count = FailAtLiveBlocks then
    raise EOutOfMemory.Create('the fake memory is full');
  GetMem(Result, ASize);
  FillChar(Result^, ASize, $CD);
  FLive.Add(Result, ASize);
end;

procedure TFakeZoneMemory.Release(APointer: Pointer; ASize: NativeInt);
var
  LSize: NativeInt;
begin
  Inc(ReleaseCalls);
  if not FLive.TryGetValue(APointer, LSize) or (LSize <> ASize) then
  begin
    Inc(BadReleases);
    Exit;
  end;
  FLive.Remove(APointer);
  FillChar(APointer^, ASize, $DD);
  FGraveyard.Add(APointer);
end;

function TFakeZoneMemory.LiveBlocks: Integer;
begin
  Result := FLive.Count;
end;

function TFakeZoneMemory.LiveBytes: Int64;
var
  LSize: NativeInt;
begin
  Result := 0;
  for LSize in FLive.Values do
    Inc(Result, LSize);
end;

end.
