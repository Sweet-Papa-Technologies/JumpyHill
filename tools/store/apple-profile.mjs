import { mkdir, writeFile } from "node:fs/promises";
import { resolve } from "node:path";
import { apple, bundleId } from "./apple-api.mjs";
if (!process.argv.includes("--create"))
  throw new Error(
    "Use --create to provision this app with the existing SPT distribution certificate.",
  );
const directory = resolve("build/ios-store");
await mkdir(directory, { recursive: true, mode: 0o700 });
const bundles = await apple(`bundleIds?filter[identifier]=${bundleId}`);
const bundle = bundles.data[0];
if (!bundle)
  throw new Error(`Register ${bundleId} in the SPT developer account first.`);
const certificates = await apple(
  "certificates?filter[certificateType]=DISTRIBUTION",
);
const certificate = certificates.data.find(
  (c) => c.attributes.serialNumber === "3C1FB41089D400C864A5282761E16504",
);
if (
  !certificate ||
  Date.parse(certificate.attributes.expirationDate) <= Date.now()
)
  throw new Error(
    "The expected SPT distribution certificate is unavailable or expired.",
  );
const name = "TreadFall App Store";
const profiles = await apple(
  `profiles?filter[name]=${encodeURIComponent(name)}`,
);
let profile = profiles.data.find(
  (p) =>
    p.attributes.profileState === "ACTIVE" &&
    Date.parse(p.attributes.expirationDate) > Date.now(),
);
if (!profile) {
  ({ data: profile } = await apple("profiles", "POST", {
    data: {
      type: "profiles",
      attributes: { name, profileType: "IOS_APP_STORE" },
      relationships: {
        bundleId: { data: { type: "bundleIds", id: bundle.id } },
        certificates: { data: [{ type: "certificates", id: certificate.id }] },
      },
    },
  }));
}
await writeFile(
  `${directory}/TREADFALL.mobileprovision`,
  Buffer.from(profile.attributes.profileContent, "base64"),
  { mode: 0o600 },
);
console.log(
  JSON.stringify({
    name,
    uuid: profile.attributes.uuid,
    expires: profile.attributes.expirationDate,
    directory,
  }),
);
