{******************************************************************************}
{                                                                              }
{  DelphiDoom: Speed library - the sprites of the cars                         }
{  Copyright (C) 1995 by Noriaworks                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom, GLSpeed)     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Speed.CarSpriteBuilder;

interface

uses
  System.SysUtils, DelphiDoom.GameData.Intf, DelphiDoom.Models.I3d.Intf, DelphiDoom.Speed.Intf,
  DelphiDoom.Speed.CarSpriteRenderer;

const
  /// <summary>The sprite name of car N is this prefix and N as two digits (CR00..CR39)</summary>
  SPEED_CAR_SPRITE_PREFIX = 'CR';

type
  /// <summary>
  ///   The cars of Speed Haste are 3D models and the software renderer of the engine draws sprites:
  ///   every car is drawn from five sides (the other three are the mirror of three of them) and the
  ///   pictures go into the WAD as the lumps of a sprite (CR00A1, CR00A2A8, CR00A3A7, CR00A4A6, CR00A5)
  ///   between S_START and S_END. The models of the cars are the ones that the table of the cars names
  /// </summary>
  TSpeedCarSpriteBuilder = class
  strict private
    FParser: II3dParser;
    FRenderer: II3dModelRenderer;
    FMeshFactory: TFunc<II3dMeshBuilder>;
    FPatches: IGamePatchBuilder;
    FAxes: TSpeedModelAxes;
    FLength: Single;
    FPitch: Single;
    FTransparent: Byte;
    function Transpose(const AImage: TSpeedCarSpriteImage): TBytes;
    function SpriteNameOf(ACar: Integer): string;
  public
    /// <param name="AMeshFactory">Makes a new mesh builder for each model (it keeps the triangles)</param>
    /// <param name="ALength">How many pixels long a car is</param>
    /// <param name="APitch">How high over the horizon the eye looks, in degrees</param>
    /// <param name="ATransparent">The index of "no pixel" in a picture of the game</param>
    /// <exception cref="EArgumentNilException">A service is nil</exception>
    constructor Create(const AParser: II3dParser; const ARenderer: II3dModelRenderer;
      const AMeshFactory: TFunc<II3dMeshBuilder>; const APatches: IGamePatchBuilder;
      const AAxes: TSpeedModelAxes; ALength, APitch: Single; ATransparent: Byte);
    /// <summary>
    ///   Draws the 40 cars of the table of the cars and adds their lumps to AWad. A car whose model the
    ///   container does not have is left out of the lumps (its name is empty)
    /// </summary>
    /// <returns>The sprite name of each car, or an empty text for the cars that have no picture</returns>
    function Build(const AContainer: ISpeedContainer; const AWad: IGameWadComposer): TArray<string>;
    /// <summary>
    ///   Draws the scenery models of the circuits (XPR040..XPR090: buildings, stands, billboards) from the
    ///   eight sides at the size of the model, as the sprites XPhh (hh = the type of the thing in
    ///   hexadecimal: XPR05A is the thing 90) and writes the ACTORDEF of their actors
    /// </summary>
    /// <returns>The ACTORDEF text of the scenery that has a picture (empty when there is none)</returns>
    function BuildScenery(const AContainer: ISpeedContainer; const AWad: IGameWadComposer): string;
  end;

implementation

uses
  System.Generics.Collections, DelphiDoom.Models.Types, DelphiDoom.Racing.Types, DelphiDoom.Racing.CarData;

const
  SPRITE_START = 'S_START';
  SPRITE_END = 'S_END';
  PLAYPAL_LUMP = 'PLAYPAL';
  COLORMAP_LUMP = 'COLORMAP';
  // how many cars use the same colors of a model: the variants cycle over the cars of a family
  FRAME = 'A';

{ TSpeedCarSpriteBuilder }

constructor TSpeedCarSpriteBuilder.Create(const AParser: II3dParser; const ARenderer: II3dModelRenderer;
  const AMeshFactory: TFunc<II3dMeshBuilder>; const APatches: IGamePatchBuilder;
  const AAxes: TSpeedModelAxes; ALength, APitch: Single; ATransparent: Byte);
