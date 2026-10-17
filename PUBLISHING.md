# Publishing

Releases follow the same Maven Central workflow as `ffmpeg-ffm`.

1. Build and test all three native classifiers through CI.
2. Remove `-SNAPSHOT`, commit, and create a GitHub release tagged exactly
   `v<project.version>`.
3. The release workflow downloads all platform artifacts and runs:

   ```sh
   ./mvnw -B clean deploy -P release,all-natives \
     -Dnative.classifier=macos-arm64 -DskipTests
   ```

The `central` server credentials and GPG key/passphrase must be configured as
repository secrets. Publishing is intentionally absent from ordinary builds.

Builds use the Maven Wrapper (`./mvnw`), which pins Maven 3.9.16. Do not
switch the release to the runner's `mvn`: under Maven 3.10 the
central-publishing plugin (0.11.0) stages resolver files such as
`_remote.repositories` and `maven-metadata-local.xml` into the bundle, and
Central rejects it with "Bundle has content that does NOT have a .pom file".

To inspect the signed bundle CI would upload, run the Release workflow
manually (optionally with a throwaway `version`). It builds all three native
classifiers through CI, builds the bundle against an unreachable Central URL
with placeholder credentials, fails if the bundle contains local repository
metadata, and attaches `central-bundle.zip` as a workflow artifact; nothing is
published.
