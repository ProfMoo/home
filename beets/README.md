# Beets

This beets configuration is built to run as automatically and as smoothly as possible, with as little human interaction as possible. There will still be certain edge cases that need manual intervention (ex: Kanye West has ~6 versions of TLOP, which is extremely hard to handle automatically), but in general the configuration handles tagging, album artwork, removing unfriendly characters form the file system, disambiguation, and more

## Guiding Principles

1. **Prefer manual over incorrect**: If there is ambiguity during a music organization task, prefer to defer to manual intervention over an incorrect action. For example, prefer to ask the user to select the correct album during import rather than assume an incorrect album. Of course, we will try to automate as much as we can.
2. **Prefer raw music file correctness**: While there are many great ways to ensure music is labeled and displayed correctly in the music viewing/browsing tool, this repository prefers to make modifications only to the underlying songs, tags, and directory structure. This ensures that as music browsing tools necessarily change over time in ways we can't predict, the underlying files remain semantically correct.

## Assumptions

This beets configuration is based on a few assumptions, which, if broken, could lead to unintended behavior

1. **Exact duplicates shouldn't be added to pre-import folder**: If duplicates are added to the pre-import folder, then you can expect both copies to be imported. There isn't any way (that I've found) to disallow exact copies while also allowing for "almost duplicates", such as multiple versions of Kanye West's Donda (which are different only in custom disambiguations, such as "streaming edition date"), Deluxe Editions, and Mac Miller's Faces (one version was a self-released mixtape, the other released on streaming). So, until this is figured out, duplicates have been allowed into the beets db. If you only want to have unique albums in your library, don't add any duplicates to the pre-processed folder.
2. **Albums are separated by folder before import**: This beets config can successfully explore a complex directory structure with album at the bottom (ex: Knxwledge -> 2014 -> Albums -> MeekMillV1), but if multiple albums are mixed together in the same directory, there is undefined behavior.
3. **New music is being added from a Gazelle-based tracker (ex: RED)**: The configuration expects an 'origin.yaml' 
file in the music directory, which is generated from the tracker's metadata. Beets might still work without it, but the results will be much less effective. This repo is configured to automatically gather that info on download. To view that code, refer [here](../qBittorrent/README.md#features)

## TODO

1. Work on a script that does everything I'd like on import:
   1. DONE: Import
   2. DONE: Get album art
   3. DONE: Get genre(s)
   4. Fix years (maybe don't need)
2. DONE: Beets automatically moves that into the final location with all the right tags
   1. DONE: Need to figure out how to tell beets to accept albums AS IS when it can't find anything
   2. DONE: Beets currently asks for permission when importing album artwork, which fails because of no STDIN. Need to fix that (check sakuraburst album for live example)
   3. DONE: Figure out why Adele's 30 Deluxe is recognized as a duplicate of the regular version (and therefore isn't being imported)
   4. Figure out why Herobust's Lose Your Shit single is so poorly categorized in beets
   5. DONE: Figure out some script that runs 'beets move' after a duplicate is detected so that beets goes back and adds the proper modifiers to the first version of the album (i.e. deluxe)
   6. DONE: Fix the album disambiguation so that it provides the proper version of the ablum (i.e. deluxe) rather than the label. Ex: Donda, Adele's 30
   7. TODO: Fix Mac Miller's Faces
   8. Look at Mac Miller's KIDS to fix the coverart (there are multiple covers)
   9. DONE: Figure out how to "update" metadata automatically once it's been imported if the config file changes (ex: we want new tags and have edited the config)
   10. TODO: Figure out album artwork more fully
   11. DONE: Figure out how to pull in scans/artwork from typical file locations
   12. TODO: Figure out how to get rid of everything in the pre-processed directory (update: or maybe not because I might ahve to keep both copied for seeding)
   13. TODO: Fix DJ @@
   14. TODO: Explore 'ftintitle' plugin (decided to put this off until later. don't need it right now and can always add in later)
   15. DONE: Look through redacted.ch for more thoughts/info on beets
       1. DONE: Found gazelle-origin here, which could really help with deluxe editions and other complex tags. Need to figure this out with Kanye's TLOP
   16. TOOD: Figure out why beets is continually trying to change some flags
   17. TODO: Fix weird warnings when that print at the top of ever beets command. Seems this comes from individual plugins, so I need to figure out which ones it's coming from and update them.
   18. 2562 - It's not importing from MusicBrainz due to track mismatch. But for some reason, bandcamp and spotify aren't returning a strong rec either. Maybe file a bug report?

### Tasks

Below are instruction for performing various tasks

#### Contributing To Musicbrainz

Musicbrainz does not support entirely programmatic entry into the canonical Musicbrainz DB. This is to prevent people from inserting massive amounts of incorrect information - they want some sort of "human check" for each entry. As such, the best way to add entries to Musicbrainz are Userscripts. Userscripts are small JS snippets that can run in your browser. For more info about them, refer to [the relevant Musicbrainz wiki page](https://wiki.musicbrainz.org/Guides/Userscripts).

### Unrelated TODO

* Figure out how to still torrent files after the import from beets. Is it even possible? Maybe I just keep both? Beets has built in symlink support - could kinda work, but then would lose the beets tags on the actual files (thonk)

* Once I get this PR merged in, the `requirements.txt` can be changed back

* Remove API keys from config.yaml
