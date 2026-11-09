{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - a cutscene (RuleVideo)                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.RuleVideo;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader;

type
  /// <summary>SlideshowHeader: the music of a slideshow and how long each slide stays</summary>
  TXcomSlideshowHeader = record
    /// <summary>Just the extension-less filename, like "GMWIN"</summary>
    MusicId: string;
    TransitionSeconds: Integer;
  end;

  /// <summary>SlideshowSlide: an image, its caption (a string id), the rectangle of the caption and how long it stays</summary>
  TXcomSlideshowSlide = record
    ImagePath: string;
    Caption: string;
    W: Integer;
    H: Integer;
    X: Integer;
    Y: Integer;
    Color: Integer;
    /// <summary>TextHAlign: ALIGN_LEFT, ALIGN_CENTER, ALIGN_RIGHT (not checked)</summary>
    Align: Integer;
    TransitionSeconds: Integer;
  end;

  /// <summary>The videos, audio tracks or slideshow of a cutscene (RuleVideo)</summary>
  TXcomRuleVideo = class
  strict private
    FId: string;
    FUseUfoAudioSequence: Boolean;
    FVideos: TArray<string>;
    FAudioTracks: TArray<string>;
    FSlideshowHeader: TXcomSlideshowHeader;
    FSlides: TArray<TXcomSlideshowSlide>;
    class function ReadSlide(const ANode: IYamlNode): TXcomSlideshowSlide; static;
    class procedure AppendStrings(var AValues: TArray<string>; const ANode: IYamlNode); static;
  public
    constructor Create(const AId: string);
    procedure Load(const ANode: IYamlNode);
    property VideoId: string read FId;
    property UseUfoAudioSequence: Boolean read FUseUfoAudioSequence;
    property Videos: TArray<string> read FVideos;
    property AudioTracks: TArray<string> read FAudioTracks;
    property SlideshowHeader: TXcomSlideshowHeader read FSlideshowHeader;
    property Slides: TArray<TXcomSlideshowSlide> read FSlides;
  end;

implementation

const
  /// <summary>Screen::ORIGINAL_WIDTH and ORIGINAL_HEIGHT: the default size of a caption</summary>
  ORIGINAL_WIDTH = 320;
  ORIGINAL_HEIGHT = 200;
  ALIGN_LEFT = 0;

{ TXcomRuleVideo }

constructor TXcomRuleVideo.Create(const AId: string);
begin
  inherited Create;
  FId := AId;
end;

class function TXcomRuleVideo.ReadSlide(const ANode: IYamlNode): TXcomSlideshowSlide;
begin
  Result.ImagePath := TXcomNodeReader.ReadString(ANode, 'imagePath', '');
  Result.Caption := TXcomNodeReader.ReadString(ANode, 'caption', '');
  TXcomNodeReader.DecodeIntPair(TXcomNodeReader.Field(ANode, 'captionSize'), ORIGINAL_WIDTH, ORIGINAL_HEIGHT,
    Result.W, Result.H);
  TXcomNodeReader.DecodeIntPair(TXcomNodeReader.Field(ANode, 'captionPos'), 0, 0, Result.X, Result.Y);
  Result.Color := TXcomNodeReader.ReadInteger(ANode, 'captionColor', MaxInt);
  Result.TransitionSeconds := TXcomNodeReader.ReadInteger(ANode, 'transitionSeconds', 0);
  Result.Align := TXcomNodeReader.ReadInteger(ANode, 'captionAlign', ALIGN_LEFT);
end;

class procedure TXcomRuleVideo.AppendStrings(var AValues: TArray<string>; const ANode: IYamlNode);
var
  LItem: IYamlNode;
begin
  for LItem in ANode.Items do
  begin
    SetLength(AValues, Length(AValues) + 1);
    AValues[High(AValues)] := TXcomNodeReader.TextOf(LItem);
  end;
end;

procedure TXcomRuleVideo.Load(const ANode: IYamlNode);
var
  LField, LSlide: IYamlNode;
begin
  FUseUfoAudioSequence := TXcomNodeReader.ReadBoolean(ANode, 'useUfoAudioSequence', False);
  LField := TXcomNodeReader.Field(ANode, 'videos');
  if LField.IsDefined then
    AppendStrings(FVideos, LField);
  LField := TXcomNodeReader.Field(ANode, 'audioTracks');
  if LField.IsDefined then
    AppendStrings(FAudioTracks, LField);
  LField := TXcomNodeReader.Field(ANode, 'slideshow');
  if LField.IsDefined then
  begin
    FSlideshowHeader.MusicId := TXcomNodeReader.ReadString(LField, 'musicId', '');
    FSlideshowHeader.TransitionSeconds := TXcomNodeReader.ReadInteger(LField, 'transitionSeconds', 30);
    for LSlide in TXcomNodeReader.Field(LField, 'slides').Items do
    begin
      SetLength(FSlides, Length(FSlides) + 1);
      FSlides[High(FSlides)] := ReadSlide(LSlide);
    end;
  end;
end;

end.
