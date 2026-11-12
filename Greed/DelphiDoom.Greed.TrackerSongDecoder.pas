{******************************************************************************}
{                                                                              }
{  DelphiDoom: Greed32 - the songs of the game played by the tracker            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.TrackerSongDecoder;

interface

uses
  System.SysUtils, DelphiDoom.Greed.PcmMixer;

type
  /// <summary>
  ///   IGreedSongDecoder on the tracker of Libs\Mikmod: the songs of the game are S3M and MOD modules (the original
  ///   gave them to BASS); the tracker also reads XM and IT. A song plays in a loop, as in the original
  /// </summary>
  TGreedTrackerSongDecoder = class(TInterfacedObject, IGreedSongDecoder)
  public
    function Open(const AModule: TBytes; ARate: Integer): IGreedSongRenderer;
  end;

implementation

uses
  DelphiDoom.Tracker.Types, DelphiDoom.Tracker.Player, DelphiDoom.Tracker.Loader.S3m,
  DelphiDoom.Tracker.Loader.ProTracker, DelphiDoom.Tracker.Loader.Xm, DelphiDoom.Tracker.Loader.It;

type
  /// <summary>A module and the player that reads it: the player uses the module, so it goes first</summary>
  TGreedTrackerSong = class(TInterfacedObject, IGreedSongRenderer)
  strict private
    FModule: TTrackerModule;
    FPlayer: TTrackerPlayer;
  public
    /// <summary>Takes the module: it is freed with the song</summary>
    constructor Create(AModule: TTrackerModule; ARate: Integer);
    destructor Destroy; override;
    procedure Render(const ASamples: TArray<SmallInt>; AFrames: Integer);
  end;

{ TGreedTrackerSong }

constructor TGreedTrackerSong.Create(AModule: TTrackerModule; ARate: Integer);
begin
  inherited Create;
  FModule := AModule;
  FPlayer := TTrackerPlayer.Create(FModule, ARate, True);
end;

destructor TGreedTrackerSong.Destroy;
begin
  FPlayer.Free;
  FModule.Free;
  inherited Destroy;
end;

procedure TGreedTrackerSong.Render(const ASamples: TArray<SmallInt>; AFrames: Integer);
begin
  FPlayer.Render(ASamples, AFrames);
end;

{ TGreedTrackerSongDecoder }

function TGreedTrackerSongDecoder.Open(const AModule: TBytes; ARate: Integer): IGreedSongRenderer;
var
  LModule: TTrackerModule;
begin
  Result := nil;
  try
    if TTrackerXmLoader.Detect(AModule) then
      LModule := TTrackerXmLoader.Load(AModule)
    else if TTrackerItLoader.Detect(AModule) then
      LModule := TTrackerItLoader.Load(AModule)
    else if TTrackerS3mLoader.Detect(AModule) then
      LModule := TTrackerS3mLoader.Load(AModule)
    else if TTrackerModLoader.Detect(AModule) then
      LModule := TTrackerModLoader.Load(AModule)
    else
      Exit;
  except
    // a module that the tracker cannot read is a game without that song, as with a device that cannot play
    on ETrackerException do
      Exit;
  end;
  Result := TGreedTrackerSong.Create(LModule, ARate);
end;

end.
