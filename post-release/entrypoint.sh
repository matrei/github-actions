#!/bin/bash
# $1 == GH_TOKEN

if [ -z "$SNAPSHOT_SUFFIX" ]; then
  SNAPSHOT_SUFFIX="-SNAPSHOT"
fi

if [ -z "$GIT_USER_EMAIL" ]; then
   GIT_USER_EMAIL="${GITHUB_ACTOR}@users.noreply.github.com"
fi

if [ -z "$GIT_USER_NAME" ]; then
   GIT_USER_NAME="github-action"
fi

echo -n "Determining release version: "
if [ -z "$RELEASE_VERSION" ]; then
  release_version=${GITHUB_REF:11}
else
  release_version=${RELEASE_VERSION}
fi
echo $release_version

echo -n "Determining next version: "
next_version=`/increment_version.sh -p $release_version`
echo $next_version
echo "next_version=${next_version}" >> $GITHUB_OUTPUT

echo "Configuring git"
git config --global --add safe.directory /github/workspace
git config --global user.email "$GIT_USER_EMAIL"
git config --global user.name "$GIT_USER_NAME"
git fetch

echo -n "Determining target branch: "
if [ -z "$TARGET_BRANCH" ]; then
  target_branch=`cat $GITHUB_EVENT_PATH | jq '.release.target_commitish' | sed -e 's/^"\(.*\)"$/\1/g'`
else
  target_branch=${TARGET_BRANCH}
fi
echo $target_branch
git checkout $target_branch

echo "Setting new snapshot version"
sed -i "s/^version.*$/version\=${next_version}$SNAPSHOT_SUFFIX/" gradle.properties
sed -i "s/^projectVersion.*$/projectVersion\=${next_version}$SNAPSHOT_SUFFIX/" gradle.properties
cat gradle.properties

echo "Committing and pushing"
git add gradle.properties
git commit -m "Next development version: ${next_version}$SNAPSHOT_SUFFIX"
git push origin $target_branch

# Clean up .git artifacts we've created as root (so non-docker actions that follow can use git without re-cloning)
echo "Cleaning up artifacts with excessive permissions"
rm -f .git/COMMIT_EDITMSG

# TODO: Not sure why this is necessary
echo "Setting release version back so that Maven Central sync can work"
sed -i "s/^version.*$/version\=${release_version}/" gradle.properties
sed -i "s/^projectVersion.*$/projectVersion\=${release_version}/" gradle.properties
cat gradle.properties
