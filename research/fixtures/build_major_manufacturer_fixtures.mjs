import fs from "node:fs/promises";
import path from "node:path";
import { Workbook } from "@oai/artifact-tool";

const repoRoot = path.resolve(process.cwd());
const inputPaths = [
  "research/fixtures/fixtures_us_bars.csv",
  "research/fixtures/fixtures_us_pro.csv",
  "research/fixtures/fixtures_eu_uk.csv",
];
const outputPath = path.join(
  repoRoot,
  "assets/fixtures/research/major-manufacturer-fixtures.csv",
);
const previewPath = "/tmp/vv-fixture-csv/major-manufacturer-fixtures.png";
const expectedHeader = [
  "name",
  "model_number",
  "manufacturer",
  "type",
  "subtype",
  "url",
  "data",
  "images",
];
const assetHeader = [
  "asset_state",
  "asset_root",
  "fixture_record",
  "fixture_note",
  "blend_asset",
  "usdz_asset",
  "validation_report",
];
const outputHeader = [...expectedHeader, ...assetHeader];

const typeNames = new Map([
  ["moving_head", "Moving head"],
  ["batten", "Batten"],
  ["profile", "Profile"],
  ["wash", "Wash"],
  ["strobe", "Strobe / blinder"],
  ["strobe_blinder", "Strobe / blinder"],
  ["fresnel", "Fresnel"],
  ["par", "PAR"],
  ["architectural wash", "Architectural wash"],
  ["spot", "Spot"],
]);

