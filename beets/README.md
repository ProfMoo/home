# TODO

1. DONE: Get beets running in a docker image so that it's more easily repeatable
2. Work on a script that does everything I'd like on import:
   1. DONE: Import
   2. DONE: Get album art
   3. Get genre
   4. Fix years
3. DONE: Beets automatically moves that into the final location with all the right tags
   1. DONE: Need to figure out how to tell beets to accept albums AS IS when it can't find anything
   2. DONE: Beets currently asks for permission when importing album artwork, which fails because of no STDIN. Need to fix that (check sakuraburst album for live example)
   3. DONE: Figure out why Adele's 30 Deluxe is recognized as a duplicate of the regular version (and therefore isn't being imported)
   4. Figure out why Herobust's Lose Your Shit single is so poorly categorized in beets
   5. Figre out some script that runs 'beets move' after a duplicate is detected so that beets goes back and adds the proper modifiers to the first version of the album (i.e. deluxe)
   6. Fix the album disambiguation so that it provides the proper version of the ablum (i.e. deluxe) rather than the label. Ex: Donda, Adele's 30
4. Lidarr can automatically download albums of artists I like and put it into the pre-processing folder

# TO TRY NEXT

1. Mixtapes from more underground rappers
2. The Skrillex disco dump
3. Mura Masa random singles
4. the heart and the tongue - chance the rapper
5. 28 mansions
