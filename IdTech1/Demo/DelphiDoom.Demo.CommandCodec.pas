{******************************************************************************}
{                                                                              }
{  DelphiDoom: demo library - reading and writing one command of a demo        }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Demo.CommandCodec;

{$POINTERMATH ON}

interface

uses
  DelphiDoom.Demo.Types;

type
  /// <summary>
  ///   The bytes of one command of a demo (G_ReadDemoTiccmd and G_WriteDemoTiccmd of the four games)
  /// </summary>
  /// <remarks>
  ///   Called once per tic and per player while a demo plays or is recorded, never in normal play:
  ///   a class of static methods on a pointer, no interface, no allocation. The writing does not move
  ///   the pointer: the engine writes, goes back and reads the command again to be sure it is the same
  /// </remarks>
  TDemoCommandCodec = class sealed
  public
    /// <summary>Reads a command and moves the pointer after it</summary>
    /// <param name="APosition">The command in the demo; moved after its last byte</param>
    /// <param name="ALayout">The layout of the game</param>
    /// <param name="AVersion">The version of the demo (the look up/down of 16 bits is from 2.03)</param>
    /// <param name="AOldDemo">An old demo of Doom: three bytes of angle and no look up/down</param>
    /// <param name="ACommand">The command</param>
    class procedure Read(var APosition: PByte; const ALayout: TDemoLayout; const AVersion: Integer;
      const AOldDemo: Boolean; out ACommand: TDemoCommand); static;

    /// <summary>Writes a command; the pointer does not move</summary>
    class procedure Write(const APosition: PByte; const ALayout: TDemoLayout;
      const ACommand: TDemoCommand); static;
  end;

implementation

const
  DEMO_VERSION_SMOOTH_LOOK = 203;

{ TDemoCommandCodec }

class procedure TDemoCommandCodec.Read(var APosition: PByte; const ALayout: TDemoLayout;
  const AVersion: Integer; const AOldDemo: Boolean; out ACommand: TDemoCommand);
begin
  ACommand := Default(TDemoCommand);

  ACommand.ForwardMove := ShortInt(APosition[0]);
  Inc(APosition);

  ACommand.SideMove := ShortInt(APosition[0]);
  Inc(APosition);

  if (ALayout = dlDoom) and AOldDemo then
  begin
    ACommand.AngleTurn := ShortInt(APosition[0]) * 256;
    Inc(APosition);
  end
  else
  begin
    ACommand.AngleTurn := PSmallInt(APosition)^;
    Inc(APosition, 2);
  end;

  ACommand.Buttons := APosition[0] and not DEMO_BUTTON_SPECIAL;
  Inc(APosition);

  case ALayout of
    dlDoom:
      if not AOldDemo then
      begin
        ACommand.LookUpDown := APosition[0];
        Inc(APosition);

        if AVersion >= DEMO_VERSION_SMOOTH_LOOK then
        begin
          ACommand.LookUpDown16 := PWord(APosition)^;
          Inc(APosition, 2);
        end
        else
          ACommand.LookUpDown16 := 256 * ACommand.LookUpDown;

        ACommand.LookLeftRight := APosition[0];
        Inc(APosition);
        ACommand.JumpCrouch := APosition[0];
        Inc(APosition);
      end;

    dlHeretic:
      begin
        ACommand.LookFly := APosition[0];
        Inc(APosition);
        ACommand.Arti := APosition[0];
        Inc(APosition);
        ACommand.LookLeftRight := APosition[0];
        Inc(APosition);
        ACommand.JumpCrouch := APosition[0];
        Inc(APosition);

        if AVersion < DEMO_VERSION_SMOOTH_LOOK then
          ACommand.LookUpDown16 := (ACommand.LookFly and 15) * 256
        else
        begin
          ACommand.LookUpDown16 := PWord(APosition)^;
          Inc(APosition, 2);
        end;
        ACommand.LookUpDown := ACommand.LookUpDown16 div 256;
      end;

    dlStrife:
      begin
        ACommand.Buttons2 := APosition[0] and not DEMO_BUTTON_SPECIAL;
        Inc(APosition);

        ACommand.Inventory := PInteger(APosition)^;
        Inc(APosition, 4);

        ACommand.LookUpDown := APosition[0];
        Inc(APosition);
        ACommand.LookLeftRight := APosition[0];
        Inc(APosition);
        ACommand.JumpCrouch := APosition[0];
        Inc(APosition);

        if AVersion >= DEMO_VERSION_SMOOTH_LOOK then
        begin
          ACommand.LookUpDown16 := PWord(APosition)^;
          Inc(APosition, 2);
        end
        else
          ACommand.LookUpDown16 := 256 * ACommand.LookUpDown;
      end;
  end;
end;

class procedure TDemoCommandCodec.Write(const APosition: PByte; const ALayout: TDemoLayout;
  const ACommand: TDemoCommand);
var
  LPosition: PByte;
begin
  LPosition := APosition;

  LPosition[0] := Byte(ACommand.ForwardMove);
  Inc(LPosition);

  LPosition[0] := Byte(ACommand.SideMove);
  Inc(LPosition);

  PSmallInt(LPosition)^ := ACommand.AngleTurn;
  Inc(LPosition, 2);

  LPosition[0] := ACommand.Buttons and not DEMO_BUTTON_SPECIAL;
  Inc(LPosition);

  case ALayout of
    dlDoom:
      begin
        LPosition[0] := ACommand.LookUpDown;
        Inc(LPosition);

        PWord(LPosition)^ := ACommand.LookUpDown16;
        Inc(LPosition, 2);

        LPosition[0] := ACommand.LookLeftRight;
        Inc(LPosition);
        LPosition[0] := ACommand.JumpCrouch;
      end;

    dlHeretic:
      begin
        LPosition[0] := ACommand.LookFly;
        Inc(LPosition);
        LPosition[0] := ACommand.Arti;
        Inc(LPosition);
        LPosition[0] := ACommand.LookLeftRight;
        Inc(LPosition);
        LPosition[0] := ACommand.JumpCrouch;
        Inc(LPosition);

        PWord(LPosition)^ := ACommand.LookUpDown16;
      end;

    dlStrife:
      begin
        LPosition[0] := ACommand.Buttons2;
        Inc(LPosition);

        PInteger(LPosition)^ := ACommand.Inventory;
        Inc(LPosition, 4);

        LPosition[0] := ACommand.LookUpDown;
        Inc(LPosition);
        LPosition[0] := ACommand.LookLeftRight;
        Inc(LPosition);
        LPosition[0] := ACommand.JumpCrouch;
        Inc(LPosition);

        PWord(LPosition)^ := ACommand.LookUpDown16;
      end;
  end;
end;

end.
