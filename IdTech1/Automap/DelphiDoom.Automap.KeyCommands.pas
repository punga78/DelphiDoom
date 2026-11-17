{******************************************************************************}
{                                                                              }
{  DelphiDoom: automap library - what a key does in the automap                }
{  Copyright (C) 1993-1996 by id Software, Inc.                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Automap.KeyCommands;

interface

type
  /// <summary>What a key of the keyboard asks of the automap</summary>
  TAutomapKeyCommand = (
    /// <summary>The key means nothing to the automap</summary>
    akcNone,
    akcPanRight,
    akcPanLeft,
    akcPanUp,
    akcPanDown,
    akcZoomOut,
    /// <summary>Both the keys of the zoom in</summary>
    akcZoomIn,
    /// <summary>The key that cycles the states of the automap</summary>
    akcToggle,
    /// <summary>The whole level in the window, and back</summary>
    akcGoBig,
    akcFollow,
    akcGrid,
    akcRotate,
    akcTextured,
    akcMark,
    akcClearMarks
  );

  /// <summary>The keys of the automap: the fixed ones and the ones the player can change</summary>
  TAutomapKeyBindings = record
    PanRight: Integer;
    PanLeft: Integer;
    PanUp: Integer;
    PanDown: Integer;
    ZoomOut: Integer;
    ZoomIn: Integer;
    ZoomInAlternative: Integer;
    Toggle: Integer;
    GoBig: Integer;
    Follow: Integer;
    Grid: Integer;
    Rotate: Integer;
    Textured: Integer;
    Mark: Integer;
    ClearMarks: Integer;
  end;

  /// <summary>
  ///   The choice of AM_Responder: which command a key is. The fixed keys win over the keys the
  ///   player sets, which are tried in a fixed order: two commands on the same key give the first one
  /// </summary>
  /// <remarks>
  ///   Cold code (once per key event, only with the automap open)
  /// </remarks>
  TAutomapKeys = class sealed
  public
    /// <summary>The command of the key; akcNone if the keys do not include it</summary>
    class function Classify(const ABindings: TAutomapKeyBindings; const AKey: Integer): TAutomapKeyCommand; static;
  end;

implementation

{ TAutomapKeys }

class function TAutomapKeys.Classify(const ABindings: TAutomapKeyBindings;
  const AKey: Integer): TAutomapKeyCommand;
begin
  if AKey = ABindings.PanRight then
    Result := akcPanRight
  else if AKey = ABindings.PanLeft then
    Result := akcPanLeft
  else if AKey = ABindings.PanUp then
    Result := akcPanUp
  else if AKey = ABindings.PanDown then
    Result := akcPanDown
  else if AKey = ABindings.ZoomOut then
    Result := akcZoomOut
  else if (AKey = ABindings.ZoomIn) or (AKey = ABindings.ZoomInAlternative) then
    Result := akcZoomIn
  else if AKey = ABindings.Toggle then
    Result := akcToggle
  else if AKey = ABindings.GoBig then
    Result := akcGoBig
  else if AKey = ABindings.Follow then
    Result := akcFollow
  else if AKey = ABindings.Grid then
    Result := akcGrid
  else if AKey = ABindings.Rotate then
    Result := akcRotate
  else if AKey = ABindings.Textured then
    Result := akcTextured
  else if AKey = ABindings.Mark then
    Result := akcMark
  else if AKey = ABindings.ClearMarks then
    Result := akcClearMarks
  else
    Result := akcNone;
end;

end.