function csvCell(value) {
  const text = String(value ?? "");
  return /[",\r\n]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
}

function normalizedType(value) {
  const key = String(value ?? "").trim().toLowerCase();
  return typeNames.get(key) ?? String(value ?? "").trim();
}

function assertHttps(url, label) {
  if (!String(url).startsWith("https://")) {
    throw new Error(`${label} is not an HTTPS URL: ${url}`);
  }
}

const existingAssets = new Map();
try {
  const existingText = await fs.readFile(outputPath, "utf8");
  const existingBook = await Workbook.fromCSV(existingText, { sheetName: "Fixtures" });
  const values = existingBook.worksheets.getItem("Fixtures").getUsedRange(true).values;
  const header = values[0].map(String);
  const indexes = Object.fromEntries(header.map((column, index) => [column, index]));
  if (assetHeader.every((column) => column in indexes)) {
    for (const row of values.slice(1)) {
      const key = ["manufacturer", "name", "model_number"]
        .map((column) => String(row[indexes[column]] ?? "").trim().toLowerCase())
        .join("::");
      existingAssets.set(
        key,
        Object.fromEntries(assetHeader.map((column) => [column, String(row[indexes[column]] ?? "").trim()])),
      );
    }
  }
} catch (error) {
  if (error?.code !== "ENOENT") throw error;
}

const records = [];
for (const relativePath of inputPaths) {
  const csvText = await fs.readFile(path.join(repoRoot, relativePath), "utf8");
  const imported = await Workbook.fromCSV(csvText, { sheetName: "Fixtures" });
  const sourceSheet = imported.worksheets.getItem("Fixtures");
  const values = sourceSheet.getUsedRange(true).values;
  const header = values[0].map(String);
  if (JSON.stringify(header) !== JSON.stringify(expectedHeader)) {
    throw new Error(`Unexpected header in ${relativePath}: ${header.join(",")}`);
  }
  for (const row of values.slice(1)) {
    if (row.every((value) => value === null || value === "")) continue;
    const record = Object.fromEntries(
      expectedHeader.map((column, index) => [column, String(row[index] ?? "").trim()]),
    );
    record.type = normalizedType(record.type);
    record.subtype = record.subtype.replaceAll("_", " ").replace(/\s+/g, " ");
    const data = JSON.parse(record.data);
    const images = JSON.parse(record.images);
    if (!data || typeof data !== "object" || Array.isArray(data)) {
      throw new Error(`${record.manufacturer} ${record.name} has invalid data JSON`);
    }
    if (!data.dimensions) {
      throw new Error(`${record.manufacturer} ${record.name} is missing dimensions`);
    }
    if (
      !Array.isArray(data.protocols) ||
      !data.protocols.some((protocol) => /dmx|art-?net/i.test(String(protocol)))
    ) {
      throw new Error(`${record.manufacturer} ${record.name} lacks DMX or Art-Net evidence`);
    }
    if (!Array.isArray(images)) {
      throw new Error(`${record.manufacturer} ${record.name} has invalid images JSON`);
    }
    assertHttps(record.url, `${record.manufacturer} ${record.name} product URL`);
    for (const imageUrl of images) {
      assertHttps(imageUrl, `${record.manufacturer} ${record.name} image URL`);
    }
    record.data = JSON.stringify(data);
    record.images = JSON.stringify([...new Set(images)]);
    const assetKey = [record.manufacturer, record.name, record.model_number]
      .map((value) => value.toLowerCase())
      .join("::");
    Object.assign(record, existingAssets.get(assetKey) ?? Object.fromEntries(assetHeader.map((column) => [column, ""])));
    records.push(record);
  }
}

records.sort(
  (a, b) =>
    a.manufacturer.localeCompare(b.manufacturer, "en", { sensitivity: "base" }) ||
    a.name.localeCompare(b.name, "en", { sensitivity: "base" }),
);

const manufacturerCounts = new Map();
const identities = new Set();
let imageRows = 0;
let lifecycleRows = 0;
for (const record of records) {
  const identity = `${record.manufacturer.toLowerCase()}::${record.model_number.toLowerCase()}`;
  if (identities.has(identity)) throw new Error(`Duplicate fixture identity: ${identity}`);
  identities.add(identity);
  manufacturerCounts.set(
    record.manufacturer,
    (manufacturerCounts.get(record.manufacturer) ?? 0) + 1,
  );
  if (JSON.parse(record.images).length > 0) imageRows += 1;
  const lifecycle = String(JSON.parse(record.data).lifecycle ?? "");
  if (/current|legacy|discontinued/i.test(lifecycle)) lifecycleRows += 1;
}

if (manufacturerCounts.size !== 10) {
  throw new Error(`Expected exactly 10 manufacturers, found ${manufacturerCounts.size}`);
}
if (records.length !== 53) {
  throw new Error(`Expected 53 fixtures, found ${records.length}`);
}
if (imageRows < 50) {
  throw new Error(`Expected at least 50 rows with official images, found ${imageRows}`);
}
if (lifecycleRows < 10) {
  throw new Error(`Expected a documented current/legacy mix, found ${lifecycleRows} lifecycle rows`);
}

const matrix = [
  outputHeader,
  ...records.map((record) => outputHeader.map((column) => record[column])),
];

const workbook = Workbook.create();
const sheet = workbook.worksheets.add("Fixtures");
sheet.getRangeByIndexes(0, 0, matrix.length, outputHeader.length).values = matrix;
sheet.showGridLines = false;
sheet.freezePanes.freezeRows(1);
sheet.getRange("A1:O1").format = {
  fill: "#1F4E78",
  font: { name: "Arial", size: 10, bold: true, color: "#FFFFFF" },
  verticalAlignment: "center",
  horizontalAlignment: "center",
};
sheet.getRange(`A2:O${matrix.length}`).format = {
  font: { name: "Arial", size: 10, color: "#1F1F1F" },
  verticalAlignment: "center",
};
sheet.getRange(`A1:O${matrix.length}`).format.autofitColumns();
sheet.getRange("A:A").format.columnWidth = 24;
sheet.getRange("B:B").format.columnWidth = 24;
sheet.getRange("C:C").format.columnWidth = 28;
sheet.getRange("D:E").format.columnWidth = 18;
sheet.getRange("F:F").format.columnWidth = 52;
sheet.getRange("G:H").format.columnWidth = 70;
sheet.getRange("I:O").format.columnWidth = 34;
workbook.recalculate();

const inspected = await workbook.inspect({
  kind: "table",
  range: `Fixtures!A1:O${matrix.length}`,
  include: "values,formulas",
  tableMaxRows: 8,
  tableMaxCols: 15,
  maxChars: 6000,
});
const errorScan = await workbook.inspect({
  kind: "match",
  searchTerm: "#REF!|#DIV/0!|#VALUE!|#NAME\\?|#N/A|#NUM!|#NULL!|#SPILL!|#CALC!",
  options: { useRegex: true, maxResults: 50 },
  summary: "final formula error scan",
});

const preview = await workbook.render({
  sheetName: "Fixtures",
  range: `A1:O${matrix.length}`,
  scale: 0.65,
  format: "png",
});
await fs.mkdir(path.dirname(previewPath), { recursive: true });
await fs.writeFile(previewPath, new Uint8Array(await preview.arrayBuffer()));

const csvText = `${matrix.map((row) => row.map(csvCell).join(",")).join("\n")}\n`;
await fs.mkdir(path.dirname(outputPath), { recursive: true });
await fs.writeFile(outputPath, csvText, "utf8");

console.log(
  JSON.stringify(
    {
      outputPath,
      previewPath,
      rows: records.length,
      manufacturers: Object.fromEntries(manufacturerCounts),
      imageRows,
      emptyImageRows: records.length - imageRows,
      lifecycleRows,
      inspected: inspected.ndjson,
      errorScan: errorScan.ndjson,
    },
    null,
    2,
  ),
);
