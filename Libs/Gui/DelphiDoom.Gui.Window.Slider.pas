{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiSliderWindow (sliderDef)                      }
{                                                                              }
{  Port of the GUI of Doom 3 (id Software, GPL v3): ui\SliderWindow.h,         }
{  SliderWindow.cpp (idSliderWindow: the parse). Copyright (C) 1999-2011 id    }
{  Software LLC, a ZeniMax Media company.                                      }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.Window.Slider;

interface

uses
  DelphiDoom.Scanner.IdParser, DelphiDoom.Gui.Context, DelphiDoom.Gui.Window, DelphiDoom.Gui.Window.Intf,
  DelphiDoom.Gui.WinVar.Base, DelphiDoom.Gui.WinVar.Bool, DelphiDoom.Gui.WinVar.Float, DelphiDoom.Gui.WinVar.Str;

type
  /// <summary>
  ///   idSliderWindow: the keys <c>step</c> (<c>stepsize</c>), <c>low</c>, <c>high</c>, <c>vertical</c>,
  ///   <c>verticalflip</c>, <c>scrollbar</c>, <c>thumbshader</c> and the variables <c>value</c>, <c>cvar</c>,
  ///   <c>liveUpdate</c>, <c>cvarGroup</c>. Not ported: the thumb material size, the cvar and the mouse.
  /// </summary>
  TGuiSliderWindow = class(TGuiWindow)
  strict private
    FLow: Single;
    FHigh: Single;
    FStepSize: Single;
    FVertical: Boolean;
    FVerticalFlip: Boolean;
    FScrollbar: Boolean;
    FThumbShader: AnsiString;
    FValue: TGuiWinFloat;
    FCvarStr: TGuiWinStr;
    FCvarGroup: TGuiWinStr;
    FLiveUpdate: TGuiWinBool;
  protected
    function ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean; override;
    procedure PostParse; override;
  public
    constructor Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator); override;
    destructor Destroy; override;
    function GetWinVarByName(const AName: AnsiString; const AFixup: Boolean;
      out AOwner: IGuiWindowNode): TGuiWinVar; override;
    property Low: Single read FLow;
    property High: Single read FHigh;
    property StepSize: Single read FStepSize;
    property Vertical: Boolean read FVertical;
    property VerticalFlip: Boolean read FVerticalFlip;
    property Scrollbar: Boolean read FScrollbar;
    property ThumbShader: AnsiString read FThumbShader;
    property Value: TGuiWinFloat read FValue;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Text.Strings, DelphiDoom.Gui.Window.Types;

constructor TGuiSliderWindow.Create(const AContext: TGuiContext; const ACreator: TGuiWindowCreator);
begin
  inherited Create(AContext, ACreator);
  FValue := TGuiWinFloat.Create;
  FCvarStr := TGuiWinStr.Create;
  FCvarGroup := TGuiWinStr.Create;
  FLiveUpdate := TGuiWinBool.Create;
  FValue.Value := 0.0;
  FLow := 0.0;
  FHigh := 100.0;
  FStepSize := 1.0;
  FLiveUpdate.Value := True;
end;

destructor TGuiSliderWindow.Destroy;
begin
  FLiveUpdate.Free;
  FCvarGroup.Free;
  FCvarStr.Free;
  FValue.Free;
  inherited Destroy;
end;

function TGuiSliderWindow.ParseInternalVar(const AName: AnsiString; const ASource: TIdParser): Boolean;
begin
  Result := True;
  if (TIdStrings.Icmp(AName, 'stepsize') = 0) or (TIdStrings.Icmp(AName, 'step') = 0) then
    FStepSize := ASource.ParseFloat
  else if TIdStrings.Icmp(AName, 'low') = 0 then
    FLow := ASource.ParseFloat
  else if TIdStrings.Icmp(AName, 'high') = 0 then
    FHigh := ASource.ParseFloat
  else if TIdStrings.Icmp(AName, 'vertical') = 0 then
    FVertical := ASource.ParseBool
  else if TIdStrings.Icmp(AName, 'verticalflip') = 0 then
    FVerticalFlip := ASource.ParseBool
  else if TIdStrings.Icmp(AName, 'scrollbar') = 0 then
    FScrollbar := ASource.ParseBool
  else if TIdStrings.Icmp(AName, 'thumbshader') = 0 then
    ParseString(ASource, FThumbShader)
  else
    Result := inherited ParseInternalVar(AName, ASource);
end;

function TGuiSliderWindow.GetWinVarByName(const AName: AnsiString; const AFixup: Boolean;
  out AOwner: IGuiWindowNode): TGuiWinVar;
begin
  AOwner := nil;
  if TIdStrings.Icmp(AName, 'value') = 0 then
    Exit(FValue);
  if TIdStrings.Icmp(AName, 'cvar') = 0 then
    Exit(FCvarStr);
  if TIdStrings.Icmp(AName, 'liveUpdate') = 0 then
    Exit(FLiveUpdate);
  if TIdStrings.Icmp(AName, 'cvarGroup') = 0 then
    Exit(FCvarGroup);
  Result := inherited GetWinVarByName(AName, AFixup, AOwner);
end;

procedure TGuiSliderWindow.PostParse;
begin
  inherited PostParse;
  FValue.Value := 0.0;
  SetFlag(WIN_HOLDCAPTURE or WIN_CANFOCUS);
  // InitCvar: the cvar itself is not ported (there is no cvar system here), the empty name is reported as in the original
  if FCvarStr.AsText = '' then
    Warning(Format('idSliderWindow::InitCvar: gui ''%s'' window ''%s'' has an empty cvar string',
      [string(Context.SourceFile), string(Name)]));
end;

end.
