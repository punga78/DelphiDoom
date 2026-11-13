// weapons written for the tests
projectileinfo
{
	name "p_blade"
	model "models/blade.md3"
	flags 1
	gravity 0
	damage 50
	radius 0
	visdamage 0
	damagetype 1
	healthinc 0
	push 0
	detonation 0
	bounce 0
	bouncefric 0
	bouncestop 0
}
projectileinfo
{
	name "p_shell"
	flags 3
	model "models/shell.md3"
	gravity 0.5
	damage 12
	radius 3.5
	damagetype 3
	push 100.25
	bounce 0.5
}
projectileinfo
{
	name "p_rocket"
	damage 100
	radius 120
	damagetype 6
	push 800
	gravity 0.1
	detonation 2.5
}
weaponinfo
{
	number 1
	name "Blade"
	level 1
	model "models/weapons/blade.md3"
	weaponindex 1
	flags 0
	projectile "p_blade"
	numprojectiles 1
	hspread 0
	vspread 0
	speed 0
	acceleration 0
	recoil {0, 0, 0}
	offset {0, 0, 0}
	angleoffset {0, 0, 0}
	extrazvelocity 0
	ammoamount 0
	ammoindex 0
	activate 0.4
	reload 0.4
	spinup 0
	spindown 0
}
weaponinfo
{
	number 2
	name "Cannon"
	level 2
	model "models/weapons/cannon.md3"
	weaponindex 2
	flags 1
	projectile "p_shell"
	numprojectiles 10
	hspread 6
	vspread 4.5
	speed 0
	acceleration 0
	recoil {0, -2, 8.5}
	offset {0, 4, -6}
	angleoffset {0, 0, 0}
	extrazvelocity 0
	ammoamount 1
	ammoindex 3
	activate 0.5
	reload 1
	spinup 0
	spindown 0
}
weaponinfo
{
	number 5
	name "Launcher"
	level 3
	weaponindex 5
	projectile "p_rocket"
	numprojectiles 1
	speed 900
	acceleration 20
	recoil {1, 2}
	extrazvelocity 50
	ammoamount 1
	ammoindex 7
	activate 0.5
	reload 0.8
	spinup 0.1
	spindown 0.2
}