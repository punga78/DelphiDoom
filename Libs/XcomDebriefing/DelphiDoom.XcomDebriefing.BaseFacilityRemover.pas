{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom debriefing library - the facilities of a base that a battle  }
{  destroys (Base::destroyFacility, destroyDisconnectedFacilities,              }
{  getDisconnectedFacilities, cleanupDefenses)                                  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomDebriefing.BaseFacilityRemover;

interface

uses
  System.SysUtils, System.Types, System.Generics.Collections, DelphiDoom.XcomMod.Ruleset, DelphiDoom.XcomMod.RuleBaseFacility,
  DelphiDoom.XcomSave.Base, DelphiDoom.XcomSave.BaseFacility, DelphiDoom.XcomSave.BaseCapacity;

type
  /// <summary>
  ///   Removes a facility from a base and deals with what it held: the workshops, laboratories, stores, quarters,
  ///   hangars and psionic laboratories that the base can no longer hold lose their users (projects, productions,
  ///   transfers). The saved game has no craft of a hangar for drawing (<c>_craftForDrawing</c> is set when the view of
  ///   the base is drawn): a hangar is treated as one without a craft, which is what the C++ does when the base was
  ///   not drawn. The vehicles of the defense (a runtime list of Base) do not exist in the saved game
  /// </summary>
  TXcomBaseFacilityRemover = class
  public
    const
      BASE_SIZE = 6;
  strict private
    FRuleset: TXcomRuleset;
    FCapacity: TXcomBaseCapacity;
    function RulesOf(const AFacility: TXcomBaseFacility): TXcomRuleBaseFacility;
    procedure RemoveHangar(const ABase: TXcomBase; const ARules: TXcomRuleBaseFacility);
    procedure RemovePsiLabs(const ABase: TXcomBase; const ARules: TXcomRuleBaseFacility);
    procedure RemoveLaboratories(const ABase: TXcomBase; const ARules: TXcomRuleBaseFacility);
    procedure RemoveWorkshops(const ABase: TXcomBase; const ARules: TXcomRuleBaseFacility);
    procedure RemoveStorage(const ABase: TXcomBase; const ARules: TXcomRuleBaseFacility);
    procedure RemovePersonnel(const ABase: TXcomBase; const ARules: TXcomRuleBaseFacility);
  public
    /// <param name="ARuleset">The ruleset (not owned)</param>
    constructor Create(const ARuleset: TXcomRuleset);
    destructor Destroy; override;
    /// <summary>destroyFacility: the facility at the index leaves the list (and is freed)</summary>
    procedure DestroyFacility(const ABase: TXcomBase; AIndex: Integer);
    /// <summary>
    ///   getDisconnectedFacilities(0): the indexes (ascending) of the facilities that the access lift does not
    ///   reach, with the way the C++ counts them: a facility counts when its first square is not reached
    /// </summary>
    function DisconnectedFacilities(const ABase: TXcomBase; const ARemove: TXcomBaseFacility = nil): TArray<Integer>;
    /// <summary>destroyDisconnectedFacilities: the unreached facilities are destroyed, the last first</summary>
    procedure DestroyDisconnectedFacilities(const ABase: TXcomBase);
  end;

implementation

type
  TGridSquare = record
    Facility: Integer;
    Visited: Boolean;
  end;

{ TXcomBaseFacilityRemover }

constructor TXcomBaseFacilityRemover.Create(const ARuleset: TXcomRuleset);
begin
  inherited Create;
  FRuleset := ARuleset;
  FCapacity := TXcomBaseCapacity.Create(ARuleset);
end;

destructor TXcomBaseFacilityRemover.Destroy;
begin
  FCapacity.Free;
  inherited Destroy;
end;

function TXcomBaseFacilityRemover.RulesOf(const AFacility: TXcomBaseFacility): TXcomRuleBaseFacility;
begin
  Result := FRuleset.Facilities.Find(AFacility.Rules.FacilityType);
end;

procedure TXcomBaseFacilityRemover.RemoveHangar(const ABase: TXcomBase; const ARules: TXcomRuleBaseFacility);
var
  LIndex: Integer;
  LRemove: Boolean;
begin
  LRemove := True;
  // no craft in the hangar: the productions of crafts that have no hangar left are cancelled
  for LIndex := 0 to ABase.Productions.Count - 1 do
    if (FCapacity.AvailableHangars(ABase) - FCapacity.UsedHangars(ABase) - ARules.Crafts < 0) and
      (ABase.Productions[LIndex].Rules.Category = 'STR_CRAFT') then
    begin
      ABase.Engineers := ABase.Engineers + ABase.Productions[LIndex].AssignedEngineers;
      ABase.Productions.Delete(LIndex);
      LRemove := False;
      Break;
    end;
  if LRemove and (ABase.Transfers.Count > 0) then
    for LIndex := 0 to ABase.Transfers.Count - 1 do
      if TXcomBaseCapacity.KindOf(ABase.Transfers[LIndex]) = tkCraft then
      begin
        ABase.Transfers.Delete(LIndex);
        Break;
      end;
end;

procedure TXcomBaseFacilityRemover.RemovePsiLabs(const ABase: TXcomBase; const ARules: TXcomRuleBaseFacility);
var
  LToRemove: Integer;
  LIndex: Integer;
begin
  LToRemove := ARules.PsiLaboratories - (FCapacity.AvailablePsiLabs(ABase) - FCapacity.UsedPsiLabs(ABase));
  LIndex := 0;
  while (LIndex < ABase.Soldiers.Count) and (LToRemove > 0) do
  begin
    if ABase.Soldiers[LIndex].PsiTraining then
    begin
      ABase.Soldiers[LIndex].PsiTraining := False;
      Dec(LToRemove);
    end;
    Inc(LIndex);
  end;
end;

procedure TXcomBaseFacilityRemover.RemoveLaboratories(const ABase: TXcomBase; const ARules: TXcomRuleBaseFacility);
var
  LToRemove: Integer;
  LIndex: Integer;
begin
  LToRemove := ARules.Laboratories - FCapacity.FreeLaboratories(ABase);
  LIndex := 0;
  while (LIndex < ABase.Research.Count) and (LToRemove > 0) do
  begin
    if ABase.Research[LIndex].Assigned >= LToRemove then
    begin
      ABase.Research[LIndex].Assigned := ABase.Research[LIndex].Assigned - LToRemove;
      ABase.Scientists := ABase.Scientists + LToRemove;
      Break;
    end;
    Dec(LToRemove, ABase.Research[LIndex].Assigned);
    ABase.Scientists := ABase.Scientists + ABase.Research[LIndex].Assigned;
    ABase.Research[LIndex].Assigned := 0;
    Inc(LIndex);
  end;
end;

procedure TXcomBaseFacilityRemover.RemoveWorkshops(const ABase: TXcomBase; const ARules: TXcomRuleBaseFacility);
var
  LToRemove: Integer;
  LIndex: Integer;
begin
  LToRemove := ARules.Workshops - FCapacity.FreeWorkshops(ABase);
  LIndex := 0;
  while (LIndex < ABase.Productions.Count) and (LToRemove > 0) do
  begin
    if ABase.Productions[LIndex].AssignedEngineers > LToRemove then
    begin
      ABase.Productions[LIndex].AssignedEngineers := ABase.Productions[LIndex].AssignedEngineers - LToRemove;
      ABase.Engineers := ABase.Engineers + LToRemove;
      Break;
    end;
    // production is cancelled: it takes up space in the workshop
    Dec(LToRemove, ABase.Productions[LIndex].AssignedEngineers);
    ABase.Engineers := ABase.Engineers + ABase.Productions[LIndex].AssignedEngineers;
    ABase.Productions.Delete(LIndex);
  end;
end;

procedure TXcomBaseFacilityRemover.RemoveStorage(const ABase: TXcomBase; const ARules: TXcomRuleBaseFacility);
var
  LIndex: Integer;
begin
  // the items of the base stay; the ones in transit go to the dead letter office
  if FCapacity.StoresOverfull(ABase, ARules.Storage) and (ABase.Transfers.Count > 0) then
    for LIndex := ABase.Transfers.Count - 1 downto 0 do
      if TXcomBaseCapacity.KindOf(ABase.Transfers[LIndex]) = tkItem then
        ABase.Transfers.Delete(LIndex);
end;

procedure TXcomBaseFacilityRemover.RemovePersonnel(const ABase: TXcomBase; const ARules: TXcomRuleBaseFacility);
var
  LIndex: Integer;
  LKind: TXcomTransferKind;
begin
  // the people stay, but no worker comes in: the soldiers are let in
  if ((FCapacity.AvailableQuarters(ABase) - FCapacity.UsedQuarters(ABase)) - ARules.Personnel < 0) and
    (ABase.Transfers.Count > 0) then
    for LIndex := ABase.Transfers.Count - 1 downto 0 do
    begin
      LKind := TXcomBaseCapacity.KindOf(ABase.Transfers[LIndex]);
      if (LKind = tkEngineer) or (LKind = tkScientist) then
        ABase.Transfers.Delete(LIndex);
    end;
end;

procedure TXcomBaseFacilityRemover.DestroyFacility(const ABase: TXcomBase; AIndex: Integer);
var
  LRules: TXcomRuleBaseFacility;
begin
  LRules := RulesOf(ABase.Facilities[AIndex]);
  if LRules.Crafts > 0 then
    RemoveHangar(ABase, LRules);
  if LRules.PsiLaboratories > 0 then
    RemovePsiLabs(ABase, LRules);
  if LRules.Laboratories <> 0 then
    RemoveLaboratories(ABase, LRules);
  if LRules.Workshops <> 0 then
    RemoveWorkshops(ABase, LRules);
  if LRules.Storage <> 0 then
    RemoveStorage(ABase, LRules);
  if LRules.Personnel <> 0 then
    RemovePersonnel(ABase, LRules);
  ABase.Facilities.Delete(AIndex);
end;

function TXcomBaseFacilityRemover.DisconnectedFacilities(const ABase: TXcomBase;
  const ARemove: TXcomBaseFacility): TArray<Integer>;
var
  LGrid: array[0..BASE_SIZE - 1, 0..BASE_SIZE - 1] of TGridSquare;
  LOrder: TList<TPair<Integer, TPoint>>;
  LStack: TStack<TPoint>;
  LFacility: TXcomBaseFacility;
  LRules: TXcomRuleBaseFacility;
  LLift: TXcomBaseFacility;
  LResult: TList<Integer>;
  LIndex, LX, LY, LPart, LLast: Integer;
  LCurrent: TPoint;

  function RuleBuildTime(AFacility: Integer): Integer;
  begin
    Result := RulesOf(ABase.Facilities[AFacility]).BuildTime;
  end;

  function Open(AFromX, AFromY, AToX, AToY: Integer): Boolean;
  var
    LHere, LThere: Integer;
  begin
    LHere := LGrid[AFromX, AFromY].Facility;
    Result := ABase.Facilities[LHere].BuildTime = 0;
    if Result then
      Exit;
    if (AToX < 0) or (AToX >= BASE_SIZE) or (AToY < 0) or (AToY >= BASE_SIZE) or (LGrid[AToX, AToY].Facility < 0) then
      Exit(False);
    LThere := LGrid[AToX, AToY].Facility;
    Result := (LThere = LHere) or (ABase.Facilities[LThere].BuildTime > RuleBuildTime(LThere));
  end;

begin
  LResult := TList<Integer>.Create;
  LOrder := TList<TPair<Integer, TPoint>>.Create;
  LStack := TStack<TPoint>.Create;
  try
    LLift := nil;
    if Assigned(ARemove) and RulesOf(ARemove).IsLift then
    begin
      for LIndex := 0 to ABase.Facilities.Count - 1 do
        if ABase.Facilities[LIndex] <> ARemove then
          LResult.Add(LIndex);
      Exit(LResult.ToArray);
    end;
    for LX := 0 to BASE_SIZE - 1 do
      for LY := 0 to BASE_SIZE - 1 do
      begin
        LGrid[LX, LY].Facility := -1;
        LGrid[LX, LY].Visited := False;
      end;
    for LIndex := 0 to ABase.Facilities.Count - 1 do
    begin
      LFacility := ABase.Facilities[LIndex];
      if LFacility = ARemove then
        Continue;
      LRules := RulesOf(LFacility);
      if LRules.IsLift then
        LLift := LFacility;
      for LX := 0 to LRules.Size - 1 do
        for LY := 0 to LRules.Size - 1 do
        begin
          LOrder.Add(TPair<Integer, TPoint>.Create(LIndex, TPoint.Create(LFacility.X + LX, LFacility.Y + LY)));
          LGrid[LFacility.X + LX, LFacility.Y + LY].Facility := LIndex;
          LGrid[LFacility.X + LX, LFacility.Y + LY].Visited := False;
        end;
    end;
    // in real trouble: no lift
    if not Assigned(LLift) then
      Exit(LResult.ToArray);
    LStack.Push(TPoint.Create(LLift.X, LLift.Y));
    while LStack.Count > 0 do
    begin
      LCurrent := LStack.Pop;
      LX := LCurrent.X;
      LY := LCurrent.Y;
      if (LX >= 0) and (LX < BASE_SIZE) and (LY >= 0) and (LY < BASE_SIZE) and (LGrid[LX, LY].Facility >= 0) and
        (not LGrid[LX, LY].Visited) then
      begin
        LGrid[LX, LY].Visited := True;
        if Open(LX, LY, LX - 1, LY) then
          LStack.Push(TPoint.Create(LX - 1, LY));
        if Open(LX, LY, LX + 1, LY) then
          LStack.Push(TPoint.Create(LX + 1, LY));
        if Open(LX, LY, LX, LY - 1) then
          LStack.Push(TPoint.Create(LX, LY - 1));
        if Open(LX, LY, LX, LY + 1) then
          LStack.Push(TPoint.Create(LX, LY + 1));
      end;
    end;
    LLast := -1;
    for LPart := 0 to LOrder.Count - 1 do
    begin
      LCurrent := LOrder[LPart].Value;
      if (LOrder[LPart].Key <> LLast) and (not LGrid[LCurrent.X, LCurrent.Y].Visited) then
        LResult.Add(LOrder[LPart].Key);
      LLast := LOrder[LPart].Key;
    end;
    Result := LResult.ToArray;
  finally
    LStack.Free;
    LOrder.Free;
    LResult.Free;
  end;
end;

procedure TXcomBaseFacilityRemover.DestroyDisconnectedFacilities(const ABase: TXcomBase);
var
  LIndexes: TArray<Integer>;
  LPosition: Integer;
begin
  LIndexes := DisconnectedFacilities(ABase);
  for LPosition := High(LIndexes) downto 0 do
    DestroyFacility(ABase, LIndexes[LPosition]);
end;

end.
