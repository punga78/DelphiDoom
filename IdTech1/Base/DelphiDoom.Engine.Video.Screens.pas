{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the screens and the palette over v_video               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Video.Screens;

interface

uses
  d_delphi,
  DelphiDoom.Engine.Video.Screens.Intf;

type
  /// <summary>
  ///   IEngineScreens over the functions of v_video.pas and of the video of the game
  ///   (i_video.pas in the software renderer, gl_main.pas in OpenGL): the only class that the
  ///   classes of the engine need to reach them for the palette and for whole pictures
  /// </summary>
  TEngineScreens = class(TInterfacedObject, IEngineScreens)
  public
    procedure SetPalette(const APalette: PByteArray);
    function NearestColorInCurrentPalette(const AColor: LongWord): Integer;
    function NearestColorInDefaultPalette(const AColor: LongWord): Integer;
    procedure CopyVideoPalette(const ADestination: PLongWordArray);
    procedure CopyCustomScreen(const ASource: PByteArray; const AWidth: Integer;
      const AHeight: Integer; const ADestination: Integer);
  end;

implementation

uses
{$IFDEF OPENGL}
  gl_main,
{$ELSE}
  i_video,
{$ENDIF}
  v_video;

{ TEngineScreens }

procedure TEngineScreens.SetPalette(const APalette: PByteArray);
begin
  V_SetPalette(APalette);
  I_SetPalette(APalette);
end;

function TEngineScreens.NearestColorInCurrentPalette(const AColor: LongWord): Integer;
begin
  Result := V_FindAproxColorIndex(@curpal, AColor);
end;

function TEngineScreens.NearestColorInDefaultPalette(const AColor: LongWord): Integer;
begin
  Result := V_FindAproxColorIndex(default_palette, AColor);
end;

procedure TEngineScreens.CopyVideoPalette(const ADestination: PLongWordArray);
var
  LIndex: Integer;
begin
  for LIndex := 0 to 255 do
    ADestination[LIndex] := videopal[LIndex];
end;

procedure TEngineScreens.CopyCustomScreen(const ASource: PByteArray; const AWidth: Integer;
  const AHeight: Integer; const ADestination: Integer);
begin
  V_CopyCustomScreen(ASource, AWidth, AHeight, ADestination);
end;

end.
