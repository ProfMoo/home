package musicbrainz

import (
	"fmt"
	"io"
	"net/http"
)

type RecordingGetter struct {
}

type Recording struct {
	ID             string `json:"id,attr"`
	Title          string `json:"title"`
	Length         int    `json:"length"`
	Disambiguation string `json:"disambiguation"`
}

func (r *RecordingGetter) GetRecording(musicbrainzID string) error {
	resp, err := http.Get(fmt.Sprintf("https://musicbrainz.org/ws/2/release/%s?&inc=artists&fmt=json", musicbrainzID))
	if err != nil {
		return err
	}

	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return err
	}

	fmt.Printf("Person: %s", body)
}
