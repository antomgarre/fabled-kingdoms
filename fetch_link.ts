import puppeteer from 'puppeteer';

(async () => {
  console.log("Launching browser...");
  const browser = await puppeteer.launch();
  const page = await browser.newPage();
  console.log("Navigating...");
  await page.goto('https://quaternius.com/packs/animatedrpgcharacters.html');
  const hrefs = await page.evaluate(() => Array.from(document.querySelectorAll('a')).map(a => a.href));
  const links = hrefs.filter(h => h.includes('drive.google') || h.includes('.zip'));
  console.log("LINKS FOUND:", links);
  await browser.close();
})();
