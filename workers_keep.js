addEventListener('scheduled', event => event.waitUntil(handleScheduled()));
// Use Yongge's serv00 SSH script or Github/VPS/soft router script to generate keep-alive and restart web page
// Each keep-alive/up page or each restart/re page is separated by a space or, or, and the page is preceded by http://
const urlString = 'http://Keep alive or restart web page 1 http://Keep alive or restart web page 2 http://Keep alive or restart web page 3 ………';
const urls = urlString.split(/[\s,，]+/);
const TIMEOUT = 5000;
async function fetchWithTimeout(url) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), TIMEOUT);
  try {
    await fetch(url, { signal: controller.signal });
    console.log(`✅ success: ${url}`);
  } catch (error) {
    console.warn(`❌ Access failed: ${url}, mistake: ${error.message}`);
  } finally {
    clearTimeout(timeout);
  }
}
async function handleScheduled() {
  console.log('⏳ Mission Start');
  await Promise.all(urls.map(fetchWithTimeout));
  console.log('📊 Mission Complete');
}
