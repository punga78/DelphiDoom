{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the scale of -turbo                                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Startup.TurboScale;

interface

type
  /// <summary>
  ///   The speed scale of the -turbo parameter of the command line (the same rule in Doom, Heretic,
  ///   Hexen and Strife): a percent, between 10 and 200, 200 when the parameter has no number
  /// </summary>
  TStartupTurboScale = class sealed
  public
    const
      DefaultScale = 200;
      MinimumScale = 10;
      MaximumScale = 200;
    /// <summary>The scale for the text that follows -turbo; a text that is not a number gives the default</summary>
    class function FromArgument(const AArgument: string): Integer; static;
  end;

implementation

uses
  d_delphi;

class function TStartupTurboScale.FromArgument(const AArgument: string): Integer;
begin
  Result := atoi(AArgument, DefaultScale);
  if Result < MinimumScale then
    Result := MinimumScale
  else if Result > MaximumScale then
    Result := MaximumScale;
end;

end.