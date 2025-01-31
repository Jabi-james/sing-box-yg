require('dotenv').config();
const express = require("express");
const { exec } = require('child_process');
const app = express();
app.use(express.json());
const commandToRun = "cd ~ && bash serv00keep.sh";
function runCustomCommand() {
exec(commandToRun, function (err, stdout, stderr) {
if (err) {
console.log("Command execution error: " + err);
return;
}
if (stderr) {
console.log("Command execution standard error output: " + stderr);
}
console.log("Command execution success:\n" + stdout);
});
}
setInterval(runCustomCommand, 3 * 60 * 1000); // 3 minutes = 3 * 60 * 1000 milliseconds
app.get("/up", function (req, res) {
runCustomCommand();
res.type("html").send("<pre>Serv00 web page keep alive start: Serv00! UP! UP! UP! </pre>");
});
app.use((req, res, next) => {
if (req.path === '/up') {
return next();
}
res.status(404).send('Change the browser address to: http://name.name.serv00.net/up to start Serv00 web page keep alive');
});
app.listen(3000, () => {
console.log("Server started, listening on port 3000");
runCustomCommand();
});
