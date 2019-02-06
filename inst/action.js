async function waitForScreenshot(page) {
  await page.waitFor(2500)
}

module.exports = {
  waitForScreenshot: waitForScreenshot
};