begin
  inherited Create;
  if not Assigned(AParser) then
    raise EArgumentNilException.Create('AParser');
  if not Assigned(ARenderer) then
    raise EArgumentNilException.Create('ARenderer');
  if not Assigned(AMeshFactory) then
    raise EArgumentNilException.Create('AMeshFactory');
  if not Assigned(APatches) then
    raise EArgumentNilException.Create('APatches');
  FParser := AParser;
  FRenderer := ARenderer;
  FMeshFactory := AMeshFactory;
  FPatches := APatches;
  FAxes := AAxes;
  FLength := ALength;
  FPitch := APitch;
  FTransparent := ATransparent;
end;

function TSpeedCarSpriteBuilder.SpriteNameOf(ACar: Integer): string;
begin
  Result := Format('%s%.2d', [SPEED_CAR_SPRITE_PREFIX, ACar]);
end;

function TSpeedCarSpriteBuilder.Transpose(const AImage: TSpeedCarSpriteImage): TBytes;
var
  LColumn, LRow: Integer;
begin
  // the patches are made of columns: the picture is stored row after row
  SetLength(Result, AImage.Width * AImage.Height);
  for LColumn := 0 to AImage.Width - 1 do
    for LRow := 0 to AImage.Height - 1 do
      Result[LColumn * AImage.Height + LRow] := AImage.Pixels[LRow * AImage.Width + LColumn];
end;

function TSpeedCarSpriteBuilder.Build(const AContainer: ISpeedContainer;
  const AWad: IGameWadComposer): TArray<string>;
const
  // the rotations drawn, and the lump name that each one has (the mirrored ones are in the names)
  ROTATIONS: array[0..4] of Integer = (1, 2, 3, 4, 5);
  SUFFIXES: array[0..4] of string = ('1', '2A8', '3A7', '4A6', '5');
var
  LRenderers: TObjectDictionary<string, TSpeedCarSpriteRenderer>;
  LFailed: TList<string>;
  LRenderer: TSpeedCarSpriteRenderer;
  LPlayPal, LColorMap, LModel: TBytes;
  LCar, LStep: Integer;
  LImage: TSpeedCarSpriteImage;
  LModelName: string;
begin
  if not Assigned(AContainer) then
    raise EArgumentNilException.Create('AContainer');
  if not Assigned(AWad) then
    raise EArgumentNilException.Create('AWad');
  SetLength(Result, RACING_CAR_COUNT);
  if (AWad.IndexOf(PLAYPAL_LUMP) < 0) or (AWad.IndexOf(COLORMAP_LUMP) < 0) then
    Exit;
  LPlayPal := AWad.LumpData[AWad.IndexOf(PLAYPAL_LUMP)];
  LColorMap := AWad.LumpData[AWad.IndexOf(COLORMAP_LUMP)];
  LRenderers := TObjectDictionary<string, TSpeedCarSpriteRenderer>.Create([doOwnsValues]);
  LFailed := TList<string>.Create;
  try
    AWad.AddMarker(SPRITE_START);
    for LCar := 0 to RACING_CAR_COUNT - 1 do
    begin
      LModelName := RACING_CAR_DATA[LCar].Model3d;
      if not LRenderers.TryGetValue(LModelName, LRenderer) then
      begin
        if (LFailed.IndexOf(LModelName) >= 0) then
          Continue;
        if not AContainer.TryRead(LModelName, LModel) then
        begin
          LFailed.Add(LModelName);
          Continue;
        end;
        LRenderer := TSpeedCarSpriteRenderer.Create(FParser, FRenderer, FMeshFactory(), LPlayPal, LColorMap,
          FTransparent, FAxes, FLength, FPitch);
        try
          LRenderer.Load(LModel);
        except
          on EModelsException do
          begin
            // a damaged model: the car stays without a picture, the game goes on
            LRenderer.Free;
            LFailed.Add(LModelName);
            Continue;
          end;
        end;
        LRenderers.Add(LModelName, LRenderer);
      end;
      for LStep := 0 to High(ROTATIONS) do
      begin
        LImage := LRenderer.Render(ROTATIONS[LStep], LCar mod SPEED_CAR_VARIANTS);
        AWad.AddLump(SpriteNameOf(LCar) + FRAME + SUFFIXES[LStep],
          FPatches.FromColumns(Transpose(LImage), LImage.Width, LImage.Height, False, LImage.LeftOffset,
            LImage.TopOffset));
      end;
      Result[LCar] := SpriteNameOf(LCar);
    end;
    AWad.AddMarker(SPRITE_END);
  finally
    LRenderers.Free;
    LFailed.Free;
  end;
