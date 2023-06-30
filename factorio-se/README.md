# Factorio Server

This is the first shared server the OB Kiddos made.

## Quick Start

```bash
./docker_run.sh local
```

## Debug

Sometimes, during Factorio's startup (not to be confused with the docker container's startup script), the container will crash out and give an error like this:

```text
34.698 Script @space-exploration-postprocess/diagnostics.lua:116: {"", {"", "[font=default-large-bold]- [color=red]", {"diagnostics.required-mod-missing", "[color=cyan]jetpack[/color]"}, "[/color][/font]\n"}}
36.837 Error ServerMultiplayerManager.cpp:92: MultiplayerManager failed: "The mod Space Exploration Postprocess (Required) (0.6.25) caused a non-recoverable error.
Please report this error to the mod author.
Error while running event space-exploration-postprocess::on_configuration_changed
[font=default-large-bold]═══════════════════════[/font]
[font=default-large-bold]═══════════════════════[/font]
[img=utility/warning_icon][font=default-large-semibold][color=yellow]Space Exploration is not properly installed.[/color][/font]
[font=default-large-semibold]Fix the issues marked below:[/font]
[font=default-large-bold]- [color=red]Required mod [color=cyan]jetpack[/color] is missing.[/color][/font]
[font=default-large-bold]═══════════════════════[/font]
[font=default-large-bold]═══════════════════════[/font]
```

This might be due to an outdated base Factorio version. Sometimes, if the startup script automatically updates the mods, but the factorio docker container is still on an older version, Factorio startup can't complete and gives an ambiguous error such as above. 
