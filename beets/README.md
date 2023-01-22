# Beets

This beets configuration is built to run as automatically and as smoothly as possible, with as little human interaction as possible. There will still be certain edge cases that need manual intervention (ex: Kanye West has ~6 versions of TLOP, which is extremely hard to handle automatically), but in general the configuration handles tagging, album artwork, removing unfriendly characters form the file system, disambiguation, and more.

This code covers the full music downloading lifecycle, starting in a Gazelle-based private tracker (i.e. RED), downloading the torrent files, sorting/organizing the music files locally, and importing into Roon.

## Guiding Principles

1. **Prefer manual over incorrect**: If there is ambiguity during a music organization task, prefer to defer to manual intervention over an incorrect action. For example, prefer to ask the user to select the correct album during import rather than assume an incorrect album. Of course, we will try to automate as much as we can.
2. **Prefer music file correctness over music viewer corrections**: While there are many great ways to ensure music is labeled and displayed correctly in the music viewing/browsing tool, this repository prefers to make modifications to the underlying songs, tags, and directory structure. This ensures that as music browsing tools necessarily change over time in ways we can't predict, the underlying files remain organizationally sound.
3. **Prefer Musicbrainz as data source**: Musicbrainz is considered the most canonical source of information for both `beets` and Roon. This repository uses Musicbrainz as its primary source of information, and prefers 

## Assumptions

This beets configuration is based on a few assumptions, which, if broken, could lead to unintended behavior

