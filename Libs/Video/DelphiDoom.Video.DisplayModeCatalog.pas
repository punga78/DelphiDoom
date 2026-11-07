{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - the screen modes to choose from                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.DisplayModeCatalog;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Video.Types,
  DelphiDoom.Video.Intf;

type
  /// <summary>
  ///   The list of the modes the game offers (menu of the video modes, size of the window).
  ///   Port of the choice of the old i_displaymodes: the modes come from an IDisplayModeSource
  /// </summary>
  TDisplayModeCatalog = class(TInterfacedObject, IDisplayModeCatalog)
  strict private
    FSource: IDisplayModeSource;
    FModes: TList<TDisplayMode>;
    procedure Collect(const ARaw: TArray<TDisplayMode>; AMinWidth, AMinHeight, AMinBits,
      AMaxBits, AMaxWidth, AMaxHeight: Integer);
    procedure Add(AWidth, AHeight, ABits: Integer);
    procedure SortModes;
    function Distance(const AMode: TDisplayMode; AWidth, AHeight: Integer): Double;
  public
    constructor Create(const ASource: IDisplayModeSource);
    destructor Destroy; override;
    function GetCount: Integer;
    function GetMode(AIndex: Integer): TDisplayMode;
    procedure Refresh(AMaxWidth, AMaxHeight: Integer);
    procedure Clear;
    function IndexOf(AWidth, AHeight: Integer): Integer;
    function NearestIndex(AWidth, AHeight: Integer): Integer;
    function FindWindowSize(AScreenWidth, AScreenHeight: Integer;
      out AWindowWidth, AWindowHeight: Integer): Boolean;
  end;

implementation

uses
  System.Math, System.Generics.Defaults;

const
  MIN_WIDTH = 320;
  MIN_HEIGHT = 200;
  FALLBACK_MIN_WIDTH = 640;
  FALLBACK_MIN_HEIGHT = 400;
  FALLBACK_MIN_BITS = 16;
  FULL_COLOR_BITS = 32;
  BIGGER_THAN_REQUEST_PENALTY = 50.0;
  SSourceMissing = 'TDisplayModeCatalog: the source of the modes is nil';

{ TDisplayModeCatalog }

constructor TDisplayModeCatalog.Create(const ASource: IDisplayModeSource);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create(SSourceMissing);
  FSource := ASource;
  FModes := TList<TDisplayMode>.Create;
end;

destructor TDisplayModeCatalog.Destroy;
begin
  FModes.Free;
  inherited Destroy;
end;

function TDisplayModeCatalog.GetCount: Integer;
begin
  Result := FModes.Count;
end;

function TDisplayModeCatalog.GetMode(AIndex: Integer): TDisplayMode;
begin
  Result := FModes[AIndex];
end;

procedure TDisplayModeCatalog.Add(AWidth, AHeight, ABits: Integer);
var
  LMode: TDisplayMode;
begin
  LMode.Width := AWidth;
  LMode.Height := AHeight;
  LMode.BitsPerPixel := ABits;
  FModes.Add(LMode);
end;

procedure TDisplayModeCatalog.Collect(const ARaw: TArray<TDisplayMode>; AMinWidth, AMinHeight,
  AMinBits, AMaxBits, AMaxWidth, AMaxHeight: Integer);
var
  LMode: TDisplayMode;
begin
  for LMode in ARaw do
    if (LMode.Width >= AMinWidth) and (LMode.Height >= AMinHeight) and
      (LMode.BitsPerPixel >= AMinBits) and (LMode.BitsPerPixel <= AMaxBits) and
      (IndexOf(LMode.Width, LMode.Height) < 0) and
      (LMode.Width <= AMaxWidth) and (LMode.Height <= AMaxHeight) then
      FModes.Add(LMode);
end;

procedure TDisplayModeCatalog.SortModes;
begin
  FModes.Sort(TComparer<TDisplayMode>.Construct(
    function(const ALeft, ARight: TDisplayMode): Integer
    begin
      Result := ALeft.Width - ARight.Width;
      if Result = 0 then
        Result := ALeft.Height - ARight.Height;
    end));
end;

procedure TDisplayModeCatalog.Refresh(AMaxWidth, AMaxHeight: Integer);
var
  LRaw: TArray<TDisplayMode>;
begin
  FModes.Clear;
  LRaw := FSource.ListModes;
  Collect(LRaw, MIN_WIDTH, MIN_HEIGHT, FULL_COLOR_BITS, FULL_COLOR_BITS, AMaxWidth, AMaxHeight);
  // the old code had this second pass too, but it never ran (the index was already past the end)
  if FModes.Count = 0 then
    Collect(LRaw, FALLBACK_MIN_WIDTH, FALLBACK_MIN_HEIGHT, FALLBACK_MIN_BITS, MaxInt,
      AMaxWidth, AMaxHeight);
  if FModes.Count = 0 then
  begin
    Add(MIN_WIDTH, MIN_HEIGHT, FULL_COLOR_BITS);
    Add(FALLBACK_MIN_WIDTH, FALLBACK_MIN_HEIGHT, FULL_COLOR_BITS);
  end;
  SortModes;
end;

procedure TDisplayModeCatalog.Clear;
begin
  FModes.Clear;
end;

function TDisplayModeCatalog.IndexOf(AWidth, AHeight: Integer): Integer;
var
  LIndex: Integer;
begin
  Result := -1;
  for LIndex := 0 to FModes.Count - 1 do
    if (FModes[LIndex].Width = AWidth) and (FModes[LIndex].Height = AHeight) then
      Exit(LIndex);
end;

function TDisplayModeCatalog.Distance(const AMode: TDisplayMode; AWidth, AHeight: Integer): Double;
begin
  Result := Sqrt(Sqr(AMode.Width - AWidth) + Sqr(AMode.Height - AHeight));
  if AWidth < AMode.Width then
    Result := Result + BIGGER_THAN_REQUEST_PENALTY;
  if AHeight < AMode.Height then
    Result := Result + BIGGER_THAN_REQUEST_PENALTY;
end;

function TDisplayModeCatalog.NearestIndex(AWidth, AHeight: Integer): Integer;
var
  LIndex: Integer;
  LDistance: Double;
  LNearest: Double;
begin
  Result := IndexOf(AWidth, AHeight);
  if Result >= 0 then
    Exit;
  LNearest := 1000000000000.0;
  for LIndex := 0 to FModes.Count - 1 do
  begin
    LDistance := Distance(FModes[LIndex], AWidth, AHeight);
    if LDistance < LNearest then
    begin
      LNearest := LDistance;
      Result := LIndex;
    end;
  end;
end;

function TDisplayModeCatalog.FindWindowSize(AScreenWidth, AScreenHeight: Integer;
  out AWindowWidth, AWindowHeight: Integer): Boolean;
var
  LIndex: Integer;
begin
  AWindowWidth := AScreenWidth;
  AWindowHeight := AScreenHeight;
  LIndex := NearestIndex(AScreenWidth, AScreenHeight);
  Result := LIndex >= 0;
  if Result then
  begin
    AWindowWidth := FModes[LIndex].Width;
    AWindowHeight := FModes[LIndex].Height;
  end;
end;

end.
