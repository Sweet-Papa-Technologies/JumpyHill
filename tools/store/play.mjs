// Closed testing only. Inspect by default; --upload explicitly commits a release.
import { readFile } from "node:fs/promises";
import { api, packageName } from "./play-api.mjs";
const args = process.argv.slice(2);
const edit = await api("edits", "POST", {});
let committed = false;
try {
  const tracks = await api(`edits/${edit.id}/tracks`);
  console.log(JSON.stringify({ packageName, tracks: tracks.tracks }, null, 2));
  if (args.includes("--upload") || args.includes("--activate")) {
    const aab =
      args.find((a) => a.endsWith(".aab")) ||
      "build/android/TREADFALL.aab";
    let bundle;
    if (args.includes("--activate")) {
      const draft = tracks.tracks
        .find((t) => t.track === "alpha")
        ?.releases?.find((r) => r.status === "draft");
      if (!draft || draft.versionCodes?.length !== 1)
        throw new Error(
          "Expected exactly one closed-testing draft version to activate.",
        );
      bundle = { versionCode: draft.versionCodes[0] };
    } else {
      bundle = await api(
        `edits/${edit.id}/bundles?uploadType=media`,
        "POST",
        await readFile(aab),
        true,
      );
    }
    console.log(
      JSON.stringify({
        uploadedVersion: bundle.versionCode,
        sha256: bundle.sha256,
      }),
    );
    const release = {
      name: "0.5.0 — Let it roll",
      versionCodes: [String(bundle.versionCode)],
      status: args.includes("--draft") ? "draft" : "completed",
      releaseNotes: [
        {
          language: "en-US",
          text: "Simpler menus and no roll time limit. Slow rolls can finish; a tire only becomes stuck after it stops making progress. Please test level 3, moving obstacles, glass banks and camera switching.",
        },
      ],
    };
    await api(`edits/${edit.id}/tracks/alpha`, "PUT", {
      track: "alpha",
      releases: [release],
    });
    await api(`edits/${edit.id}:validate`, "POST");
    await api(`edits/${edit.id}:commit`, "POST");
    committed = true;
    console.log(
      JSON.stringify({ committed: true, track: "alpha", release }, null, 2),
    );
  }
} finally {
  if (!committed) await api(`edits/${edit.id}`, "DELETE").catch(() => {});
}
