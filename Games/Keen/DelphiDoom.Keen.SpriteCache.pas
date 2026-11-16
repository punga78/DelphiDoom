{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the sprites with their shifts                     }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  CAL_CacheSprite of id_ca.c                                                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.SpriteCache;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   Makes the sprites of the game once, with the copies that the pel panning needs (CAL_CacheSprite): the
  ///   sprite table says how many shifted copies a sprite has (1: only the plain one, 2: also 4 pixels, 4: also
  ///   2, 4 and 6 pixels) and the copies are made when the sprite is first asked for
  /// </summary>
  TKeenSpriteCache = class(TInterfacedObject, IKeenSpriteCache)
  strict private
    FGraphics: IKeenGraphics;
    FTable: TArray<TKeenSpriteEntry>;
    FSprites: array of TKeenSprite;
    FMade: array of Boolean;
    function MakeSprite(AIndex: Integer): TKeenSprite;
    function IndexOf(ASpriteChunk: Integer): Integer;
  public
    constructor Create(const AGraphics: IKeenGraphics);
    function GetSprite(ASpriteChunk: Integer): TKeenSprite;
    function GetEntry(ASpriteChunk: Integer): TKeenSpriteEntry;
    /// <summary>
    ///   CAL_CacheSprite for planes that are already expanded: the sprite of ASmallPlane * 5 bytes (mask and 4
    ///   planes) with its shifted copies. AShifts is 1, 2 or 4
    /// </summary>
    class function Build(const APlanar: TBytes; AWidth, AHeight, AShifts, ASpriteChunk: Integer): TKeenSprite; static;
  end;

implementation

uses
  DelphiDoom.Keen.SpriteShifter;

{ TKeenSpriteCache }

constructor TKeenSpriteCache.Create(const AGraphics: IKeenGraphics);
begin
  inherited Create;
  if not Assigned(AGraphics) then
    raise EArgumentNilException.Create('AGraphics');
  FGraphics := AGraphics;
  FTable := AGraphics.SpriteTable;
  SetLength(FSprites, Length(FTable));
  SetLength(FMade, Length(FTable));
end;

function TKeenSpriteCache.IndexOf(ASpriteChunk: Integer): Integer;
begin
  Result := ASpriteChunk - KEEN_STARTSPRITES;
  if (Result < 0) or (Result >= Length(FTable)) then
    raise EKeenDataException.CreateFmt(SKeenSpriteInvalid, [Result, Length(FTable)]);
end;

class function TKeenSpriteCache.Build(const APlanar: TBytes; AWidth, AHeight, AShifts,
  ASpriteChunk: Integer): TKeenSprite;
var
  LSmallPlane: Integer;
  LBigPlane: Integer;
  LStarts: array[0..4] of Integer;
  LIndex: Integer;
begin
  LSmallPlane := AWidth * AHeight;
  LBigPlane := (AWidth + 1) * AHeight;
  if Length(APlanar) < LSmallPlane * (KEEN_EGA_PLANES + 1) then
    raise EKeenDataException.CreateFmt(SKeenSpriteTooShort, [LSmallPlane * (KEEN_EGA_PLANES + 1), Length(APlanar)]);
  FillChar(Result, SizeOf(Result), 0);
  LStarts[0] := 0;
  LStarts[1] := LStarts[0] + LSmallPlane * 5;
  LStarts[2] := LStarts[1] + LBigPlane * 5;
  LStarts[3] := LStarts[2] + LBigPlane * 5;
  LStarts[4] := LStarts[3] + LBigPlane * 5;
  if not (AShifts in [1, 2, 4]) then
    raise EKeenDataException.CreateFmt(SKeenSpriteShifts, [ASpriteChunk, AShifts]);
  SetLength(Result.Data, LStarts[AShifts]);
  Move(APlanar[0], Result.Data[0], LSmallPlane * 5);
  case AShifts of
    1:
      for LIndex := 0 to 3 do
      begin
        Result.SourceOffset[LIndex] := LStarts[0];
        Result.PlaneSize[LIndex] := LSmallPlane;
        Result.Width[LIndex] := AWidth;
      end;
    2:
      begin
        for LIndex := 0 to 1 do
        begin
          Result.SourceOffset[LIndex] := LStarts[0];
          Result.PlaneSize[LIndex] := LSmallPlane;
          Result.Width[LIndex] := AWidth;
        end;
        for LIndex := 2 to 3 do
        begin
          Result.SourceOffset[LIndex] := LStarts[1];
          Result.PlaneSize[LIndex] := LBigPlane;
          Result.Width[LIndex] := AWidth + 1;
        end;
        TKeenSpriteShifter.ShiftSprite(Result.Data, Result.SourceOffset[0], Result.SourceOffset[2], AWidth, AHeight, 4);
      end;
    4:
      begin
        Result.SourceOffset[0] := LStarts[0];
        Result.PlaneSize[0] := LSmallPlane;
        Result.Width[0] := AWidth;
        for LIndex := 1 to 3 do
        begin
          Result.SourceOffset[LIndex] := LStarts[LIndex];
          Result.PlaneSize[LIndex] := LBigPlane;
          Result.Width[LIndex] := AWidth + 1;
          TKeenSpriteShifter.ShiftSprite(Result.Data, Result.SourceOffset[0], Result.SourceOffset[LIndex],
            AWidth, AHeight, LIndex * 2);
        end;
      end;
  end;
end;

function TKeenSpriteCache.MakeSprite(AIndex: Integer): TKeenSprite;
var
  LEntry: TKeenSpriteEntry;
begin
  LEntry := FTable[AIndex];
  Result := Build(FGraphics.SpritePlanar(AIndex), LEntry.Width, LEntry.Height, LEntry.Shifts,
    KEEN_STARTSPRITES + AIndex);
end;

function TKeenSpriteCache.GetSprite(ASpriteChunk: Integer): TKeenSprite;
var
  LIndex: Integer;
begin
  LIndex := IndexOf(ASpriteChunk);
  if not FMade[LIndex] then
  begin
    FSprites[LIndex] := MakeSprite(LIndex);
    FMade[LIndex] := True;
  end;
  Result := FSprites[LIndex];
end;

function TKeenSpriteCache.GetEntry(ASpriteChunk: Integer): TKeenSpriteEntry;
begin
  Result := FTable[IndexOf(ASpriteChunk)];
end;

end.
