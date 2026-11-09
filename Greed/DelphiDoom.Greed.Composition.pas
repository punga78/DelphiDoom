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
      AAutoPlay: Boolean; const AShotPath: string): Integer; static;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Greed.Factory, DelphiDoom.Greed.PngEncoder, DelphiDoom.Greed.PngExporter,
  DelphiDoom.Video.Factory, DelphiDoom.Png.Provider, DelphiDoom.Platform.Factory, DelphiDoom.Clock.Factory,
  DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool, DelphiDoom.Greed.World.Intf, DelphiDoom.Greed.World,
  DelphiDoom.Greed.Palette, DelphiDoom.Greed.Frame.Intf, DelphiDoom.Greed.PlayerMovement,
  DelphiDoom.Greed.TopDownRenderer, DelphiDoom.Greed.GameLoop, DelphiDoom.Greed.MovementHost,
  DelphiDoom.Greed.AutoPlayInput, DelphiDoom.Greed.Win.Window;

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
    TGreedPngEncoder.Create(TVideoFactory.CreatePaletteConverter, TPngProvider.Client),
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
  AMapNumber, AMaxTics: Integer; AAutoPlay: Boolean; const AShotPath: string): Integer;
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
begin
  LWorld := TGreedWorld.Create;
  LWorld.Load(TGreedFactory.CreateMapLoader(AArchive, TGreedFactory.CreateFolderFiles(AFolders)).Load(AMapNumber));
  LPalette := TGreedPalette.FromLump(AArchive.ReadLump(AArchive.RequireIndexOf(GREED_LUMP_PALETTE)));
  for LIndex := 0 to 255 do
    LColors[LIndex] := (Cardinal(LPalette[LIndex * 3]) shl 16) or (Cardinal(LPalette[LIndex * 3 + 1]) shl 8) or
      Cardinal(LPalette[LIndex * 3 + 2]);
  LPresenter := TGreedWindow.Create('Greed32', 320, 200, 3);
  LInput := LPresenter as IGreedInput;
  if AAutoPlay then
    LInput := TGreedAutoPlayInput.Create(LInput);
  LPool := TGreedLinkedPool<TGreedElevator>.Create(GREED_MAX_ELEVATORS, 'elevators');
  LMovement := TGreedPlayerMovement.Create(LWorld, TGreedMovementHost.Create);
  try
    LLoop := TGreedGameLoop.Create(LWorld, LMovement, LPool,
      TGreedTopDownRenderer.Create(NearestIndex(LPalette, 60, 60, 80), NearestIndex(LPalette, 240, 240, 240),
        NearestIndex(LPalette, 230, 200, 40), NearestIndex(LPalette, 240, 40, 40)), LPresenter, LInput,
      TClockFactory.CreateClock(nil), LColors, 320, 200);
    try
      LLoop.Start(AMapNumber);
      Result := LLoop.Run(AMaxTics);
      if AShotPath <> '' then
      begin
        LImage.Width := LLoop.FrameBuffer.Width;
        LImage.Height := LLoop.FrameBuffer.Height;
        LImage.OriginX := 0;
        LImage.OriginY := 0;
        LImage.Pixels := LLoop.FrameBuffer.Pixels;
        LEncoder := TGreedPngEncoder.Create(TVideoFactory.CreatePaletteConverter, TPngProvider.Client);
        TFile.WriteAllBytes(AShotPath, LEncoder.Encode(LImage, LPalette, False));
      end;
    finally
      LLoop.Free;
    end;
  finally
    LMovement.Free;
    LPool.Free;
  end;
end;

end.
