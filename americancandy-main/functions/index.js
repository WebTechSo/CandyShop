const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const { onCall, HttpsError } = require("firebase-functions/v2/https");

admin.initializeApp();

const SETTINGS_DOC = "admin_setting/vw0U6xyVtJRKsL2b7F57";

async function getAdminSetting() {
  const snap = await admin.firestore().doc(SETTINGS_DOC).get();
  return snap.exists ? snap.data() : null;
}

function normalizeBool(v, defaultValue = false) {
  if (v === true || v === false) return v;
  if (typeof v === "string") {
    const s = v.toLowerCase().trim();
    if (s === "true" || s === "1" || s === "yes") return true;
    if (s === "false" || s === "0" || s === "no") return false;
  }
  return defaultValue;
}

async function createSmtpTransporter() {
  const settings = await getAdminSetting();
  const smtp = settings?.smtp_setup || null;
  if (!smtp || !smtp.host || !smtp.port || !smtp.username || !smtp.password) {
    throw new HttpsError("failed-precondition", "SMTP not configured");
  }
  return {
    smtp,
    transporter: nodemailer.createTransport({
      host: smtp.host,
      port: Number(smtp.port),
      secure: normalizeBool(smtp.secure, Number(smtp.port) === 465),
      auth: {
        user: smtp.username,
        pass: smtp.password,
      },
    }),
  };
}

exports.sendOrderConfirmationEmail = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Not signed in");
  const data = request.data || {};
  const orderId = (data.orderId || "").toString().trim();
  const invoiceBase64 = (data.invoiceBase64 || "").toString().trim();
  if (!orderId) throw new HttpsError("invalid-argument", "Missing orderId");
  if (!invoiceBase64)
    throw new HttpsError("invalid-argument", "Missing invoiceBase64");

  const orderSnap = await admin.firestore().collection("Orders").doc(orderId).get();
  if (!orderSnap.exists) throw new HttpsError("not-found", "Order not found");
  const order = orderSnap.data() || {};

  const orderUserId = (order.user_id || "").toString();
  if (orderUserId !== request.auth.uid) {
    throw new HttpsError("permission-denied", "Not your order");
  }

  const orderCode = (order.order_code || "").toString().trim() || orderId;
  const contactEmail = (order.contact_email || "").toString().trim();
  const authEmail = (request.auth.token.email || "").toString().trim();
  const toSet = new Set();
  if (authEmail) toSet.add(authEmail);
  if (contactEmail) toSet.add(contactEmail);
  const to = Array.from(toSet);
  if (to.length === 0) throw new HttpsError("failed-precondition", "No recipient email");

  const shippingMethod = (order.shipping_option || "").toString().trim();
  const shippingCost = Number(order.shipping_cost || 0);
  const total = Number(order.grand_total || 0);
  const invoiceUrl = (order.invoice_url || "").toString().trim();
  const name = (order.contact_name || "Customer").toString().trim();

  const subject = `Order confirmation ${orderCode}`;
  const html = `
    <p>Hi ${name || "Customer"},</p>
    <p>Thanks for your order <b>${orderCode}</b>.</p>
    <p>Shipping: <b>${shippingMethod || "Normal"}</b> (£${shippingCost.toFixed(2)})</p>
    <p>Total: <b>£${total.toFixed(2)}</b></p>
    ${invoiceUrl ? `<p>Invoice: <a href="${invoiceUrl}">Download PDF</a></p>` : ""}
  `;

  const { smtp, transporter } = await createSmtpTransporter();
  await transporter.sendMail({
    from: smtp.from_email || smtp.username,
    to: to.join(","),
    subject,
    html,
    attachments: [
      {
        filename: `invoice_${orderCode}.pdf`,
        content: Buffer.from(invoiceBase64, "base64"),
        contentType: "application/pdf",
      },
    ],
  });

  return { ok: true };
});
