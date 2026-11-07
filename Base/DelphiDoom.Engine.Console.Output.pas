{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - where the text of the console commands goes            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Console.Output;

{$I Doom32.inc}

interface

uses
  DelphiDoom.Console.Intf;

type
  /// <summary>
  ///   The output of the console library is printf: the chain outproc (the startup window, the
  ///   console of the game and the stdout file, whichever is listening)
  /// </summary>
  TEngineConsoleOutput = class(TInterfacedObject, IConsoleOutput)
  public
    procedure Write(const AText: string);
  end;

implementation

uses
  d_delphi;

{ TEngineConsoleOutput }

procedure TEngineConsoleOutput.Write(const AText: string);
begin
  printf(AText);
end;

end.
