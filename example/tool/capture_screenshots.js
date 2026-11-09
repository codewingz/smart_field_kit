const { chromium } = require('playwright-core');
const OUT = process.argv[2];
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
(async () => {
  const browser = await chromium.launch({
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    headless: true,
    args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'],
  });
  const ctx = await browser.newContext({ viewport: { width: 1100, height: 820 }, deviceScaleFactor: 1, colorScheme: 'light' });
  const page = await ctx.newPage();
  await page.goto('http://localhost:8765/');
  await sleep(7000);
  await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
  await sleep(1000);
  const nav = async (name) => { await page.getByRole('button', { name: new RegExp('^' + name) }).first().click(); await sleep(900); };
  const typeInto = async (label, text) => {
    const box = page.getByRole('textbox', { name: label }).first();
    await box.focus(); await sleep(300);
    await page.keyboard.press('Meta+A'); await page.keyboard.type(text, { delay: 60 }); await sleep(300);
  };
  const shot = async (name) => { await sleep(500); await page.screenshot({ path: `${OUT}/${name}.png` }); };

  await nav('Numbers');
  await typeInto('Amount', '50000.00');
  await typeInto('Discount', '12.5');
  await page.keyboard.press('Tab'); await sleep(800);
  await shot('amount_percentage_light');

  await nav('Passwords');
  const pw = page.getByRole('textbox', { name: 'Password', exact: true }).nth(1);
  await pw.focus(); await page.keyboard.type('abc12345', { delay: 40 });
  await typeInto('Confirm password', 'different');
  await page.getByRole('button', { name: 'Validate' }).click(); await sleep(800);
  await shot('validation_error_light');

  await nav('Phone');
  await typeInto('Phone number', '+923001234567');
  await shot('phone_parsing_light');

  await page.getByRole('button', { name: /Toggle light and dark/ }).click(); await sleep(1200);
  await shot('phone_parsing_dark');

  await page.getByRole('button', { name: /Toggle light and dark/ }).click(); await sleep(1000);
  await nav('Numbers');
  await page.getByRole('textbox', { name: 'Amount' }).first().focus(); await sleep(400); await page.keyboard.press('Meta+A'); await page.keyboard.press('Backspace');
  const fs = require('fs'); fs.mkdirSync(OUT + '/frames', { recursive: true });
  await page.mouse.move(600, 400); await page.mouse.wheel(0, 250); await sleep(600);
  let n = 0;
  const frame = async () => { await page.screenshot({ path: `${OUT}/frames/f${String(n++).padStart(3, '0')}.png` }); };
  await frame();
  for (const ch of '50000.00') { await page.keyboard.type(ch); await sleep(250); await frame(); }
  await page.keyboard.press('Tab'); await sleep(700); await frame(); await sleep(500); await frame(); await frame();
  await ctx.close();
  const mobile = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, colorScheme: 'dark' });
  const mp = await mobile.newPage();
  await mp.goto('http://localhost:8765/'); await sleep(7000);
  await mp.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click()); await sleep(1000);
  await mp.screenshot({ path: `${OUT}/mobile_dark.png` });
  await browser.close();
})().catch((e) => { console.error(e); process.exit(1); });
