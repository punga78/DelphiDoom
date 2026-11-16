{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the numbers of the command line                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Startup.Numbers;

interface

/// <summary>
///   The number of a text as the engine reads it (atoi of d_delphi: decimal, 0x or # prefixed,
///   0 when it is not a number), for the classes that must not know d_delphi
/// </summary>
function EngineParseNumber(const AText: string): Integer;

implementation

uses
  d_delphi;

function EngineParseNumber(const AText: string): Integer;
begin
  Result := atoi(AText);
end;

end.
