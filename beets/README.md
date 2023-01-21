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

### Tasks

Below are instruction for performing various tasks

#### Contributing To MusicBrainz

MusicBrainz does not support entirely programmatic entry into the canonical MusicBrainz DB. This is to prevent people from inserting massive amounts of incorrect information - they want some sort of "human check" for each entry. As such, the best way to add entries to MusicBrainz are Userscripts. Userscripts are small JS snippets that can run in your browser. For more info about them, refer to [the relevant MusicBrainz wiki page](https://wiki.musicbrainz.org/Guides/Userscripts).

#### Disambiguating Very Similar Releases

Ex: Mac Miller's Faces

### Unrelated TODO

* Figure out how to still torrent files after the import from beets. Is it even possible? Maybe I just keep both? Beets has built in symlink support - could kinda work, but then would lose the beets tags on the actual files (thonk)

* Once I get this PR merged in, the `requirements.txt` can be changed back

* Remove API keys from config.yaml
