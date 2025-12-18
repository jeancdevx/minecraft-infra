const { InstancesClient } = require('@google-cloud/compute');
const nacl = require('tweetnacl');

// Read from environment variables (set by Terraform)
const PROJECT_ID = process.env.PROJECT_ID;
const ZONE = process.env.ZONE;
const INSTANCE_NAME = process.env.INSTANCE_NAME;
const DISCORD_PUBLIC_KEY = process.env.DISCORD_PUBLIC_KEY;

// Initialize client outside handler for connection reuse
let computeClient = null;
function getComputeClient() {
  if (!computeClient) computeClient = new InstancesClient();
  return computeClient;
}

function verifyDiscordRequest(req) {
  const signature = req.headers['x-signature-ed25519'];
  const timestamp = req.headers['x-signature-timestamp'];
  const body = JSON.stringify(req.body);
  if (!signature || !timestamp) return false;
  try {
    return nacl.sign.detached.verify(
      Buffer.from(timestamp + body),
      Buffer.from(signature, 'hex'),
      Buffer.from(DISCORD_PUBLIC_KEY, 'hex')
    );
  } catch { return false; }
}

async function getInstanceStatus() {
  const [instance] = await getComputeClient().get({
    project: PROJECT_ID, zone: ZONE, instance: INSTANCE_NAME
  });
  return {
    status: instance.status,
    ip: instance.networkInterfaces?.[0]?.accessConfigs?.[0]?.natIP || 'N/A'
  };
}

async function startInstance() {
  await getComputeClient().start({
    project: PROJECT_ID, zone: ZONE, instance: INSTANCE_NAME
  });
}

async function stopInstance() {
  await getComputeClient().stop({
    project: PROJECT_ID, zone: ZONE, instance: INSTANCE_NAME
  });
}

async function sendFollowup(appId, token, content) {
  const url = `https://discord.com/api/v10/webhooks/${appId}/${token}`;
  await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ content })
  });
}

async function processCommand(appId, token, command, subcommand) {
  try {
    let content = '❓ Comando no reconocido';
    if (command === 'server') {
      if (subcommand === 'start') {
        const { status, ip } = await getInstanceStatus();
        if (status === 'RUNNING') {
          content = `✅ El servidor ya está corriendo!\n📍 IP: ${ip}:25565`;
        } else {
          await startInstance();
          content = '🚀 Iniciando servidor... Espera 2-3 minutos.';
        }
      } else if (subcommand === 'stop') {
        const { status } = await getInstanceStatus();
        if (status !== 'RUNNING') {
          content = '⚠️ El servidor ya está apagado.';
        } else {
          await stopInstance();
          content = '🛑 Apagando servidor...';
        }
      } else if (subcommand === 'status') {
        const { status, ip } = await getInstanceStatus();
        const emoji = status === 'RUNNING' ? '🟢' : '🔴';
        const statusText = status === 'RUNNING' ? 'Online' : 'Offline';
        content = `${emoji} **Estado:** ${statusText}\n📍 **IP:** ${ip}:25565`;
      }
    }
    await sendFollowup(appId, token, content);
  } catch (error) {
    console.error('Command error:', error);
    await sendFollowup(appId, token, `❌ Error: ${error.message}`);
  }
}

exports.discordBot = async (req, res) => {
  if (!verifyDiscordRequest(req)) return res.status(401).send('Invalid signature');
  
  const { type, data, application_id, token } = req.body;
  
  if (type === 1) return res.json({ type: 1 });
  
  if (type === 2) {
    const command = data.name;
    const subcommand = data.options?.[0]?.name;
    
    // Respond immediately with DEFERRED (type 5) to avoid timeout
    res.json({ type: 5 });
    
    // Process in background
    processCommand(application_id, token, command, subcommand);
    return;
  }
  
  res.status(400).send('Unknown interaction type');
};
