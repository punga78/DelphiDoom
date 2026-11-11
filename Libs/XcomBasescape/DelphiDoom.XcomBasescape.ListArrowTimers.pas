{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom basescape library - the arrows of a list of quantities      }
{  (lstItemsLeftArrowPress... of PurchaseState, SellState, TransferItemsState)  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBasescape.ListArrowTimers;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Action, DelphiDoom.XcomEngine.Timer,
  DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Options, DelphiDoom.XcomUi.TextList;

type
  /// <summary>
  ///   The behaviour that the three lists of quantities (purchase, sale, transfer) share: the left arrow of the
  ///   selected row increases (left click one, right click as much as possible, held down it repeats after 250 ms
  ///   and then every 50 ms), the right one decreases, the mouse wheel over the arrows changes by the option value.
  ///   The state that owns it calls Think and frees it before the list
  /// </summary>
  TXcomListArrowTimers = class
  strict private
    FList: TXcomTextList;
    FOptions: TXcomOptions;
    FTimerInc: TXcomTimer;
    FTimerDec: TXcomTimer;
    FIncrease: TProc<Integer>;
    FDecrease: TProc<Integer>;
    FSelected: Integer;
    procedure LeftPress(AAction: TXcomAction);
    procedure LeftRelease(AAction: TXcomAction);
    procedure LeftClick(AAction: TXcomAction);
    procedure RightPress(AAction: TXcomAction);
    procedure RightRelease(AAction: TXcomAction);
    procedure RightClick(AAction: TXcomAction);
    procedure ListPress(AAction: TXcomAction);
    procedure IncreaseTick;
    procedure DecreaseTick;
  public
    /// <param name="AList">The list (owned by the state), already with its arrow column</param>
    /// <param name="AIncrease">Increase the selected row by the quantity</param>
    /// <param name="ADecrease">Decrease the selected row by the quantity</param>
    constructor Create(const AClock: IXcomClock; AOptions: TXcomOptions; AList: TXcomTextList;
      const AIncrease, ADecrease: TProc<Integer>);
    destructor Destroy; override;
    procedure Think;
    /// <summary>The increase timer stops (after an error message)</summary>
    procedure StopIncrease;
    /// <summary>The row that the last press of an arrow selected (_sel)</summary>
    property Selected: Integer read FSelected;
  end;

implementation

{ TXcomListArrowTimers }

constructor TXcomListArrowTimers.Create(const AClock: IXcomClock; AOptions: TXcomOptions; AList: TXcomTextList;
  const AIncrease, ADecrease: TProc<Integer>);
begin
  inherited Create;
  FList := AList;
  FOptions := AOptions;
  FIncrease := AIncrease;
  FDecrease := ADecrease;
  FTimerInc := TXcomTimer.Create(AClock, 250);
  FTimerInc.OnTimerState(IncreaseTick);
  FTimerDec := TXcomTimer.Create(AClock, 250);
  FTimerDec.OnTimerState(DecreaseTick);
  FList.OnLeftArrowPress(LeftPress);
  FList.OnLeftArrowRelease(LeftRelease);
  FList.OnLeftArrowClick(LeftClick);
  FList.OnRightArrowPress(RightPress);
  FList.OnRightArrowRelease(RightRelease);
  FList.OnRightArrowClick(RightClick);
  FList.OnMousePress(ListPress);
end;

destructor TXcomListArrowTimers.Destroy;
begin
  FTimerInc.Free;
  FTimerDec.Free;
  inherited Destroy;
end;

procedure TXcomListArrowTimers.Think;
begin
  FTimerInc.Think(True, False);
  FTimerDec.Think(True, False);
end;

procedure TXcomListArrowTimers.StopIncrease;
begin
  FTimerInc.Stop;
end;

procedure TXcomListArrowTimers.LeftPress(AAction: TXcomAction);
begin
  FSelected := FList.GetSelectedRow;
  if (AAction.Details^.Button = XCOM_BUTTON_LEFT) and not FTimerInc.IsRunning then
    FTimerInc.Start;
end;

procedure TXcomListArrowTimers.LeftRelease(AAction: TXcomAction);
begin
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
    FTimerInc.Stop;
end;

procedure TXcomListArrowTimers.LeftClick(AAction: TXcomAction);
begin
  if AAction.Details^.Button = XCOM_BUTTON_RIGHT then
    FIncrease(MaxInt);
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
  begin
    FIncrease(1);
    FTimerInc.SetInterval(250);
    FTimerDec.SetInterval(250);
  end;
end;

procedure TXcomListArrowTimers.RightPress(AAction: TXcomAction);
begin
  FSelected := FList.GetSelectedRow;
  if (AAction.Details^.Button = XCOM_BUTTON_LEFT) and not FTimerDec.IsRunning then
    FTimerDec.Start;
end;

procedure TXcomListArrowTimers.RightRelease(AAction: TXcomAction);
begin
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
    FTimerDec.Stop;
end;

procedure TXcomListArrowTimers.RightClick(AAction: TXcomAction);
begin
  if AAction.Details^.Button = XCOM_BUTTON_RIGHT then
    FDecrease(MaxInt);
  if AAction.Details^.Button = XCOM_BUTTON_LEFT then
  begin
    FDecrease(1);
    FTimerInc.SetInterval(250);
    FTimerDec.SetInterval(250);
  end;
end;

procedure TXcomListArrowTimers.ListPress(AAction: TXcomAction);
var
  LOverArrows: Boolean;
begin
  FSelected := FList.GetSelectedRow;
  if (AAction.Details^.Button <> XCOM_BUTTON_WHEELUP) and (AAction.Details^.Button <> XCOM_BUTTON_WHEELDOWN) then
    Exit;
  FTimerInc.Stop;
  FTimerDec.Stop;
  LOverArrows := (AAction.AbsoluteXMouse >= FList.GetArrowsLeftEdge) and
    (AAction.AbsoluteXMouse <= FList.GetArrowsRightEdge);
  if LOverArrows then
    if AAction.Details^.Button = XCOM_BUTTON_WHEELUP then
      FIncrease(FOptions.ChangeValueByMouseWheel)
    else
      FDecrease(FOptions.ChangeValueByMouseWheel);
end;

procedure TXcomListArrowTimers.IncreaseTick;
begin
  FTimerDec.SetInterval(50);
  FTimerInc.SetInterval(50);
  FIncrease(1);
end;

procedure TXcomListArrowTimers.DecreaseTick;
begin
  FTimerInc.SetInterval(50);
  FTimerDec.SetInterval(50);
  FDecrease(1);
end;

end.
