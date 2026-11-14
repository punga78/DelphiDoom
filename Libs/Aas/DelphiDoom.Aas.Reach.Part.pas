{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - base of the calculators of one kind of            }
{  reachability                                                                }
{                                                                              }
{  Based on the Quake III Arena GPL Source Code (id Software). Copyright (C)   }
{  1999-2005 Id Software, Inc. This unit is derived from the Quake III Arena   }
{  source code and is therefore available under the GNU General Public         }
{  License, version 2 or (at your option) any later version.                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reach.Part;

{$Q-}
{$R+}

interface

uses
  DelphiDoom.Aas.Reach.Context;

type
  /// <summary>A calculator of be_aas_reach.c: it works on the shared context, which it does not own</summary>
  TAasReachPart = class
  strict private
    FContext: TAasReachContext;
  protected
    property Context: TAasReachContext read FContext;
  public
    constructor Create(const AContext: TAasReachContext);
  end;

implementation

{ TAasReachPart }

constructor TAasReachPart.Create(const AContext: TAasReachContext);
begin
  inherited Create;
  FContext := AContext;
end;

end.
