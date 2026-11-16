{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the score box                                     }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  SpawnScore, FixScoreBox, MemDrawChar, ShiftScore, ScoreThink and ScoreReact  }
{  of kd_keen.c                                                                 }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.ScoreBox;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   The box at the top of the screen with the score, the lives and the flower powers. The numbers are drawn
  ///   with the 8x8 tiles into the planes of the sprite of the box (the sprite changes), and the copies of the
  ///   sprite that the pel panning needs are made again
  /// </summary>
  TKeenScoreBox = class
  strict private
    FContext: IKeenActionContext;
    FGraphics: IKeenGraphics;
    FSprites: IKeenSpriteCache;
    procedure MemDrawChar(var AData: TBytes; ACharTile, ADest, AWidth, APlaneSize: Integer);
    procedure ShiftScore(var ASprite: TKeenSprite);
    procedure DrawNumber(var ASprite: TKeenSprite; ARow, AColumn, ADigits: Integer; const AText: string);
  public
    constructor Create(const AContext: IKeenActionContext; const AGraphics: IKeenGraphics;
      const ASprites: IKeenSpriteCache);
    /// <summary>SpawnScore: the score box is the second actor of the list</summary>
    procedure SpawnScore;
    /// <summary>FixScoreBox: the bomb (level 15) or the flower is drawn in the box</summary>
    procedure FixScoreBox;
    procedure ScoreThink(AObject: PKeenObject);
    procedure ScoreReact(AObject: PKeenObject);
  end;

implementation

uses
  DelphiDoom.Keen.GraphicsIds, DelphiDoom.Keen.StateTable, DelphiDoom.Keen.Arithmetic, DelphiDoom.Keen.SpriteShifter;

const
  /// <summary>CHARWIDTH of the EGA: the bytes of a character</summary>
  CHAR_WIDTH = 1;

{ TKeenScoreBox }

constructor TKeenScoreBox.Create(const AContext: IKeenActionContext; const AGraphics: IKeenGraphics;
  const ASprites: IKeenSpriteCache);
begin
  inherited Create;
  if not Assigned(AContext) then
    raise EArgumentNilException.Create('AContext');
  if not Assigned(AGraphics) then
    raise EArgumentNilException.Create('AGraphics');
  if not Assigned(ASprites) then
    raise EArgumentNilException.Create('ASprites');
  FContext := AContext;
  FGraphics := AGraphics;
  FSprites := ASprites;
end;

procedure TKeenScoreBox.SpawnScore;
var
  LScore: PKeenObject;
begin
  LScore := FContext.Objects.ScoreObj;
  LScore^.ObClass := kcInert;
  LScore^.Active := kaAllways;
  LScore^.NeedToClip := False;
  LScore^.Temp1 := -1; // force score to be updated
  LScore^.Temp2 := -1;
  LScore^.Temp3 := -1; // and flower power
  LScore^.Temp4 := -1; // and lives
  FContext.Physics.NewState(LScore, KEEN_STATE_S_SCORE);
end;

procedure TKeenScoreBox.MemDrawChar(var AData: TBytes; ACharTile, ADest, AWidth, APlaneSize: Integer);
var
  LTile: TBytes;
  LPlane: Integer;
  LRow: Integer;
  LSource: Integer;
begin
  LTile := FGraphics.Tile8(ACharTile);
  // a tile that the file does not have is drawn black
  for LPlane := 0 to 3 do
    for LRow := 0 to 7 do
    begin
      LSource := LPlane * 8 + LRow;
      if LSource < Length(LTile) then
        AData[ADest + LPlane * APlaneSize + LRow * AWidth] := LTile[LSource]
      else
        AData[ADest + LPlane * APlaneSize + LRow * AWidth] := 0;
    end;
end;

procedure TKeenScoreBox.ShiftScore(var ASprite: TKeenSprite);
var
  LEntry: TKeenSpriteEntry;
begin
  LEntry := FSprites.GetEntry(KEEN_GFX_SCOREBOXSPR);
  if LEntry.Shifts < 4 then
    Exit; // a sprite with no copies of 2, 4 and 6 pixels (a test)
  TKeenSpriteShifter.ShiftSprite(ASprite.Data, ASprite.SourceOffset[0], ASprite.SourceOffset[1], LEntry.Width,
    LEntry.Height, 2);
  TKeenSpriteShifter.ShiftSprite(ASprite.Data, ASprite.SourceOffset[0], ASprite.SourceOffset[2], LEntry.Width,
    LEntry.Height, 4);
  TKeenSpriteShifter.ShiftSprite(ASprite.Data, ASprite.SourceOffset[0], ASprite.SourceOffset[3], LEntry.Width,
    LEntry.Height, 6);
end;

procedure TKeenScoreBox.DrawNumber(var ASprite: TKeenSprite; ARow, AColumn, ADigits: Integer; const AText: string);
var
  LDest: Integer;
  LIndex: Integer;
  LWidth: Integer;
  LPlaneSize: Integer;
