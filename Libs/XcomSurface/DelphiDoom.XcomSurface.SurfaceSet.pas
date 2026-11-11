{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom surface library - SurfaceSet of OpenXcom (frames of the     }
{  same size, by number)                                                        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSurface.SurfaceSet;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Image,
  DelphiDoom.XcomSurface.Surface;

type
  /// <summary>
  ///   A set of frames of one size, numbered with holes allowed (a std::map of Surface). The set owns the frames.
  ///   getTotalFrames is the number of frames that exist, not the highest number
  /// </summary>
  TXcomSurfaceSet = class
  strict private
    FWidth: Integer;
    FHeight: Integer;
    FMaxSharedFrames: Integer;
    FFrames: TObjectDictionary<Integer, TXcomSurface>;
  public
    constructor Create(AWidth, AHeight: Integer);
    destructor Destroy; override;
    /// <summary>The copy constructor: every frame is cloned</summary>
    function Clone: TXcomSurfaceSet;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property MaxSharedFrames: Integer read FMaxSharedFrames write FMaxSharedFrames;
    /// <summary>SurfaceSet::getFrame: nil if there is no such frame. The frame belongs to the set</summary>
    function GetFrame(AIndex: Integer): TXcomSurface;
    /// <summary>SurfaceSet::addFrame: a new blank frame (an old one with the number is replaced)</summary>
    function AddFrame(AIndex: Integer): TXcomSurface;
    /// <summary>Adds a frame with the pixels of an image (loadPck and loadDat)</summary>
    procedure AddImage(AIndex: Integer; const AImage: TXcomImage);
    function TotalFrames: Integer;
    /// <summary>The numbers of the frames, in order</summary>
    function Indexes: TArray<Integer>;
    /// <summary>SurfaceSet::setPalette: the colors go to every frame</summary>
    procedure SetPalette(const AColors: array of TXcomColor; AFirst: Integer = 0);
  end;

implementation

constructor TXcomSurfaceSet.Create(AWidth, AHeight: Integer);
begin
  inherited Create;
  FWidth := AWidth;
  FHeight := AHeight;
  FMaxSharedFrames := -1;
  FFrames := TObjectDictionary<Integer, TXcomSurface>.Create([doOwnsValues]);
end;

destructor TXcomSurfaceSet.Destroy;
begin
  FFrames.Free;
  inherited Destroy;
end;

function TXcomSurfaceSet.Clone: TXcomSurfaceSet;
var
  LIndex: Integer;
begin
  Result := TXcomSurfaceSet.Create(FWidth, FHeight);
  Result.FMaxSharedFrames := FMaxSharedFrames;
  for LIndex in Indexes do
    Result.FFrames.Add(LIndex, FFrames[LIndex].Clone);
end;

function TXcomSurfaceSet.GetFrame(AIndex: Integer): TXcomSurface;
begin
  if not FFrames.TryGetValue(AIndex, Result) then
    Result := nil;
end;

function TXcomSurfaceSet.AddFrame(AIndex: Integer): TXcomSurface;
begin
  Result := TXcomSurface.Create(FWidth, FHeight);
  FFrames.AddOrSetValue(AIndex, Result);
end;

procedure TXcomSurfaceSet.AddImage(AIndex: Integer; const AImage: TXcomImage);
var
  LFrame: TXcomSurface;
begin
  LFrame := TXcomSurface.Create(AImage.Width, AImage.Height);
  FFrames.AddOrSetValue(AIndex, LFrame);
  if Length(AImage.Pixels) >= AImage.Width * AImage.Height then
    Move(AImage.Pixels[0], LFrame.PixelPointer(0, 0)^, AImage.Width * AImage.Height);
end;

function TXcomSurfaceSet.TotalFrames: Integer;
begin
  Result := FFrames.Count;
end;

function TXcomSurfaceSet.Indexes: TArray<Integer>;
begin
  Result := FFrames.Keys.ToArray;
  TArray.Sort<Integer>(Result);
end;

procedure TXcomSurfaceSet.SetPalette(const AColors: array of TXcomColor; AFirst: Integer);
var
  LFrame: TXcomSurface;
begin
  for LFrame in FFrames.Values do
    LFrame.SetColors(AColors, AFirst);
end;

end.
