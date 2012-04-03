synced_hash=$(git log --pretty=format:'%s' \
  | egrep -m 1 "$docas .* [0-9a-f]{10}" \
  | tail -c 11)

synced_hash_gh=$(git log --pretty=oneline \
  | egrep -m 1 "$docas .* [0-9a-f]{10}" \
  | head -c 10)

  | sed 's?^?'"$tempdir"'/?' \


git diff --name-only 139f89ed32b82d558fb292b0e9c181fc14e45a5a..HEAD

git diff --name-only 139f89ed32b82d558fb292b0e9c181fc14e45a5a..HEAD \
  | sed 's/^/abc\//'

git diff --name-only 139f89ed32b82d558fb292b0e9c181fc14e45a5a..HEAD \
  | sed 's/^/\/Users\/Sheng\/GitHub\//' \
  | while read file; do dirname $file; done \
  | uniq >> changed_directories

1: Get Last Docas Synced Master Commit Hash

2: Get Last Docas Synced gh-pages Commit Hash

3: Get gh-pages modified directories, plus, master modified directories

4: Build
