{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the zone library - parity with the old allocator       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Zone.Golden;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Zone.Intf;

type
  /// <summary>
  ///   The golden file (Tests\Data\Zone\replay.golden.txt) holds the digest that the OLD
  ///   TMemManager of the engine gave for four series of 6000 operations; the allocator of the
  ///   library has to give the same, line by line
  /// </summary>
  [TestFixture]
  [Category('zone')]
  TTestZoneGolden = class(TObject)
  private
    FDataFolder: string;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeDareLeStesseImpronteDelVecchioCodice;
    [Test]
    procedure DovrebbeRispettareLeRegoleInOgniSerie;
    [Test]
    procedure DovrebbeDareLeStesseImpronteConUnaMemoriaFinta;
  end;

implementation

uses
  System.Classes, System.IOUtils, DelphiDoom.Tests.Zone.Replay, DelphiDoom.Tests.Zone.FakeMemory,
  DelphiDoom.Zone.Factory;

type
  TAllocatorTarget = class(TZoneReplayTarget)
  private
    FAllocator: IZoneAllocator;
  public
    constructor Create(const AAllocator: IZoneAllocator);
    function Malloc(ASize, ATag: Integer; AUser: PPointer): Pointer; override;
    function Realloc(APointer: Pointer; ASize, ATag: Integer; AUser: PPointer): Pointer; override;
    procedure Release(APointer: Pointer); override;
    function SizeOfBlock(APointer: Pointer): Integer; override;
    procedure ChangeTag(APointer: Pointer; ATag: Integer); override;
    procedure FreeTags(ALowTag, AHighTag: Integer); override;
    function BlockCount: Integer; override;
  end;

{ TAllocatorTarget }

constructor TAllocatorTarget.Create(const AAllocator: IZoneAllocator);
begin
  inherited Create;
  FAllocator := AAllocator;
end;

function TAllocatorTarget.Malloc(ASize, ATag: Integer; AUser: PPointer): Pointer;
begin
  Result := FAllocator.Allocate(ASize, ATag, AUser);
end;

function TAllocatorTarget.Realloc(APointer: Pointer; ASize, ATag: Integer; AUser: PPointer): Pointer;
begin
  Result := FAllocator.Reallocate(APointer, ASize, ATag, AUser);
end;

procedure TAllocatorTarget.Release(APointer: Pointer);
begin
  FAllocator.FreeBlock(APointer);
end;

function TAllocatorTarget.SizeOfBlock(APointer: Pointer): Integer;
begin
  Result := FAllocator.BlockSize(APointer);
end;

procedure TAllocatorTarget.ChangeTag(APointer: Pointer; ATag: Integer);
begin
  FAllocator.ChangeTag(APointer, ATag);
end;

procedure TAllocatorTarget.FreeTags(ALowTag, AHighTag: Integer);
begin
  FAllocator.FreeTags(ALowTag, AHighTag);
end;

function TAllocatorTarget.BlockCount: Integer;
begin
  Result := FAllocator.Statistics.BlockCount;
end;

{ TTestZoneGolden }

procedure TTestZoneGolden.Setup;
begin
  FDataFolder := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\Tests\Data\Zone'));
end;

procedure TTestZoneGolden.DovrebbeDareLeStesseImpronteDelVecchioCodice;
var
  LGolden: TStringList;
  LActual: TStringList;
  LTarget: TAllocatorTarget;
  LLine: string;
  LSeed: Integer;
begin
  LGolden := TStringList.Create;
  LActual := TStringList.Create;
  try
    LGolden.LoadFromFile(TPath.Combine(FDataFolder, 'replay.golden.txt'));
    for LSeed := 1 to 4 do
    begin
      LTarget := TAllocatorTarget.Create(TZoneFactory.CreateAllocator);
      try
        for LLine in TZoneReplay.Run(LTarget, LSeed, 6000, 500) do
          LActual.Add(LLine);
      finally
        LTarget.Free;
      end;
    end;
    Assert.AreEqual(LGolden.Count, LActual.Count);
    for LSeed := 0 to LGolden.Count - 1 do
      Assert.AreEqual(LGolden[LSeed], LActual[LSeed]);
  finally
    LActual.Free;
    LGolden.Free;
  end;
end;

procedure TTestZoneGolden.DovrebbeRispettareLeRegoleInOgniSerie;
var
  LTarget: TAllocatorTarget;
  LLine: string;
  LSeed: Integer;
begin
  for LSeed := 10 to 17 do
  begin
    LTarget := TAllocatorTarget.Create(TZoneFactory.CreateAllocator);
    try
      for LLine in TZoneReplay.Run(LTarget, LSeed, 4000, 1000) do
        Assert.IsFalse(LLine.StartsWith('ERR'), LLine);
    finally
      LTarget.Free;
    end;
  end;
end;

procedure TTestZoneGolden.DovrebbeDareLeStesseImpronteConUnaMemoriaFinta;
var
  LMemory: TFakeZoneMemory;
  LMemoryIntf: IZoneMemory;
  LTarget: TAllocatorTarget;
  LHeap: TStringList;
  LFake: TStringList;
  LLine: string;
  LIndex: Integer;
begin
  LHeap := TStringList.Create;
  LFake := TStringList.Create;
  try
    LTarget := TAllocatorTarget.Create(TZoneFactory.CreateAllocator);
    try
      for LLine in TZoneReplay.Run(LTarget, 5, 3000, 500) do
        LHeap.Add(LLine);
    finally
      LTarget.Free;
    end;
    LMemory := TFakeZoneMemory.Create;
    LMemoryIntf := LMemory;
    LTarget := TAllocatorTarget.Create(TZoneFactory.CreateAllocator(LMemoryIntf));
    try
      for LLine in TZoneReplay.Run(LTarget, 5, 3000, 500) do
        LFake.Add(LLine);
    finally
      LTarget.Free;
    end;
    Assert.AreEqual(LHeap.Count, LFake.Count);
    for LIndex := 0 to LHeap.Count - 1 do
      Assert.AreEqual(LHeap[LIndex], LFake[LIndex]);
    Assert.AreEqual(0, LMemory.BadReleases);
    Assert.AreEqual(0, LMemory.LiveBlocks);
  finally
    LFake.Free;
    LHeap.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestZoneGolden);

end.
