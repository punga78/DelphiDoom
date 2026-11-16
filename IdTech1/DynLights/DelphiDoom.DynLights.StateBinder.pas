{******************************************************************************}
{                                                                              }
{  DelphiDoom: dynamic lights library - the binding of lights to states       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DynLights.StateBinder;

interface

uses
  System.Generics.Collections, DelphiDoom.DynLights.Intf;

type
  /// <summary>
  ///   Binds a light to the states of a sprite (the old code of the "frame" lines). The states
  ///   that the object goes through are looked at first; if none is of that sprite and frame,
  ///   all the states of the game are. The first time a text binds a state that has lights from
  ///   another text, the lights of that object are taken away, so a later definition replaces
  ///   an earlier one
  /// </summary>
  TDynLightStateBinder = class(TInterfacedObject, IDynLightBinder)
  private
    FStates: IDynLightStateTable;
    /// <summary>The states that this text has already bound</summary>
    FBound: TList<Integer>;
    class function Contains(const AStates: TArray<Integer>; AState: Integer): Boolean; static;
    function Matches(AState, ASprite, AFrame: Integer; AHasFrame: Boolean): Boolean;
    procedure BindState(AState, AObject, ALight: Integer);
  public
    constructor Create(const AStates: IDynLightStateTable);
    destructor Destroy; override;
    procedure BeginScript;
    function Bind(AObject, ASprite, AFrame: Integer; AHasFrame: Boolean; ALight: Integer): Boolean;
  end;

implementation

uses
  System.SysUtils;

const
  SNeedsStates = 'TDynLightStateBinder needs a table of states';

{ TDynLightStateBinder }

constructor TDynLightStateBinder.Create(const AStates: IDynLightStateTable);
begin
  inherited Create;
  if not Assigned(AStates) then
    raise EArgumentNilException.Create(SNeedsStates);
  FStates := AStates;
  FBound := TList<Integer>.Create;
end;

destructor TDynLightStateBinder.Destroy;
begin
  FBound.Free;
  inherited Destroy;
end;

procedure TDynLightStateBinder.BeginScript;
begin
  FBound.Clear;
end;

class function TDynLightStateBinder.Contains(const AStates: TArray<Integer>;
  AState: Integer): Boolean;
var
  LState: Integer;
begin
  for LState in AStates do
    if LState = AState then
      Exit(True);
  Result := False;
end;

function TDynLightStateBinder.Matches(AState, ASprite, AFrame: Integer; AHasFrame: Boolean): Boolean;
begin
  Result := FStates.SpriteOf(AState) = ASprite;
  if Result and AHasFrame then
    Result := FStates.FrameOf(AState) = AFrame;
end;

procedure TDynLightStateBinder.BindState(AState, AObject, ALight: Integer);
begin
  if not FStates.HasLights(AState) then
  begin
    FStates.CreateLights(AState);
    FBound.Add(AState);
  end
  else if FBound.IndexOf(AState) < 0 then
  begin
    if AObject >= 0 then
      FStates.RemoveLightsOfObject(AState, AObject);
    FBound.Add(AState);
  end;
  FStates.AddLight(AState, AObject, ALight);
end;

function TDynLightStateBinder.Bind(AObject, ASprite, AFrame: Integer; AHasFrame: Boolean;
  ALight: Integer): Boolean;
var
  LCandidates: TArray<Integer>;
  LState: Integer;
begin
  Result := False;
  LCandidates := FStates.StatesOfObject(AObject);
  while True do
  begin
    for LState := 0 to FStates.StateCount - 1 do
      if (Length(LCandidates) = 0) or Contains(LCandidates, LState) then
        if Matches(LState, ASprite, AFrame, AHasFrame) then
        begin
          BindState(LState, AObject, ALight);
          Result := True;
        end;

    if Result or (Length(LCandidates) = 0) then
      Break;
    // none of the states of the object is of that sprite: then every state is looked at
    LCandidates := nil;
  end;
end;

end.
