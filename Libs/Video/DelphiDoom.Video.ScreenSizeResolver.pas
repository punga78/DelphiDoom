{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - the size of the screen from the command line    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.ScreenSizeResolver;

interface

uses
  System.SysUtils,
  DelphiDoom.CommandLine.Intf,
  DelphiDoom.Video.Types,
  DelphiDoom.Video.Intf;

type
  /// <summary>
  ///   The size part of the old D_CheckCommonParams, in the same order (the command line
  ///   remembers the options it was asked for, and the console lists them in that order)
  /// </summary>
  TScreenSizeResolver = class(TInterfacedObject, IScreenSizeResolver)
  strict private
    FCommandLine: ICommandLine;
    FMetrics: IDisplayMetrics;
    FLimits: TScreenSizeLimits;
    FParseNumber: TFunc<string, Integer>;
    function ValueAfter(const AName: string; out AValue: string): Boolean;
    function ClampWidth(AWidth: Integer): Integer;
    function ClampHeight(AHeight: Integer): Integer;
    procedure ApplyPreset(const AName: string; APresetWidth, APresetHeight: Integer;
      var AWidth, AHeight: Integer);
  public
    /// <param name="AParseNumber">The number of a text (the atoi of the engine: 0 when it is not a number)</param>
    constructor Create(const ACommandLine: ICommandLine; const AMetrics: IDisplayMetrics;
      const ALimits: TScreenSizeLimits; const AParseNumber: TFunc<string, Integer>);
    procedure Resolve(var AWidth, AHeight: Integer);
  end;

implementation

{ TScreenSizeResolver }

constructor TScreenSizeResolver.Create(const ACommandLine: ICommandLine;
  const AMetrics: IDisplayMetrics; const ALimits: TScreenSizeLimits;
  const AParseNumber: TFunc<string, Integer>);
begin
  inherited Create;
  if not Assigned(ACommandLine) then
    raise EArgumentNilException.Create('ACommandLine');
  if not Assigned(AMetrics) then
    raise EArgumentNilException.Create('AMetrics');
  if not Assigned(AParseNumber) then
    raise EArgumentNilException.Create('AParseNumber');
  FCommandLine := ACommandLine;
  FMetrics := AMetrics;
  FLimits := ALimits;
  FParseNumber := AParseNumber;
end;

function TScreenSizeResolver.ValueAfter(const AName: string; out AValue: string): Boolean;
var
  LPosition: Integer;
begin
  LPosition := FCommandLine.IndexOf(AName);
  Result := (LPosition <> 0) and (LPosition < FCommandLine.Count - 1);
  if Result then
    AValue := FCommandLine[LPosition + 1]
  else
    AValue := '';
end;

function TScreenSizeResolver.ClampWidth(AWidth: Integer): Integer;
begin
  Result := AWidth;
  if Result > FLimits.MaxWidth then
    Result := FLimits.MaxWidth;
end;

function TScreenSizeResolver.ClampHeight(AHeight: Integer): Integer;
begin
  Result := AHeight;
  if Result > FLimits.MaxHeight then
    Result := FLimits.MaxHeight;
end;

procedure TScreenSizeResolver.ApplyPreset(const AName: string; APresetWidth,
  APresetHeight: Integer; var AWidth, AHeight: Integer);
begin
  if FCommandLine.IndexOf(AName) <> 0 then
  begin
    AWidth := ClampWidth(APresetWidth);
    AHeight := ClampHeight(APresetHeight);
  end;
end;

procedure TScreenSizeResolver.Resolve(var AWidth, AHeight: Integer);
var
  LValue: string;
  LSeparator: Integer;
  LIndex: Integer;
begin
  if ValueAfter('-screenwidth', LValue) then
    AWidth := FParseNumber(LValue);
  AWidth := ClampWidth(AWidth);

  if ValueAfter('-screenheight', LValue) then
    AHeight := FParseNumber(LValue);
  AHeight := ClampHeight(AHeight);

  if ValueAfter('-geom', LValue) then
  begin
    // WIDTHxHEIGHT; without the 'x' the whole text is the width and the height is 0
    LSeparator := 0;
    for LIndex := 1 to Length(LValue) do
      if (LValue[LIndex] = 'X') or (LValue[LIndex] = 'x') then
      begin
        LSeparator := LIndex;
        Break;
      end;
    if LSeparator = 0 then
    begin
      AWidth := FParseNumber(LValue);
      AHeight := FParseNumber('');
    end
    else
    begin
      AWidth := FParseNumber(Trim(Copy(LValue, 1, LSeparator - 1)));
      AHeight := FParseNumber(Trim(Copy(LValue, LSeparator + 1, Length(LValue) - LSeparator)));
    end;
    AWidth := ClampWidth(AWidth);
    if AWidth < FLimits.MinWidth then
      AWidth := FLimits.MinWidth;
    AHeight := ClampHeight(AHeight);
    if AHeight < FLimits.MinHeight then
      AHeight := FLimits.MinHeight;
  end;

  ApplyPreset('-fullhd', 1920, 1080, AWidth, AHeight);
  ApplyPreset('-vga', 640, 480, AWidth, AHeight);
  ApplyPreset('-svga', 800, 600, AWidth, AHeight);
  ApplyPreset('-cga', 320, 200, AWidth, AHeight);
  ApplyPreset('-cgaX2', 640, 400, AWidth, AHeight);
  ApplyPreset('-cgaX3', 960, 600, AWidth, AHeight);

  if AHeight = -1 then
    AHeight := FMetrics.Height;
  if AHeight > FLimits.MaxHeight then
    AHeight := FLimits.MaxHeight
  else if AHeight < FLimits.MinHeight then
    AHeight := FLimits.MinHeight;

  if AWidth = -1 then
    AWidth := FMetrics.Width;
  if AWidth > FLimits.MaxWidth then
    AWidth := FLimits.MaxWidth
  else if AWidth < FLimits.MinWidth then
    AWidth := FLimits.MinWidth;
end;

end.
