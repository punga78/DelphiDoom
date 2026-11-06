{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the size of the screen of the game                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Input.ScreenSize;

interface

uses
  DelphiDoom.Input.Intf;

type
  /// <summary>SCREENWIDTH and SCREENHEIGHT, read every time because they change with the video mode</summary>
  TEngineScreenSize = class(TInterfacedObject, IScreenSize)
  public
    function GetWidth: Integer;
    function GetHeight: Integer;
  end;

implementation

uses
  doomdef;

{ TEngineScreenSize }

function TEngineScreenSize.GetWidth: Integer;
begin
  Result := SCREENWIDTH;
end;

function TEngineScreenSize.GetHeight: Integer;
begin
  Result := SCREENHEIGHT;
end;

end.
