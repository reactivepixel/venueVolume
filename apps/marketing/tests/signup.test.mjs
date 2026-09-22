import test from "node:test";
import assert from "node:assert/strict";
import { classifyContact, makeAlphaLead } from "../src/signup.js";

test("accepts ordinary email addresses", () => {
  assert.equal(classifyContact("operator@glasshouse.live"), "email");
});

test("accepts formatted international phone numbers", () => {
  assert.equal(classifyContact("+1 (212) 555-0199"), "phone");
});

test("rejects incomplete contact details", () => {
  assert.equal(classifyContact("not ready"), null);
  assert.equal(classifyContact("555-12"), null);
});

test("builds a structured mock lead", () => {
  const lead = makeAlphaLead(" test@example.com ");
  assert.equal(lead.contact, "test@example.com");
  assert.equal(lead.contactType, "email");
  assert.equal(lead.source, "marketing-alpha");
  assert.ok(!Number.isNaN(Date.parse(lead.capturedAt)));
});
