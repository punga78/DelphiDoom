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
{  available under the GNU General Public License, version 3 or (at your       }
{  option) any later version, with the additional terms of the Doom 3 Source   }
{  Code License (Reference\doom3\COPYING.txt: preservation of legal notices    }
{  and trademarks, no use of the licensors' names for publicity, warranty      }
{  disclaimer). The repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}unit DelphiDoom.Scanner.IdDictCommands;

interface

uses
  System.SysUtils, DelphiDoom.Scanner.IdDict, DelphiDoom.Scanner.IdDictCommands.Intf,
  DelphiDoom.Scanner.IdDictLister;

type
  /// <summary>Gives the dictionaries whose strings the commands list (the original reads the global pools)</summary>
  TIdDictionariesProvider = reference to function: TArray<TIdDict>;

  /// <summary>
  ///   Registers <c>showDictMemory</c>, <c>listDictKeys</c> and <c>listDictValues</c> in a command registry, as
  ///   <c>idCommonLocal::Init</c> does, with the same descriptions and flags. The commands run
  ///   <c>TIdDictLister</c> on the dictionaries of the provider.
  /// </summary>
  TIdDictCommands = class
  strict private
    FLister: TIdDictLister;
    FProvider: TIdDictionariesProvider;
    FHost: IIdCommandHost;
  public
    /// <summary>The lister is not owned; the provider is called every time a command runs</summary>
    constructor Create(const ALister: TIdDictLister; const AProvider: TIdDictionariesProvider);
    /// <summary>Adds the three commands to the host (the host is released by <c>Unregister</c>)</summary>
    procedure Register(const AHost: IIdCommandHost);
    procedure Unregister;
  end;

implementation

const
  SShowDictMemory = 'showDictMemory';
  SListDictKeys = 'listDictKeys';
  SListDictValues = 'listDictValues';

{ TIdDictCommands }

constructor TIdDictCommands.Create(const ALister: TIdDictLister;
  const AProvider: TIdDictionariesProvider);
begin
  inherited Create;
  if not Assigned(ALister) then
    raise EArgumentNilException.Create('ALister');
  if not Assigned(AProvider) then
    raise EArgumentNilException.Create('AProvider');
  FLister := ALister;
  FProvider := AProvider;
end;

procedure TIdDictCommands.Register(const AHost: IIdCommandHost);
begin
  if not Assigned(AHost) then
    raise EArgumentNilException.Create('AHost');
  Unregister;
  FHost := AHost;
  FHost.AddCommand(SShowDictMemory, 'shows memory used by dictionaries', ID_CMD_FL_SYSTEM,
    procedure
    begin
      FLister.ShowMemoryUsage(FProvider());
    end);
  FHost.AddCommand(SListDictKeys, 'lists all keys used by dictionaries',
    ID_CMD_FL_SYSTEM or ID_CMD_FL_CHEAT,
    procedure
    begin
      FLister.ListKeys(FProvider());
    end);
  FHost.AddCommand(SListDictValues, 'lists all values used by dictionaries',
    ID_CMD_FL_SYSTEM or ID_CMD_FL_CHEAT,
    procedure
    begin
      FLister.ListValues(FProvider());
    end);
end;

procedure TIdDictCommands.Unregister;
begin
  if not Assigned(FHost) then
    Exit;
  FHost.RemoveCommand(SShowDictMemory);
  FHost.RemoveCommand(SListDictKeys);
  FHost.RemoveCommand(SListDictValues);
  FHost := nil;
end;

end.