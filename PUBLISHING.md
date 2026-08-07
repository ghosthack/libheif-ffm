# Publishing

Releases follow the same Maven Central workflow as `ffmpeg-ffm`.

1. Build and test all three native classifiers through CI.
2. Remove `-SNAPSHOT`, commit, and create a GitHub release tagged exactly
   `v<project.version>`.
3. The release workflow downloads all platform artifacts and runs:

   ```sh
   mvn -B clean deploy -P release,all-natives \
     -Dnative.classifier=macos-arm64 -DskipTests
   ```

The `central` server credentials and GPG key/passphrase must be configured as
repository secrets. Publishing is intentionally absent from ordinary builds.
