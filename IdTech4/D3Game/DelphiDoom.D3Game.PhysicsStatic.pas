{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - the default physics of an entity          }
{                                                                              }
{  Reduced port of Doom 3 (id Software): game\physics\Physics_Static.cpp (an   }
{  origin and the bounds of the clip model; nothing moves).                    }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Game.PhysicsStatic;

interface

uses
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.D3Game.Physics.Intf;

type
  /// <summary>
  ///   idPhysics_Static: the physics an entity has until it gets another one. It has an origin and the bounds the
  ///   entity's <c>size</c>, <c>mins</c> and <c>maxs</c> make (there is no clip model: the bounds are given); it
  ///   never moves and has no end of motion.
  /// </summary>
  TD3PhysicsStatic = class(TInterfacedObject, ID3Physics)
  strict private
    FOrigin: TIdVec3;
    FMins: TIdVec3;
    FMaxs: TIdVec3;
    FTime: Integer;
  public
    /// <param name="AMins">the bounds relative to the origin (zero for no clip model)</param>
    constructor Create(const AOrigin, AMins, AMaxs: TIdVec3);
    function GetOrigin: TIdVec3;
    procedure SetOrigin(const AOrigin: TIdVec3);
    function GetAbsBoundsMin: TIdVec3;
    function GetAbsBoundsMax: TIdVec3;
    function Evaluate(const ATimeStepMSec, AEndTimeMSec: Integer): Boolean;
    procedure UpdateTime(const AEndTimeMSec: Integer);
    function GetTime: Integer;
    function GetLinearEndTime: Integer;
    function GetAngularEndTime: Integer;
    function IsAtRest: Boolean;
    /// <summary>The bounds relative to the origin (what the clip model had)</summary>
    function GetLocalMins: TIdVec3;
    function GetLocalMaxs: TIdVec3;
  end;

implementation

constructor TD3PhysicsStatic.Create(const AOrigin, AMins, AMaxs: TIdVec3);
begin
  inherited Create;
  FOrigin := AOrigin;
  FMins := AMins;
  FMaxs := AMaxs;
end;

function TD3PhysicsStatic.GetOrigin: TIdVec3;
begin
  Result := FOrigin;
end;

procedure TD3PhysicsStatic.SetOrigin(const AOrigin: TIdVec3);
begin
  FOrigin := AOrigin;
end;

function TD3PhysicsStatic.GetAbsBoundsMin: TIdVec3;
begin
  Result := FMins + FOrigin;
end;

function TD3PhysicsStatic.GetAbsBoundsMax: TIdVec3;
begin
  Result := FMaxs + FOrigin;
end;

function TD3PhysicsStatic.GetLocalMins: TIdVec3;
begin
  Result := FMins;
end;

function TD3PhysicsStatic.GetLocalMaxs: TIdVec3;
begin
  Result := FMaxs;
end;

function TD3PhysicsStatic.Evaluate(const ATimeStepMSec, AEndTimeMSec: Integer): Boolean;
begin
  FTime := AEndTimeMSec;
  Result := False;
end;

procedure TD3PhysicsStatic.UpdateTime(const AEndTimeMSec: Integer);
begin
  FTime := AEndTimeMSec;
end;

function TD3PhysicsStatic.GetTime: Integer;
begin
  Result := FTime;
end;

function TD3PhysicsStatic.GetLinearEndTime: Integer;
begin
  Result := 0;
end;

function TD3PhysicsStatic.GetAngularEndTime: Integer;
begin
  Result := 0;
end;

function TD3PhysicsStatic.IsAtRest: Boolean;
begin
  Result := True;
end;

end.
