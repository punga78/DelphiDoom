{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - what the deferred video notifications do               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Video.DisplayModeApplier;

{$I Doom32.inc}

interface

uses
  DelphiDoom.Video.Intf;

type
  /// <summary>
  ///   V_SetDisplayMode in the software versions, GL_SetDisplayMode and GL_NotifyDisplayMode in
  ///   the OpenGL ones (the software versions have no OpenGL window to tell)
  /// </summary>
  TEngineDisplayModeApplier = class(TInterfacedObject, IDisplayModeApplier)
  public
    procedure ApplyDisplayMode(AWidth, AHeight: Integer);
    procedure ApplyGLDisplayMode;
  end;

implementation

uses
{$IFDEF OPENGL}
  gl_main
{$ELSE}
  v_displaymode
{$ENDIF}
  ;

{ TEngineDisplayModeApplier }

procedure TEngineDisplayModeApplier.ApplyDisplayMode(AWidth, AHeight: Integer);
begin
{$IFDEF OPENGL}
  GL_SetDisplayMode(AWidth, AHeight);
{$ELSE}
  V_SetDisplayMode(AWidth, AHeight);
{$ENDIF}
end;

procedure TEngineDisplayModeApplier.ApplyGLDisplayMode;
begin
{$IFDEF OPENGL}
  GL_NotifyDisplayMode;
{$ENDIF}
end;

end.
