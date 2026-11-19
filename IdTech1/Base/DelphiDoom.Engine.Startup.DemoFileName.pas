{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the file name of -playdemo and -timedemo             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Startup.DemoFileName;

interface

type
  /// <summary>
  ///   The file of a demo given to -playdemo or -timedemo (the same rule in the four games): a name
  ///   with an extension is used as it is, a name without one gets the extension .lmp
  /// </summary>
  TStartupDemoFileName = class sealed
  public
    const
      DefaultExtension = '.lmp';
    /// <summary>The file name for the text that follows -playdemo or -timedemo</summary>
    class function FromArgument(const AArgument: string): string; static;
  end;

implementation

uses
  d_delphi;

class function TStartupDemoFileName.FromArgument(const AArgument: string): string;
begin
  if CharPos('.', AArgument) > 0 then
    Result := AArgument
  else
    Result := AArgument + DefaultExtension;
end;

end.