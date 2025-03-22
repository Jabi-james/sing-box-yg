require('dotenv').config();
const express = require("express");
const { exec } = require('child_process');
const app = express();
app.use(express.json());
const commandToRun = "cd ~ && bash serv00keep.sh";
function runCustomCommand() {
    exec(commandToRun, (err, stdout, stderr) => {
        if (err) console.error("Execution Error:", err);
        else console.log("Execution Success:", stdout);
    });
}
app.get("/up", (req, res) => {
    runCustomCommand();
    res.type("html").send("<pre>Serv00-name server web page keep alive start：Serv00-name！UP！UP！UP！</pre>");
});
app.get("/re", (req, res) => {
    const additionalCommands = `
        USERNAME=$(whoami | tr '[:upper:]' '[:lower:]')
        FULL_PATH="/home/\${USERNAME}/domains/\${USERNAME}.serv00.net/logs"
        cd "\$FULL_PATH"
        pkill -f 'run -c con' || echo "No processes to terminate, ready to restart……"
        sbb="\$(cat sb.txt 2>/dev/null)"
        nohup ./"\$sbb" run -c config.json >/dev/null 2>&1 &
        sleep 2
        (cd ~ && bash serv00keep.sh >/dev/null 2>&1) &  
        echo 'The main program restarted successfully. Please check whether the three main nodes are available. If not, refresh the restart webpage or reset the port'
    `;
    exec(additionalCommands, (err, stdout, stderr) => {
        console.log('stdout:', stdout);
        console.error('stderr:', stderr);
        if (err) {
            return res.status(500).send(`错误：${stderr || stdout}`);
        }
        res.type('text').send(stdout);
    });
}); 

const changeportCommands = "cd ~ && bash webport.sh"; 
function runportCommand() {
exec(changeportCommands, { maxBuffer: 1024 * 1024 * 10 }, (err, stdout, stderr) => {
        console.log('stdout:', stdout);
        console.error('stderr:', stderr);
        if (err) {
            console.error('Execution error:', err);
            return res.status(500).send(`错误：${stderr || stdout}`);
        }
        if (stderr) {
            console.error('stderr output:', stderr);
            return res.status(500).send(`stderr: ${stderr}`);
        }
        res.type('text').send(stdout);
    });
}
app.get("/rp", (req, res) => {
   runportCommand();  
   res.type("html").send("<pre>Resetting three node ports is complete! Please close this page immediately and wait for 20 seconds. Change the homepage suffix to /list/youruuid to view the node and subscription information after the updated port</pre>");
});
app.get("/list/key", (req, res) => {
    const listCommands = `
        USERNAME=$(whoami | tr '[:upper:]' '[:lower:]')
        USERNAME1=$(whoami)
        FULL_PATH="/home/\${USERNAME1}/domains/\${USERNAME}.serv00.net/logs/list.txt"
        cat "\$FULL_PATH"
    `;
    exec(listCommands, (err, stdout, stderr) => {
        if (err) {
            console.error(`Path validation failed: ${stderr}`);
            return res.status(404).send(stderr);
        }
        res.type('text').send(stdout);
    });
});
app.use((req, res) => {
    res.status(404).send('Please enter the browser address：http://where.name.serv00.net Add three path functions at the end: /up is for keep alive, /re is for restart, /rp is for resetting the node port, and /list/youruuid is for node and subscription information');
});
setInterval(runCustomCommand, 3 * 60 * 1000);
app.listen(3000, () => {
    console.log("The server runs on port 3000");
    runCustomCommand();
});
