fx_version 'cerulean'
game 'gta5'

name "FiveM Dui Boilerplate"
description "A Boilerplate for Using Dui in FiveM"
author "Mycroft Studios"
this_is_a_map 'yes'
version "1.0.0"
lua54 'yes'

shared_scripts {
	"@ox_lib/init.lua",
}

client_scripts {
	'client/classes/*.lua',
	'client/*.lua'
}

ui_page "nui/index.html"

files {
	'nui/index.html',
}

dependencies {
	'ox_lib',
	'ox_target',
}