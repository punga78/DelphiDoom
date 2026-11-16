{******************************************************************************}
{                                                                              }
{  DelphiDoom: info tables library - the states that show a sprite             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Info.SpriteStates;

interface

uses
  DelphiDoom.Info.Intf;

type
  /// <summary>Finds the states by the sprite they show (the old Info_FindStatesFromSprite)</summary>
  TInfoSpriteStates = class sealed
  strict private
    FSprites: IInfoSpriteSource;
    FStates: IInfoStateSource;
  public
    constructor Create(const ASprites: IInfoSpriteSource; const AStates: IInfoStateSource);
    /// <summary>
    ///   ASprite is four characters (all the states of the sprite) or five (the fifth, a letter,
    ///   is the frame: A is 0). The states are in table order; nothing if the sprite is unknown
    ///   or the text has another length
    /// </summary>
    function Find(const ASprite: string): TArray<Integer>;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.Info.SpriteNames,
  DelphiDoom.Info.Types;

{ TInfoSpriteStates }

constructor TInfoSpriteStates.Create(const ASprites: IInfoSpriteSource; const AStates: IInfoStateSource);
begin
  inherited Create;
  if not Assigned(ASprites) then
    raise EArgumentNilException.Create('ASprites');
  if not Assigned(AStates) then
    raise EArgumentNilException.Create('AStates');
  FSprites := ASprites;
  FStates := AStates;
end;

function TInfoSpriteStates.Find(const ASprite: string): TArray<Integer>;
var
  LList: TList<Integer>;
  LCode: Integer;
  LSpriteIndex: Integer;
  LFrame: Integer;
  LCheckFrame: Boolean;
  LIndex: Integer;
  LState: TInfoState;
  LLetter: Char;
begin
  Result := nil;
  LCheckFrame := Length(ASprite) = 5;
  if (Length(ASprite) <> 4) and not LCheckFrame then
    Exit;
  if not TInfoSpriteNames.TryCode(Copy(ASprite, 1, 4), LCode) then
    Exit;

  LSpriteIndex := -1;
  for LIndex := 0 to FSprites.Count - 1 do
    if FSprites.Code(LIndex) = LCode then
    begin
      LSpriteIndex := LIndex;
      Break;
    end;
  if LSpriteIndex = -1 then
    Exit;

  LFrame := 0;
  if LCheckFrame then
  begin
    LLetter := ASprite[5];
    if (LLetter >= 'a') and (LLetter <= 'z') then
      LLetter := Char(Ord(LLetter) - 32);
    LFrame := Ord(LLetter) - Ord('A');
  end;

  LList := TList<Integer>.Create;
  try
    for LIndex := 0 to FStates.Count - 1 do
    begin
      LState := FStates.Get(LIndex);
      if LState.Sprite = LSpriteIndex then
        if (not LCheckFrame) or (LState.Frame = LFrame) then
          LList.Add(LIndex);
    end;
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

end.
