package torrent

import (
	"fmt"
	"log"
	"os"
	"path"

	"github.com/anacrolix/torrent/bencode"
	"github.com/anacrolix/torrent/metainfo"
)

var announceURLs = [][]string{
	{"https://flacsfor.me/foobar/announce"},
}

type Creator struct {
}

func (c *Creator) Create(inputMusicFolder string) string {
	mi := metainfo.MetaInfo{
		AnnounceList: announceURLs,
	}

	mi.SetDefaults()
	info := metainfo.Info{
		PieceLength: 256 * 1024,
	}
	err := info.BuildFromFilePath(inputMusicFolder)
	if err != nil {
		log.Fatal(err)
	}
	mi.InfoBytes, err = bencode.Marshal(info)
	if err != nil {
		log.Fatal(err)
	}

	torrentOutput := fmt.Sprintf("%s.torrent", path.Base(inputMusicFolder))
	fmt.Printf("Outputting torrent file at location: %s", torrentOutput)

	myFile, err := os.Create(torrentOutput)
	if err != nil {
		panic(err)
	}
	err = mi.Write(myFile)
	if err != nil {
		log.Fatal(err)
	}

	return ""
}
