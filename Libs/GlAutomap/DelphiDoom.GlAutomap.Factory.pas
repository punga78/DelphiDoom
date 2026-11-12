{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL automap - the factory: the composition root              }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlAutomap.Factory;

interface

uses
  DelphiDoom.GlAutomap.Intf;

type
  /// <summary>The only place that knows the classes behind the interfaces of the OpenGL automap</summary>
  TGlAutomapFactory = class
  public
    /// <summary>An empty list of the items of a frame</summary>
    class function CreateDisplayList: IGlAutomapDisplayList; static;
  end;

implementation

uses
  DelphiDoom.GlAutomap.DisplayList;

{ TGlAutomapFactory }

class function TGlAutomapFactory.CreateDisplayList: IGlAutomapDisplayList;
begin
  Result := TGlAutomapDisplayList.Create;
end;

end.
