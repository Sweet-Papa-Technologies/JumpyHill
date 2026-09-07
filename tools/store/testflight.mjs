import { apple, bundleId } from "./apple-api.mjs";
const appId = "6809527457";
const args = process.argv.slice(2);
const app = (await apple(`apps/${appId}`)).data;
if (app.attributes.bundleId !== bundleId)
  throw new Error("Unexpected App Store Connect app.");
const groupName = "TreadFall Playtest";
let groups = (await apple(`apps/${appId}/betaGroups`)).data;
let group = groups.find(
  (g) => g.attributes.name === groupName && g.attributes.isInternalGroup,
);
if (args.includes("--setup")) {
  if (!group)
    ({ data: group } = await apple("betaGroups", "POST", {
      data: {
        type: "betaGroups",
        attributes: { name: groupName, isInternalGroup: true },
        relationships: { app: { data: { type: "apps", id: appId } } },
      },
    }));
  const localizations = (await apple(`apps/${appId}/betaAppLocalizations`))
    .data;
  if (!localizations.some((l) => l.attributes.locale === "en-US"))
    await apple("betaAppLocalizations", "POST", {
      data: {
        type: "betaAppLocalizations",
        attributes: {
          locale: "en-US",
          description:
            "TreadFall: choose your launch angle and roll a tire through 33 downhill courses. Read the bumps, moving obstacles, gaps, modifiers and breakable glass. Progress is saved on this device. No account is required.",
          feedbackEmail: "fterry@sweetpapatechnologies.com",
        },
        relationships: { app: { data: { type: "apps", id: appId } } },
      },
    });
}
const buildAt = args.indexOf("--build");
if (buildAt >= 0) {
  if (!group) throw new Error("Run --setup first.");
  const buildId = args[buildAt + 1];
  const build = (await apple(`builds/${buildId}?include=app`)).data;
  if (
    build.relationships.app.data.id !== appId ||
    build.attributes.processingState !== "VALID"
  )
    throw new Error("Expected a valid, processed build of this app.");
  const notes = (await apple(`builds/${buildId}/betaBuildLocalizations`)).data;
  if (!notes.some((n) => n.attributes.locale === "en-US"))
    await apple("betaBuildLocalizations", "POST", {
      data: {
        type: "betaBuildLocalizations",
        attributes: {
          locale: "en-US",
          whatsNew:
            "0.5.0: Simpler menus and no roll time limit. Test long rolls on level 3, launch angle controls, both camera views, moving obstacles, glass walls, retry and pause/resume.",
        },
        relationships: { build: { data: { type: "builds", id: buildId } } },
      },
    });
  const builds = (await apple(`betaGroups/${group.id}/builds`)).data;
  if (!builds.some((b) => b.id === buildId))
    await apple(`betaGroups/${group.id}/relationships/builds`, "POST", {
      data: [{ type: "builds", id: buildId }],
    });
}
groups = (await apple(`apps/${appId}/betaGroups`)).data;
const result = await apple(
  `builds?filter[app]=${appId}&include=buildBetaDetail`,
);
console.log(
  JSON.stringify(
    {
      appId,
      groups: groups.map((g) => ({ id: g.id, ...g.attributes })),
      builds: result.data.map((b) => ({ id: b.id, ...b.attributes })),
      testing: result.included?.map((b) => ({ id: b.id, ...b.attributes })),
    },
    null,
    2,
  ),
);
