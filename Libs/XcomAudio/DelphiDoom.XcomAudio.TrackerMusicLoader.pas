{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom audio library - the module format of the music (a .mod      }
{  file of the SOUND folder; MOD, S3M, XM and IT are told by their content)     }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAudio.TrackerMusicLoader;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomAudio.Intf, DelphiDoom.XcomAudio.Types;

type
  /// <summary>MUSIC_MOD: name.mod in the SOUND folder, read by the tracker of Libs\Mikmod</summary>
  TXcomTrackerMusicLoader = class(TInterfacedObject, IXcomMusicFormatLoader)
  strict private
    FRate: Integer;
    FResources: IXcomResources;
  public
    constructor Create(ARate: Integer);
    function Format: TXcomMusicFormat;
    procedure Reload(const AResources: IXcomResources);
    function Load(const ARule: TXcomMusicRule): IXcomMusicTrack;
  end;

implementation

uses
  DelphiDoom.XcomAudio.TrackerTrack;

constructor TXcomTrackerMusicLoader.Create(ARate: Integer);
begin
  inherited Create;
  FRate := ARate;
end;

function TXcomTrackerMusicLoader.Format: TXcomMusicFormat;
begin
  Result := mfMod;
end;

procedure TXcomTrackerMusicLoader.Reload(const AResources: IXcomResources);
begin
  FResources := AResources;
end;

function TXcomTrackerMusicLoader.Load(const ARule: TXcomMusicRule): IXcomMusicTrack;
var
  LBytes: TBytes;
begin
  Result := nil;
  if (FResources = nil) or (ARule.Name = '') then
    Exit;
  LBytes := FResources.SoundFile(LowerCase(ARule.Name) + '.mod');
  if (Length(LBytes) = 0) or not TXcomTrackerTrack.Accepts(LBytes) then
    Exit;
  Result := TXcomTrackerTrack.Create(LBytes, FRate);
end;

end.
