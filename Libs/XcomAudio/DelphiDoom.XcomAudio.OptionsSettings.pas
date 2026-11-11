{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom audio library - the music settings read from the options    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAudio.OptionsSettings;

interface

uses
  DelphiDoom.XcomEngine.Options, DelphiDoom.XcomAudio.Intf;

type
  /// <summary>IXcomMusicSettings on the options of the game; the options belong to the game, not to this class</summary>
  TXcomOptionsMusicSettings = class(TInterfacedObject, IXcomMusicSettings)
  strict private
    FOptions: TXcomOptions;
  public
    constructor Create(AOptions: TXcomOptions);
    function Mute: Boolean;
    function AlwaysLoop: Boolean;
    function PreferredFormat: Integer;
  end;

implementation

constructor TXcomOptionsMusicSettings.Create(AOptions: TXcomOptions);
begin
  inherited Create;
  FOptions := AOptions;
end;

function TXcomOptionsMusicSettings.Mute: Boolean;
begin
  Result := FOptions.Mute;
end;

function TXcomOptionsMusicSettings.AlwaysLoop: Boolean;
begin
  Result := FOptions.GetBool('musicAlwaysLoop');
end;

function TXcomOptionsMusicSettings.PreferredFormat: Integer;
begin
  Result := FOptions.PreferredMusic;
end;

end.
