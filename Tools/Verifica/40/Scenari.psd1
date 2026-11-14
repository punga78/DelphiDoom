@{
  # Issue #40 (sotto-issue #43): gli scenari della prova dei salvataggi tra 32 e 64 bit (Prova-Salvataggi.ps1).
  #   Warp, Skill, Seed, Extra: come nel corpus della parita' (Tools\Verifica\185\Corpus.psd1): il livello e il
  #         seme del pilota automatico (-autodemo) che porta la partita fino al tic del salvataggio
  #   Tics: quanti tic gioca il pilota nell'esplorazione; i tic dei salvataggi si scelgono li' dentro (il tic con piu'
  #         thinker di settore attivi: porte, piattaforme, luci, script ACS; il tic con piu' mobj: proiettili in volo,
  #         oggetti nati; un tic avanti nella partita) oppure si fissano con SaveTics = @(...)
  #   SaveDirs: le cartelle dei salvataggi del gioco, relative alla cartella di lavoro
  Games = @{
    Doom    = @{ SaveDirs = @('DATA\SAVES') }
    Heretic = @{ SaveDirs = @('DATA\SAVES') }
    Hexen   = @{ SaveDirs = @('DATA\SAVES', 'HEXNDATA') }
    # Strife: una cartella per slot nella cartella dei dati; la 6 e' quella temporanea della partita in corso
    Strife  = @{ SaveDirs = @('strfsav0.ssg', 'strfsav1.ssg', 'strfsav2.ssg', 'strfsav3.ssg', 'strfsav4.ssg', 'strfsav5.ssg', 'strfsav6.ssg') }
  }
  Entries = @(
    @{ Game = 'Doom'; Name = 'd1_e1m1'; Iwad = 'DOOM1.WAD'; Warp = '1 1'; Skill = 3; Seed = 11; Tics = 1000 }
    @{ Game = 'Doom'; Name = 'd1_e1m3'; Iwad = 'DOOM1.WAD'; Warp = '1 3'; Skill = 2; Seed = 13; Tics = 1000 }
    @{ Game = 'Doom'; Name = 'f2_map02'; Iwad = 'FREEDOOM2.WAD'; Warp = '2'; Skill = 1; Seed = 22; Tics = 1000 }
    @{ Game = 'Doom'; Name = 'f2_map07'; Iwad = 'FREEDOOM2.WAD'; Warp = '7'; Skill = 3; Seed = 27; Tics = 1000 }

    @{ Game = 'Heretic'; Name = 'h_e1m1'; Iwad = 'HERETIC1.WAD'; Warp = '1 1'; Skill = 3; Seed = 41; Tics = 1000 }
    @{ Game = 'Heretic'; Name = 'h_e1m3'; Iwad = 'HERETIC1.WAD'; Warp = '1 3'; Skill = 2; Seed = 43; Tics = 1000 }
    @{ Game = 'Heretic'; Name = 'h_e1m6'; Iwad = 'HERETIC1.WAD'; Warp = '1 6'; Skill = 1; Seed = 46; Tics = 1000 }

    @{ Game = 'Hexen'; Name = 'x_map01_f'; Iwad = 'HEXEN.WAD'; Warp = '1'; Skill = 3; Seed = 61; Tics = 1000; Extra = '-class 0' }
    @{ Game = 'Hexen'; Name = 'x_map02_m'; Iwad = 'HEXEN.WAD'; Warp = '2'; Skill = 3; Seed = 63; Tics = 1000; Extra = '-class 2' }
    @{ Game = 'Hexen'; Name = 'x_map03_c'; Iwad = 'HEXEN.WAD'; Warp = '3'; Skill = 1; Seed = 83; Tics = 1000; Extra = '-class 1' }
    @{ Game = 'Hexen'; Name = 'x_map04_c'; Iwad = 'HEXEN.WAD'; Warp = '4'; Skill = 1; Seed = 71; Tics = 1000; Extra = '-class 1' }

    @{ Game = 'Strife'; Name = 's_map32'; Iwad = 'STRIFE0.WAD'; Warp = '32'; Skill = 3; Seed = 71; Tics = 1000 }
    @{ Game = 'Strife'; Name = 's_map33'; Iwad = 'STRIFE0.WAD'; Warp = '33'; Skill = 1; Seed = 72; Tics = 1000 }
    @{ Game = 'Strife'; Name = 's_map34'; Iwad = 'STRIFE0.WAD'; Warp = '34'; Skill = 1; Seed = 76; Tics = 1000 }
  )
}
