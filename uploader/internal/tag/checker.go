package tag

type Checker struct {
	recordingGetter RecordingGetter
}

type RecordingGetter interface {
	GetRecording(musicbrainzID string) error
}

func (c *Checker) Check(musicFolderLocation string, musicbrainzID string) error {
	recording, err := c.recordingGetter.GetRecording(musicbrainzID)
	if err != nil {
		return err
	}
	// Check that the folder is name is correct

	// Check that the track names are correct

	// Check that the tracks have at least the required tags, as per the rules
	return nil
}
