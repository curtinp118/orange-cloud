#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build_stamp="$(TZ=Asia/Shanghai date +%Y%m%d-%H%M%S)"
scratch_dir="$project_root/.tmp/personal-ipa-$build_stamp"
output_dir="${1:-$project_root/artifacts/personal-ipa-$build_stamp}"
project="$project_root/apps/ios/Orange Cloud/Orange Cloud.xcodeproj"

if ! xcodebuild -version; then
  echo "Full Xcode 26+ is required. Set DEVELOPER_DIR to Xcode.app/Contents/Developer." >&2
  exit 1
fi
mkdir -p "$scratch_dir" "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"
trap 'rm -rf "$scratch_dir"' EXIT

xcodebuild -version > "$output_dir/xcode-version.txt"
xcodebuild \
  -project "$project" \
  -scheme "Orange Cloud" \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -archivePath "$scratch_dir/OrangeCloud.xcarchive" \
  -derivedDataPath "$scratch_dir/DerivedData" \
  -clonedSourcePackagesDirPath "$scratch_dir/SourcePackages" \
  -onlyUsePackageVersionsFromResolvedFile \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  DEVELOPMENT_TEAM= \
  'SWIFT_ACTIVE_COMPILATION_CONDITIONS=$(inherited) OPENSOURCE_UNLOCKED' \
  archive 2>&1 | tee "$output_dir/build.log"

app_path="$scratch_dir/OrangeCloud.xcarchive/Products/Applications/Orange Cloud.app"
test -d "$app_path"
mkdir -p "$scratch_dir/package/Payload"
ditto "$app_path" "$scratch_dir/package/Payload/Orange Cloud.app"
ipa_path="$output_dir/OrangeCloud-2.2.0-OpenSource-Unlocked-unsigned.ipa"
ditto -c -k --keepParent "$scratch_dir/package/Payload" "$ipa_path"
unzip -tq "$ipa_path"

python3 - "$project_root" "$ipa_path" "$output_dir" <<'PY'
import hashlib
import json
import pathlib
import plistlib
import subprocess
import sys
import zipfile

root, ipa, output = map(pathlib.Path, sys.argv[1:])
with zipfile.ZipFile(ipa) as archive:
    info = plistlib.loads(archive.read("Payload/Orange Cloud.app/Info.plist"))
    executable = "Payload/Orange Cloud.app/" + info["CFBundleExecutable"]
    assert executable in archive.namelist()
    assert info["CFBundleSupportedPlatforms"] == ["iPhoneOS"]
    manifest = {
        "source_commit": subprocess.check_output(
            ["git", "-C", str(root), "rev-parse", "HEAD"], text=True
        ).strip(),
        "version": info["CFBundleShortVersionString"],
        "build": info["CFBundleVersion"],
        "bundle_identifier": info["CFBundleIdentifier"],
        "minimum_ios_version": info["MinimumOSVersion"],
        "compilation_condition": "OPENSOURCE_UNLOCKED",
        "configuration": "Release",
        "signed": False,
        "embedded_watch_app": any("/Watch/" in name for name in archive.namelist()),
        "extensions": sorted(
            name for name in archive.namelist()
            if name.endswith(".appex/Info.plist")
        ),
        "sha256": hashlib.sha256(ipa.read_bytes()).hexdigest(),
    }
(output / "build-manifest.json").write_text(
    json.dumps(manifest, ensure_ascii=False, indent=2) + "\n"
)
(output / "SHA256SUMS").write_text(f"{manifest['sha256']}  {ipa.name}\n")
print(json.dumps(manifest, ensure_ascii=False, indent=2))
PY

echo "IPA: $ipa_path"
