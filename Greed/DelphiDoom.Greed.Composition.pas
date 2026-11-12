{******************************************************************************}
{                                                                              }
{  DelphiDoom: Greed32 - the composition root                                   }
{  Port of xGreed (Jim Valavanis, GPL v2 or later), "In Pursuit of Greed"       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Composition;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf;

type
  /// <summary>
  ///   The one place of Greed32 that knows the classes behind the interfaces: the library of the greed port
  ///   (Libs\Greed) and the ones that it shares with the Doom engine (video palette, PNG, files). It does not
  ///   touch ComposeEngine nor TIdTechGeneration: Greed is not an id Tech 1 game
  /// </summary>
  TGreedComposition = class
  public
    /// <summary>The name of the data file of the game</summary>
    const DataFileName = 'GREED.BLO';
    /// <summary>The archive GREED.BLO of the first folder that has it; EGreedNotFoundException if none</summary>
    class function OpenArchive(const AFolders: array of string): IGreedArchive; static;
    /// <summary>What saves maps and lumps as PNG files; the maps of the demos are looked for in AFolders</summary>
    class function CreateExporter(const AArchive: IGreedArchive; const AFolders: array of string): IGreedPngExporter; static;
    /// <summary>What says the kind of a lump</summary>
    class function CreateClassifier(const AArchive: IGreedArchive): IGreedLumpClassifier; static;
    /// <summary>
    ///   Opens the window and plays the map (the first is 0) with the keyboard, or by itself with AAutoPlay, until the
    ///   window is closed or AMaxTics tics were played (0 = no limit). The view is the one from above (the renderer
    ///   of the game, G11, is not ported). With AShotPath the last picture is saved as a PNG. Returns the tics played
    /// </summary>
    class function Play(const AArchive: IGreedArchive; const AFolders: array of string; AMapNumber, AMaxTics: Integer;
      AAutoPlay: Boolean; const AShotPath: string; AFirstPerson: Boolean = True): Integer; static;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Greed.Factory, DelphiDoom.Greed.PngEncoder, DelphiDoom.Greed.PngExporter,
  DelphiDoom.Png.Provider, DelphiDoom.Png.IndexedEncoder, DelphiDoom.Platform.Factory, DelphiDoom.Clock.Factory,
  DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.World,
  DelphiDoom.Greed.Palette, DelphiDoom.Greed.Frame.Intf, DelphiDoom.Greed.PlayerMovement,
  DelphiDoom.Greed.TopDownRenderer, DelphiDoom.Greed.GameLoop, DelphiDoom.Greed.MovementHost,
  DelphiDoom.Greed.AutoPlayInput, DelphiDoom.Greed.HostWindow, DelphiDoom.GameHost.Events.Intf,
  DelphiDoom.GameHost.KeyState, DelphiDoom.GameHost.Win.Window, DelphiDoom.GameHost.Factory,
  DelphiDoom.Greed.Door.Intf,
  DelphiDoom.Greed.DoorRules, DelphiDoom.Greed.DoorSpawner, DelphiDoom.Greed.Random, DelphiDoom.Greed.Render.Types,
  DelphiDoom.Greed.Render.Assets.Intf, DelphiDoom.Greed.Render.ArchiveAssets, DelphiDoom.Greed.Render.FrameRenderer;

const
  WINDOW_TITLE = 'Greed32';

type
  /// <summary>The doors of the archive: the picture of a door is the wall of the lump door_1 .. door_7</summary>
  TGreedArchiveDoorPictures = class(TInterfacedObject, IGreedDoorPictures)
  strict private
    FArchive: IGreedArchive;
  public
    constructor Create(const AArchive: IGreedArchive);
    function PictureOf(ADoorKind: Integer): Integer;
  end;

  /// <summary>The time of the game for the renderer and the doors: the tics of the loop (set when it is made)</summary>
  TGreedLoopTime = class(TInterfacedObject, IGreedRenderClock, IGreedDoorHost)
  public
    Loop: TGreedGameLoop;
    function GetTimeCount: Integer;
    function GetSpriteMoveTime: Integer;
    procedure PlayDoorSound(AX, AY: TGreedFixed);
  end;

{ TGreedArchiveDoorPictures }

constructor TGreedArchiveDoorPictures.Create(const AArchive: IGreedArchive);
begin
  inherited Create;
  FArchive := AArchive;
end;

function TGreedArchiveDoorPictures.PictureOf(ADoorKind: Integer): Integer;
begin
  Result := FArchive.RequireIndexOf('door_' + IntToStr(ADoorKind)) - FArchive.RequireIndexOf(GREED_LUMP_START_WALLS);
end;

{ TGreedLoopTime }

function TGreedLoopTime.GetTimeCount: Integer;
begin
  if Assigned(Loop) then
    Result := Loop.Tics
  else
    Result := 0;
end;

function TGreedLoopTime.GetSpriteMoveTime: Integer;
begin
  Result := GetTimeCount;
end;

procedure TGreedLoopTime.PlayDoorSound(AX, AY: TGreedFixed);
begin
  // the sound device is not connected to the game
end;

{ TGreedComposition }

class function TGreedComposition.OpenArchive(const AFolders: array of string): IGreedArchive;
var
  LFolder: string;
  LPath: string;
begin
  for LFolder in AFolders do
  begin
    LPath := TPath.Combine(LFolder, DataFileName);
    if TFile.Exists(LPath) then
      Exit(TGreedFactory.OpenArchiveFile(LPath));
  end;
  raise EGreedNotFoundException.CreateFmt(SGreedFileNotFound, [DataFileName]);
end;

class function TGreedComposition.CreateExporter(const AArchive: IGreedArchive;
  const AFolders: array of string): IGreedPngExporter;
begin
  Result := TGreedPngExporter.Create(AArchive,
    TGreedFactory.CreateMapLoader(AArchive, TGreedFactory.CreateFolderFiles(AFolders)),
    TGreedFactory.CreateMapRenderer(AArchive), TGreedFactory.CreateLumpClassifier(AArchive),
    TGreedPngEncoder.Create(TPngIndexedEncoder.Create(TPngProvider.Client)),
    TPlatformFactory.CreateFileStore);
end;

class function TGreedComposition.CreateClassifier(const AArchive: IGreedArchive): IGreedLumpClassifier;
begin
  Result := TGreedFactory.CreateLumpClassifier(AArchive);
end;

// The index of the palette whose color is the closest to the one asked for (the distance of the squares of the channels)
function NearestIndex(const APalette: TBytes; ARed, AGreen, ABlue: Integer): Byte;
var
  LIndex, LDistance, LBest: Integer;
begin
  Result := 0;
  LBest := MaxInt;
  for LIndex := 0 to 255 do
  begin
    LDistance := Sqr(APalette[LIndex * 3] - ARed) + Sqr(APalette[LIndex * 3 + 1] - AGreen) +
      Sqr(APalette[LIndex * 3 + 2] - ABlue);
    if LDistance < LBest then
    begin
      LBest := LDistance;
      Result := Byte(LIndex);
    end;
  end;
end;

class function TGreedComposition.Play(const AArchive: IGreedArchive; const AFolders: array of string;
  AMapNumber, AMaxTics: Integer; AAutoPlay: Boolean; const AShotPath: string; AFirstPerson: Boolean): Integer;
var
  LWorld: IGreedWorld;
  LPalette: TBytes;
  LColors: TGreedColors;
  LIndex: Integer;
  LPresenter: IGreedFramePresenter;
  LInput: IGreedInput;
  LPool: TGreedLinkedPool<TGreedElevator>;
  LMovement: TGreedPlayerMovement;
  LLoop: TGreedGameLoop;
  LImage: TGreedImage;
  LEncoder: IGreedImageEncoder;
  LMap: IGreedMap;
  LSprites: TGreedLinkedPool<TGreedSprite>;
  LAssets: TGreedArchiveRenderAssets;
  LAssetsIntf: IGreedRenderAssets;
  LTime: TGreedLoopTime;
  LTimeIntf: IGreedRenderClock;
  LDoorRules: TGreedDoorRules;
  LRenderer: IGreedFrameRenderer;
  LScript: string;
  LBackdrop, LLump: Integer;
  LFrameWidth, LFrameHeight: Integer;
  LScale: Integer;
  LKeys: IGameHostKeyState;
  LWindow: TGameHostWinWindow;
begin
  LWorld := TGreedWorld.Create;
  LMap := TGreedFactory.CreateMapLoader(AArchive, TGreedFactory.CreateFolderFiles(AFolders)).Load(AMapNumber);
  LWorld.Load(LMap);
  LPalette := TGreedPalette.FromLump(AArchive.ReadLump(AArchive.RequireIndexOf(GREED_LUMP_PALETTE)));
  for LIndex := 0 to 255 do
    LColors[LIndex] := (Cardinal(LPalette[LIndex * 3]) shl 16) or (Cardinal(LPalette[LIndex * 3 + 1]) shl 8) or
      Cardinal(LPalette[LIndex * 3 + 2]);
  if AFirstPerson then
  begin
    LFrameWidth := 640;
    LFrameHeight := 400;
    LScale := 1;
  end
  else
  begin
    LFrameWidth := 320;
    LFrameHeight := 200;
    LScale := 3;
  end;
  LPool := nil;
  LSprites := nil;
  LMovement := nil;
  LDoorRules := nil;
  // The window of Libs\GameHost with its display on GDI; the keys it says are down are what the game reads. The
  // system cursor stays visible: the game draws none
  LKeys := TGameHostKeyState.Create;
  LWindow := TGameHostFactory.CreateWindow(WINDOW_TITLE, LKeys as IGameHostEventSink, False);
  try
    LPresenter := TGreedHostWindow.Create(TGameHostFactory.CreateGdiDevice(LWindow), LKeys,
      function: Boolean
      begin
        Result := LWindow.Pump;
      end, WINDOW_TITLE, LFrameWidth, LFrameHeight, LScale);
    LInput := LPresenter as IGreedInput;
    if AAutoPlay then
      LInput := TGreedAutoPlayInput.Create(LInput);
    LPool := TGreedLinkedPool<TGreedElevator>.Create(GREED_MAX_ELEVATORS, 'elevators');
    LSprites := TGreedLinkedPool<TGreedSprite>.Create(GREED_MAX_SPRITES, 'sprites');
    LMovement := TGreedPlayerMovement.Create(LWorld, TGreedMovementHost.Create);
    LTime := TGreedLoopTime.Create;
    LTimeIntf := LTime;
    LDoorRules := TGreedDoorRules.Create(LWorld, LTime);
    TGreedDoorSpawner.SpawnAll(LWorld, TGreedArchiveDoorPictures.Create(AArchive), 0);
    if AFirstPerson then
    begin
      LAssets := TGreedArchiveRenderAssets.Create(AArchive);
      LAssetsIntf := LAssets;
      // the sky of the map is the lump that its script names after BACKDROP
      LScript := TEncoding.ANSI.GetString(LMap.Trailer);
      LBackdrop := Pos('BACKDROP', UpperCase(LScript));
      if LBackdrop > 0 then
      begin
        LScript := Trim(Copy(LScript, LBackdrop + 8, 64));
        LScript := LScript.Split([' ', #9, #13, #10])[0];
        LLump := AArchive.IndexOf(LScript);
        if LLump >= 0 then
          LAssets.LoadBackdrop(LLump);
      end;
      LRenderer := TGreedFrameRenderer.Create(LAssetsIntf, LSprites, LTimeIntf, TGreedRandomTable.Create);
    end
    else
      LRenderer := TGreedTopDownRenderer.Create(NearestIndex(LPalette, 60, 60, 80), NearestIndex(LPalette, 240, 240, 240),
        NearestIndex(LPalette, 230, 200, 40), NearestIndex(LPalette, 240, 40, 40));
    LLoop := TGreedGameLoop.Create(LWorld, LMovement, LPool, LRenderer, LPresenter, LInput,
      TClockFactory.CreateClock(nil), LColors, LFrameWidth, LFrameHeight);
    try
      LTime.Loop := LLoop;
      LLoop.Doors := LDoorRules;
      LLoop.Start(AMapNumber);
      Result := LLoop.Run(AMaxTics);
      if AShotPath <> '' then
      begin
        LImage.Width := LLoop.FrameBuffer.Width;
        LImage.Height := LLoop.FrameBuffer.Height;
        LImage.OriginX := 0;
        LImage.OriginY := 0;
        LImage.Pixels := LLoop.FrameBuffer.Pixels;
        LEncoder := TGreedPngEncoder.Create(TPngIndexedEncoder.Create(TPngProvider.Client));
        TFile.WriteAllBytes(AShotPath, LEncoder.Encode(LImage, LPalette, False));
      end;
    finally
      LTime.Loop := nil;
      LLoop.Free;
    end;
  finally
    LDoorRules.Free;
    LRenderer := nil;
    LMovement.Free;
    LSprites.Free;
    LPool.Free;
    // the display draws in the window: its last references go before the window
    LInput := nil;
    LPresenter := nil;
    LWindow.Free;
  end;
end;

end.