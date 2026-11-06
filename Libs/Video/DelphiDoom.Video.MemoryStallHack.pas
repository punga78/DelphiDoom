{******************************************************************************}
{                                                                              }
{  DelphiDoom: video library - the memory stall hack                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Video.MemoryStallHack;

interface

uses
  DelphiDoom.Video.Intf;

type
  /// <summary>
  ///   A memory stall can make an addition of 4096 to a register much slower than an addition of
  ///   4088 (1024 pixels of 4 bytes against 1022): so a screen of 1024, 1152 or 1280 pixels is
  ///   made two pixels narrower
  /// </summary>
  TMemoryStallHack = class(TInterfacedObject, IMemoryStallHack)
  private
    FApplied: Boolean;
  public
    function Apply(var AScreenWidth: Integer; AEnabled: Boolean): Boolean;
  end;

implementation

{ TMemoryStallHack }

function TMemoryStallHack.Apply(var AScreenWidth: Integer; AEnabled: Boolean): Boolean;
begin
  if (AScreenWidth = 1024) or (AScreenWidth = 1152) or (AScreenWidth = 1280) then
  begin
    if AEnabled then
    begin
      Dec(AScreenWidth, 2);
      FApplied := True;
    end;
  end
  else
    FApplied := False;
  Result := FApplied;
end;

end.
