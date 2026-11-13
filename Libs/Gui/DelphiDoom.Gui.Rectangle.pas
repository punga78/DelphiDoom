{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiRectangle, the rectangle of a window          }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\Rectangle.h             }
{  (idRectangle). Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media     }
{  company.                                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Rectangle;

interface

uses
  DelphiDoom.IdLib.Math.Vec4;

type
  /// <summary>
  ///   idRectangle: position and size of a window (four singles, 16 bytes). The original
  ///   <c>operator==</c> is broken (it compares <c>a.h</c> as a boolean); <c>IsEqual</c> compares the four fields.
  /// </summary>
  TGuiRectangle = record
    X: Single;
    Y: Single;
    W: Single;
    H: Single;
    class function Create(const AX, AY, AW, AH: Single): TGuiRectangle; static;
    /// <summary>idRectangle::operator=(idVec4): x, y, z, w become x, y, w, h</summary>
    class function FromVec4(const AValue: TIdVec4): TGuiRectangle; static;
    function ToVec4: TIdVec4;
    function Right: Single;
    function Bottom: Single;
    procedure Offset(const AX, AY: Single);
    /// <summary>False for an empty rectangle (width and height both zero)</summary>
    function Contains(const AX, AY: Single): Boolean;
    function IsEqual(const AOther: TGuiRectangle): Boolean;
  end;

implementation

class function TGuiRectangle.Create(const AX, AY, AW, AH: Single): TGuiRectangle;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.W := AW;
  Result.H := AH;
end;

class function TGuiRectangle.FromVec4(const AValue: TIdVec4): TGuiRectangle;
begin
  Result.X := AValue.X;
  Result.Y := AValue.Y;
  Result.W := AValue.Z;
  Result.H := AValue.W;
end;

function TGuiRectangle.ToVec4: TIdVec4;
begin
  Result := TIdVec4.Create(X, Y, W, H);
end;

function TGuiRectangle.Right: Single;
begin
  Result := X + W;
end;

function TGuiRectangle.Bottom: Single;
begin
  Result := Y + H;
end;

procedure TGuiRectangle.Offset(const AX, AY: Single);
begin
  X := X + AX;
  Y := Y + AY;
end;

function TGuiRectangle.Contains(const AX, AY: Single): Boolean;
begin
  if (W = 0.0) and (H = 0.0) then
    Exit(False);
  Result := (AX >= X) and (AX <= Right) and (AY >= Y) and (AY <= Bottom);
end;

function TGuiRectangle.IsEqual(const AOther: TGuiRectangle): Boolean;
begin
  Result := (X = AOther.X) and (Y = AOther.Y) and (W = AOther.W) and (H = AOther.H);
end;

end.
