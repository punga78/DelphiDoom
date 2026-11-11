{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom audio library - the digital formats of the music (a file    }
{  of the SOUND folder of the mod with the name of the rule and an extension:   }
{  .flac, .ogg, .mp3 or .wav)                                                   }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAudio.DigitalMusicLoader;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomAudio.Intf, DelphiDoom.XcomAudio.Types;

type
  /// <summary>
  ///   One digital format: the file is name + extension in lower case (Mod::loadMusic); a missing file, or one the
  ///   decoder does not recognise, gives nil so that the next format is tried
  /// </summary>
  TXcomDigitalMusicLoader = class(TInterfacedObject, IXcomMusicFormatLoader)
  strict private
    FFormat: TXcomMusicFormat;
    FExtension: string;
    FFormatName: string;
    FDecoder: IXcomSampleDecoder;
    FRate: Integer;
    FResources: IXcomResources;
  public
    /// <param name="AFormat">mfFlac, mfOgg, mfMp3 or mfWav</param>
    /// <param name="AExtension">With the dot: .flac</param>
    /// <param name="AFormatName">As the audio options show it: FLAC</param>
    constructor Create(AFormat: TXcomMusicFormat; const AExtension, AFormatName: string;
      const ADecoder: IXcomSampleDecoder; ARate: Integer);
    function Format: TXcomMusicFormat;
    procedure Reload(const AResources: IXcomResources);
    function Load(const ARule: TXcomMusicRule): IXcomMusicTrack;
  end;

implementation

uses
  DelphiDoom.XcomAudio.DigitalTrack;

constructor TXcomDigitalMusicLoader.Create(AFormat: TXcomMusicFormat; const AExtension, AFormatName: string;
  const ADecoder: IXcomSampleDecoder; ARate: Integer);
begin
  inherited Create;
  if not Assigned(ADecoder) then
    raise EArgumentNilException.Create('ADecoder');
  FFormat := AFormat;
  FExtension := AExtension;
  FFormatName := AFormatName;
  FDecoder := ADecoder;
  FRate := ARate;
end;

function TXcomDigitalMusicLoader.Format: TXcomMusicFormat;
begin
  Result := FFormat;
end;

procedure TXcomDigitalMusicLoader.Reload(const AResources: IXcomResources);
begin
  FResources := AResources;
end;

function TXcomDigitalMusicLoader.Load(const ARule: TXcomMusicRule): IXcomMusicTrack;
var
  LBytes: TBytes;
begin
  Result := nil;
  if (FResources = nil) or (ARule.Name = '') then
    Exit;
  LBytes := FResources.SoundFile(LowerCase(ARule.Name) + FExtension);
  if (Length(LBytes) = 0) or not FDecoder.Accepts(LBytes) then
    Exit;
  Result := TXcomDigitalTrack.Create(FDecoder, LBytes, FRate, FFormatName);
end;

end.
