{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - fakes of the interface and scenes    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.UiFakes;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.Generics.Collections, System.Generics.Defaults, DelphiDoom.War.Graphics.Types,
  DelphiDoom.War.Level.Types, DelphiDoom.War.Campaign.Types, DelphiDoom.War.Campaign.Intf, DelphiDoom.War.Ui.Types,
  DelphiDoom.War.Ui.Intf, DelphiDoom.War.Ui.Game;

type
  /// <summary>
  ///   The sprites of the interface without DATA.WAR: a record is a solid color made from its index. Records from
  ///   FRAMES_FROM on are sprites of 3 frames (each frame a color), the others images; the size is 16 x 16 unless it
  ///   is set. The calls are counted
  /// </summary>
  TFakeUiSprites = class(TInterfacedObject, IWarUiSprites)
  strict private
    FSizes: TDictionary<Integer, TPoint>;
    FCreated: TList<Integer>;
    FSpriteResources: TList<Integer>;
  public
    const FRAMES_FROM = 1000;
    /// <summary>The frames of a sprite record of the fake: 3 from FRAMES_FROM on, 31 for the briefing animations</summary>
    constructor Create;
    destructor Destroy; override;
    procedure SetSize(AResource, AWidth, AHeight: Integer);
    function CreateSprite(AResourceIndex: Integer): IWarUiSprite;
    procedure CursorHotspot(AResourceIndex: Integer; out AX, AY: Integer);
    property Created: TList<Integer> read FCreated;
  end;

  /// <summary>Records the audio the scenes ask for</summary>
  TFakeAudio = class(TInterfacedObject, IWarSceneAudio)
  strict private
    FPlayed: TList<Integer>;
    FLoops: TList<Boolean>;
    FMusicStops: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Play(AAudioId: Integer; ALoop: Boolean);
    procedure StopMusic;
    property Played: TList<Integer> read FPlayed;
    property Loops: TList<Boolean> read FLoops;
    property MusicStops: Integer read FMusicStops;
  end;

  /// <summary>A map that does nothing: a scene that counts what is done to it</summary>
  TFakeMapScene = class(TInterfacedObject, IWarScene)
  strict private
    FName: string;
    FLog: TStrings;
  public
    constructor Create(const AName: string; const ALog: TStrings);
    function GetSceneType: TWarSceneType;
    procedure Enter;
    procedure Update;
    procedure Render;
    procedure Leave;
    procedure HandleTextInput(const AText: AnsiString);
  end;

  /// <summary>Makes TFakeMapScene and records what was asked</summary>
  TFakeMapLauncher = class(TInterfacedObject, IWarMapLauncher)
  strict private
    FLog: TStrings;
  public
    constructor Create(const ALog: TStrings);
    function CreateCampaignMap(AMapType: Integer): IWarScene;
    function CreateCustomMap(AMapIndex, APlayerRace, AEnemyRace: Integer): IWarScene;
  end;

  /// <summary>The table of the campaigns of the original with the texts of a short briefing (the data are not needed)</summary>
  TFakeUiRig = class
  public
    /// <summary>Metrics of the two fonts and images of their size, white and opaque</summary>
    class function FontImages: TArray<TWarImage>; static;
    /// <summary>A game on the fake sprites; the caller frees it. The audio and the launcher may be nil</summary>
    class function CreateGame(const ASprites: IWarUiSprites; const AAudio: IWarSceneAudio;
      const ALauncher: IWarMapLauncher; AIsDemo: Boolean): TWarUiGame; static;
  end;

/// <summary>Round to an Integer (Round gives an Int64, and Assert.AreEqual does not infer a type from the two)</summary>
function RoundInt(AValue: Double): Integer;

implementation

uses
  DelphiDoom.War.Types, DelphiDoom.War.Factory, DelphiDoom.War.Font.Types, DelphiDoom.War.Font.Data,
  DelphiDoom.War.Sprite.Sheet,
  DelphiDoom.War.Ui.Sprite, DelphiDoom.War.Ui.Factory, DelphiDoom.War.Campaign.Catalog;

function RoundInt(AValue: Double): Integer;
begin
  Result := Integer(Round(AValue));
end;

{ TFakeUiSprites }

constructor TFakeUiSprites.Create;
var
  LIndex: Integer;
begin
  inherited Create;
  FSpriteResources := TList<Integer>.Create;
  FSizes := TDictionary<Integer, TPoint>.Create;
  FCreated := TList<Integer>.Create;
  // the buttons of the menu are 112 and 48 pixels wide, 15 high; the animations of the briefings are sprites of 31 frames
  SetSize(239, 112, 15);
  SetSize(240, 112, 15);
  SetSize(241, 48, 15);
  SetSize(242, 48, 15);
  for LIndex := 425 to 431 do
    FSpriteResources.Add(LIndex);
end;

destructor TFakeUiSprites.Destroy;
begin
  FCreated.Free;
  FSpriteResources.Free;
  FSizes.Free;
  inherited Destroy;
end;

procedure TFakeUiSprites.SetSize(AResource, AWidth, AHeight: Integer);
begin
  FSizes.AddOrSetValue(AResource, Point(AWidth, AHeight));
end;

function TFakeUiSprites.CreateSprite(AResourceIndex: Integer): IWarUiSprite;
var
  LSize: TPoint;
  LImage: TWarImage;
  LSprite: TWarSprite;
  LFrame: Integer;
  LPixel: Integer;
begin
  FCreated.Add(AResourceIndex);
  if not FSizes.TryGetValue(AResourceIndex, LSize) then
    LSize := Point(16, 16);
  if (AResourceIndex >= FRAMES_FROM) or FSpriteResources.Contains(AResourceIndex) then
  begin
    LSprite.FrameWidth := LSize.X;
    LSprite.FrameHeight := LSize.Y;
    if AResourceIndex >= FRAMES_FROM then
      SetLength(LSprite.Frames, 3)
    else
      SetLength(LSprite.Frames, 31);
    for LFrame := 0 to High(LSprite.Frames) do
    begin
      LSprite.Frames[LFrame].Dx := LFrame * 2;
      LSprite.Frames[LFrame].Dy := LFrame;
      LSprite.Frames[LFrame].Width := LSize.X;
      LSprite.Frames[LFrame].Height := LSize.Y;
      SetLength(LSprite.Frames[LFrame].Pixels, LSize.X * LSize.Y * 4);
      for LPixel := 0 to LSize.X * LSize.Y - 1 do
      begin
        LSprite.Frames[LFrame].Pixels[LPixel * 4] := (AResourceIndex + LFrame * 40) and 255;
        LSprite.Frames[LFrame].Pixels[LPixel * 4 + 1] := 100 + LFrame * 50;
        LSprite.Frames[LFrame].Pixels[LPixel * 4 + 2] := 30;
        LSprite.Frames[LFrame].Pixels[LPixel * 4 + 3] := 255;
      end;
    end;
    Result := TWarUiSprite.Create(TWarSpriteSheet.FromSprite(LSprite, nil), False);
  end
  else
  begin
    LImage.Width := LSize.X;
    LImage.Height := LSize.Y;
    SetLength(LImage.Pixels, LSize.X * LSize.Y * 4);
    for LPixel := 0 to LSize.X * LSize.Y - 1 do
    begin
      LImage.Pixels[LPixel * 4] := AResourceIndex and 255;
      LImage.Pixels[LPixel * 4 + 1] := (AResourceIndex shr 2) and 255;
      LImage.Pixels[LPixel * 4 + 2] := 200;
      LImage.Pixels[LPixel * 4 + 3] := 255;
    end;
    Result := TWarUiSprite.Create(TWarSpriteSheet.FromImage(LImage), True);
  end;
end;

procedure TFakeUiSprites.CursorHotspot(AResourceIndex: Integer; out AX, AY: Integer);
begin
  AX := 3;
  AY := 4;
end;

{ TFakeAudio }

constructor TFakeAudio.Create;
begin
  inherited Create;
  FPlayed := TList<Integer>.Create;
  FLoops := TList<Boolean>.Create;
end;

destructor TFakeAudio.Destroy;
begin
  FLoops.Free;
  FPlayed.Free;
  inherited Destroy;
end;

procedure TFakeAudio.Play(AAudioId: Integer; ALoop: Boolean);
begin
  FPlayed.Add(AAudioId);
  FLoops.Add(ALoop);
end;

procedure TFakeAudio.StopMusic;
begin
  Inc(FMusicStops);
end;

{ TFakeMapScene }

constructor TFakeMapScene.Create(const AName: string; const ALog: TStrings);
begin
  inherited Create;
  FName := AName;
  FLog := ALog;
end;

function TFakeMapScene.GetSceneType: TWarSceneType;
begin
  Result := wstMap;
end;

procedure TFakeMapScene.Enter;
begin
  FLog.Add(FName + ' enter');
end;

procedure TFakeMapScene.Update;
begin
  FLog.Add(FName + ' update');
end;

procedure TFakeMapScene.Render;
begin
  FLog.Add(FName + ' render');
end;

procedure TFakeMapScene.Leave;
begin
  FLog.Add(FName + ' leave');
end;

procedure TFakeMapScene.HandleTextInput(const AText: AnsiString);
begin
  FLog.Add(FName + ' text ' + string(AText));
end;

{ TFakeMapLauncher }

constructor TFakeMapLauncher.Create(const ALog: TStrings);
begin
  inherited Create;
  FLog := ALog;
end;

function TFakeMapLauncher.CreateCampaignMap(AMapType: Integer): IWarScene;
begin
  FLog.Add(Format('campaign %d', [AMapType]));
  Result := TFakeMapScene.Create('map', FLog);
end;

function TFakeMapLauncher.CreateCustomMap(AMapIndex, APlayerRace, AEnemyRace: Integer): IWarScene;
begin
  FLog.Add(Format('custom %d %d %d', [AMapIndex, APlayerRace, AEnemyRace]));
  Result := TFakeMapScene.Create('map', FLog);
end;

{ TFakeUiRig }

class function TFakeUiRig.FontImages: TArray<TWarImage>;
var
  LFont: Integer;
  LData: TWarFontData;
  LIndex: Integer;
begin
  SetLength(Result, 2);
  for LFont := 0 to 1 do
  begin
    LData := WarDefaultFontData(LFont);
    Result[LFont].Width := LData.SpriteWidth;
    Result[LFont].Height := LData.SpriteHeight;
    SetLength(Result[LFont].Pixels, LData.SpriteWidth * LData.SpriteHeight * 4);
    for LIndex := 0 to High(Result[LFont].Pixels) do
      Result[LFont].Pixels[LIndex] := 255;
  end;
end;

class function TFakeUiRig.CreateGame(const ASprites: IWarUiSprites; const AAudio: IWarSceneAudio;
  const ALauncher: IWarMapLauncher; AIsDemo: Boolean): TWarUiGame;
begin
  Result := TWarUiFactory.CreateGameOnSprites(ASprites, TWarFactory.CreateFontMetrics, FontImages, TWarCampaigns.Create,
    AAudio, ALauncher, AIsDemo, 320, 200);
end;

end.
