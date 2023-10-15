package main

import (
	"fmt"

	"github.com/ProfMoo/home/uploader/internal/tag"
	"github.com/ProfMoo/home/uploader/internal/torrent"
)

func main() {
	fmt.Printf("Hello World!!!")

	musicFolderLocation := "Uppermost - H34RTB34TS - 2023 (WEB - FLAC - Lossless)"
	musicBrainzRelease := "a56c7cba-5254-49ab-9308-01e377f9a570"

	// 1. Ensure folder is named correctly
	// Could do a check of the file and see if the specs are good?

	// 2. Ensure tags on file are up to par
	// Maybe check album artwork as well

	tagChecker := tag.Checker{}
	err := tagChecker.Check(musicFolderLocation, musicBrainzRelease)
	if err != nil {
		panic(err)
	}

	// 3. Create torrent file

	torrentCreator := torrent.Creator{}
	torrentCreator.Create(musicFolderLocation)

	// 4. Check desired upload locations for similar or dupes

}