1. **Exact duplicates shouldn't be added to pre-import folder**: If duplicates are added to the pre-import folder, then you can expect both copies to be imported. There isn't any way (that I've found) to disallow exact copies while also allowing for "almost duplicates", such as multiple versions of Kanye West's Donda (which are different only in custom disambiguations, such as "streaming edition date"), Deluxe Editions, and Mac Miller's Faces (one version was a self-released mixtape, the other released on streaming). So, until this is figured out, duplicates have been allowed into the beets db. If you only want to have unique albums in your library, don't add any duplicates to the pre-processed folder.
2. **Albums are separated by folder before import**: This beets config can successfully explore a complex directory structure with album at the bottom (ex: Knxwledge -> 2014 -> Albums -> MeekMillV1), but if multiple albums are mixed together in the same directory, there is undefined behavior.
3. **New music is being added from a Gazelle-based tracker (ex: RED)**: The configuration expects an 'origin.yaml' 
file in the music directory, which is generated from the tracker's metadata. Beets might still work without it, but the results will be much less effective. This repo is configured to automatically gather that info on download. To view that code, refer [here](../qBittorrent/README.md#features)

## How Tos

Below are instruction for performing various tasks that are important for maintaining the music library, but might not be immediately obvious.

### Contributing To MusicBrainz

MusicBrainz does not support entirely programmatic entry into the canonical MusicBrainz DB. This is to prevent people from inserting massive amounts of incorrect information - they want some sort of "human check" for each entry. As such, the best way to add entries to MusicBrainz are Userscripts. Userscripts are small JS snippets that can run in your browser. For more info about them, refer to [the relevant MusicBrainz wiki page](https://wiki.musicbrainz.org/Guides/Userscripts).

### Disambiguating Very Similar Releases

#### Overview

The import process *should* account for very similar releases, such as the various releases of Kanye West's The Life of Pablo. However, this might not be the case for two reasons:

1. One of the versions was added to the library at a previous date, before additional disambiguation fields were added to the download/import process.
2. The information coming from the source (i.e. the Gazelle-based tracker) is simply not complete enough.

> **NOTE** 
> 
> Beets will only add the disambiguation to the file when it's needed. If you only have one of these versions, beets will not add any information because the `albumartist` and `album`

#### Diagnosis

First, to get the full scope of the situation, run this command, which tells you all the information relevant to `beets` for disambiguating releases:

   ```bash
   beet ls album:"<album>" -af 'id: $id path: $path | $albumartist - $album - $albumtype - $releasegroupdisambig - $albumdisambig - $label - $catalognum'
   ```


> **NOTE** 
> 
> `albumdisambig` - refers to differentiators within one album, such as "Deluxe Edition" or "Bootleg Release"
> 
> `releasegroupdisambig` - refers to differentiators between similarly named albums, such as the numerous self-titled Weezer albums. They are called "Blue Album" and "Red Album" by convention, but that is not the technical name.

The output of the above command will begin to paint a picture of how `beets` is currently disambiguating the two releases. It's worth noting that in the current configuration, `beets` currently doesn't account for various forms of media (ex: CD vs. Vinyl) in the release group disambiguation process. Instead, `beets` will differentiate on something like Catalog number.

#### Fixing

Beets will use the first differing field in the bash command above as the disambiguation field. So, modify the first field that makes sense for this particular scenario (it will be different for each disambiguation task) by using a command similar to:

   ```bash
   # In this case, the most logical item to change is `albumdisambig`, but it could be any of the fields above
   beet modify -a id:<id_from_above> albumdisambig=<custom_disambig>
   ```

#### Disambiguation Examples

Below is a table providing relatively complex example of how the disambiguation process would look in practice. The bolded fields indicate the field that beets will recognize as disambiguated *first* (it's in order). This is important because the first disambiguated field is the field that will be populated next to the directory in the filesystem and picked up by Roon.

| Release Description                                                                                                             | `albumartist` | `album`              | `albumtype` | `releasegroupdisambig` | `albumdisambig`              | `label`                 | `catalognum`          |
| ------------------------------------------------------------------------------------------------------------------------------- | ------------- | -------------------- | ----------- | ---------------------- | ---------------------------- | ----------------------- | --------------------- |
| [30 - Adele - Target Exclusive](https://musicbrainz.org/release/5c2b134a-70df-4bd3-8b72-7cfce4f82e49)                           | Adele         | 30                   | album       | -                      | **Target Exclusive**         | Columbia                | 19439941962           |
| [30 - Adele - Normal Release](https://musicbrainz.org/release/c646429a-bda5-4e38-b4d2-3804b9dea74a)                             | Adele         | 30                   | album       | -                      | -                            | Columbia                | 19439937971           |
| [Faces - Mac Miller - Original Bootleg](https://musicbrainz.org/release/0505543b-3387-4119-a1cf-8670fec5632a)                   | Mac Miller    | Faces                | album       | -                      | -                            | -                       | -                     |
| [Faces - Mac Miller - Google Play Release](https://www.discogs.com/release/12690000-Mac-Miller-Mac-Miller)                      | Mac Miller    | Faces                | album       | -                      | **Google Play Release**      | Dundridge Entertainment | -                     |
| [Faces - Mac Miller - 2021 Reissue](https://musicbrainz.org/release/73d5bede-e281-4e08-b00e-d81dcae2e75c)                       | Mac Miller    | Faces                | album       | -                      | **2021 Reissue**             | Warner Records          | 093624881391          |
| [People's Instinctive - Tribe - Original Release](https://musicbrainz.org/release/1c65dc93-6748-3bb5-be18-bdbbad7f8d42)         | Tribe         | People's Instinctive | album       | -                      | -                            | Jive                    | **1331-2-J, J2 1331** |
| [People's Instinctive - Tribe - 25th Anniversary Edition](https://musicbrainz.org/release/3a301916-9140-4265-a719-fb89dc85fa35) | Tribe         | People's Instinctive | album       | -                      | **25th Anniversary Edition** | Jive                    | 88875157852           |
| [People's Instinctive - Tribe - UK Version](https://musicbrainz.org/release/72875d9b-8a1e-4633-8a9b-3951f768b9cd)               | Tribe         | People's Instinctive | album       | -                      | -                            | Jive                    | **CHIP 96**           |
| [People's Instinctive - Tribe - Germany Version](https://musicbrainz.org/release/a30577af-64e7-3e86-9930-556e3e5357b5)          | Tribe         | People's Instinctive | album       | -                      | -                            | **Zomba Label Group**   | 74321 19421 2         |
| [TLOP - Kanye West - 2016-02-14 Edition](https://musicbrainz.org/release/99e14f9e-5831-4b2c-b595-531be0f225ea)                  | Kanye West    | TLOP                 | album       | -                      | **2016-02-14 Edition**       | G.O.O.D. Music          | -                     |
| [TLOP - Kanye West - 2016-03-16 Edition](https://musicbrainz.org/release/435983dd-cffc-436f-a700-231d8d65c0d3)                  | Kanye West    | TLOP                 | album       | -                      | **2016-03-16 Edition**       | G.O.O.D. Music          | -                     |
| [Weezer - Weezer - (Blue Album)](https://musicbrainz.org/release/1e477f68-c407-4eae-ad01-518528cedc2c)                          | Weezer        | Weezer               | album       | **Blue Album**         |                              | DGC Records             | DGCD 24629            |
| [Weezer - Weezer - (Black Album)](https://musicbrainz.org/release-group/1a5ae023-9cd4-431d-8176-d93515e63549)                   | Weezer        | Weezer               | album       | **Black Album**        |                              | Atlantic                | WPCR-18183            |
| [Highway To Hell - AC/DC - Album](https://musicbrainz.org/release/6cd71d78-e5bf-3484-8353-9536e6bae53f)                         | AC/DC         | Highway To Hell      | **album**   | -                      | -                            | Atlantic                | SD 19244              |
| [Highway To Hell - AC/DC - Single](https://musicbrainz.org/release/180dd0a6-a08d-4614-9508-ff11e6dd7bf1)                        | AC/DC         | Highway To Hell      | **single**  | -                      | -                            | Atlantic                | K 11321               |

This command provides the full list of fields that are used for disambiguation within the beets DB, **in order starting with `albumartist`**. If all of these fields are the same (besides `id` and `path`), then the beets DB will mark the releases as precisely the same.

#### More Disambiguation Information

For more information about how `beets` handles release disambiguation, please refer to the [relevant documentation](https://beets.readthedocs.io/en/latest/reference/pathformat.html#album-disambiguation).

### Tips

1. **Do not run multiple `beets` commands simultaneously against one DB**. It is highly likely that one of the command will fail due to locked rows/tables. If this occurs, the DB could be in an undetermined state, such as partially imported albums or partially modified metadata. This situation could require a lot of manual, tedious work to recover from.

### Unrelated TODO

* Figure out how to still seed torrents after the import from beets. Is it even possible? Maybe I just keep both? Beets has built in symlink support - could kinda work, but then would lose the beets tags on the actual files (thonk)

* Once I get this PR merged in, the `requirements.txt` can be changed back

* Remove API keys from config.yaml

* Move Roon to a container. [It's seemingly possible](https://hub.docker.com/r/steefdebruijn/docker-roonserver)