end;

function TSpeedCarSpriteBuilder.BuildScenery(const AContainer: ISpeedContainer;
  const AWad: IGameWadComposer): string;
const
  ROTATIONS: array[0..4] of Integer = (1, 2, 3, 4, 5);
  SUFFIXES: array[0..4] of string = ('1', '2A8', '3A7', '4A6', '5');
  // the models of the fork are drawn at 0.0122 map units for each unit of the mesh; the pictures use two pixels
  // for each map unit (the actor has Scale 0.5, as the cars do)
  MAP_UNITS_PER_MESH_UNIT = 0.01220703125;
  PIXELS_PER_MAP_UNIT = 2;
var
  LRenderer: TSpeedCarSpriteRenderer;
  LPlayPal, LColorMap, LModel: TBytes;
  LIndex, LStep, LType: Integer;
  LName, LSprite: string;
  LImage: TSpeedCarSpriteImage;
  LText: TStringBuilder;
  LAny: Boolean;
begin
  if not Assigned(AContainer) then
    raise EArgumentNilException.Create('AContainer');
  if not Assigned(AWad) then
    raise EArgumentNilException.Create('AWad');
  Result := '';
  if (AWad.IndexOf(PLAYPAL_LUMP) < 0) or (AWad.IndexOf(COLORMAP_LUMP) < 0) then
    Exit;
  LPlayPal := AWad.LumpData[AWad.IndexOf(PLAYPAL_LUMP)];
  LColorMap := AWad.LumpData[AWad.IndexOf(COLORMAP_LUMP)];
  LText := TStringBuilder.Create;
  try
    LAny := False;
    for LIndex := 0 to AContainer.Count - 1 do
    begin
      LName := UpperCase(AContainer.Entries[LIndex].Name);
      if not (LName.StartsWith('XPR') and LName.EndsWith('.I3D') and (Length(LName) = 10)) then
        Continue;
      LType := StrToIntDef('$' + Copy(LName, 4, 3), -1);
      if (LType < 0) or not AContainer.TryRead(AContainer.Entries[LIndex].Name, LModel) then
        Continue;
      LRenderer := TSpeedCarSpriteRenderer.Create(FParser, FRenderer, FMeshFactory(), LPlayPal, LColorMap,
        FTransparent, FAxes, FLength, FPitch);
      try
        LRenderer.FixedScale := MAP_UNITS_PER_MESH_UNIT * PIXELS_PER_MAP_UNIT;
        try
          LRenderer.Load(LModel);
        except
          on EModelsException do
            Continue;
        end;
        if not LAny then
          AWad.AddMarker(SPRITE_START);
        LAny := True;
        LSprite := Format('XP%.2X', [LType and $FF]);
        for LStep := 0 to High(ROTATIONS) do
        begin
          LImage := LRenderer.Render(ROTATIONS[LStep], 0);
          AWad.AddLump(LSprite + FRAME + SUFFIXES[LStep],
            FPatches.FromColumns(Transpose(LImage), LImage.Width, LImage.Height, False, LImage.LeftOffset,
              LImage.TopOffset));
        end;
        LText.Append('ACTOR SpeedScenery').Append(IntToHex(LType, 2)).Append(' ').Append(LType).Append(#13#10);
        LText.Append('{'#13#10'  Radius 16'#13#10'  Height 16'#13#10'  +NOBLOCKMAP'#13#10);
        LText.Append('  Scale ').Append(FloatToStr(MAP_UNITS_PER_MESH_UNIT / LRenderer.PixelsPerMeshUnit,
          TFormatSettings.Invariant)).Append(#13#10);
        LText.Append('  States'#13#10'  {'#13#10'  Spawn:'#13#10'    ').Append(LSprite).Append(' A -1'#13#10);
        LText.Append('    Stop'#13#10'  }'#13#10'}'#13#10);
      finally
        LRenderer.Free;
      end;
    end;
    if LAny then
      AWad.AddMarker(SPRITE_END);
    Result := LText.ToString;
  finally
    LText.Free;
  end;
end;

end.
