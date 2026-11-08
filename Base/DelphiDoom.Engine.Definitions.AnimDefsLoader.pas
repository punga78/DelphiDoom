{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the animations of ANIMDEFS                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Definitions.AnimDefsLoader;

interface

uses
  DelphiDoom.Definitions.Intf,
  DelphiDoom.Engine.Wad.Lumps.Intf,
  DelphiDoom.Engine.Definitions.Intf;

type
  /// <summary>
  ///   Reads the lump ANIMDEFS with the parser of Libs\Definitions and writes the animations in
  ///   the data of p_animdefs.pas (AnimDefs[], FrameDefs[] and the lists of the animated
  ///   pictures). It was P_InitFTAnims; a game without the lump keeps the animations it had
  /// </summary>
  TEngineAnimDefsLoader = class(TInterfacedObject, IEngineAnimDefsLoader)
  strict private
    FParser: IDefAnimDefsParser;
    FLumps: IEngineLumps;
  public
    /// <summary>
    ///   The parser leaves out the animations of flats and textures that do not exist; ALumps
    ///   gives the lump ANIMDEFS
    /// </summary>
    constructor Create(const AParser: IDefAnimDefsParser; const ALumps: IEngineLumps);
    procedure Load;
  end;

implementation

uses
  System.SysUtils,
  i_system,
  r_data,
  p_animdefs,
  DelphiDoom.Definitions.Types;

const
  ANIM_SCRIPT_NAME = 'ANIMDEFS';

{ TEngineAnimDefsLoader }

constructor TEngineAnimDefsLoader.Create(const AParser: IDefAnimDefsParser;
  const ALumps: IEngineLumps);
begin
  inherited Create;
  if not Assigned(AParser) then
    raise EArgumentNilException.Create('AParser');
  if not Assigned(ALumps) then
    raise EArgumentNilException.Create('ALumps');
  FParser := AParser;
  FLumps := ALumps;
end;

procedure TEngineAnimDefsLoader.Load;
var
  LFrameIndex: Integer;
  LAnimation: PanimDef_t;
  LLump: Integer;
  LAnimations: TArray<TDefAnimation>;
  LDefinition: TDefAnimation;
  LFrame: TDefAnimFrame;
  LBase: Integer;
  LIndex: Integer;
  LInner: Integer;
begin
  LLump := FLumps.CheckNumForName(ANIM_SCRIPT_NAME);
  if LLump < 0 then
    Exit;

  animatedflatslist.Clear;
  animatedtextureslist.Clear;
  LFrameIndex := 0;
  LAnimation := @AnimDefs[0];
  AnimDefCount := 0;

  try
    LAnimations := FParser.Parse(FLumps.TextOf(LLump));
  except
    on E: EDefinitionsException do
      I_Error('%s', [E.Message]);
  end;

  for LIndex := 0 to Length(LAnimations) - 1 do
  begin
    LDefinition := LAnimations[LIndex];
    if LDefinition.Kind = TDefAnimKind.Flat then
    begin
      LAnimation._type := ANIM_FLAT;
      LBase := R_FlatNumForName(LDefinition.Name);
    end
    else
    begin
      LAnimation._type := ANIM_TEXTURE;
      LBase := R_TextureNumForName(LDefinition.Name);
    end;
    LAnimation.index := LBase;

    // The list of the animated pictures: the first one and the one of every pic line
    for LInner := 0 to Length(LDefinition.AnimatedOffsets) - 1 do
      if LAnimation._type = ANIM_FLAT then
        animatedflatslist.Add(LBase + LDefinition.AnimatedOffsets[LInner])
      else
        animatedtextureslist.Add(LBase + LDefinition.AnimatedOffsets[LInner]);

    LAnimation.startFrameDef := LFrameIndex;
    for LInner := 0 to Length(LDefinition.Frames) - 1 do
    begin
      LFrame := LDefinition.Frames[LInner];
      FrameDefs[LFrameIndex].index := LBase + LFrame.PicNumber - 1;
      FrameDefs[LFrameIndex].tics := LFrame.PackedTics;
      Inc(LFrameIndex);
    end;
    LAnimation.endFrameDef := LFrameIndex - 1;
    LAnimation.currentFrameDef := LAnimation.endFrameDef;
    LAnimation.tics := 1; // Force 1st game tic to animate
    Inc(AnimDefCount);
    Inc(LAnimation);
  end;
end;

end.
