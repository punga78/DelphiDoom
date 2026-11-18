{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the list of the thinkers                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.List;

// The generator of the random scenarios wraps
{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework,
  DelphiDoom.Thinkers.List, DelphiDoom.Tests.Thinkers.OldList;

type
  PTestNode = ^TTestNode;

  /// <summary>A thinker of the tests: the map object of the old code first, as in the engine</summary>
  TTestNode = record
    Mobj: mobj_t;
    Id: Integer;
    Released: Boolean;
  end;

  TTestNodeKind = (Plain, MapObject, PlayerObject, UnfrozenObject, NoFunction);

  /// <summary>
  ///   A list of thinkers driven by a test, old or new: everything that the list does to the
  ///   outside (calls of thinkers, index of the map objects, releases) is written in a log
  /// </summary>
  TListScenario = class abstract
  strict private
    FNodes: TList<PTestNode>;
    FLog: string;
    FSeed: Cardinal;
    FOnThink: TProc<PTestNode>;
    function NextRandom(ARange: Integer): Integer;
    procedure RemoveRandom;
  strict protected
    procedure DoClear; virtual; abstract;
    procedure DoAdd(ANode: PTestNode); virtual; abstract;
    procedure DoRemove(ANode: PTestNode); virtual; abstract;
    procedure DoRun(AFrozen: Boolean); virtual; abstract;
    function DoIsRemoved(ANode: PTestNode): Boolean; virtual; abstract;
    function HeadNode: Pthinker_t; virtual; abstract;
  public
    constructor Create;
    destructor Destroy; override;
    function NewNode(AKind: TTestNodeKind): PTestNode;
    function AddNew(AKind: TTestNodeKind): PTestNode;
    procedure Clear;
    procedure Add(ANode: PTestNode);
    procedure Remove(ANode: PTestNode);
    procedure Run(AFrozen: Boolean);
    function IsRemoved(ANode: PTestNode): Boolean;
    /// <summary>What a thinker of the tests does at its turn</summary>
    procedure Think(ANode: PTestNode);
    procedure Write(const AText: string);
    /// <summary>The id of the last node of the list, 0 when it is empty</summary>
    function LastId: Integer;
    /// <summary>The ids from the head following next</summary>
    function Order: string;
    /// <summary>The ids from the head following prev</summary>
    function ReverseOrder: string;
    /// <summary>A whole random game: the same seed gives the same requests to the list</summary>
    procedure PlayRandom(ASeed: Cardinal; ATics: Integer);
    property Calls: string read FLog write FLog;
    property OnThink: TProc<PTestNode> read FOnThink write FOnThink;
  end;

  TOldListScenario = class(TListScenario)
  strict protected
    procedure DoClear; override;
    procedure DoAdd(ANode: PTestNode); override;
    procedure DoRemove(ANode: PTestNode); override;
    procedure DoRun(AFrozen: Boolean); override;
    function DoIsRemoved(ANode: PTestNode): Boolean; override;
    function HeadNode: Pthinker_t; override;
  end;

  TNewListScenario = class(TListScenario)
  strict private
    FHead: TThinkerNode;
    FList: TThinkerList;
  strict protected
    procedure DoClear; override;
    procedure DoAdd(ANode: PTestNode); override;
    procedure DoRemove(ANode: PTestNode); override;
    procedure DoRun(AFrozen: Boolean); override;
    function DoIsRemoved(ANode: PTestNode): Boolean; override;
    function HeadNode: Pthinker_t; override;
  public
    constructor Create;
    destructor Destroy; override;
    property List: TThinkerList read FList;
  end;

  [TestFixture]
  [Category('thinkers')]
  TTestThinkersList = class(TObject)
  strict private
    FNew: TNewListScenario;
    function PlayOld(ASeed: Cardinal; ATics: Integer): string;
    function PlayNew(ASeed: Cardinal; ATics: Integer): string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeAvereIlNodoConLaFormaDelThinkerDelMotore;
    [Test]
    procedure DovrebbeDareErroreSenzaLaTesta;
    [Test]
    [TestCase('Cleared', '0')]
    [TestCase('Added', '1')]
    [TestCase('Removed', '2')]
    [TestCase('Release', '3')]
    [TestCase('RunsWhenFrozen', '4')]
    procedure DovrebbeDareErroreSenzaUnaProcedura(AMissing: Integer);
    [Test]
    procedure DovrebbeLasciareLaTestaAlChiamante;
    [Test]
    procedure DovrebbeSvuotareLaListaEAvvisare;
    [Test]
    procedure DovrebbeAggiungereInCoda;
    [Test]
    procedure DovrebbeAvvisareDellAggiuntaPrimaDiCollegare;
    [Test]
    procedure DovrebbeSegnareIlRimossoSenzaScollegarlo;
    [Test]
    procedure DovrebbeAvvisareDellaRimozioneConLaFunzioneAncoraAlSuoPosto;
    [Test]
    procedure DovrebbeDareRimossoUnNodoSenzaFunzione;
    [Test]
    procedure DovrebbeEseguireNellOrdineDiAggiunta;
    [Test]
    procedure DovrebbeLiberareIlRimossoAlSuoTurnoENonEseguirlo;
    [Test]
    procedure DovrebbeSaltareIlNodoSenzaFunzione;
    [Test]
    procedure DovrebbeEseguireNelloStessoTurnoIlNodoAggiuntoDaUnThinker;
    [Test]
    procedure DovrebbeLiberareNelloStessoTurnoIlSuccessivoRimossoDaUnThinker;
    [Test]
    procedure DovrebbeLiberareAlTurnoDopoChiRimuoveSeStesso;
    [Test]
    procedure DovrebbeLiberareAlTurnoDopoIlPrecedenteRimossoDaUnThinker;
    [Test]
    procedure DovrebbeEseguireDaCongelatoSoloChiPassaIlFiltro;
    [Test]
    procedure DovrebbeLiberareIRimossiAncheDaCongelato;
    [Test]
    procedure DovrebbeNonChiedereIlFiltroPerUnNodoSenzaFunzione;
    [Test]
    procedure DovrebbeNonFareNullaConLaListaVuota;
    [Test]
    procedure DovrebbeDareLeStesseChiamateDelVecchioCodiceInScenariCasuali;
    [Test]
    procedure DovrebbeDareLeStesseChiamateDelVecchioCodiceInPartiteLunghe;
  end;

implementation

var
  // the scenario that the plain procedures given to the lists write to
  Current: TListScenario;
  FilterCalls: Integer;

procedure SectorThink(ANode: Pointer);
begin
  Current.Think(ANode);
end;

procedure MobjThink(m: Pmobj_t);
begin
  Current.Think(PTestNode(m));
end;

procedure LogCleared;
begin
  Current.Write('C ');
end;

// with the last node of the list: it shows that the node is not linked yet
procedure LogMobjAdded(m: Pmobj_t);
begin
  Current.Write(Format('A%d@%d ', [PTestNode(m).Id, Current.LastId]));
end;

// with the state of the node: it shows that it is not marked yet
procedure LogMobjRemoved(m: Pmobj_t);
begin
  Current.Write(Format('R%d:%d ', [PTestNode(m).Id, Ord(Current.IsRemoved(PTestNode(m)))]));
end;

// The links are spoiled as a freed block would be: a list that reads them afterwards breaks
procedure LogReleased(ptr: pointer);
begin
  Current.Write(Format('F%d ', [PTestNode(ptr).Id]));
  PTestNode(ptr).Released := True;
  PTestNode(ptr).Mobj.thinker.prev := nil;
  PTestNode(ptr).Mobj.thinker.next := nil;
end;

// What the engine gives to the new list: the same checks that the old code had inside

procedure NewAdded(ANode: PThinkerNode);
begin
  if @ANode.Think = @P_MobjThinker then
    LogMobjAdded(Pmobj_t(ANode));
end;

procedure NewRemoved(ANode: PThinkerNode);
begin
  if @ANode.Think = @P_MobjThinker then
    LogMobjRemoved(Pmobj_t(ANode));
end;

procedure NewRelease(ANode: PThinkerNode);
begin
  LogReleased(ANode);
end;

function NewRunsWhenFrozen(ANode: PThinkerNode): Boolean;
begin
  Inc(FilterCalls);
  Result := False;
  if @ANode.Think = @P_MobjThinker then
    if (Pmobj_t(ANode).player <> nil) or (Pmobj_t(ANode).flags3_ex and MF3_EX_NOTIMEFREEZE <> 0) then
      Result := True;
end;

function NewHooks: TThinkerListHooks;
begin
  Result.Cleared := LogCleared;
  Result.Added := NewAdded;
  Result.Removed := NewRemoved;
  Result.Release := NewRelease;
  Result.RunsWhenFrozen := NewRunsWhenFrozen;
end;

{ TListScenario }

constructor TListScenario.Create;
begin
  inherited Create;
  FNodes := TList<PTestNode>.Create;
end;

destructor TListScenario.Destroy;
var
  LNode: PTestNode;
begin
  for LNode in FNodes do
    FreeMem(LNode);
  FNodes.Free;
  inherited;
end;

function TListScenario.NextRandom(ARange: Integer): Integer;
begin
  FSeed := FSeed * 1103515245 + 12345;
  Result := Integer((FSeed shr 16) mod Cardinal(ARange));
end;

function TListScenario.NewNode(AKind: TTestNodeKind): PTestNode;
begin
  Result := AllocMem(SizeOf(TTestNode));
  FNodes.Add(Result);
  Result.Id := FNodes.Count;
  case AKind of
    TTestNodeKind.Plain:
      Result.Mobj.thinker._function.acp1 := SectorThink;
    TTestNodeKind.MapObject:
      @Result.Mobj.thinker._function.acp1 := @P_MobjThinker;
    TTestNodeKind.PlayerObject:
      begin
        @Result.Mobj.thinker._function.acp1 := @P_MobjThinker;
        Result.Mobj.player := Result;
      end;
    TTestNodeKind.UnfrozenObject:
      begin
        @Result.Mobj.thinker._function.acp1 := @P_MobjThinker;
        Result.Mobj.flags3_ex := MF3_EX_NOTIMEFREEZE or 1;
      end;
  end;
end;

function TListScenario.AddNew(AKind: TTestNodeKind): PTestNode;
begin
  Result := NewNode(AKind);
  Add(Result);
end;

procedure TListScenario.Clear;
begin
  Current := Self;
  DoClear;
end;

procedure TListScenario.Add(ANode: PTestNode);
begin
  Current := Self;
  DoAdd(ANode);
end;

procedure TListScenario.Remove(ANode: PTestNode);
begin
  Current := Self;
  DoRemove(ANode);
end;

procedure TListScenario.Run(AFrozen: Boolean);
begin
  Current := Self;
  DoRun(AFrozen);
end;

function TListScenario.IsRemoved(ANode: PTestNode): Boolean;
begin
  Result := DoIsRemoved(ANode);
end;

procedure TListScenario.Write(const AText: string);
begin
  FLog := FLog + AText;
end;

function TListScenario.LastId: Integer;
begin
  if HeadNode.prev = HeadNode then
    Result := 0
  else
    Result := PTestNode(HeadNode.prev).Id;
end;

function TListScenario.Order: string;
var
  LNode: Pthinker_t;
begin
  Result := '';
  LNode := HeadNode.next;
  while LNode <> HeadNode do
  begin
    Result := Result + IntToStr(PTestNode(LNode).Id);
    if IsRemoved(PTestNode(LNode)) then
      Result := Result + '-';
    Result := Result + ' ';
    LNode := LNode.next;
  end;
end;

function TListScenario.ReverseOrder: string;
var
  LNode: Pthinker_t;
begin
  Result := '';
  LNode := HeadNode.prev;
  while LNode <> HeadNode do
  begin
    Result := Result + IntToStr(PTestNode(LNode).Id) + ' ';
    LNode := LNode.prev;
  end;
end;

procedure TListScenario.RemoveRandom;
var
  LNode: PTestNode;
begin
  LNode := FNodes[NextRandom(FNodes.Count)];
  if not LNode.Released then
    Remove(LNode);
end;

procedure TListScenario.Think(ANode: PTestNode);
var
  LNext: PTestNode;
  LKind: TTestNodeKind;
begin
  if ANode.Released then
  begin
    Write(Format('X%d ', [ANode.Id]));
    Exit;
  end;
  Write(Format('T%d ', [ANode.Id]));
  if Assigned(FOnThink) then
  begin
    FOnThink(ANode);
    Exit;
  end;

  LNext := PTestNode(ANode.Mobj.thinker.next);
  case NextRandom(12) of
    0:
      begin
        LKind := TTestNodeKind(NextRandom(5));
        AddNew(LKind);
      end;
    1:
      Remove(ANode);
    2:
      if Pthinker_t(LNext) <> HeadNode then
        Remove(LNext);
    3:
      RemoveRandom;
    4:
      begin
        LKind := TTestNodeKind(NextRandom(5));
        AddNew(LKind);
        Remove(ANode);
      end;
    5:
      if Pthinker_t(LNext) <> HeadNode then
      begin
        Remove(LNext);
        LKind := TTestNodeKind(NextRandom(5));
        AddNew(LKind);
      end;
  end;
end;

procedure TListScenario.PlayRandom(ASeed: Cardinal; ATics: Integer);
var
  LIndex, LCount, LTic: Integer;
  LKind: TTestNodeKind;
  LFrozen: Boolean;
begin
  FSeed := ASeed;
  Clear;
  LCount := 12 + NextRandom(12);
  for LIndex := 1 to LCount do
  begin
    LKind := TTestNodeKind(NextRandom(5));
    AddNew(LKind);
  end;
  for LTic := 1 to ATics do
  begin
    LCount := NextRandom(4);
    for LIndex := 1 to LCount do
    begin
      LKind := TTestNodeKind(NextRandom(5));
      AddNew(LKind);
    end;
    LCount := NextRandom(4);
    for LIndex := 1 to LCount do
      RemoveRandom;
    LFrozen := NextRandom(4) = 0;
    if LFrozen then
      Write('[frozen ')
    else
      Write('[run ');
    Run(LFrozen);
    Write('] ' + Order + '/ ' + ReverseOrder + sLineBreak);
  end;
end;

{ TOldListScenario }

procedure TOldListScenario.DoClear;
begin
  TTickRoutines.P_InitThinkers;
end;

procedure TOldListScenario.DoAdd(ANode: PTestNode);
begin
  TTickRoutines.P_AddThinker(@ANode.Mobj.thinker);
end;

procedure TOldListScenario.DoRemove(ANode: PTestNode);
begin
  TTickRoutines.P_RemoveThinker(@ANode.Mobj.thinker);
end;

procedure TOldListScenario.DoRun(AFrozen: Boolean);
begin
  isgamefreezed := AFrozen;
  P_RunThinkers;
end;

function TOldListScenario.DoIsRemoved(ANode: PTestNode): Boolean;
begin
  Result := TTickRoutines.P_ThinkerIsRemoved(@ANode.Mobj.thinker);
end;

function TOldListScenario.HeadNode: Pthinker_t;
begin
  Result := @thinkercap;
end;

{ TNewListScenario }

constructor TNewListScenario.Create;
begin
  inherited Create;
  FList := TThinkerList.Create(@FHead, NewHooks);
end;

destructor TNewListScenario.Destroy;
begin
  FList.Free;
  inherited;
end;

procedure TNewListScenario.DoClear;
begin
  FList.Clear;
end;

procedure TNewListScenario.DoAdd(ANode: PTestNode);
begin
  FList.Add(PThinkerNode(ANode));
end;

procedure TNewListScenario.DoRemove(ANode: PTestNode);
begin
  FList.Remove(PThinkerNode(ANode));
end;

procedure TNewListScenario.DoRun(AFrozen: Boolean);
begin
  if AFrozen then
    FList.RunFrozen
  else
    FList.Run;
end;

function TNewListScenario.DoIsRemoved(ANode: PTestNode): Boolean;
begin
  Result := TThinkerList.IsRemoved(PThinkerNode(ANode));
end;

function TNewListScenario.HeadNode: Pthinker_t;
begin
  Result := Pthinker_t(@FHead);
end;

{ TTestThinkersList }

procedure TTestThinkersList.Setup;
begin
  mobjlist.OnClear := LogCleared;
  mobjlist.OnAdd := LogMobjAdded;
  mobjlist.OnRemove := LogMobjRemoved;
  OldZFree := LogReleased;
  OldMobjThink := MobjThink;
  FilterCalls := 0;
  FNew := TNewListScenario.Create;
  FNew.Clear;
  FNew.Calls := '';
end;

procedure TTestThinkersList.TearDown;
begin
  FNew.Free;
  FNew := nil;
  Current := nil;
end;

function TTestThinkersList.PlayOld(ASeed: Cardinal; ATics: Integer): string;
var
  LScenario: TOldListScenario;
begin
  LScenario := TOldListScenario.Create;
  try
    LScenario.PlayRandom(ASeed, ATics);
    Result := LScenario.Calls;
  finally
    LScenario.Free;
  end;
end;

function TTestThinkersList.PlayNew(ASeed: Cardinal; ATics: Integer): string;
var
  LScenario: TNewListScenario;
begin
  LScenario := TNewListScenario.Create;
  try
    LScenario.PlayRandom(ASeed, ATics);
    Result := LScenario.Calls;
  finally
    LScenario.Free;
  end;
end;

procedure TTestThinkersList.DovrebbeAvereIlNodoConLaFormaDelThinkerDelMotore;
var
  LNode: TThinkerNode;
  LOld: thinker_t;
begin
  Assert.AreEqual<Integer>(3 * SizeOf(Pointer), SizeOf(TThinkerNode), 'size');
  Assert.AreEqual<Integer>(SizeOf(thinker_t), SizeOf(TThinkerNode), 'size of the old record');
  Assert.AreEqual<NativeInt>(NativeInt(@LOld.prev) - NativeInt(@LOld),
    NativeInt(@LNode.Prev) - NativeInt(@LNode), 'prev');
  Assert.AreEqual<NativeInt>(NativeInt(@LOld.next) - NativeInt(@LOld),
    NativeInt(@LNode.Next) - NativeInt(@LNode), 'next');
  Assert.AreEqual<NativeInt>(NativeInt(@LOld._function) - NativeInt(@LOld),
    NativeInt(@@LNode.Think) - NativeInt(@LNode), 'function');
end;

procedure TTestThinkersList.DovrebbeDareErroreSenzaLaTesta;
begin
  Assert.WillRaise(
    procedure
    begin
      TThinkerList.Create(nil, NewHooks).Free;
    end,
    EArgumentNilException);
end;

procedure TTestThinkersList.DovrebbeDareErroreSenzaUnaProcedura(AMissing: Integer);
var
  LHooks: TThinkerListHooks;
  LHead: TThinkerNode;
begin
  LHooks := NewHooks;
  case AMissing of
    0: LHooks.Cleared := nil;
    1: LHooks.Added := nil;
    2: LHooks.Removed := nil;
    3: LHooks.Release := nil;
    4: LHooks.RunsWhenFrozen := nil;
  end;
  Assert.WillRaise(
    procedure
    begin
      TThinkerList.Create(@LHead, LHooks).Free;
    end,
    EArgumentNilException);
end;

procedure TTestThinkersList.DovrebbeLasciareLaTestaAlChiamante;
var
  LHead: TThinkerNode;
  LList: TThinkerList;
begin
  LHead.Prev := nil;
  LHead.Next := nil;
  LList := TThinkerList.Create(@LHead, NewHooks);
  try
    Assert.IsTrue(LList.Head = @LHead, 'head');
    Assert.IsTrue(LHead.Next = nil, 'the links are not touched before Clear');
  finally
    LList.Free;
  end;
end;

procedure TTestThinkersList.DovrebbeSvuotareLaListaEAvvisare;
begin
  FNew.AddNew(TTestNodeKind.Plain);
  FNew.AddNew(TTestNodeKind.Plain);
  FNew.Calls := '';
  FNew.Clear;
  Assert.AreEqual('C ', FNew.Calls, 'the owner is told');
  Assert.AreEqual('', FNew.Order, 'forward');
  Assert.AreEqual('', FNew.ReverseOrder, 'backward');
  Assert.IsTrue(FNew.List.Head.Next = FNew.List.Head, 'next of the head');
  Assert.IsTrue(FNew.List.Head.Prev = FNew.List.Head, 'prev of the head');
end;

procedure TTestThinkersList.DovrebbeAggiungereInCoda;
begin
  FNew.AddNew(TTestNodeKind.Plain);
  FNew.AddNew(TTestNodeKind.MapObject);
  FNew.AddNew(TTestNodeKind.NoFunction);
  Assert.AreEqual('1 2 3- ', FNew.Order, 'forward');
  Assert.AreEqual('3 2 1 ', FNew.ReverseOrder, 'backward');
end;

procedure TTestThinkersList.DovrebbeAvvisareDellAggiuntaPrimaDiCollegare;
begin
  FNew.AddNew(TTestNodeKind.Plain);
  FNew.AddNew(TTestNodeKind.MapObject);
  FNew.AddNew(TTestNodeKind.PlayerObject);
  // only the map objects reach the index, and when they do the last node is still the one before
  Assert.AreEqual('A2@1 A3@2 ', FNew.Calls);
end;

procedure TTestThinkersList.DovrebbeSegnareIlRimossoSenzaScollegarlo;
var
  LNode: PTestNode;
begin
  FNew.AddNew(TTestNodeKind.Plain);
  LNode := FNew.AddNew(TTestNodeKind.Plain);
  FNew.AddNew(TTestNodeKind.Plain);
  Assert.IsFalse(FNew.IsRemoved(LNode), 'before');
  FNew.Remove(LNode);
  Assert.IsTrue(FNew.IsRemoved(LNode), 'after');
  Assert.AreEqual('1 2- 3 ', FNew.Order, 'it stays in the list until its turn');
  Assert.AreEqual('', FNew.Calls, 'nothing is released and a plain thinker is not in the index');
end;

procedure TTestThinkersList.DovrebbeAvvisareDellaRimozioneConLaFunzioneAncoraAlSuoPosto;
var
  LNode: PTestNode;
begin
  LNode := FNew.AddNew(TTestNodeKind.MapObject);
  FNew.Calls := '';
  FNew.Remove(LNode);
  Assert.AreEqual('R1:0 ', FNew.Calls, 'told once, before the mark');
  // a second removal finds the mark in place of the function: the index is not asked again
  FNew.Remove(LNode);
  Assert.AreEqual('R1:0 ', FNew.Calls, 'not told twice');
end;

procedure TTestThinkersList.DovrebbeDareRimossoUnNodoSenzaFunzione;
var
  LNode: PTestNode;
begin
  LNode := FNew.AddNew(TTestNodeKind.NoFunction);
  Assert.IsTrue(FNew.IsRemoved(LNode));
end;

procedure TTestThinkersList.DovrebbeEseguireNellOrdineDiAggiunta;
begin
  FNew.OnThink :=
    procedure(ANode: PTestNode)
    begin
    end;
  FNew.AddNew(TTestNodeKind.Plain);
  FNew.AddNew(TTestNodeKind.MapObject);
  FNew.AddNew(TTestNodeKind.Plain);
  FNew.Calls := '';
  FNew.Run(False);
  Assert.AreEqual('T1 T2 T3 ', FNew.Calls, 'first turn');
  FNew.Run(False);
  Assert.AreEqual('T1 T2 T3 T1 T2 T3 ', FNew.Calls, 'second turn');
end;

procedure TTestThinkersList.DovrebbeLiberareIlRimossoAlSuoTurnoENonEseguirlo;
var
  LNode: PTestNode;
begin
  FNew.OnThink :=
    procedure(ANode: PTestNode)
    begin
    end;
  FNew.AddNew(TTestNodeKind.Plain);
  LNode := FNew.AddNew(TTestNodeKind.Plain);
  FNew.AddNew(TTestNodeKind.Plain);
  FNew.Remove(LNode);
  FNew.Run(False);
  Assert.AreEqual('T1 F2 T3 ', FNew.Calls, 'released between its neighbours');
  Assert.AreEqual('1 3 ', FNew.Order, 'forward');
  Assert.AreEqual('3 1 ', FNew.ReverseOrder, 'backward');
  Assert.IsTrue(LNode.Released, 'released');
end;

procedure TTestThinkersList.DovrebbeSaltareIlNodoSenzaFunzione;
begin
  FNew.OnThink :=
    procedure(ANode: PTestNode)
    begin
    end;
  FNew.AddNew(TTestNodeKind.Plain);
  FNew.AddNew(TTestNodeKind.NoFunction);
  FNew.AddNew(TTestNodeKind.Plain);
  FNew.Run(False);
  Assert.AreEqual('T1 T3 ', FNew.Calls, 'not called and not released');
  Assert.AreEqual('1 2- 3 ', FNew.Order, 'it stays in the list');
end;

procedure TTestThinkersList.DovrebbeEseguireNelloStessoTurnoIlNodoAggiuntoDaUnThinker;
var
  LScenario: TNewListScenario;
begin
  LScenario := FNew;
  FNew.OnThink :=
    procedure(ANode: PTestNode)
    begin
      // the last one adds a node after itself: next is read after the call
      if ANode.Id = 2 then
        LScenario.AddNew(TTestNodeKind.Plain);
    end;
  FNew.AddNew(TTestNodeKind.Plain);
  FNew.AddNew(TTestNodeKind.Plain);
  FNew.Run(False);
  Assert.AreEqual('T1 T2 T3 ', FNew.Calls);
end;

procedure TTestThinkersList.DovrebbeLiberareNelloStessoTurnoIlSuccessivoRimossoDaUnThinker;
var
  LScenario: TNewListScenario;
  LVictim: PTestNode;
begin
  LScenario := FNew;
  FNew.AddNew(TTestNodeKind.Plain);
  LVictim := FNew.AddNew(TTestNodeKind.MapObject);
  FNew.AddNew(TTestNodeKind.Plain);
  FNew.Calls := '';
  FNew.OnThink :=
    procedure(ANode: PTestNode)
    begin
      if ANode.Id = 1 then
        LScenario.Remove(LVictim);
    end;
  FNew.Run(False);
  Assert.AreEqual('T1 R2:0 F2 T3 ', FNew.Calls);
  Assert.AreEqual('1 3 ', FNew.Order);
end;

procedure TTestThinkersList.DovrebbeLiberareAlTurnoDopoChiRimuoveSeStesso;
var
  LScenario: TNewListScenario;
begin
  LScenario := FNew;
  FNew.OnThink :=
    procedure(ANode: PTestNode)
    begin
      if ANode.Id = 2 then
        LScenario.Remove(ANode);
    end;
  FNew.AddNew(TTestNodeKind.Plain);
  FNew.AddNew(TTestNodeKind.Plain);
  FNew.AddNew(TTestNodeKind.Plain);
  FNew.Run(False);
  Assert.AreEqual('T1 T2 T3 ', FNew.Calls, 'the turn of the removal');
  Assert.AreEqual('1 2- 3 ', FNew.Order, 'still linked');
  FNew.Run(False);
  Assert.AreEqual('T1 T2 T3 T1 F2 T3 ', FNew.Calls, 'the turn after');
end;

procedure TTestThinkersList.DovrebbeLiberareAlTurnoDopoIlPrecedenteRimossoDaUnThinker;
var
  LScenario: TNewListScenario;
  LFirst: PTestNode;
begin
  LScenario := FNew;
  LFirst := FNew.AddNew(TTestNodeKind.Plain);
  FNew.AddNew(TTestNodeKind.Plain);
  FNew.OnThink :=
    procedure(ANode: PTestNode)
    begin
      if (ANode.Id = 2) and not LScenario.IsRemoved(LFirst) then
        LScenario.Remove(LFirst);
    end;
  FNew.Run(False);
  FNew.Run(False);
  Assert.AreEqual('T1 T2 F1 T2 ', FNew.Calls);
end;

procedure TTestThinkersList.DovrebbeEseguireDaCongelatoSoloChiPassaIlFiltro;
begin
  FNew.OnThink :=
    procedure(ANode: PTestNode)
    begin
    end;
  FNew.AddNew(TTestNodeKind.Plain);
  FNew.AddNew(TTestNodeKind.MapObject);
  FNew.AddNew(TTestNodeKind.PlayerObject);
  FNew.AddNew(TTestNodeKind.UnfrozenObject);
  FNew.Calls := '';
  FNew.Run(True);
  Assert.AreEqual('T3 T4 ', FNew.Calls, 'only the player and the one that ignores the freeze');
  Assert.AreEqual(4, FilterCalls, 'the owner is asked once for every node with a function');
  Assert.AreEqual('1 2 3 4 ', FNew.Order, 'nobody leaves the list');
end;

procedure TTestThinkersList.DovrebbeLiberareIRimossiAncheDaCongelato;
var
  LNode: PTestNode;
begin
  FNew.OnThink :=
    procedure(ANode: PTestNode)
    begin
    end;
  FNew.AddNew(TTestNodeKind.PlayerObject);
  LNode := FNew.AddNew(TTestNodeKind.Plain);
  FNew.AddNew(TTestNodeKind.PlayerObject);
  FNew.Calls := '';
  FNew.Remove(LNode);
  FNew.Run(True);
  Assert.AreEqual('T1 F2 T3 ', FNew.Calls);
  Assert.AreEqual('1 3 ', FNew.Order);
  Assert.AreEqual(2, FilterCalls, 'the filter is not asked for a removed node');
end;

procedure TTestThinkersList.DovrebbeNonChiedereIlFiltroPerUnNodoSenzaFunzione;
begin
  FNew.AddNew(TTestNodeKind.NoFunction);
  FNew.Run(True);
  Assert.AreEqual(0, FilterCalls, 'filter');
  Assert.AreEqual('', FNew.Calls, 'calls');
  Assert.AreEqual('1- ', FNew.Order, 'list');
end;

procedure TTestThinkersList.DovrebbeNonFareNullaConLaListaVuota;
begin
  FNew.Run(False);
  FNew.Run(True);
  Assert.AreEqual('', FNew.Calls, 'calls');
  Assert.AreEqual(0, FilterCalls, 'filter');
  Assert.AreEqual('', FNew.Order, 'list');
end;

procedure TTestThinkersList.DovrebbeDareLeStesseChiamateDelVecchioCodiceInScenariCasuali;
var
  LSeed: Integer;
  LOld, LNew: string;
begin
  for LSeed := 1 to 400 do
  begin
    LOld := PlayOld(Cardinal(LSeed) * 2654435761, 40);
    LNew := PlayNew(Cardinal(LSeed) * 2654435761, 40);
    Assert.IsTrue(Pos('X', LOld) = 0, Format('seed %d: the old list ran a released node', [LSeed]));
    Assert.IsTrue(Pos('F', LOld) > 0, Format('seed %d: nothing was released', [LSeed]));
    Assert.IsTrue(Pos('[frozen', LOld) > 0, Format('seed %d: never frozen', [LSeed]));
    Assert.AreEqual(LOld, LNew, Format('seed %d', [LSeed]));
  end;
end;

procedure TTestThinkersList.DovrebbeDareLeStesseChiamateDelVecchioCodiceInPartiteLunghe;
var
  LSeed: Integer;
  LOld, LNew: string;
begin
  for LSeed := 1 to 8 do
  begin
    LOld := PlayOld(Cardinal(LSeed) * 40503 + 7, 1500);
    LNew := PlayNew(Cardinal(LSeed) * 40503 + 7, 1500);
    Assert.AreEqual(LOld, LNew, Format('seed %d', [LSeed]));
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersList);

end.
