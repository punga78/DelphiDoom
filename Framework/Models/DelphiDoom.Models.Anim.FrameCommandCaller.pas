{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - calling the commands of the frames          }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\anim\Anim_Blend.cpp }
{  (idAnim::CallFrameCommands). Copyright (C) 1999-2011 id Software LLC, a     }
{  ZeniMax Media company. This unit is derived from the Doom 3 GPL source      }
{  code and is therefore available under the GNU General Public License,       }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see README.md of Framework\IdLib); the repository as a whole is GPL v2 or  }
{  later.                                                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Anim.FrameCommandCaller;

interface

uses
  DelphiDoom.Models.Anim.Intf,
  DelphiDoom.Models.Anim.Blend.Types;

type
  /// <summary>
  ///   The loop of <c>idAnim::CallFrameCommands</c>: from the frame after AFrom up to AFrameTo
  ///   (included), wrapping to frame 0 at the end of the anim, every command of every frame goes to
  ///   the sink in the order it was added. The original runs the commands in the engine; here the
  ///   game does it.
  /// </summary>
  TAnimFrameCommandCaller = class sealed
  public
    /// <summary>
    ///   AFrom and ATo are zero based frames; AFrom may be -1 (before the first frame). Nothing
    ///   happens when they are equal. A frame at or past the end of the anim wraps to 0.
    /// </summary>
    class procedure Call(const AAnim: IAnim; const ASink: IAnimFrameCommandSink;
      const AFrom, ATo: Integer); static;
  end;

implementation

uses
  DelphiDoom.Models.Anim.Types;

{ TAnimFrameCommandCaller }

class procedure TAnimFrameCommandCaller.Call(const AAnim: IAnim; const ASink: IAnimFrameCommandSink;
  const AFrom, ATo: Integer);
var
  LFrame, LNumFrames: Integer;
  LCommand: TAnimFrameCommand;
begin
  LNumFrames := AAnim.NumFrames;
  // the original loops forever when the target frame does not exist: here it is an error
  if (AFrom <> ATo) and ((ATo < 0) or (ATo >= LNumFrames)) then
    raise EAnimException.CreateFmt(SAnimFrameRange, [ATo + 1]);
  LFrame := AFrom;
  while LFrame <> ATo do
  begin
    Inc(LFrame);
    if LFrame >= LNumFrames then
      LFrame := 0;
    for LCommand in AAnim.GetFrameCommands(LFrame) do
      ASink.CallFrameCommand(AAnim, LFrame, LCommand);
  end;
end;

end.
