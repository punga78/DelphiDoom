{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - the size limiter                                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.SizeLimiter;

interface

uses
  DelphiDoom.Video.Intf;

type
  TSizeLimiter = class(TInterfacedObject, ISizeLimiter)
  private
    FMetrics: IDisplayMetrics;
  public
    constructor Create(const AMetrics: IDisplayMetrics);
    function Limit(var AWidth, AHeight: Integer): Boolean;
  end;

implementation

{ TSizeLimiter }

constructor TSizeLimiter.Create(const AMetrics: IDisplayMetrics);
begin
  inherited Create;
  FMetrics := AMetrics;
end;

function TSizeLimiter.Limit(var AWidth, AHeight: Integer): Boolean;
begin
  Result := False;
  if AWidth > FMetrics.Width then
  begin
    AWidth := FMetrics.Width;
    Result := True;
  end;
  if AHeight > FMetrics.Height then
  begin
    AHeight := FMetrics.Height;
    Result := True;
  end;
end;

end.
