{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - what the tests of the model watch    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.ModelObserver;

interface

uses
  DelphiDoom.War.Sound.Intf, DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Intf, DelphiDoom.War.Model.Gather.Intf;

type
  /// <summary>
  ///   The random generator of the model (the LCG of TWarSeededRandom, with the same numbers) and the events of the
  ///   model in a single object that counts the calls: the draws and their sum, the messages of the status bar, the
  ///   sounds that the original would ask for, and the other events in order. war_model_ref.c counts the same things
  /// </summary>
  TModelObserver = class(TInterfacedObject, IWarRandom, IWarModelEvents, IWarGatherEvents)
  strict private
    FChops: Integer;
    FState: Cardinal;
    FDraws: Cardinal;
    FSum: Cardinal;
    FFlashCount: Cardinal;
    FAudioCount: Cardinal;
    FLeftSelection: Integer;
    FDied: Integer;
    FCollapsing: Integer;
    FDamagePercent: Integer;
    FLastMessage: TWarStatusMessage;
  public
    constructor Create(ASeed: Cardinal);
    function Below(ALimit: Integer): Integer;
    procedure FlashStatus(AMessage: TWarStatusMessage);
    procedure EntityLeftSelection(AEntityId: Word);
    procedure UnitDied(AEntityId: Word; AUnitType: Integer; const APosition: TWarVec2);
    procedure BuildingCollapsing(AEntityId: Word; AUnitType: Integer; const APosition: TWarVec2);
    procedure BuildingDamaged(AEntityId: Word; AHpPercent: Integer);
    procedure TreeChopped(const APosition: TWarVec2);
    /// <summary>How many blows of an axe were heard</summary>
    property Chops: Integer read FChops;
    property Draws: Cardinal read FDraws;
    property Sum: Cardinal read FSum;
    property FlashCount: Cardinal read FFlashCount;
    property AudioCount: Cardinal read FAudioCount;
    property LeftSelection: Integer read FLeftSelection;
    property Died: Integer read FDied;
    property Collapsing: Integer read FCollapsing;
    property DamagePercent: Integer read FDamagePercent;
    property LastMessage: TWarStatusMessage read FLastMessage;
  end;

implementation

{$Q-}
{$R-}

{ TModelObserver }

constructor TModelObserver.Create(ASeed: Cardinal);
begin
  inherited Create;
  FState := ASeed;
  FDamagePercent := -1;
end;

function TModelObserver.Below(ALimit: Integer): Integer;
begin
  Result := 0;
  if ALimit > 0 then
  begin
    FState := FState * 1664525 + 1013904223;
    Result := Integer((FState shr 8) mod Cardinal(ALimit));
  end;
  Inc(FDraws);
  FSum := FSum * 31 + Cardinal(Result) + 1;
end;

procedure TModelObserver.FlashStatus(AMessage: TWarStatusMessage);
begin
  Inc(FFlashCount);
  FLastMessage := AMessage;
end;

procedure TModelObserver.EntityLeftSelection(AEntityId: Word);
begin
  Inc(FLeftSelection);
end;

procedure TModelObserver.UnitDied(AEntityId: Word; AUnitType: Integer; const APosition: TWarVec2);
begin
  Inc(FDied);
  Inc(FAudioCount);
end;

procedure TModelObserver.BuildingCollapsing(AEntityId: Word; AUnitType: Integer; const APosition: TWarVec2);
begin
  Inc(FCollapsing);
  Inc(FAudioCount);
end;

procedure TModelObserver.BuildingDamaged(AEntityId: Word; AHpPercent: Integer);
begin
  FDamagePercent := AHpPercent;
end;

procedure TModelObserver.TreeChopped(const APosition: TWarVec2);
begin
  Inc(FChops);
  Inc(FAudioCount);
end;

end.
