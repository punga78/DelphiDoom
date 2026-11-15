{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - the console commands of idDict                }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): the registration of the        }
{  commands of idDict (framework\Common.cpp, idDict::ListKeys_f, ListValues_f  }
{  and ShowMemoryUsage_f of idlib\Dict.cpp).                                   }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}unit DelphiDoom.Scanner.IdDictCommands.Intf;

interface

const
  /// <summary>CMD_FL_CHEAT: the command is considered a cheat</summary>
  ID_CMD_FL_CHEAT = 1;
  /// <summary>CMD_FL_SYSTEM: a system command</summary>
  ID_CMD_FL_SYSTEM = 2;

type
  /// <summary>The body of a console command (the C++ commands take the arguments, the dictionary ones ignore them)</summary>
  TIdCommandHandler = reference to procedure;

  /// <summary>
  ///   The registry of console commands as far as the dictionary commands need it (idCmdSystem::AddCommand).
  ///   The console library of the engine gives an adapter; here it is a small contract so that no console is linked.
  /// </summary>
  IIdCommandHost = interface
    ['{0B6E6A1C-5C0F-4F5B-9E58-2A3D6E7C1F21}']
    procedure AddCommand(const AName, ADescription: string; const AFlags: Integer;
      const AHandler: TIdCommandHandler);
    procedure RemoveCommand(const AName: string);
  end;

implementation

end.