begin
  LWidth := ASprite.Width[0];
  LPlaneSize := ASprite.PlaneSize[0];
  LDest := ASprite.SourceOffset[0] + LPlaneSize + LWidth * ARow + AColumn * CHAR_WIDTH;
  // erase the leading spaces (the pointer goes on before each character, as in the C)
  for LIndex := ADigits downto Length(AText) + 1 do
  begin
    Inc(LDest, CHAR_WIDTH);
    MemDrawChar(ASprite.Data, 0, LDest, LWidth, LPlaneSize);
  end;
  for LIndex := 1 to Length(AText) do
  begin
    Inc(LDest, CHAR_WIDTH);
    MemDrawChar(ASprite.Data, Ord(AText[LIndex]) - Ord('0') + 1, LDest, LWidth, LPlaneSize);
  end;
end;

procedure TKeenScoreBox.ScoreThink(AObject: PKeenObject);
var
  LState: PKeenGameState;
  LSprite: TKeenSprite;
  LNumber: Word;
  LWidth: Integer;
  LPlaneSize: Integer;
  LDest: Integer;
  LText: string;
  LView: IKeenActionView;
begin
  LState := FContext.Play.GameState;
  LView := FContext.View;
  LSprite := FSprites.GetSprite(KEEN_GFX_SCOREBOXSPR);
  // score changed
  if (LState^.Score div 65536 <> AObject^.Temp1) or (Word(LState^.Score) <> Word(AObject^.Temp2)) then
  begin
    DrawNumber(LSprite, 4, 1, 6, IntToStr(LState^.Score));
    ShiftScore(LSprite);
    AObject^.NeedToReact := True;
    AObject^.Temp1 := TKeenArithmetic.ToInt16(LState^.Score div 65536);
    AObject^.Temp2 := TKeenArithmetic.ToInt16(LState^.Score);
  end;
  // flower power changed
  if FContext.Play.MapOn = 15 then
    LNumber := Word(LState^.BoobusBombs)
  else
    LNumber := Word(LState^.FlowerPowers);
  if LNumber <> Word(AObject^.Temp3) then
  begin
    if LNumber > 99 then
      LText := '99'
    else
      LText := IntToStr(LNumber);
    DrawNumber(LSprite, 20, 5, 2, LText);
    ShiftScore(LSprite);
    AObject^.NeedToReact := True;
    // the C keeps the flower powers even on the level of the bombs: the box is redrawn at every frame there
    AObject^.Temp3 := LState^.FlowerPowers;
  end;
  // lives changed
  if LState^.Lives <> AObject^.Temp4 then
  begin
    LWidth := LSprite.Width[0];
    LPlaneSize := LSprite.PlaneSize[0];
    LDest := LSprite.SourceOffset[0] + LPlaneSize + LWidth * 20 + 2 * CHAR_WIDTH;
    if LState^.Lives > 9 then
      MemDrawChar(LSprite.Data, Ord('9') - Ord('0') + 1, LDest, LWidth, LPlaneSize)
    else
      MemDrawChar(LSprite.Data, LState^.Lives + 1, LDest, LWidth, LPlaneSize);
    ShiftScore(LSprite);
    AObject^.NeedToReact := True;
    AObject^.Temp4 := LState^.Lives;
  end;
  if (Word(LView.OriginXGlobal) <> AObject^.X) or (Word(LView.OriginYGlobal) <> AObject^.Y) then
    AObject^.NeedToReact := True;
end;

procedure TKeenScoreBox.ScoreReact(AObject: PKeenObject);
begin
  AObject^.X := Word(FContext.View.OriginXGlobal);
  AObject^.Y := Word(FContext.View.OriginYGlobal);
  FContext.View.PlaceSprite(AObject^.Sprite, TKeenArithmetic.ToWord(AObject^.X + 4 * KEEN_PIXGLOBAL),
    TKeenArithmetic.ToWord(AObject^.Y + 4 * KEEN_PIXGLOBAL), KEEN_GFX_SCOREBOXSPR, KEEN_PRIORITIES - 1);
end;

procedure TKeenScoreBox.FixScoreBox;
var
  LSprite: TKeenSprite;
  LWidth: Integer;
  LPlaneSize: Integer;
  LDest: Integer;
begin
  LSprite := FSprites.GetSprite(KEEN_GFX_SCOREBOXSPR);
  LWidth := LSprite.Width[0];
  LPlaneSize := LSprite.PlaneSize[0];
  LDest := LSprite.SourceOffset[0] + LPlaneSize + LWidth * 16 + 4 * CHAR_WIDTH;
  // the bomb of Boobus on level 15, otherwise the flower power
  if FContext.Play.MapOn = 15 then
  begin
    MemDrawChar(LSprite.Data, 20, LDest, LWidth, LPlaneSize);
    MemDrawChar(LSprite.Data, 21, LDest + CHAR_WIDTH, LWidth, LPlaneSize);
    MemDrawChar(LSprite.Data, 22, LDest + LWidth * 8, LWidth, LPlaneSize);
    MemDrawChar(LSprite.Data, 23, LDest + LWidth * 8 + CHAR_WIDTH, LWidth, LPlaneSize);
  end
  else
  begin
    MemDrawChar(LSprite.Data, 28, LDest, LWidth, LPlaneSize);
    MemDrawChar(LSprite.Data, 29, LDest + CHAR_WIDTH, LWidth, LPlaneSize);
    MemDrawChar(LSprite.Data, 30, LDest + LWidth * 8, LWidth, LPlaneSize);
    MemDrawChar(LSprite.Data, 31, LDest + LWidth * 8 + CHAR_WIDTH, LWidth, LPlaneSize);
  end;
end;

end.
