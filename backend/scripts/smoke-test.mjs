const apiBaseUrl = process.env.API_BASE_URL ?? "http://127.0.0.1/api";

async function requestJson(path, options = {}) {
  const response = await fetch(`${apiBaseUrl}${path}`, options);
  const body = await response.json();
  return { status: response.status, body };
}

const devices = await requestJson("/devices");
const adminLogin = await requestJson("/auth/login", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ username: "admin", password: "admin123" })
});

console.log(JSON.stringify({
  apiBaseUrl,
  devicesStatus: devices.status,
  devicesCount: Array.isArray(devices.body) ? devices.body.length : null,
  adminLoginStatus: adminLogin.status,
  adminLoginBody: adminLogin.body
}, null, 2));
