const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function classifyContact(value) {
  const contact = value.trim();
  if (EMAIL_PATTERN.test(contact)) return "email";

  const digits = contact.replace(/\D/g, "");
  if (digits.length >= 7 && digits.length <= 15 && /^[+\d\s().-]+$/.test(contact)) {
    return "phone";
  }

  return null;
}

export function makeAlphaLead(contact) {
  return {
    contact: contact.trim(),
    contactType: classifyContact(contact),
    source: "marketing-alpha",
    capturedAt: new Date().toISOString(),
  };
}
