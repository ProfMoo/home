import os
import json
import requests

from torf import Torrent


def create_torrent_file(torrent_release_location: str) -> str:

    TORRENT_DIR = os.getenv('TORRENT_DIR')
    REDACTED_ANNOUNCE_URL = os.getenv('REDACTED_ANNOUNCE_URL')

    print("Starting up torrent manager script")

    newTorrent = Torrent(path=torrent_release_location,
                         trackers=[
                             REDACTED_ANNOUNCE_URL
                         ],
                         source='RED',
                         private='True')

    print("Creating new torrent with properties: " + str(newTorrent))

    newTorrent.generate()

    torrent_file_location = TORRENT_DIR + '/test.torrent'
    newTorrent.write(torrent_file_location)

    print("New torrent created at location: " + torrent_file_location)

    return torrent_file_location


def query_red() -> None:

    REDACTED_API_KEY = os.getenv('REDACTED_API_KEY')

    url = 'https://redacted.ch/ajax.php?action=top10'
    headers = {'Authorization': REDACTED_API_KEY}

    x = requests.get(url, headers=headers)

    print(x.text)

    return True


def upload_torrent_to_red(torrent_file_location: str) -> bool:

    REDACTED_API_KEY = os.getenv('REDACTED_API_KEY')

    url = 'https://redacted.ch/ajax.php?action=upload'
    headers = {'Authorization': REDACTED_API_KEY}

    params = {'file_input': torrent_file_location,
              'type': 'Music'}

    x = requests.post(url, headers=headers, json=params)

    print(x.text)

    return True


MUSIC_TO_UPLOAD_DIR = os.getenv('MUSIC_TO_UPLOAD_DIR')

create_torrent_file(MUSIC_TO_UPLOAD_DIR + '/Losing My Way')
query_red()
