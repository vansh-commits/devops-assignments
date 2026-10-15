const http = require("http");

const PORT = process.env.PORT || 3000;

function greeting(name = "World") {
  return `Hello ${name} from Vansh's CI/CD demo app!`;
}

function handler(req, res) {
  if (req.url === "/health") {
    res.writeHead(200, { "Content-Type": "application/json" });
    return res.end(JSON.stringify({ status: "ok" }));
  }
  res.writeHead(200, { "Content-Type": "text/html" });
  res.end(`<h1>${greeting()}</h1><p>Build: ${process.env.BUILD_SHA || "local"}</p>`);
}

if (require.main === module) {
  http.createServer(handler).listen(PORT, () => console.log(`Demo app on :${PORT}`));
}

module.exports = { greeting, handler };
