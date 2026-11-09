{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - chunks that all start with their length           }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  CA_CacheAudioChunk of id_ca.c                                                }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.ExplicitLayout;

interface

uses
  DelphiDoom.Keen.Intf;

type
  /// <summary>The layout of the audio file: every chunk starts with the expanded length (a 32 bit number)</summary>
  TKeenExplicitLayout = class(TInterfacedObject, IKeenChunkLayout)
  strict private
    FLenient: Boolean;
  public
    /// <param name="ALenient">
    ///   True if the data may end early (the audio file of the shareware 1.13 is shorter than its header: the digitized
    ///   sounds are not in it, and one sound has one byte less than it says)
    /// </param>
    constructor Create(ALenient: Boolean = False);
    function ImplicitLength(AIndex: Integer): Integer;
    function IsLenient(AIndex: Integer): Boolean;
  end;

implementation

{ TKeenExplicitLayout }

constructor TKeenExplicitLayout.Create(ALenient: Boolean);
begin
  inherited Create;
  FLenient := ALenient;
end;

function TKeenExplicitLayout.ImplicitLength(AIndex: Integer): Integer;
begin
  Result := -1;
end;

function TKeenExplicitLayout.IsLenient(AIndex: Integer): Boolean;
begin
  Result := FLenient;
end;

end.
