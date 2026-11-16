{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - what the console commands need besides    }
{  the manager                                                                 }
{                                                                              }
{  Written from the description of the calls of idDeclManagerLocal::           }
{  ReloadDecls_f; licensed under the GNU General Public License, version 2 or  }
{  later.                                                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Console.Intf;

interface

type
  /// <summary>
  ///   <c>soundSystem->SetMute</c>: <c>reloadDecls</c> mutes the sound while the decls are read again (a sound
  ///   shader that changes would restart the sounds that play). The engine gives its sound system; the commands
  ///   work without one.
  /// </summary>
  IDeclSoundMute = interface
    ['{5E0C1A52-7B1E-4C0B-9D4B-4C6E3D0A0030}']
    procedure SetMute(const AMute: Boolean);
  end;

implementation

end.
