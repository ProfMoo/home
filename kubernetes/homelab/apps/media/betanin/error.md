# Error

Artists:

* Charli XCX (haven't diagnosed full issue yet)

* ~~Just A Gent (can't see newer one, so not as big of a problem)~~

* Medasin (fixed filesystem, not playlists)

* Seventh Stitch (haven't diagnosed full issue yet)

* Tyler, The Creator (can't see old albums, completely fucked)

* Fred Again...

## Library Problem

Also have [this problem](https://discourse.beets.io/t/library-db-still-has-old-path-after-moving-collection-to-a-new-location/2331)

```bash
beet -l /beets/beets.db move -p -a albumartist:"Fred Again"
```

Ran this query to fix all the paths in the DB:

```sql
UPDATE items
SET path = CAST(
   REPLACE(CAST(path AS TEXT), '/music/', '/data/media/music/')
   AS BLOB
)
WHERE
    CAST(path AS TEXT) LIKE '/music/%';
```

For the album artwork:

```sql
UPDATE albums
SET artpath = CAST(
   REPLACE(CAST(artpath AS TEXT), '/music/', '/data/media/music/')
   AS BLOB
)
WHERE
    CAST(artpath AS TEXT) LIKE '/music/%';
```

Random SQL:

```sql
select * from albums limit 100; 

select count(*) from albums limit 100; 

select * from items limit 100; 

select count(*) from items; 

select * from items WHERE album_id = '1';

select * from items WHERE title = 'Make You Feel My Love';

select * from items WHERE path = '/data/media/music/Adele/Make You Feel My Love/01 Make You Feel My Love.m4a';

PRAGMA table_info(items);

SELECT * FROM items WHERE path LIKE '%';
```
