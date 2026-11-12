{******************************************************************************}
{                                                                              }
{  DelphiDoom: parity library - the hash of a frame                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Parity.FrameHashWriter;

interface

uses
  System.SysUtils,
  DelphiDoom.Parity.Intf,
  DelphiDoom.Parity.Types;

type
  /// <summary>
  ///   Writes for every frame one line <c>F tic full view hud</c> (16 digits each): view is the hash of the
  ///   rectangle of the 3D view (row by row), hud of everything outside of it (the border, the status bar,
  ///   the menu), full is the hash of the two together and of the palette. In a mode of 8 bits the pixels
  ///   are the indexes of the palette, so the hash of the palette goes in full (and only there)
  /// </summary>
  TFrameHashWriter = class
  strict private
    FLog: IParityLog;
  public
    constructor Create(const ALog: IParityLog);
    /// <summary>
    ///   Hashes one frame. APixels: the buffer of Width x Height pixels of ABytesPerPixel (1 or 4) bytes,
    ///   row after row without gaps. APaletteHash: the hash of the palette (0 in the modes of 32 bits)
    /// </summary>
    procedure WriteFrame(ATic: Integer; const ALayout: TParityFrameLayout; APixels: Pointer;
      ABytesPerPixel: Integer; APaletteHash: UInt64);
  end;

implementation

uses
  DelphiDoom.Parity.Hasher;

const
  SNoLog = 'ALog';
  SNoPixels = 'The frame has no pixels';
  SWrongLayout = 'The layout of the frame is wrong';
  SWrongPixelSize = 'The pixels must be of 1 or 4 bytes';

{ TFrameHashWriter }

constructor TFrameHashWriter.Create(const ALog: IParityLog);
begin
  inherited Create;
  if not Assigned(ALog) then
    raise EArgumentNilException.Create(SNoLog);
  FLog := ALog;
end;

procedure TFrameHashWriter.WriteFrame(ATic: Integer; const ALayout: TParityFrameLayout; APixels: Pointer;
  ABytesPerPixel: Integer; APaletteHash: UInt64);
var
  LView: TParityHasher;
  LHud: TParityHasher;
  LFull: TParityHasher;
  LRow: PByte;
  LRowBytes: Integer;
  LY: Integer;
  LLeft: Integer;
  LRight: Integer;
  LViewEnd: Integer;
begin
  if not Assigned(APixels) then
    raise EParityException.Create(SNoPixels);
  if (ABytesPerPixel <> 1) and (ABytesPerPixel <> 4) then
    raise EParityException.Create(SWrongPixelSize);
  if (ALayout.Width <= 0) or (ALayout.Height <= 0) or (ALayout.ViewX < 0) or (ALayout.ViewY < 0) or
    (ALayout.ViewWidth < 0) or (ALayout.ViewHeight < 0) or (ALayout.ViewX + ALayout.ViewWidth > ALayout.Width) or
    (ALayout.ViewY + ALayout.ViewHeight > ALayout.Height) then
    raise EParityException.Create(SWrongLayout);

  LView.Reset;
  LHud.Reset;
  LRowBytes := ALayout.Width * ABytesPerPixel;
  LViewEnd := ALayout.ViewY + ALayout.ViewHeight;
  LLeft := ALayout.ViewX * ABytesPerPixel;
  LRight := (ALayout.ViewX + ALayout.ViewWidth) * ABytesPerPixel;
  LRow := PByte(APixels);
  for LY := 0 to ALayout.Height - 1 do
  begin
    if (LY >= ALayout.ViewY) and (LY < LViewEnd) then
    begin
      LHud.AddSpan(LRow, LLeft);
      LView.AddSpan(LRow + LLeft, LRight - LLeft);
      LHud.AddSpan(LRow + LRight, LRowBytes - LRight);
    end
    else
      LHud.AddSpan(LRow, LRowBytes);
    Inc(LRow, LRowBytes);
  end;

  LFull.Reset;
  LFull.AddInt64(Int64(LView.Value));
  LFull.AddInt64(Int64(LHud.Value));
  LFull.AddInt64(Int64(APaletteHash));
  FLog.WriteLine(Format('F %d %s %s %s', [ATic, TParityHasher.ToHex(LFull.Value),
    TParityHasher.ToHex(LView.Value), TParityHasher.ToHex(LHud.Value)]));
end;

end.
